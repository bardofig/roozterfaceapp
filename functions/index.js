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
 * Gestiona la denormalización de datos hacia 'showcase_listings' y 'transactions'.
 * Se dispara cuando un documento de gallo es escrito.
 */
exports.onRoosterUpdate = onDocumentWritten("galleras/{galleraId}/gallos/{roosterId}", async (event) => {
    const { galleraId, roosterId } = event.params;
    const showcaseRef = db.collection("showcase_listings").doc(roosterId);
    // --- CAMBIO DE RUTA ---
    const transactionRef = db.collection("galleras").doc(galleraId).collection("transactions").doc(`sale_${roosterId}`);

    // CASO 1: Gallo eliminado
    if (!event.data.after.exists) {
        logger.info(`[${roosterId}] Gallo eliminado. Limpiando escaparate y transacción.`);
        try {
            await showcaseRef.delete();
            await transactionRef.delete();
        } catch (error) {
            if (error.code !== 5) {
                logger.error(`[${roosterId}] Error al limpiar tras eliminación:`, error);
            }
        }
        return;
    }

    const roosterData = event.data.after.data();
    const isInShowcase = roosterData.status === "En Venta" && roosterData.showInShowcase === true;
    const isSold = roosterData.status === "Vendido" && roosterData.salePrice != null && roosterData.salePrice > 0 && roosterData.saleDate;

    // --- GESTIÓN DEL ESCAPARATE ---
    if (isInShowcase) {
        logger.info(`[${roosterId}] Publicando/Actualizando en escaparate.`);
        try {
            const galleraDoc = await db.collection("galleras").doc(galleraId).get();
            if (!galleraDoc.exists) {
                logger.error(`[${roosterId}] Gallera ${galleraId} no encontrada.`);
                return showcaseRef.delete();
            }
            const ownerId = galleraDoc.data().ownerId;
            if (!ownerId) {
                logger.error(`[${roosterId}] La gallera ${galleraId} no tiene ownerId.`);
                return showcaseRef.delete();
            }
            const ownerDoc = await db.collection("users").doc(ownerId).get();
            if (!ownerDoc.exists) {
                logger.error(`[${roosterId}] Dueño ${ownerId} no encontrado.`);
                return showcaseRef.delete();
            }
            
            const ownerName = ownerDoc.data().fullName;
            const galleraName = galleraDoc.data().name;

            const listingData = {
                originalRoosterId: roosterId, originalGalleraId: galleraId,
                name: roosterData.name || null, plate: roosterData.plate || null,
                imageUrl: roosterData.imageUrl || null, birthDate: roosterData.birthDate || null,
                breedLine: roosterData.breedLine || null, color: roosterData.color || null,
                combType: roosterData.combType || null, legColor: roosterData.legColor || null,
                fatherName: roosterData.fatherName || null, fatherPlate: roosterData.fatherPlate || null,
                fatherLineageText: roosterData.fatherLineageText || null,
                motherName: roosterData.motherName || null, motherPlate: roosterData.motherPlate || null,
                motherLineageText: roosterData.motherLineageText || null,
                salePrice: roosterData.salePrice || null, ownerUid: ownerId,
                ownerName: ownerName || null, galleraName: galleraName || null,
                lastUpdate: FieldValue.serverTimestamp(),
            };
            
            await showcaseRef.set(listingData, { merge: true });
        } catch (error) {
            logger.error(`[${roosterId}] Error durante la publicación en escaparate:`, error);
        }
    } else {
        try {
            await showcaseRef.delete();
        } catch (error) { if (error.code !== 5) { logger.error(`[${roosterId}] Error al limpiar escaparate:`, error); } }
    }

    // --- GESTIÓN DE TRANSACCIONES DE VENTA ---
    if (isSold) {
        const transactionData = {
            type: "ingreso", category: "venta",
            amount: roosterData.salePrice, date: roosterData.saleDate,
            description: `Venta de: ${roosterData.name} (${roosterData.plate || 'S/P'})`,
            relatedDocId: roosterId, createdAt: FieldValue.serverTimestamp(),
        };
        await transactionRef.set(transactionData);
    } else {
        await transactionRef.delete().catch(() => {});
    }
});

