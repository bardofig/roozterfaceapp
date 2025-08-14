// functions/index.js

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue, FieldPath } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { GoogleAuth } = require("google-auth-library");
const logger = require("firebase-functions/logger");

initializeApp();
const db = getFirestore();
const auth = getAuth();

/**
 * Se dispara cuando un documento en cualquier subcolección 'gallos' es escrito.
 * Mantiene la colección raíz 'showcase_listings' sincronizada.
 */
exports.onRoosterUpdate = onDocumentWritten("galleras/{galleraId}/gallos/{roosterId}", async (event) => {
    const { galleraId, roosterId } = event.params;
    const showcaseRef = db.collection("showcase_listings").doc(roosterId);

    if (!event.data.after.exists) {
        logger.log(`Gallo ${roosterId} eliminado, quitando del escaparate.`);
        try {
            await showcaseRef.delete();
        } catch (error) {
            logger.error("Error al eliminar del escaparate tras borrado:", error);
        }
        return;
    }

    const roosterData = event.data.after.data();
    const isInShowcase = roosterData.status === "En Venta" && roosterData.showInShowcase === true;

    if (isInShowcase) {
        logger.log(`Publicando/Actualizando gallo ${roosterId} en el escaparate.`);
        try {
            const galleraDoc = await db.collection("galleras").doc(galleraId).get();
            if (!galleraDoc.exists) {
                logger.error(`Gallera ${galleraId} no encontrada.`);
                return showcaseRef.delete();
            }
            const ownerId = galleraDoc.data().ownerId;
            const ownerDoc = await db.collection("users").doc(ownerId).get();
            if (!ownerDoc.exists) {
                logger.error(`Dueño ${ownerId} no encontrado.`);
                return showcaseRef.delete();
            }
            const ownerName = ownerDoc.data().fullName;
            const galleraName = galleraDoc.data().name;

            await showcaseRef.set({
                originalRoosterId: roosterId,
                originalGalleraId: galleraId,
                name: roosterData.name,
                plate: roosterData.plate,
                imageUrl: roosterData.imageUrl,
                birthDate: roosterData.birthDate,
                breedLine: roosterData.breedLine,
                color: roosterData.color,
                combType: roosterData.combType,
                legColor: roosterData.legColor,
                fatherName: roosterData.fatherName,
                fatherPlate: roosterData.fatherPlate,
                fatherLineageText: roosterData.fatherLineageText,
                motherName: roosterData.motherName,
                motherPlate: roosterData.motherPlate,
                motherLineageText: roosterData.motherLineageText,
                salePrice: roosterData.salePrice,
                ownerUid: ownerId,
                ownerName: ownerName,
                galleraName: galleraName,
                lastUpdate: FieldValue.serverTimestamp(),
            }, { merge: true });
        } catch (error) {
            logger.error("Error al publicar en el escaparate:", error);
        }
    } else {
        logger.log(`Gallo ${roosterId} no cumple requisitos, quitando del escaparate.`);
        try {
            await showcaseRef.delete();
        } catch (error) {
            logger.error("Error al eliminar del escaparate:", error);
        }
    }
});

/**
 * Obtiene los perfiles detallados de los miembros de una gallera.
 */
exports.getGalleraMemberDetails = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    }
    const requesterUid = request.auth.uid;
    const { galleraId } = request.data;
    if (!galleraId) {
        throw new HttpsError("invalid-argument", "Se requiere el ID de la gallera.");
    }
    try {
        const galleraDoc = await db.collection("galleras").doc(galleraId).get();
        if (!galleraDoc.exists) {
            throw new HttpsError("not-found", "La gallera no existe.");
        }
        const members = galleraDoc.data().members;
        if (!members || !members[requesterUid]) {
            throw new HttpsError("permission-denied", "No eres miembro de esta gallera.");
        }
        const memberIds = Object.keys(members);
        if (memberIds.length === 0) return [];
        const userDocs = await db.collection("users").where(FieldPath.documentId(), "in", memberIds).get();
        return userDocs.docs.map((doc) => ({
            ...doc.data(),
            roleInGallera: members[doc.id] ?? 'desconocido',
        }));
    } catch (error) {
        logger.error("Error en getGalleraMemberDetails:", error);
        throw new HttpsError("internal", "Error al obtener detalles de miembros.");
    }
});

