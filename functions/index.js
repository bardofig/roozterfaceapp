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
 * Se dispara cuando un documento de gallo es escrito.
 * RECONSTRUIDA CON LÓGICA DEFENSIVA CONTRA VALORES `undefined`.
 */
exports.onRoosterUpdate = onDocumentWritten("galleras/{galleraId}/gallos/{roosterId}", async (event) => {
    const { galleraId, roosterId } = event.params;
    const showcaseRef = db.collection("showcase_listings").doc(roosterId);

    if (!event.data.after.exists) {
        logger.info(`[${roosterId}] Gallo eliminado. Limpiando escaparate.`);
        try {
            await showcaseRef.delete();
        } catch (error) {
            if (error.code !== 5) {
                logger.error(`[${roosterId}] Error al limpiar escaparate tras eliminación:`, error);
            }
        }
        return;
    }

    const roosterData = event.data.after.data();
    const isInShowcase = roosterData.status === "En Venta" && roosterData.showInShowcase === true;

    if (isInShowcase) {
        logger.info(`[${roosterId}] Publicando/Actualizando en escaparate.`);
        try {
            const galleraDoc = await db.collection("galleras").doc(galleraId).get();
            if (!galleraDoc.exists) {
                logger.error(`[${roosterId}] Gallera ${galleraId} no encontrada. Abortando.`);
                return showcaseRef.delete();
            }
            const ownerId = galleraDoc.data().ownerId;
            if (!ownerId) {
                logger.error(`[${roosterId}] La gallera ${galleraId} no tiene ownerId. Abortando.`);
                return showcaseRef.delete();
            }

            const ownerDoc = await db.collection("users").doc(ownerId).get();
            if (!ownerDoc.exists) {
                logger.error(`[${roosterId}] Dueño ${ownerId} no encontrado. Abortando.`);
                return showcaseRef.delete();
            }
            
            const ownerName = ownerDoc.data().fullName;
            const galleraName = galleraDoc.data().name;

            // SANITIZACIÓN: Usamos `|| null` para convertir `undefined` a `null`, que es válido para Firestore.
            const listingData = {
                originalRoosterId: roosterId,
                originalGalleraId: galleraId,
                name: roosterData.name || null,
                plate: roosterData.plate || null,
                imageUrl: roosterData.imageUrl || null,
                birthDate: roosterData.birthDate || null,
                breedLine: roosterData.breedLine || null,
                color: roosterData.color || null,
                combType: roosterData.combType || null,
                legColor: roosterData.legColor || null,
                fatherName: roosterData.fatherName || null,
                fatherPlate: roosterData.fatherPlate || null,
                fatherLineageText: roosterData.fatherLineageText || null,
                motherName: roosterData.motherName || null,
                motherPlate: roosterData.motherPlate || null,
                motherLineageText: roosterData.motherLineageText || null,
                salePrice: roosterData.salePrice || null,
                ownerUid: ownerId,
                ownerName: ownerName || null,
                galleraName: galleraName || null,
                lastUpdate: FieldValue.serverTimestamp(),
            };
            
            await showcaseRef.set(listingData, { merge: true });
            logger.info(`[${roosterId}] Anuncio publicado/actualizado con ÉXITO.`);

        } catch (error) {
            logger.error(`[${roosterId}] ERROR CATASTRÓFICO durante la publicación:`, error);
            try {
                await showcaseRef.delete();
            } catch (deleteError) {
                // Silencio
            }
        }
    } else {
        logger.info(`[${roosterId}] No cumple requisitos. Limpiando escaparate.`);
        try {
            await showcaseRef.delete();
        } catch (error) {
             if (error.code !== 5) {
                logger.error(`[${roosterId}] Error al limpiar escaparate:`, error);
            }
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
        return userDocs.docs.map((doc) => ({ ...doc.data(), roleInGallera: members[doc.id] ?? 'desconocido' }));
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
        const inviterProfileRef = db.collection("users").doc(inviterUid);
        
        const [galleraDoc, inviterProfileDoc] = await Promise.all([galleraRef.get(), inviterProfileRef.get()]);
        
        if (!galleraDoc.exists) {
            throw new HttpsError("not-found", "La gallera no existe.");
        }
        if (galleraDoc.data().ownerId !== inviterUid) {
            throw new HttpsError("permission-denied", "Solo el propietario puede invitar.");
        }
        if (!inviterProfileDoc.exists) {
            throw new HttpsError("internal", "No se pudo encontrar el perfil del invitador.");
        }
        
        const galleraName = galleraDoc.data().name;
        const inviterName = inviterProfileDoc.data().fullName;

        await invitationRef.set({
            pending_invitations: { [galleraId]: { inviterName, galleraName, role, date: FieldValue.serverTimestamp() } }
        }, { merge: true });
        
        logger.log(`Invitación creada de ${inviterUid} (${inviterName}) para ${invitedUid}.`);
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
        await db.runTransaction(async (t) => {
            const invitationDoc = await t.get(invitationRef);
            const invitation = invitationDoc.data()?.pending_invitations?.[galleraId];
            if (!invitation) {
                throw new HttpsError("not-found", "No se encontró una invitación válida.");
            }
            const role = invitation.role;
            
            t.update(galleraRef, { [`members.${invitedUid}`]: role });
            t.update(userRef, { galleraIds: FieldValue.arrayUnion(galleraId) });
            t.update(invitationRef, { [`pending_invitations.${galleraId}`]: FieldValue.delete() });
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
        await invitationRef.update({ [`pending_invitations.${galleraId}`]: FieldValue.delete() });
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
            if (!galleraDoc.exists) {
                throw new HttpsError("not-found", "La gallera no existe.");
            }

            const galleraData = galleraDoc.data();
            if (galleraData.ownerId !== removerUid) {
                throw new HttpsError("permission-denied", "Solo el propietario puede eliminar.");
            }
            if (galleraData.ownerId === memberId) {
                throw new HttpsError("invalid-argument", "El propietario no puede eliminarse a sí mismo.");
            }

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
        if (subscriptionId.startsWith("maestro_criador")) {
            newPlan = "maestro";
        } else if (subscriptionId.startsWith("club_elite")) {
            newPlan = "elite";
        }
        
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