exports.onUserUpdate = onDocumentWritten("users/{userId}", async (event) => {
    if (!event.data.before.exists || !event.data.after.exists) return null;
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    if (beforeData.fullName === afterData.fullName) return null;

    const newName = afterData.fullName;
    const userId = event.params.userId;
    logger.info(`[User: ${userId}] Nombre cambiado. Sincronizando anuncios.`);

    try {
        const snapshot = await db.collection("showcase_listings").where("ownerUid", "==", userId).get();
        if (snapshot.empty) return null;
        const batch = db.batch();
        snapshot.docs.forEach(doc => {
            batch.update(db.collection("showcase_listings").doc(doc.id), { ownerName: newName });
        });
        await batch.commit();
        logger.info(`[User: ${userId}] Se sincronizaron ${snapshot.size} anuncios.`);
    } catch (error) {
        logger.error(`[User: ${userId}] Error al sincronizar nombre:`, error);
    }
});

exports.onGalleraUpdate = onDocumentWritten("galleras/{galleraId}", async (event) => {
    if (!event.data.before.exists || !event.data.after.exists) return null;
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    if (beforeData.name === afterData.name) return null;

    const newName = afterData.name;
    const galleraId = event.params.galleraId;
    logger.info(`[Gallera: ${galleraId}] Nombre cambiado. Sincronizando anuncios.`);

    try {
        const snapshot = await db.collection("showcase_listings").where("originalGalleraId", "==", galleraId).get();
        if (snapshot.empty) return null;
        const batch = db.batch();
        snapshot.docs.forEach(doc => {
            batch.update(db.collection("showcase_listings").doc(doc.id), { galleraName: newName });
        });
        await batch.commit();
        logger.info(`[Gallera: ${galleraId}] Se sincronizaron ${snapshot.size} anuncios.`);
    } catch (error) {
        logger.error(`[Gallera: ${galleraId}] Error al sincronizar nombre:`, error);
    }
});

exports.addExpenseTransaction = onCall(async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    const { galleraId, date, category, description, amount } = request.data;
    if (!galleraId || !date || !category || !description || !amount) throw new HttpsError("invalid-argument", "Faltan datos.");
    
    const galleraDoc = await db.collection("galleras").doc(galleraId).get();
    if (!galleraDoc.exists || !galleraDoc.data().members[request.auth.uid]) throw new HttpsError("permission-denied", "No tienes permiso.");
    
    try {
        const transactionData = {
            type: "gasto", category: category,
            amount: Number(amount), date: new Date(date), description: description,
            createdAt: FieldValue.serverTimestamp(),
        };
        const docRef = await db.collection("galleras").doc(galleraId).collection("transactions").add(transactionData);
        return { success: true, transaction: { id: docRef.id, ...transactionData } };
    } catch (error) {
        logger.error("Error al crear transacción de gasto:", error);
        throw new HttpsError("internal", "No se pudo registrar el gasto.");
    }
});

exports.updateExpenseTransaction = onCall(async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    const { transactionId, galleraId, date, category, description, amount } = request.data;
    if (!transactionId || !galleraId || !date || !category || !description || !amount) throw new HttpsError("invalid-argument", "Faltan datos.");

    const transactionRef = db.collection("galleras").doc(galleraId).collection("transactions").doc(transactionId);
    
    const galleraDoc = await db.collection("galleras").doc(galleraId).get();
    if (!galleraDoc.exists || !galleraDoc.data().members[request.auth.uid]) throw new HttpsError("permission-denied", "No tienes permiso.");

    try {
        const updatedData = { date: new Date(date), category: category, description: description, amount: Number(amount) };
        await transactionRef.update(updatedData);
        return { success: true };
    } catch (error) {
        logger.error(`Error al actualizar transacción ${transactionId}:`, error);
        throw new HttpsError("internal", "No se pudo actualizar el gasto.");
    }
});