/**
 * Crea una invitación para que un usuario se una a una gallera.
 */
exports.inviteMemberToGallera = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    }
    const inviterUid = request.auth.uid;
    const inviterName = request.auth.token.name || request.auth.token.email;
    const { galleraId, invitedEmail, role } = request.data;
    if (!galleraId || !invitedEmail || !role) {
        throw new HttpsError("invalid-argument", "Faltan datos.");
    }

    try {
        const invitedUserRecord = await auth.getUserByEmail(invitedEmail);
        const invitedUid = invitedUserRecord.uid;

        if (inviterUid === invitedUid) {
            throw new HttpsError("invalid-argument", "No puedes invitarte a ti mismo.");
        }

        const galleraRef = db.collection("galleras").doc(galleraId);
        const invitationRef = db.collection("invitations").doc(invitedUid);

        const galleraDoc = await galleraRef.get();
        if (!galleraDoc.exists) {
            throw new HttpsError("not-found", "La gallera no existe.");
        }
        if (galleraDoc.data().ownerId !== inviterUid) {
            throw new HttpsError("permission-denied", "Solo el propietario puede invitar.");
        }
        
        const galleraName = galleraDoc.data().name;

        await invitationRef.set({
            pending_invitations: {
                [galleraId]: {
                    inviterName: inviterName,
                    galleraName: galleraName,
                    role: role,
                    date: FieldValue.serverTimestamp(),
                },
            },
        }, { merge: true });

        logger.log(`Invitación creada de ${inviterUid} para ${invitedUid} a la gallera ${galleraId}.`);
        return { success: true, message: "Invitación enviada con éxito." };

    } catch (error) {
        logger.error("Error al enviar invitación:", error);
        if (error.code === "auth/user-not-found") {
            throw new HttpsError("not-found", `No se encontró usuario con el email: ${invitedEmail}.`);
        }
        throw new HttpsError("internal", "Error al procesar la invitación.");
    }
});

/**
 * Acepta una invitación a una gallera.
 */
exports.acceptInvitation = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    }
    const invitedUid = request.auth.uid;
    const { galleraId } = request.data;
    if (!galleraId) {
        throw new HttpsError("invalid-argument", "Falta el ID de la gallera.");
    }
    
    const galleraRef = db.collection("galleras").doc(galleraId);
    const userRef = db.collection("users").doc(invitedUid);
    const invitationRef = db.collection("invitations").doc(invitedUid);

    try {
        const invitationDoc = await invitationRef.get();
        const pendingInvites = invitationDoc.data()?.pending_invitations || {};
        const invitation = pendingInvites[galleraId];

        if (!invitation) {
            throw new HttpsError("not-found", "No se encontró una invitación válida para esta gallera.");
        }
        
        const role = invitation.role;

        await db.runTransaction(async (transaction) => {
            transaction.update(galleraRef, { [`members.${invitedUid}`]: role });
            transaction.update(userRef, { galleraIds: FieldValue.arrayUnion(galleraId) });
            transaction.update(invitationRef, { [`pending_invitations.${galleraId}`]: FieldValue.delete() });
        });

        logger.log(`Usuario ${invitedUid} aceptó la invitación a la gallera ${galleraId}.`);
        return { success: true, message: "Te has unido a la gallera con éxito." };

    } catch (error) {
        logger.error("Error al aceptar invitación:", error);
        throw new HttpsError("internal", "No se pudo procesar la aceptación.");
    }
});

/**
 * Rechaza una invitación a una gallera.
 */
