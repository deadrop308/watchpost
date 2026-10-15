const functions = require("firebase-functions");
/// firebase-admin v14 only supports the modular API (getFirestore, getAuth...)
/// — the old db / getAuth() style was removed.
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { getMessaging } = require("firebase-admin/messaging");
const nodemailer = require("nodemailer");
const https = require("https");
const crypto = require("crypto");
const { defineSecret } = require("firebase-functions/params");

initializeApp();

/// Shared Firestore instance
const db = getFirestore();

// ─────────────────────────────────────────────
// APP CHECK
// Once you register App Check providers in the Firebase console
// (reCAPTCHA for web, Play Integrity for Android), flip this to true.
// Leaving it false until the providers exist — turning it on first
// would reject every call from the real app.
// ─────────────────────────────────────────────
const ENFORCE_APP_CHECK = false;

/// Shared options for every callable: enforce App Check when enabled.
const callableOptions = (extra = {}) => ({
  enforceAppCheck: ENFORCE_APP_CHECK,
  ...extra,
});

// ─────────────────────────────────────────────
// SECRETS & EMAIL CONFIGURATION
// Secrets are stored in Google Secret Manager, never in source code.
// Set them with:
//   firebase functions:secrets:set GMAIL_APP_PASSWORD
//   firebase functions:secrets:set PLACES_API_KEY
// ─────────────────────────────────────────────
const gmailAddress = "deadrop308@gmail.com";
const gmailAppPassword = defineSecret("GMAIL_APP_PASSWORD");
const placesApiKey = defineSecret("PLACES_API_KEY");

/// Creates the email transporter at runtime.
/// Secret values are only available inside a running function,
/// so the transporter can't be created at the top level.
function createEmailTransporter() {
  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: gmailAddress,
      pass: gmailAppPassword.value(),
    },
  });
}

/// Escapes HTML special characters so user-provided text
/// (like a full name) can't inject HTML into the credential emails.
function escapeHtml(text) {
  return String(text ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

// ─────────────────────────────────────────────
// INPUT VALIDATION HELPERS
// Never trust request.data — the client-side limits can be bypassed
// by calling the function directly.
// ─────────────────────────────────────────────

/// Requires a non-empty string no longer than maxLength. Returns it trimmed.
function requireString(value, fieldName, maxLength) {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument", `${fieldName} is required.`);
  }
  if (value.length > maxLength) {
    throw new functions.https.HttpsError(
      "invalid-argument", `${fieldName} is too long.`);
  }
  return value.trim();
}

/// Requires a plausibly-valid email address. Returns it trimmed + lowercased.
function requireEmail(value) {
  const email = requireString(value, "Email address", 254);
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new functions.https.HttpsError(
      "invalid-argument", "Email address is not valid.");
  }
  return email.toLowerCase();
}

// ─────────────────────────────────────────────
// AUTH / ROLE HELPERS
// Every privileged function checks BOTH the role AND that the account
// is still active, so a deactivated user can't keep calling them.
// ─────────────────────────────────────────────

/// Verifies the caller is authenticated, their user document exists,
/// their account is active, and their role is one of allowedRoles.
/// Returns the caller's user document data.
async function requireActiveRole(request, allowedRoles) {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated", "You must be logged in.");
  }

  const callerDoc = await db
    .collection("users")
    .doc(request.auth.uid)
    .get();

  const caller = callerDoc.data();

  if (!callerDoc.exists || caller.isActive !== true ||
    !allowedRoles.includes(caller.role)) {
    throw new functions.https.HttpsError(
      "permission-denied", "You do not have permission to do this.");
  }

  return caller;
}

// ─────────────────────────────────────────────
// RATE LIMITING
// Transactional so parallel requests can't all slip past the cap.
// The rateLimits collection is locked to clients in Firestore rules;
// only this admin-SDK code can touch it.
// ─────────────────────────────────────────────
async function checkRateLimit(userId, action, maxCalls, windowInMinutes) {
  const now = Date.now();
  const windowStart = now - (windowInMinutes * 60 * 1000);
  const rateLimitRef = db
    .collection("rateLimits")
    .doc(`${userId}_${action}`);

  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(rateLimitRef);

    /// First call in a fresh window — (re)start the counter
    if (!snapshot.exists || snapshot.data().windowStart < windowStart) {
      transaction.set(rateLimitRef, {
        count: 1,
        windowStart: now,
        lastCall: now,
      });
      return true;
    }

    const data = snapshot.data();
    if (data.count >= maxCalls) {
      return false;
    }

    transaction.update(rateLimitRef, {
      count: data.count + 1,
      lastCall: now,
    });
    return true;
  });
}

