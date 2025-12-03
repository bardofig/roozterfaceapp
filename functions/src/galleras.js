const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue, FieldPath } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const logger = require("firebase-functions/logger");

const db = getFirestore();
const auth = getAuth();

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