exports.declineInvitation = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    }
    const invitedUid = request.auth.uid;
    const { galleraId } = request.data;
    if (!galleraId) {
        throw new HttpsError("invalid-argument", "Falta el ID de la gallera.");
    }

    const invitationRef = db.collection("invitations").doc(invitedUid);
    try {
        await invitationRef.update({
            [`pending_invitations.${galleraId}`]: FieldValue.delete(),
        });
        logger.log(`Usuario ${invitedUid} rechazó la invitación a la gallera ${galleraId}.`);
        return { success: true, message: "Invitación rechazada." };
    } catch (error) {
        logger.error("Error al rechazar invitación:", error);
        throw new HttpsError("internal", "No se pudo procesar el rechazo.");
    }
});

/**
 * Elimina a un miembro de una gallera.
 */
exports.removeMemberFromGallera = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    }
    const removerUid = request.auth.uid;
    const { galleraId, memberId } = request.data;
    if (!galleraId || !memberId) {
        throw new HttpsError("invalid-argument", "Faltan datos.");
    }

    try {
        const galleraRef = db.collection("galleras").doc(galleraId);
        await db.runTransaction(async (transaction) => {
            const galleraDoc = await transaction.get(galleraRef);
            if (!galleraDoc.exists) throw new HttpsError("not-found", "La gallera no existe.");

            const galleraData = galleraDoc.data();
            if (galleraData.ownerId !== removerUid) throw new HttpsError("permission-denied", "Solo el propietario puede eliminar.");
            if (galleraData.ownerId === memberId) throw new HttpsError("invalid-argument", "El propietario no puede eliminarse.");

            const memberToRemoveRef = db.collection("users").doc(memberId);
            transaction.update(galleraRef, { [`members.${memberId}`]: FieldValue.delete() });
            transaction.update(memberToRemoveRef, { galleraIds: FieldValue.arrayRemove(galleraId) });
        });
        logger.log(`Éxito: Miembro ${memberId} eliminado de la gallera ${galleraId}.`);
        return { success: true, message: "Miembro eliminado con éxito." };
    } catch (error) {
        logger.error("Error al eliminar miembro:", error);
        throw new HttpsError("internal", "Error al eliminar al miembro.");
    }
});

/**
 * Valida una compra de suscripción de Android.
 */
exports.validateAndroidPurchase = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    }
    const uid = request.auth.uid;
    const { packageName, subscriptionId, purchaseToken } = request.data;
    if (!packageName || !subscriptionId || !purchaseToken) {
        throw new HttpsError("invalid-argument", "Faltan datos de validación.");
    }

    try {
        const auth = new GoogleAuth({ scopes: "https://www.googleapis.com/auth/androidpublisher" });
        const authClient = await auth.getClient();
        const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptions/${subscriptionId}/tokens/${purchaseToken}`;
        const response = await authClient.request({ url });
        const purchaseData = response.data;

        if (purchaseData.paymentState !== 1) { // 1 = Pagado
            throw new HttpsError("failed-precondition", `La compra no está activa. Estado: ${purchaseData.paymentState}`);
        }
        let newPlan = "iniciacion";
        if (subscriptionId.startsWith("maestro_criador")) newPlan = "maestro";
        else if (subscriptionId.startsWith("club_elite")) newPlan = "elite";
        
        const expiryTimeMillis = parseInt(purchaseData.expiryTimeMillis);

        await db.collection("users").doc(uid).update({
            plan: newPlan,
            activeSubscriptionId: subscriptionId,
            purchaseToken: purchaseToken,
            subscriptionExpiryDate: new Date(expiryTimeMillis),
        });
        logger.log(`Éxito: Usuario ${uid} actualizado al plan '${newPlan}'.`);
        return { success: true, plan: newPlan };
    } catch (error) {
        logger.error(`Error validando la compra para ${uid}:`, error);
        throw new HttpsError("internal", "Error al validar la compra.");
    }
});