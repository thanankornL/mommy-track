const { MongoClient } = require("mongodb");

const uri = "mongodb+srv://thanankornc2551:25082551@carebellmom.lpfhwhk.mongodb.net";
const client = new MongoClient(uri);

let db;

async function connectToDatabase() {
  if (db) return; // Avoid reconnecting if already connected.
  try {
    await client.connect();
    db = client.db("User");
    console.log("Connected to MongoDB");
  } catch (err) {
    console.error("MongoDB connection error:", err);
    process.exit(1);
  }
}

async function getdate(patient) {
  if (!db) {
    console.error("Database not initialized");
    return;
  }
  try {
    const patientData = await db.collection("patients_data").findOne({ username: patient });
    if (!patientData) {
      console.error(`No data found for patient: ${patient}`);
      return null;
    }
    const date = patientData?.LMP || patientData?.US;
    if (!date) {
      console.error(`No date (LMP or US) available for patient: ${patient}`);
    }
    return date;
  } catch (err) {
    console.error("Error fetching patient data:", err);
    return null;
  }
}

function convertToDateFormat(dateString) {
  const [day, month, year] = dateString.split('/');
  const date = new Date(`${year}-${month}-${day}`);
  if (isNaN(date)) {
    throw new Error(`Invalid date format: ${dateString}`);
  }
  return date;
}

async function updateGA(username) {

  const datenow = new Date();
  datenow.setHours(0, 0, 0, 0);

  let date = await getdate(username);
  if (!date) {
    return;
  }

  let inputDate;
  try {
    inputDate = date.includes('/') ? convertToDateFormat(date) : new Date(date);
    inputDate.setHours(0, 0, 0, 0);
  } catch (err) {
    console.error(`Invalid date format for username: ${username}`, err.message);
    return;
  }

  const differenceInTime = datenow.getTime() - inputDate.getTime();
  let GA = differenceInTime < 0 ? 0 : Math.floor(differenceInTime / (1000 * 3600 * 24));

  if (GA < 0) {
    console.error(`GA is negative for username ${username}. Setting GA to 0.`);
    GA = 0;
  }

  console.log(`Calculated GA for username ${username}:`, GA);

  try {
    const updateResult = await db.collection("patients_data").updateOne(
      { username: username },
      { $set: { GA: GA.toString() } }
    );
  } catch (err) {
    console.error(`Error updating GA for username: ${username}`, err.message);
  }
}

async function runDailyGACheck() {
  await connectToDatabase();

  const patients = await db.collection("patients_data").find({}, {
    projection: { _id: 0, password: 0, role: 0 }
  }).toArray();

  for (const patient of patients) {
    await updateGA(patient.username);
  }

  console.log("✅ Daily GA Check completed.");
}

module.exports = { runDailyGACheck };