/// Throws a resource-exhausted error if the caller is over the limit.
async function enforceRateLimit(userId, action, maxCalls, windowInMinutes) {
  const allowed = await checkRateLimit(
    userId, action, maxCalls, windowInMinutes);
  if (!allowed) {
    throw new functions.https.HttpsError(
      "resource-exhausted", "Too many requests. Please try again later.");
  }
}

// ─────────────────────────────────────────────
// PASSWORD GENERATION
// Uses the crypto module (cryptographically secure), not Math.random().
// ─────────────────────────────────────────────
function generateSecurePassword() {
  const uppercaseChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  const lowercaseChars = "abcdefghijklmnopqrstuvwxyz";
  const numberChars = "0123456789";
  const allChars = uppercaseChars + lowercaseChars + numberChars;

  /// Picks one random character from a set using a uniform, unbiased source
  const pick = (set) => set[crypto.randomInt(set.length)];

  const passwordChars = [
    pick(uppercaseChars),
    pick(lowercaseChars),
    pick(numberChars),
  ];

  /// Fill the remaining 7 characters
  for (let i = 0; i < 7; i++) {
    passwordChars.push(pick(allChars));
  }

  /// Fisher–Yates shuffle with a secure source, so the guaranteed
  /// upper/lower/digit aren't always in the first three positions
  for (let i = passwordChars.length - 1; i > 0; i--) {
    const j = crypto.randomInt(i + 1);
    [passwordChars[i], passwordChars[j]] = [passwordChars[j], passwordChars[i]];
  }

  return passwordChars.join("");
}

/// Maps an account-creation error to a safe client-facing error.
/// Logs the real error server-side; never leaks internal details.
function throwSafeCreationError(error, context) {
  if (error.code === "auth/email-already-exists") {
    throw new functions.https.HttpsError(
      "already-exists", "An account with this email address already exists.");
  }
  console.error(`${context} failed:`, error);
  throw new functions.https.HttpsError(
    "internal", "Something went wrong. Please try again.");
}

/// Undoes a half-finished account creation (Auth user + Firestore doc),
/// so a failed step — usually the email — never leaves an orphan account
/// that blocks a retry with "email already exists". Best effort: errors
/// here are only logged.
async function rollbackCreatedUser(uid) {
  try {
    await db.collection("users").doc(uid).delete();
  } catch (error) {
    console.error("Rollback: could not delete user document", uid, error);
  }
  try {
    await getAuth().deleteUser(uid);
  } catch (error) {
    console.error("Rollback: could not delete auth user", uid, error);
  }
}

// ─────────────────────────────────────────────
// CREATE WORKER ACCOUNT  (managers only)
// ─────────────────────────────────────────────
exports.createWorkerAccount = functions.https.onCall(
  callableOptions({ secrets: [gmailAppPassword] }),
  async (request) => {
    const caller = await requireActiveRole(request, ["manager"]);
    await enforceRateLimit(request.auth.uid, "createWorker", 20, 60);

    const workerEmailAddress = requireEmail(request.data.emailAddress);
    const workerFullName = requireString(request.data.fullName, "Full name", 60);
    const workerBranchId = caller.branchId;

    const generatedPassword = generateSecurePassword();

    /// Set once the Auth account exists, so a later failure can undo it
    let newAuthUser = null;

    try {
      newAuthUser = await getAuth().createUser({
        email: workerEmailAddress,
        password: generatedPassword,
        displayName: workerFullName,
      });

      await db.collection("users").doc(newAuthUser.uid).set({
        emailAddress: workerEmailAddress,
        fullName: workerFullName,
        role: "worker",
        branchId: workerBranchId,
        isActive: true,
        createdAt: FieldValue.serverTimestamp(),
      });

      await createEmailTransporter().sendMail({
        from: `Watchpost <${gmailAddress}>`,
        to: workerEmailAddress,
        subject: "Your Watchpost Account Credentials",
        html: `
            <h2>Welcome to Watchpost</h2>
            <p>Hello ${escapeHtml(workerFullName)},</p>
            <p>Your account has been created. Here are your login credentials:</p>
            <p><strong>Email:</strong> ${escapeHtml(workerEmailAddress)}</p>
            <p><strong>Password:</strong> ${escapeHtml(generatedPassword)}</p>
            <p>Please keep these credentials safe.</p>
          `,
      });

      return { success: true, message: "Worker account created successfully." };
    } catch (error) {
      if (newAuthUser) await rollbackCreatedUser(newAuthUser.uid);
      throwSafeCreationError(error, "createWorkerAccount");
    }
  },
);

