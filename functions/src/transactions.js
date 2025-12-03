const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

const db = getFirestore();

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
        await transactionRef.delete().catch(() => { });
        return { success: true };
    }
});