exports.deleteTransaction = onCall(async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    const { transactionId, galleraId } = request.data;
    if (!transactionId || !galleraId) throw new HttpsError("invalid-argument", "Faltan IDs.");

    const transactionRef = db.collection("galleras").doc(galleraId).collection("transactions").doc(transactionId);
    
    const galleraDoc = await db.collection("galleras").doc(galleraId).get();
    if (!galleraDoc.exists || !galleraDoc.data().members[request.auth.uid]) throw new HttpsError("permission-denied", "No tienes permiso.");

    try {
        await transactionRef.delete();
        return { success: true };
    } catch (error) {
        logger.error(`Error al eliminar transacción ${transactionId}:`, error);
        throw new HttpsError("internal", "No se pudo eliminar la transacción.");
    }
});

exports.updateFightTransaction = onCall(async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    const { galleraId, fightId, netProfit, fightDate, roosterName, opponent } = request.data;
    if (!galleraId || !fightId || !fightDate) throw new HttpsError("invalid-argument", "Faltan datos.");

    const galleraDoc = await db.collection("galleras").doc(galleraId).get();
    if (!galleraDoc.exists || !galleraDoc.data().members[request.auth.uid]) throw new HttpsError("permission-denied", "No tienes permiso.");

    const transactionRef = db.collection("galleras").doc(galleraId).collection("transactions").doc(`fight_${fightId}`);

    if (netProfit != null && typeof netProfit === 'number' && netProfit !== 0) {
        const transactionData = {
            type: netProfit > 0 ? "ingreso" : "gasto", category: "combate",
            amount: Math.abs(netProfit), date: new Date(fightDate),
            description: `Combate de ${roosterName || 'Gallo'} vs ${opponent || 'Oponente'}`,
            relatedDocId: fightId, createdAt: FieldValue.serverTimestamp(),
        };
        await transactionRef.set(transactionData, { merge: true });
        return { success: true };
    } else {
        await transactionRef.delete().catch(() => {});
        return { success: true };
    }
});

exports.getGalleraMemberDetails = onCall(async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    const requesterUid = request.auth.uid;
    const { galleraId } = request.data;
    if (!galleraId) throw new HttpsError("invalid-argument", "Se requiere el ID de la gallera.");
    
    try {
        const galleraDoc = await db.collection("galleras").doc(galleraId).get();
        if (!galleraDoc.exists) throw new HttpsError("not-found", "La gallera no existe.");
        const members = galleraDoc.data().members;
        if (!members || !members[requesterUid]) throw new HttpsError("permission-denied", "No eres miembro.");
        
        const memberIds = Object.keys(members);
        if (memberIds.length === 0) return [];

        const userDocs = await db.collection("users").where(FieldPath.documentId(), "in", memberIds).get();
        return userDocs.docs.map((doc) => ({ ...doc.data(), roleInGallera: members[doc.id] ?? 'desconocido' }));
    } catch (error) {
        logger.error("Error en getGalleraMemberDetails:", error);
        throw new HttpsError("internal", "Error al obtener detalles de miembros.");
    }
});

