// --- V2 IMPORTS ---
const { onUserCreate } = require("firebase-functions/v2/auth");
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const calendarData = require("./academic_calendar.json");

admin.initializeApp();

// ======================================================================
// AUTHENTICATION TRIGGERS
// ======================================================================

/**
 * Triggers when a new user account is created in Firebase Authentication.
 * This function automatically creates their default set of leave balances.
 */
exports.createLeaveBalancesForNewUser = onUserCreate(async (event) => {
  const user = event.data; // The user object is in event.data
  const { uid } = user;
  logger.log(`New user signed up. Creating leave balances for UID: ${uid}`);

  const db = admin.firestore();
  const year = new Date().getFullYear();
  const leaveBalanceRef = db.collection("users").doc(uid).collection("leaveBalances");

  const defaultLeaves = {
    "Privilege/Earned Leave": 12, "Sick Leave": 10, "Maternity Leave": 180,
    "Paternity Leave": 15, "Unpaid Leave": 999,
  };

  const batch = db.batch();
  for (const [leaveType, days] of Object.entries(defaultLeaves)) {
    const docId = `${leaveType.replace(/\//g, "-").replace(/ /g, "_").toLowerCase()}_${year}`;
    const docRef = leaveBalanceRef.doc(docId);
    batch.set(docRef, {
      leaveType, year, allocatedDays: days, takenDays: 0,
    });
  }

  try {
    await batch.commit();
    logger.log(`Successfully seeded leave balances for user ${uid}`);
  } catch (error) {
    logger.error(`Failed to seed leave balances for user ${uid}:`, error);
  }
});


// ======================================================================
// FIRESTORE TRIGGERS
// ======================================================================

/**
 * Triggers when a user document is written (created or updated).
 * It creates and maintains lowercase, searchable fields for name and roles.
 */
exports.updateUserSearchFields = onDocumentWritten("users/{userId}", async (event) => {
  const data = event.data?.after.data();
  const oldData = event.data?.before.data();

  if (!data) return null; // Document was deleted

  const name = data.name || "";
  const additionalRoles = data.additionalRoles || [];

  // Only run if name or roles have changed to save resources
  if (data.name === oldData?.name && JSON.stringify(data.additionalRoles) === JSON.stringify(oldData?.additionalRoles)) {
    return null;
  }

  const searchableName = name.toLowerCase();
  const searchableRoles = [];
  additionalRoles.forEach((role) => {
    const words = role.toLowerCase().split(" ");
    searchableRoles.push(...words);
  });

  logger.log(`Updating search fields for user ${event.params.userId}`);
  return event.data.after.ref.update({
    searchableName: searchableName,
    searchableRoles: searchableRoles,
  });
});


// ======================================================================
// HTTP-TRIGGERED UTILITY FUNCTIONS
// ======================================================================

/**
 * An HTTP-triggered function to backfill search fields for all existing users.
 * Run this ONCE after deploying to update your current database.
 */
exports.backfillUserSearchFields = onRequest(async (req, res) => {
    const db = admin.firestore();
    const usersRef = db.collection("users");
    const snapshot = await usersRef.get();

    if (snapshot.empty) {
        return res.status(200).send("No users to update.");
    }

    const batch = db.batch();
    let count = 0;
    snapshot.forEach((doc) => {
        const data = doc.data();
        const name = data.name || "";
        const additionalRoles = data.additionalRoles || [];

        const searchableName = name.toLowerCase();
        const searchableRoles = [];
        additionalRoles.forEach((role) => {
            const words = role.toLowerCase().split(" ");
            searchableRoles.push(...words);
        });
        
        batch.update(doc.ref, {
            searchableName: searchableName,
            searchableRoles: searchableRoles,
        });
        count++;
    });

    await batch.commit();
    const message = `Successfully updated search fields for ${count} users.`;
    logger.log(message);
    return res.status(200).send(message);
});

/**
 * An HTTP-triggered function that reads from academic_calendar.json
 * and populates Firestore.
 */
exports.populateAcademicCalendar = onRequest(async (req, res) => {
  const db = admin.firestore();
  const batch = db.batch();

  // Populate Holidays
  calendarData.holidays.forEach((holiday) => {
    batch.set(db.collection("holidays").doc(), {
      name: holiday.name,
      date: admin.firestore.Timestamp.fromDate(new Date(holiday.date)),
    });
  });

  // Populate Academic Tasks
  calendarData.academicTasks.forEach((task) => {
    batch.set(db.collection("academicTasks").doc(), {
      title: task.title, date: admin.firestore.Timestamp.fromDate(new Date(task.date)),
      type: task.type, assignedBy: task.assignedBy, details: task.details,
      startTime: task.startTime || "09:00", durationMinutes: task.durationMinutes || 60,
    });
  });

  try {
    await batch.commit();
    const successMsg = "Successfully populated Firestore with academic calendar data!";
    logger.log(successMsg);
    res.status(200).send(successMsg);
  } catch (error) {
    logger.error("Error populating Firestore:", error);
    res.status(500).send("An error occurred.");
  }
});