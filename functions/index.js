// lib/functions/index.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {GoogleAuth} = require("google-auth-library");

// ... (El código de inicialización y la función validateAndroidPurchase se mantienen igual)
admin.initializeApp();
const db = admin.firestore();

exports.validateAndroidPurchase = functions.https.onCall(async (data, context) => {
  // ... (código existente completo)
});


// --- ¡NUEVA CLOUD FUNCTION PARA INVITAR MIEMBROS! ---

/**
 * Invita a un usuario a unirse a una gallera.
 * @param {object} data - Datos enviados desde la app.
 * @param {string} data.galleraId - El ID de la gallera a la que se invita.
 * @param {string} data.invitedEmail - El email del usuario a invitar.
 * @param {string} data.role - El rol a asignar (ej: "cuidador").
 * @param {object} context - Contexto, incluye la autenticación del invitador.
 * @return {Promise<{success: boolean, message: string}>} Resultado.
 */
exports.inviteMemberToGallera = functions.https.onCall(async (data, context) => {
  // 1. Verificar que el que invita esté autenticado
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Debes estar autenticado para invitar.");
  }
  const inviterUid = context.auth.uid;

  // 2. Validar datos de entrada
  const {galleraId, invitedEmail, role} = data;
  if (!galleraId || !invitedEmail || !role) {
    throw new functions.https.HttpsError("invalid-argument", "Faltan datos (galleraId, invitedEmail, role).");
  }

  // No permitimos auto-invitaciones
  const inviterEmail = context.auth.token.email;
  if (inviterEmail.toLowerCase() === invitedEmail.toLowerCase()) {
    throw new functions.https.HttpsError("invalid-argument", "No puedes invitarte a ti mismo.");
  }

  try {
    const galleraRef = db.collection("galleras").doc(galleraId);
    const galleraDoc = await galleraRef.get();

    if (!galleraDoc.exists) {
      throw new functions.https.HttpsError("not-found", "La gallera especificada no existe.");
    }

    // 3. Verificar que el que invita sea el propietario de la gallera
    const galleraData = galleraDoc.data();
    if (galleraData.ownerId !== inviterUid) {
      throw new functions.https.HttpsError("permission-denied", "Solo el propietario puede invitar miembros.");
    }

    // 4. Buscar al usuario invitado por su email
    const invitedUserRecord = await admin.auth().getUserByEmail(invitedEmail);
    const invitedUid = invitedUserRecord.uid;

    // 5. Usar una transacción para actualizar ambos documentos de forma atómica
    await db.runTransaction(async (transaction) => {
      const userToInviteRef = db.collection("users").doc(invitedUid);

      // Actualizar la lista de miembros en el documento de la gallera
      transaction.update(galleraRef, {
        [`members.${invitedUid}`]: role, // Sintaxis para actualizar un campo en un mapa
      });

      // Actualizar el perfil del usuario invitado para añadir el ID de la gallera
      transaction.update(userToInviteRef, {
        // Usamos ArrayUnion para añadir el ID sin duplicarlo si ya existe
        galleraIds: admin.firestore.FieldValue.arrayUnion(galleraId),
      });
    });

    console.log(`Éxito: ${inviterUid} invitó a ${invitedUid} a la gallera ${galleraId} con el rol de ${role}.`);
    return {success: true, message: "Invitación procesada con éxito."};
  } catch (error) {
    console.error("Error al invitar miembro:", error);
    // Devolvemos errores más amigables para la UI
    if (error.code === "auth/user-not-found") {
      throw new functions.https.HttpsError("not-found", `No se encontró ningún usuario con el email: ${invitedEmail}.`);
    }
    throw new functions.https.HttpsError("internal", "Ocurrió un error al procesar la invitación.");
  }
});


// --- FUNCIÓN DE PRUEBA DE AUTENTICACIÓN ---
exports.checkAuth = functions.https.onCall((data, context) => {
  if (!context.auth) {
    // Si no hay autenticación, lanza un error claro.
    throw new functions.https.HttpsError(
        "unauthenticated",
        "La función confirma: NO estás autenticado.",
    );
  }

  // Si hay autenticación, devuelve los datos.
  console.log(`Autenticación exitosa para el UID: ${context.auth.uid}`);
  return {
    message: `¡Éxito! Estás autenticado como ${context.auth.token.email}.`,
    uid: context.auth.uid,
  };
});