exports.inviteMemberToGallera = onCall(async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    const inviterUid = request.auth.uid;
    const { galleraId, invitedEmail, role } = request.data;
    if (!galleraId || !invitedEmail || !role) throw new HttpsError("invalid-argument", "Faltan datos.");

    try {
        const invitedUserRecord = await auth.getUserByEmail(invitedEmail);
        const invitedUid = invitedUserRecord.uid;

        if (inviterUid === invitedUid) throw new HttpsError("invalid-argument", "No puedes invitarte a ti mismo.");
        
        const galleraRef = db.collection("galleras").doc(galleraId);
        const invitationRef = db.collection("invitations").doc(invitedUid);
        const inviterProfileRef = db.collection("users").doc(inviterUid);
        
        const [galleraDoc, inviterProfileDoc] = await Promise.all([galleraRef.get(), inviterProfileRef.get()]);
        
        if (!galleraDoc.exists) throw new HttpsError("not-found", "La gallera no existe.");
        if (galleraDoc.data().ownerId !== inviterUid) throw new HttpsError("permission-denied", "Solo el propietario puede invitar.");
        if (!inviterProfileDoc.exists) throw new HttpsError("internal", "No se pudo encontrar el perfil del invitador.");
        
        const galleraName = galleraDoc.data().name;
        const inviterName = inviterProfileDoc.data().fullName;

        await invitationRef.set({
            pending_invitations: { [galleraId]: { inviterName, galleraName, role, date: FieldValue.serverTimestamp() } }
        }, { merge: true });
        
        return { success: true };
    } catch (error) {
        logger.error("Error al enviar invitación:", error);
        if (error.code === "auth/user-not-found") throw new HttpsError("not-found", `No se encontró usuario con el email: ${invitedEmail}.`);
        throw new HttpsError("internal", "Error al procesar la invitación.");
    }
});

exports.acceptInvitation = onCall(async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    const invitedUid = request.auth.uid;
    const { galleraId } = request.data;
    if (!galleraId) throw new HttpsError("invalid-argument", "Falta el ID de la gallera.");
    
    const galleraRef = db.collection("galleras").doc(galleraId);
    const userRef = db.collection("users").doc(invitedUid);
    const invitationRef = db.collection("invitations").doc(invitedUid);
    try {
        await db.runTransaction(async (t) => {
            const invitationDoc = await t.get(invitationRef);
            const invitation = invitationDoc.data()?.pending_invitations?.[galleraId];
            if (!invitation) throw new HttpsError("not-found", "No se encontró una invitación válida.");
            const role = invitation.role;
            
            t.update(galleraRef, { [`members.${invitedUid}`]: role });
            t.update(userRef, { galleraIds: FieldValue.arrayUnion(galleraId) });
            t.update(invitationRef, { [`pending_invitations.${galleraId}`]: FieldValue.delete() });
        });
        return { success: true };
    } catch (error) {
        logger.error("Error al aceptar invitación:", error);
        throw new HttpsError("internal", "No se pudo procesar la aceptación.");
    }
});

exports.declineInvitation = onCall(async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    const invitedUid = request.auth.uid;
    const { galleraId } = request.data;
    if (!galleraId) throw new HttpsError("invalid-argument", "Falta el ID de la gallera.");

    const invitationRef = db.collection("invitations").doc(invitedUid);
    try {
        await invitationRef.update({ [`pending_invitations.${galleraId}`]: FieldValue.delete() });
        return { success: true };
    } catch (error) {
        logger.error("Error al rechazar invitación:", error);
        throw new HttpsError("internal", "No se pudo procesar el rechazo.");
    }
});

exports.removeMemberFromGallera = onCall(async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    const removerUid = request.auth.uid;
    const { galleraId, memberId } = request.data;
    if (!galleraId || !memberId) throw new HttpsError("invalid-argument", "Faltan datos.");

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
        return { success: true };
    } catch (error) {
        logger.error("Error al eliminar miembro:", error);
        throw new HttpsError("internal", "Error al eliminar al miembro.");
    }
});

exports.validateAndroidPurchase = onCall(async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    const uid = request.auth.uid;
    const { packageName, subscriptionId, purchaseToken } = request.data;
    if (!packageName || !subscriptionId || !purchaseToken) throw new HttpsError("invalid-argument", "Faltan datos.");

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
            plan: newPlan, activeSubscriptionId: subscriptionId,
            purchaseToken: purchaseToken, subscriptionExpiryDate: new Date(expiryTimeMillis),
        });
        logger.log(`Éxito: Usuario ${uid} actualizado al plan '${newPlan}'.`);
        return { success: true, plan: newPlan };
    } catch (error) {
        logger.error(`Error validando la compra para ${uid}:`, error);
        throw new HttpsError("internal", "Error al validar la compra.");
    }
});