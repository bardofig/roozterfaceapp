// functions/index.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {GoogleAuth} = require("google-auth-library");

admin.initializeApp();
const db = admin.firestore();

/**
 * Valida una compra de suscripción de Android.
 * @param {object} data - Datos enviados desde la app.
 * @param {object} context - Contexto de la llamada.
 * @return {Promise<{success: boolean, plan: string}>} Resultado.
 */
exports.validateAndroidPurchase = functions.https.onCall(
    async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "El usuario debe estar autenticado para validar la compra.",
        );
      }
      const uid = context.auth.uid;

      const {packageName, subscriptionId, purchaseToken} = data;
      if (!packageName || !subscriptionId || !purchaseToken) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Faltan datos esenciales para la validación.",
        );
      }

      try {
        const auth = new GoogleAuth({
          scopes: "https://www.googleapis.com/auth/androidpublisher",
        });
        const authClient = await auth.getClient();

        const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptions/${subscriptionId}/tokens/${purchaseToken}`;

        const response = await authClient.request({url});
        const purchaseData = response.data;

        const isActive = purchaseData.paymentState === 1 ||
                         purchaseData.paymentState === 2;

        if (!isActive) {
          throw new functions.https.HttpsError(
              "failed-precondition",
              `La compra no está activa. Estado: ${purchaseData.paymentState}`,
          );
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

        console.log(`Éxito! Usuario ${uid} actualizado al plan '${newPlan}'.`);
        return {success: true, plan: newPlan};
      } catch (error) {
        console.error(`Error validando la compra para ${uid}:`, error);
        throw new functions.https.HttpsError(
            "internal",
            "Ocurrió un error interno al validar la compra.",
        );
      }
    },
);