// ─────────────────────────────────────────────
// CREATE MANAGER ACCOUNT  (admins only)
// ─────────────────────────────────────────────
exports.createManagerAccount = functions.https.onCall(
  callableOptions({ secrets: [gmailAppPassword] }),
  async (request) => {
    await requireActiveRole(request, ["admin"]);
    await enforceRateLimit(request.auth.uid, "createManager", 10, 60);

    const managerEmailAddress = requireEmail(request.data.emailAddress);
    const managerFullName = requireString(request.data.fullName, "Full name", 60);
    const managerBranchId = requireString(request.data.branchId, "Branch", 128);

    /// Verify the branch exists and is active before attaching a manager to it
    const branchDoc = await db
      .collection("branches")
      .doc(managerBranchId)
      .get();

    if (!branchDoc.exists || branchDoc.data().isActive !== true) {
      throw new functions.https.HttpsError(
        "invalid-argument", "The selected branch does not exist.");
    }

    const generatedPassword = generateSecurePassword();

    /// Set once the Auth account exists, so a later failure can undo it
    let newAuthUser = null;

    try {
      newAuthUser = await getAuth().createUser({
        email: managerEmailAddress,
        password: generatedPassword,
        displayName: managerFullName,
      });

      await db.collection("users").doc(newAuthUser.uid).set({
        emailAddress: managerEmailAddress,
        fullName: managerFullName,
        role: "manager",
        branchId: managerBranchId,
        isActive: true,
        createdAt: FieldValue.serverTimestamp(),
      });

      await createEmailTransporter().sendMail({
        from: `Watchpost <${gmailAddress}>`,
        to: managerEmailAddress,
        subject: "Your Watchpost Manager Account Credentials",
        html: `
            <h2>Welcome to Watchpost</h2>
            <p>Hello ${escapeHtml(managerFullName)},</p>
            <p>Your manager account has been created. Here are your login credentials:</p>
            <p><strong>Email:</strong> ${escapeHtml(managerEmailAddress)}</p>
            <p><strong>Password:</strong> ${escapeHtml(generatedPassword)}</p>
            <p>Please keep these credentials safe.</p>
          `,
      });

      return { success: true, message: "Manager account created successfully." };
    } catch (error) {
      if (newAuthUser) await rollbackCreatedUser(newAuthUser.uid);
      throwSafeCreationError(error, "createManagerAccount");
    }
  },
);

// ─────────────────────────────────────────────
// SET USER ACTIVE / INACTIVE  (managers → workers, admins → managers)
// This is the ONLY correct way to deactivate someone: it flips the
// Firestore flag AND disables the Firebase Auth account AND revokes
// existing sessions, so a deactivated person is locked out immediately
// instead of staying logged in until their token expires.
// ─────────────────────────────────────────────
exports.setUserActive = functions.https.onCall(
  callableOptions(),
  async (request) => {
    const caller = await requireActiveRole(request, ["manager", "admin"]);
    await enforceRateLimit(request.auth.uid, "setUserActive", 100, 60);

    const targetUserId = requireString(request.data.userId, "User", 128);
    const active = request.data.active;
    if (typeof active !== "boolean") {
      throw new functions.https.HttpsError(
        "invalid-argument", "active must be true or false.");
    }

    /// A user can't change their own active status
    if (targetUserId === request.auth.uid) {
      throw new functions.https.HttpsError(
        "permission-denied", "You cannot change your own status.");
    }

    const targetDoc = await db
      .collection("users").doc(targetUserId).get();
    if (!targetDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found.");
    }
    const target = targetDoc.data();

    /// Managers may only toggle workers in their own branch.
    /// Admins may only toggle managers.
    const callerIsManager = caller.role === "manager";
    const callerIsAdmin = caller.role === "admin";
    const managerMayToggle = callerIsManager &&
      target.role === "worker" && target.branchId === caller.branchId;
    const adminMayToggle = callerIsAdmin && target.role === "manager";

    if (!managerMayToggle && !adminMayToggle) {
      throw new functions.https.HttpsError(
        "permission-denied", "You cannot change this user's status.");
    }

    try {
      /// 1) Firestore flag (what the app reads everywhere)
      await db.collection("users").doc(targetUserId)
        .update({ isActive: active });

      /// 2) Enable/disable the actual Auth account
      await getAuth().updateUser(targetUserId, { disabled: !active });

      /// 3) When deactivating, kill any session they already hold
      if (!active) {
        await getAuth().revokeRefreshTokens(targetUserId);
      }

      return { success: true };
    } catch (error) {
      console.error("setUserActive failed:", error);
      throw new functions.https.HttpsError(
        "internal", "Could not update the user. Please try again.");
    }
  },
);

