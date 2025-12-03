const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

const db = getFirestore();

/**
 * Gestiona la denormalización de datos hacia 'showcase_listings' y 'transactions'.
 * Se dispara cuando un documento de gallo es escrito.
 */
exports.onRoosterUpdate = onDocumentWritten("galleras/{galleraId}/gallos/{roosterId}", async (event) => {
    const { galleraId, roosterId } = event.params;
    const showcaseRef = db.collection("showcase_listings").doc(roosterId);
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
