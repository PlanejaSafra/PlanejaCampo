/**
 * Firebase Cloud Functions for PlanejaChuva Regional Statistics
 *
 * This function aggregates rainfall data in real-time as users upload records.
 * It creates hierarchical aggregates at multiple GeoHash precision levels (3, 4, 5)
 * to support K-Anonymity while minimizing read costs.
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

/**
 * Triggered when a new rainfall record is written to Firestore.
 * Automatically updates aggregate statistics at multiple GeoHash precision levels.
 *
 * Path: rainfall_data/{geoHash5}/records/{recordId}
 */
exports.onRainfallWrite = functions.firestore
  .document('rainfall_data/{geoHash5}/records/{recordId}')
  .onCreate(async (snap, context) => {
    const geoHash5 = context.params.geoHash5;
    const data = snap.data();

    console.log(`Processing new rainfall record: ${context.params.recordId}`);
    console.log(`GeoHash5: ${geoHash5}, mm: ${data.mm}`);

    // Extract hierarchical GeoHash levels
    const geoHash4 = geoHash5.substring(0, 4);  // ~25km x 25km
    const geoHash3 = geoHash5.substring(0, 3);  // ~156km x 156km

    // Update aggregates at all precision levels
    const updatePromises = [
      updateAggregate(geoHash5, data.mm, 5),
      updateAggregate(geoHash4, data.mm, 4),
      updateAggregate(geoHash3, data.mm, 3),
    ];

    try {
      await Promise.all(updatePromises);
      console.log(`Successfully updated aggregates for ${geoHash5}`);
    } catch (error) {
      console.error(`Error updating aggregates for ${geoHash5}:`, error);
      throw error; // Retry on failure
    }
  });

/**
 * Update aggregate statistics for a specific GeoHash.
 * Uses Firestore transactions to ensure consistency.
 *
 * @param {string} geoHash - GeoHash string (3, 4, or 5 characters)
 * @param {number} mm - Rainfall in millimeters
 * @param {number} precision - GeoHash precision level
 */
async function updateAggregate(geoHash, mm, precision) {
  const aggregateRef = db.collection('rainfall_stats').doc(geoHash);

  return db.runTransaction(async (transaction) => {
    const doc = await transaction.get(aggregateRef);

    if (!doc.exists) {
      // Create new aggregate document
      transaction.set(aggregateRef, {
        total_mm: mm,
        count: 1,
        avg_mm: mm,
        geohash_precision: precision,
        last_updated: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Created new aggregate for ${geoHash} (precision: ${precision})`);
    } else {
      // Update existing aggregate
      const current = doc.data();
      const newCount = current.count + 1;
      const newTotal = current.total_mm + mm;
      const newAvg = newTotal / newCount;

      transaction.update(aggregateRef, {
        total_mm: newTotal,
        count: newCount,
        avg_mm: newAvg,
        last_updated: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Updated aggregate for ${geoHash}: count=${newCount}, avg=${newAvg.toFixed(2)}mm`);
    }
  });
}

/**
 * Scheduled function to clean up old rainfall records (optional).
 * Runs daily at 2 AM UTC to remove records older than 365 days.
 *
 * This helps keep Firestore costs low while maintaining useful historical data.
 */
exports.cleanupOldRecords = functions.pubsub
  .schedule('0 2 * * *') // Daily at 2 AM UTC
  .timeZone('America/Sao_Paulo')
  .onRun(async (context) => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 365); // 365 days ago

    console.log(`Starting cleanup of records older than ${cutoffDate.toISOString()}`);

    const batch = db.batch();
    let deletedCount = 0;

    // Query old records across all GeoHash5 collections
    // Note: This is simplified. In production, you'd need to iterate through all geoHash5 docs
    const snapshot = await db.collectionGroup('records')
      .where('date', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
      .limit(500) // Process in batches
      .get();

    snapshot.forEach((doc) => {
      batch.delete(doc.ref);
      deletedCount++;
    });

    if (deletedCount > 0) {
      await batch.commit();
      console.log(`Cleanup completed: Deleted ${deletedCount} old records`);
    } else {
      console.log('No old records to clean up');
    }

    return null;
  });

/**
 * HTTP endpoint to manually trigger aggregate recalculation (for testing/recovery).
 *
 * Usage: POST https://us-central1-[PROJECT_ID].cloudfunctions.net/recalculateAggregates
 * Body: { "geoHash": "6gyf4" }
 */
exports.recalculateAggregates = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).send('Method Not Allowed');
  }

  const { geoHash } = req.body;
  if (!geoHash) {
    return res.status(400).send('Missing geoHash parameter');
  }

  try {
    console.log(`Manually recalculating aggregates for ${geoHash}`);

    // Get all records for this geoHash
    const recordsSnapshot = await db
      .collection('rainfall_data')
      .doc(geoHash)
      .collection('records')
      .get();

    if (recordsSnapshot.empty) {
      return res.status(404).send(`No records found for geoHash: ${geoHash}`);
    }

    // Calculate new aggregate
    let totalMm = 0;
    let count = 0;

    recordsSnapshot.forEach((doc) => {
      const data = doc.data();
      totalMm += data.mm;
      count++;
    });

    const avgMm = totalMm / count;
    const precision = geoHash.length;

    // Update aggregate
    await db.collection('rainfall_stats').doc(geoHash).set({
      total_mm: totalMm,
      count: count,
      avg_mm: avgMm,
      geohash_precision: precision,
      last_updated: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Recalculation complete: ${geoHash} - count=${count}, avg=${avgMm.toFixed(2)}mm`);

    return res.status(200).json({
      success: true,
      geoHash: geoHash,
      count: count,
      totalMm: totalMm,
      avgMm: avgMm,
    });
  } catch (error) {
    console.error('Error recalculating aggregates:', error);
    return res.status(500).send(`Error: ${error.message}`);
  }
});
