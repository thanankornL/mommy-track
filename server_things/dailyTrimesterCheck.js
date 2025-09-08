const { MongoClient } = require("mongodb");

const uri = "mongodb+srv://thanankornc2551:25082551@carebellmom.lpfhwhk.mongodb.net";
const client = new MongoClient(uri);

let db;

async function connectToDatabase() {
  try {
    await client.connect();
    db = client.db("User");
    console.log("Connected to MongoDB");
  } catch (err) {
    console.error("MongoDB connection error:", err);
    process.exit(1);
  }
}

function getGATrimester(GA) {
  if (GA < 0 || isNaN(GA)) return null;

  const totalWeeks = GA / 7;
  if (totalWeeks < 12) {
    return { label: "First Trimester", stepper: 0 };
  }

  const segments = [
    { upper: 20, lower:12, label: "Second Trimester", stepper: 1 },
    { upper: 26, lower:20, label: "Third Trimester", stepper: 2 },
    { upper: 32, lower:26, label: "Fourth Segment", stepper: 3 },
    { upper: 34, lower:32, label: "Fifth Segment", stepper: 4 },
    { upper: 36, lower:34, label: "Sixth Segment", stepper: 5 },
    { upper: 38, lower:36, label: "Seventh Segment", stepper: 6 },
    { upper: 40, lower:38, label: "Eighth Segment", stepper: 7 },
  ];

  for (let segment of segments) {
    if ((totalWeeks <= segment.upper) && (totalWeeks >= segment.lower)) {
      return segment;
    }
  }

  return null;
}
async function checkAndNotify(patient) {
  const { username, display_name, GA } = patient;

  const segmentInfo = getGATrimester(GA);
  if (!segmentInfo) return;

  const { label: currentTrimester, stepper } = segmentInfo;

  try {
    const patientRecord = await db.collection("patients_data").findOne({ username });
    const lastNotified = patientRecord?.lastNotify;

    if (lastNotified !== currentTrimester) {
      const title = `New Trimester Reached!`;
      const body = `Hi ${display_name}, you've entered the ${currentTrimester}.`;
      const timestamp = new Date();

      await db.collection("notifications_data").insertOne({
        username,
        title,
        body,
        timestamp,
      });

      await db.collection("patients_data").updateOne(
        { username },
        {
          $set: {
            lastNotify: currentTrimester,
            action: stepper,
          },
        }
      );

      console.log(`📢 Notification sent to ${display_name}: ${currentTrimester}`);
    } else {
      console.log(`✅ ${display_name} is still in ${currentTrimester}. No notification needed.`);
    }
  } catch (error) {
    console.error("❌ Error in checkAndNotify:", error);
  }
}



async function runDailyCheck() {
  await connectToDatabase();

  const patients = await db.collection("patients_data").find({}, {
    projection: { _id: 0, password: 0, role: 0 }
  }).toArray();

  for (const patient of patients) {
    await checkAndNotify(patient);
  }

  console.log("✅ Daily Trimester Check completed.");
}

module.exports = { runDailyCheck }; // Export the function