// ─────────────────────────────────────────────
// PLACES AUTOCOMPLETE  (any active user)
// ─────────────────────────────────────────────
exports.placesAutocomplete = functions.https.onCall(
  callableOptions({ secrets: [placesApiKey] }),
  async (request) => {
    await requireActiveRole(request, ["worker", "manager", "admin"]);
    await enforceRateLimit(request.auth.uid, "placesAutocomplete", 100, 60);

    const input = requireString(request.data.input, "Input", 200);
    const apiKey = placesApiKey.value();

    const url = "https://maps.googleapis.com/maps/api/place/autocomplete/json" +
      `?input=${encodeURIComponent(input)}&key=${apiKey}` +
      "&components=country:il&language=he";

    return fetchJson(url);
  },
);

// ─────────────────────────────────────────────
// PLACES DETAILS  (any active user)
// ─────────────────────────────────────────────
exports.placesDetails = functions.https.onCall(
  callableOptions({ secrets: [placesApiKey] }),
  async (request) => {
    await requireActiveRole(request, ["worker", "manager", "admin"]);
    await enforceRateLimit(request.auth.uid, "placesDetails", 50, 60);

    const placeId = requireString(request.data.placeId, "Place", 300);
    const apiKey = placesApiKey.value();

    const url = "https://maps.googleapis.com/maps/api/place/details/json" +
      `?place_id=${encodeURIComponent(placeId)}&key=${apiKey}` +
      "&fields=formatted_address,geometry";

    return fetchJson(url);
  },
);

/// Fetches a URL and parses the JSON body, guarding against a non-200
/// response or a non-JSON body (which previously crashed the function).
function fetchJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (response) => {
      let body = "";
      response.on("data", (chunk) => (body += chunk));
      response.on("end", () => {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          reject(new functions.https.HttpsError(
            "unavailable", "The location service is unavailable."));
          return;
        }
        try {
          resolve(JSON.parse(body));
        } catch (parseError) {
          console.error("Places response was not valid JSON:", parseError);
          reject(new functions.https.HttpsError(
            "unavailable", "The location service returned an invalid response."));
        }
      });
    }).on("error", (error) => {
      console.error("Places request failed:", error);
      reject(new functions.https.HttpsError(
        "unavailable", "The location service is unavailable."));
    });
  });
}

// ─────────────────────────────────────────────
// SEND CALL ASSIGNMENT NOTIFICATION  (managers only, own branch)
// ─────────────────────────────────────────────
exports.sendCallAssignmentNotification = functions.https.onCall(
  callableOptions(),
  async (request) => {
    const caller = await requireActiveRole(request, ["manager"]);
    await enforceRateLimit(request.auth.uid, "sendNotification", 50, 60);

    const workerUserId = requireString(request.data.workerUserId, "Worker", 128);
    const operationName = requireString(
      request.data.operationName, "Operation", 100);
    const locationName = requireString(
      request.data.locationName, "Location", 100);
    const managerInstructions =
      typeof request.data.managerInstructions === "string"
        ? request.data.managerInstructions.slice(0, 500)
        : "";

    const workerDocument = await db
      .collection("users").doc(workerUserId).get();

    if (!workerDocument.exists) {
      throw new functions.https.HttpsError("not-found", "Worker not found.");
    }

    /// Managers can only notify members of their own branch
    if (workerDocument.data().branchId !== caller.branchId) {
      throw new functions.https.HttpsError(
        "permission-denied", "You can only assign calls to your branch.");
    }

    const fcmToken = workerDocument.data().fcmToken;
    if (!fcmToken) {
      /// Worker has no FCM token — nothing to send
      return { success: true, message: "No FCM token found for worker." };
    }

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: "Watchpost: New Assigned Call",
          body: `${operationName} at ${locationName}`,
        },
        data: {
          operationName: operationName,
          locationName: locationName,
          instructions: managerInstructions,
        },
      });
      return { success: true, message: "Notification sent successfully." };
    } catch (error) {
      console.error("sendCallAssignmentNotification failed:", error);
      throw new functions.https.HttpsError(
        "internal", "Could not send the notification.");
    }
  },
);