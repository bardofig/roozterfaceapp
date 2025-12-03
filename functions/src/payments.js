const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { GoogleAuth } = require("google-auth-library");
const logger = require("firebase-functions/logger");

const db = getFirestore();

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
