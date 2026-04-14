const { initializeApp } = require("firebase-admin/app");

initializeApp();

// Export triggers
const triggers = require("./src/triggers");
exports.onRoosterUpdate = triggers.onRoosterUpdate;
exports.onUserUpdate = triggers.onUserUpdate;
exports.onGalleraUpdate = triggers.onGalleraUpdate;
exports.onTransactionCreated = triggers.onTransactionCreated;
exports.onFightResult = triggers.onFightResult;

// Export gallera management
const galleras = require("./src/galleras");
exports.getGalleraMemberDetails = galleras.getGalleraMemberDetails;
exports.inviteMemberToGallera = galleras.inviteMemberToGallera;
exports.acceptInvitation = galleras.acceptInvitation;
exports.declineInvitation = galleras.declineInvitation;
exports.removeMemberFromGallera = galleras.removeMemberFromGallera;

// Export transactions
const transactions = require("./src/transactions");
exports.addExpenseTransaction = transactions.addExpenseTransaction;
exports.updateExpenseTransaction = transactions.updateExpenseTransaction;
exports.deleteTransaction = transactions.deleteTransaction;
exports.updateFightTransaction = transactions.updateFightTransaction;

// Export payments
const payments = require("./src/payments");
exports.validateAndroidPurchase = payments.validateAndroidPurchase;