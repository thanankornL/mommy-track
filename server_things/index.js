
const express = require("express");
const cors = require("cors");
const { MongoClient } = require("mongodb");
const bcrypt = require("bcrypt");
const cron = require("node-cron");
const { exec } = require("child_process");
const { runDailyCheck } = require("./dailyTrimesterCheck");
const { runDailyGACheck } = require("./updateGA");
const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection
const uri = "mongodb+srv://thanankornc2551:25082551@carebellmom.lpfhwhk.mongodb.net";
const client = new MongoClient(uri);

let db;

// Connect to MongoDB
async function connectToDatabase() {
  try {
    await client.connect();
    db = client.db("User");
    console.log("Connected to MongoDB");

    // Log all collections in the database
    const collections = await db.listCollections().toArray();
    console.log("Collections in the database:", collections.map((col) => col.name));
  } catch (err) {
    console.error("MongoDB connection error:", err);
    process.exit(1);
  }
}
connectToDatabase();

// Helper function
function getGATrimester(GA) {
  if (!GA || GA < 0) return "Unknown";
  if (GA <= 12) return "First Trimester";
  if (GA <= 28) return "Second Trimester";
  return "Third Trimester";
}

cron.schedule("* * * * *", async () => {
  console.log("⏰ Running Daily Trimester and GA Check...");

  try {
    // Run both tasks sequentially
    await runDailyGACheck();
    await runDailyCheck();
  } catch (error) {
    console.error("❌ Error during scheduled task:", error);
  }
});

// Simple route
app.get("/", (req, res) => {
  res.send("Backend is working!");
});

// Example API route
app.post("/api/echo", (req, res) => {
  const { message } = req.body;
  res.json({ received: message });
});

// Login API route
app.post("/api/login", async (req, res) => {
  const { username, password } = req.body;
  try {
    // Check if user exists in the database
    const user = await db.collection("login_data").findOne({ username });
    if (user && await bcrypt.compare(password, user.password)) {
      res.json({
        success: true,
        message: "Login successful!",
        name: user.username,
        role: user.role,
      });
      console.log(user.role);
    } else {
      res.status(401).json({ success: false, message: "Invalid username or password" });
    }
  } catch (err) {
    console.error("Error during login:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

app.post("/api/register", async (req, res) => {
  const { username, password, name, role, EDC = "", GA = "", LMP = "", US = "", telephone = "" } = req.body;
  try {
    const existingUser = await db.collection("login_data").findOne({ username });
    if (existingUser) {
      return res.status(409).json({ success: false, message: "Username already exists" });
    }
    console.log("Registering user:", { username, password, name, role, EDC, GA, LMP, US, telephone });
    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert into login_data
    await db.collection("login_data").insertOne({
      username,
      password: hashedPassword,
      role,
    });

    // Insert into the appropriate collection
    if (role === "patient") {
      await db.collection("patients_data").insertOne({
        username,
        display_name: name,
        EDC,
        GA,
        LMP,
        US,
        telephone
      });
    } else if (role === "nurse") {
      await db.collection("nurses_data").insertOne({
        username,
        display_name: name,
        role,
        telephone,
      });
    } else if (role == "admin") {
      await db.collection("admin_data").insertOne({
        username,
        display_name: name,
        role,
      });
    }

    res.status(201).json({ success: true, message: "User registered successfully" });
  } catch (err) {
    console.error("Error during registration:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

app.post("/api/send_notification", async (req, res) => {
  const { username, title, body, timestamp } = req.body;
  console.log("Received notification data:", { username, title, body, timestamp });
  try {
    // Insert the message into the messages collection
    await db.collection("notifications_data").insertOne({ username, title, body, timestamp });
    res.status(201).json({ success: true, message: "Message sent successfully" });
  } catch (err) {
    console.error("Error sending message:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// Get all users
app.get("/api/users", async (_, res) => {
  try {
    const users = await db.collection("patients_data").find({}, {
      projection: { username: 1, display_name: 1, telephone: 1 }
    }).toArray();

    console.log("Fetched users:", users);
    res.json(users);
  } catch (err) {
    console.error("Error fetching users:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// ค้นหา Route นี้
app.post("/api/get_user_data", async (req, res) => {
  const { username, role } = req.body;
  try {
    let collectionName;
    if (role === "patient") {
      collectionName = "patients_data";
    } else if (role === "nurse") {
      collectionName = "nurses_data";
    } else if (role === "admin") {
      collectionName = "admin_data";
    } else {
      return res.status(400).json({ success: false, message: "Invalid role" });
    }

    const userData = await db.collection(collectionName).findOne(
      { username },
      {
        projection:
        {
          _id: 0,
          password: 0,
          role: 0,
        }
      }
    );
    if (!userData) {
      return res.status(404).json({ success: false, message: "User not found" });
    }


    if (role === "patient" && userData) {

      if (userData.GA && typeof userData.GA === 'string' && userData.GA.trim() !== '') {
        userData.GA = parseInt(userData.GA, 10);

        if (isNaN(userData.GA)) {
          userData.GA = null;
        }
      } else if (userData.GA === '' || typeof userData.GA === 'undefined') {

        userData.GA = null;
      }


      if (userData.LMP === '') {
        userData.LMP = null;
      }
    }


    res.json(userData);
  } catch (err) {
    console.error("Error fetching user data:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

app.post("/api/edit_user_data", async (req, res) => {
  const { username, role, data } = req.body;
  try {
    let collectionName;
    if (role === "patient") {
      collectionName = "patients_data";
    } else if (role === "nurse") {
      collectionName = "nurses_data";
    } else if (role === "admin") {
      collectionName = "admin_data";
    } else {
      return res.status(400).json({ success: false, message: "Invalid role" });
    }

    // Update the user data in the appropriate collection
    const result = await db.collection(collectionName).updateOne(
      { username },
      { $set: data }
    );

    if (result.modifiedCount === 0) {
      return res.status(404).json({ success: false, message: "User not found or no changes made" });
    }
    res.json({ success: true, message: "User data updated successfully" });
  } catch (err) {
    console.error("Error updating user data:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

app.post("/api/delete_user", async (req, res) => {
  const { username, role } = req.body;
  try {
    let collectionName;
    if (role === "patient") {
      collectionName = "patients_data";
    } else if (role === "nurse") {
      collectionName = "nurses_data";
    } else if (role === "admin") {
      collectionName = "admin_data";
    } else {
      return res.status(400).json({ success: false, message: "Invalid role" });
    }

    // Delete the user from the appropriate collection
    const result = await db.collection(collectionName).deleteOne({ username });
    if (result.deletedCount === 0) {
      return res.status(404).json({ success: false, message: "User not found" });
    }
    res.json({ success: true, message: "User deleted successfully" });
  } catch (err) {
    console.error("Error deleting user:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

app.post("/api/get_GA_state", async (req, res) => {
  const { GA } = req.body;
  try {
    const state = getGATrimester(GA);
    console.log(GA);
    res.json({ success: true, state });
  } catch (err) {
    console.error("Error fetching GA state:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

app.get("/api/notifications", async (req, res) => {
  const { username } = req.query;
  console.log("Fetching notifications for user:", username);
  try {
    const messages = await db.collection("notifications_data").find(
      {
        username: username
      },
      {
        projection: { _id: 0 }
      }
    )
      .sort({ timestamp: -1 })
      .limit(10)
      .toArray();

    console.log("Fetched notifications:", messages);
    res.json(messages);
  } catch (err) {
    console.error("Error fetching messages:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

app.get('/api/getAction', async (req, res) => {
  const { username } = req.query;

  try {
    const patient = await db.collection("patients_data").findOne({ username });

    if (!patient) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    res.json({ success: true, action: patient.action });
  } catch (err) {
    console.error("Error fetching action:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

app.post('/api/updateAction', async (req, res) => {
  const { username, action } = req.body;

  try {
    const updateResult = await db.collection("patients_data").updateOne(
      { username },
      { $set: { action } }
    );
    const addedChildDate = await db.collection("patients_data").updateOne(
      { username },
      { $set: { childDate: new Date() } }
    );
    if (updateResult.modifiedCount === 0) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    res.status(200).json({
      success: true,
      message: "อัพเดทข้อมูลเสร็จสิ้น",
      action
    });
  } catch (err) {
    console.error("Error updating action:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

app.post('/api/create_baby_data', async (req, res) => {
  const { mother, birthday, action, gender, child } = req.body;

  try {
    const result = await db.collection("baby_data").insertOne({
      child: child,
      mother: mother,
      birthday: birthday,
      action: action,
      gender: gender,
    });

    if (result.insertedCount === 0) {
      return res.status(500).json({ success: false, message: "Failed to create baby data" });
    }

    res.status(201).json({ success: true, message: "Baby data created successfully" });
  } catch (err) {
    console.error("Error creating baby data:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

app.post('/api/get_baby_data', async (req, res) => {
  const { mother } = req.body; // Get 'mother' from the request body
  console.log("Fetching baby data for mother:", mother); // Debugging log
  try {
    // Fetch baby data from the database using 'mother' as a filter
    const babyData = await db.collection("baby_data").findOne({ mother });

    if (!babyData) {
      // Respond with a 404 status if no data is found
      return res.status(404).json({ success: false, message: "Baby data not found" });
    }

    // Return the fetched baby data if found
    res.json({ success: true, data: babyData });
  } catch (err) {
    // Handle any errors and respond with a 500 status code
    console.error("Error fetching baby data:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// ================== CHAT APIs ==================

// API สำหรับส่งข้อความ
app.post("/api/send_message", async (req, res) => {
  const { sender, receiver, message, timestamp, senderRole } = req.body;

  console.log("Sending message:", { sender, receiver, message, senderRole });

  try {
    if (!sender || !receiver || !message || !senderRole) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields"
      });
    }

    const messageData = {
      sender,
      receiver,
      message,
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      senderRole,
      isRead: false
    };

    const result = await db.collection("chat_messages").insertOne(messageData);

    console.log("Message saved:", result.insertedId);

    res.status(201).json({
      success: true,
      message: "Message sent successfully",
      data: messageData
    });
  } catch (err) {
    console.error("Error sending message:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับดึงประวัติแชท
app.post("/api/get_chat_history", async (req, res) => {
  const { user1, user2, limit = 50 } = req.body;

  console.log("Getting chat history:", { user1, user2, limit });

  try {
    if (!user1 || !user2) {
      return res.status(400).json({
        success: false,
        message: "Missing user1 or user2"
      });
    }

    const messages = await db.collection("chat_messages")
      .find({
        $or: [
          { sender: user1, receiver: user2 },
          { sender: user2, receiver: user1 }
        ]
      })
      .sort({ timestamp: 1 })
      .limit(parseInt(limit))
      .toArray();

    console.log(`Found ${messages.length} messages`);

    res.json({ success: true, messages });
  } catch (err) {
    console.error("Error fetching chat history:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับดึงรายชื่อคนที่เคยแชทด้วย
app.post("/api/get_chat_contacts", async (req, res) => {
  const { username, role } = req.body;

  console.log("Getting chat contacts:", { username, role });

  try {
    if (!username || !role) {
      return res.status(400).json({
        success: false,
        message: "Missing username or role"
      });
    }

    let contacts = [];

    if (role === 'nurse') {
      // พยาบาลดูรายชื่อคนไข้ที่เคยแชทด้วย
      const patientChats = await db.collection("chat_messages")
        .aggregate([
          {
            $match: {
              $or: [
                { sender: username, senderRole: 'nurse' },
                { receiver: username }
              ]
            }
          },
          {
            $group: {
              _id: {
                contact: {
                  $cond: [
                    { $eq: ["$sender", username] },
                    "$receiver",
                    "$sender"
                  ]
                }
              },
              lastMessage: { $last: "$message" },
              lastTimestamp: { $last: "$timestamp" },
              unreadCount: {
                $sum: {
                  $cond: [
                    {
                      $and: [
                        { $eq: ["$receiver", username] },
                        { $eq: ["$isRead", false] }
                      ]
                    },
                    1,
                    0
                  ]
                }
              }
            }
          }
        ])
        .toArray();

      // ดึงข้อมูลคนไข้
      for (let chat of patientChats) {
        const patient = await db.collection("patients_data")
          .findOne(
            { username: chat._id.contact },
            { projection: { display_name: 1, username: 1 } }
          );

        if (patient) {
          contacts.push({
            username: patient.username,
            displayName: patient.display_name,
            lastMessage: chat.lastMessage || '',
            lastTimestamp: chat.lastTimestamp || new Date(),
            unreadCount: chat.unreadCount || 0,
            role: 'patient'
          });
        }
      }
    } else if (role === 'patient') {
      // คนไข้ดูรายชื่อพยาบาลที่เคยแชทด้วย
      const nurseChats = await db.collection("chat_messages")
        .aggregate([
          {
            $match: {
              $or: [
                { sender: username, senderRole: 'patient' },
                { receiver: username }
              ]
            }
          },
          {
            $group: {
              _id: {
                contact: {
                  $cond: [
                    { $eq: ["$sender", username] },
                    "$receiver",
                    "$sender"
                  ]
                }
              },
              lastMessage: { $last: "$message" },
              lastTimestamp: { $last: "$timestamp" },
              unreadCount: {
                $sum: {
                  $cond: [
                    {
                      $and: [
                        { $eq: ["$receiver", username] },
                        { $eq: ["$isRead", false] }
                      ]
                    },
                    1,
                    0
                  ]
                }
              }
            }
          }
        ])
        .toArray();

      // ดึงข้อมูลพยาบาล
      for (let chat of nurseChats) {
        const nurse = await db.collection("nurses_data")
          .findOne(
            { username: chat._id.contact },
            { projection: { display_name: 1, username: 1 } }
          );

        if (nurse) {
          contacts.push({
            username: nurse.username,
            displayName: nurse.display_name,
            lastMessage: chat.lastMessage || '',
            lastTimestamp: chat.lastTimestamp || new Date(),
            unreadCount: chat.unreadCount || 0,
            role: 'nurse'
          });
        }
      }
    }

    // เรียงตาม timestamp ล่าสุด
    contacts.sort((a, b) => new Date(b.lastTimestamp) - new Date(a.lastTimestamp));

    console.log(`Found ${contacts.length} contacts`);

    res.json({ success: true, contacts });
  } catch (err) {
    console.error("Error fetching chat contacts:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

//แก้ให้ลักกี้ที่ทำให้มันไม่ขึ้นทุกuser ขึ้นแต่คนไข้
app.get('/api/patients_data', async (req, res) => {
  console.log("Getting all patients data");
  try {
    // ดึงเฉพาะข้อมูลผู้ป่วยจาก patients_data collection
    const patients = await db.collection("patients_data")
      .find({}, {
        projection: {
          username: 1,
          display_name: 1,
          action: 1,
          GA: 1,
          EDC: 1,
          LMP: 1,
          telephone: 1,
          _id: 0  // ไม่เอา _id
        }
      })
      .toArray();

    console.log(`Found ${patients.length} patients`);

    // ส่งข้อมูลกลับในรูปแบบ array - แก้ไขตรงนี้
    res.json(patients); // ตรวจสอบว่าเป็น patients ไม่ใช่ atients
  } catch (err) {
    console.error("Error fetching patients:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});
app.get('/api/patients_data/:username', async (req, res) => { //ดึง
  const { username } = req.params;
  console.log(`Getting data for patient: ${username}`);

  try {
    const patient = await db.collection("patients_data").findOne({ username });

    if (patient) {
      // ส่งข้อมูลผู้ป่วยที่พบกลับไป
      res.json(patient);
    } else {
      // หากไม่พบผู้ป่วย
      res.status(404).json({ success: false, message: "Patient not found" });
    }
  } catch (err) {
    console.error(`Error fetching patient ${username}:`, err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});
// API สำหรับอัพเดทสถานะว่าอ่านแล้ว
app.post("/api/mark_messages_read", async (req, res) => {
  const { sender, receiver } = req.body;

  console.log("Marking messages as read:", { sender, receiver });

  try {
    if (!sender || !receiver) {
      return res.status(400).json({
        success: false,
        message: "Missing sender or receiver"
      });
    }

    const result = await db.collection("chat_messages").updateMany(
      {
        sender: sender,
        receiver: receiver,
        isRead: false
      },
      {
        $set: { isRead: true }
      }
    );

    console.log(`Marked ${result.modifiedCount} messages as read`);

    res.json({ success: true, message: "Messages marked as read" });
  } catch (err) {
    console.error("Error marking messages as read:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับพยาบาลดูรายชื่อคนไข้ทั้งหมด (เพื่อเริ่มแชทใหม่)
app.get("/api/get_all_patients", async (req, res) => {
  console.log("Getting all patients");

  try {
    const patients = await db.collection("patients_data")
      .find({}, {
        projection: {
          username: 1,
          display_name: 1,
          telephone: 1,
          _id: 0
        }
      })
      .toArray();

    console.log(`Found ${patients.length} patients`);

    res.json({ success: true, patients });
  } catch (err) {
    console.error("Error fetching patients:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับคนไข้ดูรายชื่อพยาบาลทั้งหมด (เพื่อเริ่มแชทใหม่)
app.get("/api/get_all_nurses", async (req, res) => {
  console.log("Getting all nurses");

  try {
    const nurses = await db.collection("nurses_data")
      .find({}, {
        projection: {
          username: 1,
          display_name: 1,
          telephone: 1,
          _id: 0
        }
      })
      .toArray();

    console.log(`Found ${nurses.length} nurses`);

    res.json({ success: true, nurses });
  } catch (err) {
    console.error("Error fetching nurses:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// Test API สำหรับทดสอบการเชื่อมต่อ
app.get("/api/test_chat", async (req, res) => {
  try {
    // ทดสอบการเชื่อมต่อ database
    const collections = await db.listCollections().toArray();
    const chatMessagesExists = collections.some(col => col.name === 'chat_messages');

    // นับจำนวนข้อความ
    const messageCount = await db.collection("chat_messages").countDocuments();

    res.json({
      success: true,
      message: "Chat system is working",
      collections: collections.map(col => col.name),
      chatMessagesCollection: chatMessagesExists,
      totalMessages: messageCount
    });
  } catch (err) {
    console.error("Error testing chat:", err);
    res.status(500).json({ success: false, message: "Chat system error" });
  }
});
// เพิ่มใน index.js - API สำหรับการบันทึกวันนัดที่ปรับปรุงแล้ว
app.post('/api/save_appointment', async (req, res) => {
  const { username, step, stepTitle, stepDescription, nextAppointment, note = "" } = req.body;

  console.log("Incoming request to /api/save_appointment:", req.body);

  try {
    // เช็กค่าที่จำเป็น
    if (!username || step === undefined || !nextAppointment) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields"
      });
    }

    // เช็กว่า DB พร้อมหรือยัง
    if (!db) {
      console.error("Database is not connected yet!");
      return res.status(500).json({
        success: false,
        message: "Database connection is not ready"
      });
    }

    const stepNum = parseInt(step);
    const appointmentData = {
      username,
      step: stepNum,
      stepTitle: stepTitle || `การแจ้งเตือนที่ ${stepNum + 1}`,
      stepDescription: stepDescription || "",
      nextAppointment: new Date(nextAppointment),
      note: note?.trim() || "",
      updatedAt: new Date()
      // ไม่มี createdAt ตรงนี้
    };

    const result = await db.collection("appointments_data").updateOne(
      { username, step: stepNum },
      {
        $set: appointmentData,
        $setOnInsert: { createdAt: new Date() }
      },
      { upsert: true }
    );

    console.log("MongoDB updateOne result:", result);

    res.status(200).json({
      success: true,
      message: "Appointment saved successfully"
    });

  } catch (err) {
    console.error("Error in /api/save_appointment:", err.stack || err);
    res.status(500).json({
      success: false,
      message: "Internal server error",
      error: err.message
    });
  }
});

function calculateAppointmentDate(lmp, gaWeeks) {
  if (!lmp) return null;

  const lmpDate = new Date(lmp);
  const targetWeeks = gaWeeks;
  const appointmentDate = new Date(lmpDate);
  appointmentDate.setDate(appointmentDate.getDate() + (targetWeeks * 7));

  return appointmentDate;
}

// ฟังก์ชันตรวจสอบว่าวันที่เลือกอยู่ในช่วงที่อนุญาต
function isDateInAllowedRange(selectedDate, targetDate) {
  const target = new Date(targetDate);
  const selected = new Date(selectedDate);

  // อนุญาตให้เลือกได้ ±3 วันจากวันที่คำนวณได้
  const minDate = new Date(target);
  minDate.setDate(target.getDate() - 3);

  const maxDate = new Date(target);
  maxDate.setDate(target.getDate() + 3);

  return selected >= minDate && selected <= maxDate;
}

// API สำหรับคำนวณวันนัดตาม GA
app.post('/api/calculate_appointment_dates', async (req, res) => {
  const { username } = req.body;

  try {
    // ดึงข้อมูลผู้ป่วย
    const patient = await db.collection("patients_data").findOne({ username });
    if (!patient) {
      return res.status(404).json({ success: false, message: "Patient not found" });
    }

    const { LMP, GA } = patient;
    if (!LMP) {
      return res.status(400).json({
        success: false,
        message: "LMP date is required for calculation"
      });
    }

    // คำนวณวันนัดสำหรับแต่ละ step
    const appointmentWeeks = [12, 20, 26, 32, 34, 36, 38, 40];
    const currentGA = parseInt(GA) || 0;

    const calculatedDates = appointmentWeeks.map((weeks, index) => {
      const appointmentDate = calculateAppointmentDate(LMP, weeks);
      const isPassed = currentGA > weeks;
      const isCurrent = currentGA >= weeks - 2 && currentGA <= weeks + 2;

      return {
        step: index,
        targetWeeks: weeks,
        calculatedDate: appointmentDate,
        isPassed,
        isCurrent,
        isUpcoming: currentGA < weeks
      };
    });

    res.json({
      success: true,
      calculatedDates,
      currentGA,
      patientLMP: LMP
    });

  } catch (err) {
    console.error("Error calculating appointment dates:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับบันทึกวันนัด (อัพเดท)
app.post('/api/save_appointment', async (req, res) => {
  const { username, step, stepTitle, stepDescription, nextAppointment, note = "", nurseUsername } = req.body;

  console.log("Saving appointment:", req.body);

  try {
    if (!username || step === undefined || !nextAppointment) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields"
      });
    }

    // ดึงข้อมูลผู้ป่วยเพื่อตรวจสอบ LMP
    const patient = await db.collection("patients_data").findOne({ username });
    if (!patient) {
      return res.status(404).json({ success: false, message: "Patient not found" });
    }

    // คำนวณวันที่ที่ควรจะนัด
    const appointmentWeeks = [12, 20, 26, 32, 34, 36, 38, 40];
    const targetWeeks = appointmentWeeks[parseInt(step)];

    if (patient.LMP && targetWeeks) {
      const calculatedDate = calculateAppointmentDate(patient.LMP, targetWeeks);

      // ตรวจสอบว่าวันที่เลือกอยู่ในช่วงที่อนุญาต
      if (!isDateInAllowedRange(nextAppointment, calculatedDate)) {
        return res.status(400).json({
          success: false,
          message: "Selected date is outside allowed range",
          suggestedDate: calculatedDate,
          allowedRange: {
            min: new Date(calculatedDate.getTime() - 3 * 24 * 60 * 60 * 1000),
            max: new Date(calculatedDate.getTime() + 3 * 24 * 60 * 60 * 1000)
          }
        });
      }
    }

    const stepNum = parseInt(step);
    const appointmentData = {
      username,
      step: stepNum,
      stepTitle: stepTitle || `การแจ้งเตือนที่ ${stepNum + 1}`,
      stepDescription: stepDescription || "",
      nextAppointment: new Date(nextAppointment),
      note: note?.trim() || "",
      status: "scheduled", // scheduled, confirmed, requested_change
      createdBy: nurseUsername || "system",
      updatedAt: new Date()
    };

    const result = await db.collection("appointments_data").updateOne(
      { username, step: stepNum },
      {
        $set: appointmentData,
        $setOnInsert: { createdAt: new Date() }
      },
      { upsert: true }
    );

    // ส่งการแจ้งเตือนให้ผู้ป่วย
    await db.collection("notifications_data").insertOne({
      username: username,
      title: "วันนัดตรวจใหม่",
      body: `คุณมีวันนัดตรวจ: ${stepTitle} วันที่ ${new Date(nextAppointment).toLocaleDateString('th-TH')}`,
      timestamp: new Date(),
      type: "appointment",
      appointmentStep: stepNum,
      isRead: false
    });

    res.status(200).json({
      success: true,
      message: "Appointment saved successfully"
    });

  } catch (err) {
    console.error("Error saving appointment:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับผู้ป่วยยืนยันวันนัด
app.post('/api/confirm_appointment', async (req, res) => {
  const { username, step } = req.body;

  try {
    const result = await db.collection("appointments_data").updateOne(
      { username, step: parseInt(step) },
      {
        $set: {
          status: "confirmed",
          confirmedAt: new Date(),
          updatedAt: new Date()
        }
      }
    );

    if (result.modifiedCount === 0) {
      return res.status(404).json({ success: false, message: "Appointment not found" });
    }

    // แจ้งเตือนพยาบาล
    const appointment = await db.collection("appointments_data").findOne({ username, step: parseInt(step) });
    await db.collection("notifications_nurse").insertOne({
      username: appointment.createdBy, // พยาบาลที่สร้างนัด
      title: "ผู้ป่วยยืนยันวันนัด",
      body: `${username} ได้ยืนยันวันนัด: ${appointment.stepTitle}`,
      timestamp: new Date(),
      type: "appointment_confirmed",
      isRead: false
    });

    res.json({ success: true, message: "Appointment confirmed successfully" });
  } catch (err) {
    console.error("Error confirming appointment:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับผู้ป่วยขอแก้ไขวันนัด
// ฟังก์ชันหาช่วงวันนัดถัดไปตามสัปดาห์
function getAppointmentRange(gaWeeks) {
  const ranges = [12, 20, 26, 32, 34, 36, 38, 40];
  for (let week of ranges) {
    if (gaWeeks <= week) {
      return week;
    }
  }
  return null; // ถ้าเกิน 40 สัปดาห์
}

app.post("/api/request_appointment_change", async (req, res) => {
  try {
    const { username, step, requestedDate, reason } = req.body;

    // ดึงข้อมูลผู้ป่วยเพื่อนำมาคำนวณ GA (อายุครรภ์)
    const patient = await db.collection("patients_data").findOne({ username });
    if (!patient || !patient.LMP) {
      return res.status(400).json({ success: false, message: "ไม่พบข้อมูลผู้ป่วยหรือ LMP" });
    }

    // คำนวณ GA (อายุครรภ์เป็นสัปดาห์)
    const lmpDate = new Date(patient.LMP);
    const today = new Date();
    const diffDays = Math.floor((today - lmpDate) / (1000 * 60 * 60 * 24));
    const gaWeeks = Math.floor(diffDays / 7);

    // หาช่วงวันนัดถัดไปตาม GA
    const nextRange = getAppointmentRange(gaWeeks);

    // บันทึกคำขอเปลี่ยนการนัด
    await db.collection("appointment_change_requests").insertOne({
      username,
      step,
      requestedDate: new Date(requestedDate),
      reason,
      status: "pending",
      gaWeeks,
      nextAppointmentWeek: nextRange,
      createdAt: new Date()
    });

    // ดึงพยาบาลทั้งหมด
    const nurses = await db.collection("nurses_data")
      .find({}, { projection: { username: 1, display_name: 1, _id: 0 } })
      .toArray();

    // สร้างข้อความแจ้งเตือน
    const message = `ผู้ป่วย ${username} (GA ${gaWeeks} สัปดาห์) ขอเปลี่ยนการนัด (Step ${step}) 
วันที่ ${new Date(requestedDate).toLocaleDateString('th-TH')} 
เหตุผล: ${reason} 
ช่วงนัดถัดไป: ≤ ${nextRange} สัปดาห์`;

    // บันทึกแจ้งเตือนให้พยาบาลทุกคน
    const nurseNotis = nurses.map(nurse => ({
      nurse_username: nurse.username,
      message,
      type: "appointment_change_request",
      createdAt: new Date(),
      read: false
    }));

    await db.collection("notifications_data").insertMany(nurseNotis);

    res.json({ success: true, message: "บันทึกคำขอและแจ้งเตือนพยาบาลแล้ว" });
  } catch (err) {
    console.error("Error in request_appointment_change:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});






// API สำหรับดึงข้อมูลการแจ้งเตือนพร้อมลิงก์
app.get("/api/notifications", async (req, res) => {
  const { username } = req.query;
  console.log("Fetching notifications for user:", username);

  try {
    const notifications = await db.collection("notifications_data")
      .find({ username })
      .sort({ timestamp: -1 })
      .limit(20)
      .toArray();

    // เพิ่มข้อมูล navigation สำหรับแต่ละ notification
    const enrichedNotifications = notifications.map(notification => {
      let navigationData = null;

      switch (notification.type) {
        case "appointment":
        case "appointment_confirmed":
        case "appointment_approved":
          navigationData = {
            page: "appointment_details",
            step: notification.appointmentStep
          };
          break;
        case "appointment_change_request":
          navigationData = {
            page: "appointment_management",
            step: notification.appointmentStep
          };
          break;
        default:
          navigationData = {
            page: "view_details"
          };
      }

      return {
        ...notification,
        navigationData
      };
    });

    console.log("Fetched notifications:", enrichedNotifications.length);
    res.json(enrichedNotifications);
  } catch (err) {
    console.error("Error fetching notifications:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับอัพเดทสถานะอ่านแล้วของการแจ้งเตือน
app.post("/api/mark_notification_read", async (req, res) => {
  const { username, notificationId } = req.body;

  try {
    const result = await db.collection("notifications_data").updateOne(
      {
        username,
        _id: new require('mongodb').ObjectId(notificationId)
      },
      { $set: { isRead: true, readAt: new Date() } }
    );

    res.json({ success: true, message: "Notification marked as read" });
  } catch (err) {
    console.error("Error marking notification as read:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// เพิ่มใน index.js - APIs เพิ่มเติมสำหรับการจัดการวันนัด

// API สำหรับดึงวันนัดของผู้ป่วยคนหนึ่ง
app.get('/api/get_appointments', async (req, res) => {
  const { username } = req.query;

  try {
    const appointments = await db.collection("appointments_data")
      .find({ username })
      .sort({ step: 1 })
      .toArray();

    res.json({
      success: true,
      appointments: appointments
    });

  } catch (err) {
    console.error("Error fetching appointments:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับดึงวันนัดทั้งหมด (สำหรับพยาบาล)
app.get('/api/get_all_appointments', async (req, res) => {
  try {
    // ดึงข้อมูลวันนัดทั้งหมด พร้อมข้อมูลผู้ป่วย
    const appointments = await db.collection("appointments_data").aggregate([
      {
        $lookup: {
          from: "patients_data",
          localField: "username",
          foreignField: "username",
          as: "patientInfo"
        }
      },
      {
        $unwind: {
          path: "$patientInfo",
          preserveNullAndEmptyArrays: true
        }
      },
      {
        $project: {
          username: 1,
          step: 1,
          stepTitle: 1,
          stepDescription: 1,
          nextAppointment: 1,
          note: 1,
          status: 1,
          createdBy: 1,
          updatedAt: 1,
          patientName: "$patientInfo.display_name",
          patientPhone: "$patientInfo.phone",
          patientAge: "$patientInfo.age"
        }
      },
      {
        $sort: { nextAppointment: 1 }
      }
    ]).toArray();

    res.json({
      success: true,
      appointments: appointments
    });

  } catch (err) {
    console.error("Error fetching all appointments:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับดึงวันนัดของวันนี้
app.get('/api/get_today_appointments', async (req, res) => {
  try {
    const today = new Date();
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const endOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);

    const appointments = await db.collection("appointments_data").aggregate([
      {
        $match: {
          nextAppointment: {
            $gte: startOfDay,
            $lt: endOfDay
          }
        }
      },
      {
        $lookup: {
          from: "patients_data",
          localField: "username",
          foreignField: "username",
          as: "patientInfo"
        }
      },
      {
        $unwind: {
          path: "$patientInfo",
          preserveNullAndEmptyArrays: true
        }
      },
      {
        $project: {
          username: 1,
          step: 1,
          stepTitle: 1,
          nextAppointment: 1,
          note: 1,
          status: 1,
          patientName: "$patientInfo.display_name",
          patientPhone: "$patientInfo.phone"
        }
      },
      {
        $sort: { nextAppointment: 1 }
      }
    ]).toArray();

    res.json({
      success: true,
      appointments: appointments,
      count: appointments.length
    });

  } catch (err) {
    console.error("Error fetching today's appointments:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับดึงวันนัดที่กำลังจะมาถึง (7 วันข้างหน้า)
app.get('/api/get_upcoming_appointments', async (req, res) => {
  try {
    const today = new Date();
    const nextWeek = new Date(today.getTime() + (7 * 24 * 60 * 60 * 1000));

    const appointments = await db.collection("appointments_data").aggregate([
      {
        $match: {
          nextAppointment: {
            $gte: today,
            $lte: nextWeek
          }
        }
      },
      {
        $lookup: {
          from: "patients_data",
          localField: "username",
          foreignField: "username",
          as: "patientInfo"
        }
      },
      {
        $unwind: {
          path: "$patientInfo",
          preserveNullAndEmptyArrays: true
        }
      },
      {
        $project: {
          username: 1,
          step: 1,
          stepTitle: 1,
          nextAppointment: 1,
          note: 1,
          status: 1,
          patientName: "$patientInfo.display_name",
          patientPhone: "$patientInfo.phone",
          daysUntil: {
            $ceil: {
              $divide: [
                { $subtract: ["$nextAppointment", today] },
                1000 * 60 * 60 * 24
              ]
            }
          }
        }
      },
      {
        $sort: { nextAppointment: 1 }
      }
    ]).toArray();

    res.json({
      success: true,
      appointments: appointments,
      count: appointments.length
    });

  } catch (err) {
    console.error("Error fetching upcoming appointments:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับดึงสถิติวันนัด
app.get('/api/appointment_statistics', async (req, res) => {
  try {
    const today = new Date();
    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    const nextWeek = new Date(today.getTime() + (7 * 24 * 60 * 60 * 1000));

    // สถิติต่างๆ
    const [
      totalAppointments,
      todayAppointments,
      upcomingAppointments,
      pendingChanges,
      confirmedAppointments,
      monthlyAppointments
    ] = await Promise.all([
      // Total appointments
      db.collection("appointments_data").countDocuments({}),

      // Today's appointments
      db.collection("appointments_data").countDocuments({
        nextAppointment: {
          $gte: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
          $lt: new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1)
        }
      }),

      // Upcoming appointments (next 7 days)
      db.collection("appointments_data").countDocuments({
        nextAppointment: {
          $gte: today,
          $lte: nextWeek
        }
      }),

      // Pending change requests
      db.collection("appointments_data").countDocuments({
        status: "requested_change"
      }),

      // Confirmed appointments
      db.collection("appointments_data").countDocuments({
        status: "confirmed"
      }),

      // This month's appointments
      db.collection("appointments_data").countDocuments({
        nextAppointment: {
          $gte: startOfMonth,
          $lt: new Date(today.getFullYear(), today.getMonth() + 1, 1)
        }
      })
    ]);

    res.json({
      success: true,
      statistics: {
        total: totalAppointments,
        today: todayAppointments,
        upcoming: upcomingAppointments,
        pendingChanges: pendingChanges,
        confirmed: confirmedAppointments,
        thisMonth: monthlyAppointments
      }
    });

  } catch (err) {
    console.error("Error fetching appointment statistics:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});



// API สำหรับอัพเดทสถานะวันนัดหลายรายการ
app.post('/api/bulk_update_appointments', async (req, res) => {
  const { appointments, status, nurseUsername } = req.body;

  try {
    if (!Array.isArray(appointments) || appointments.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Invalid appointments data"
      });
    }

    const bulkOperations = appointments.map(appt => ({
      updateOne: {
        filter: { username: appt.username, step: appt.step },
        update: {
          $set: {
            status: status,
            updatedBy: nurseUsername || "system",
            updatedAt: new Date()
          }
        }
      }
    }));

    const result = await db.collection("appointments_data").bulkWrite(bulkOperations);

    // ส่งการแจ้งเตือนให้ผู้ป่วยที่ได้รับการอัพเดท
    const notificationPromises = appointments.map(appt =>
      db.collection("notifications_data").insertOne({
        username: appt.username,
        title: "อัพเดทสถานะวันนัด",
        body: `วันนัดของคุณได้รับการอัพเดทเป็น: ${status}`,
        timestamp: new Date(),
        type: "appointment_status_update",
        isRead: false
      })
    );

    await Promise.all(notificationPromises);

    res.json({
      success: true,
      message: `Updated ${result.modifiedCount} appointments`,
      modifiedCount: result.modifiedCount
    });

  } catch (err) {
    console.error("Error bulk updating appointments:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับลบวันนัด
app.delete('/api/delete_appointment', async (req, res) => {
  const { username, step, nurseUsername } = req.body;

  try {
    const result = await db.collection("appointments_data").deleteOne({
      username: username,
      step: parseInt(step)
    });

    if (result.deletedCount === 0) {
      return res.status(404).json({
        success: false,
        message: "Appointment not found"
      });
    }

    // แจ้งเตือนผู้ป่วย
    await db.collection("notifications_data").insertOne({
      username: username,
      title: "วันนัดถูกยกเลิก",
      body: `วันนัดตรวจของคุณได้ถูกยกเลิกโดยเจ้าหน้าที่`,
      timestamp: new Date(),
      type: "appointment_cancelled",
      isRead: false
    });

    res.json({
      success: true,
      message: "Appointment deleted successfully"
    });

  } catch (err) {
    console.error("Error deleting appointment:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับค้นหาวันนัดตามเกณฑ์
app.post('/api/search_appointments', async (req, res) => {
  const {
    patientName,
    dateFrom,
    dateTo,
    status,
    step,
    limit = 50,
    skip = 0
  } = req.body;

  try {
    let matchStage = {};

    // ค้นหาตามวันที่
    if (dateFrom || dateTo) {
      matchStage.nextAppointment = {};
      if (dateFrom) matchStage.nextAppointment.$gte = new Date(dateFrom);
      if (dateTo) matchStage.nextAppointment.$lte = new Date(dateTo);
    }

    // ค้นหาตามสถานะ
    if (status) {
      matchStage.status = status;
    }

    // ค้นหาตาม step
    if (step !== undefined) {
      matchStage.step = parseInt(step);
    }

    const pipeline = [
      {
        $lookup: {
          from: "patients_data",
          localField: "username",
          foreignField: "username",
          as: "patientInfo"
        }
      },
      {
        $unwind: {
          path: "$patientInfo",
          preserveNullAndEmptyArrays: true
        }
      }
    ];

    // เพิ่มเงื่อนไขค้นหาชื่อผู้ป่วย
    if (patientName) {
      pipeline.push({
        $match: {
          "patientInfo.display_name": {
            $regex: patientName,
            $options: "i"
          }
        }
      });
    }

    // เพิ่มเงื่อนไขอื่นๆ
    if (Object.keys(matchStage).length > 0) {
      pipeline.push({ $match: matchStage });
    }

    // เพิ่ม projection และ sort
    pipeline.push(
      {
        $project: {
          username: 1,
          step: 1,
          stepTitle: 1,
          nextAppointment: 1,
          note: 1,
          status: 1,
          createdBy: 1,
          updatedAt: 1,
          patientName: "$patientInfo.display_name",
          patientPhone: "$patientInfo.phone"
        }
      },
      { $sort: { nextAppointment: 1 } },
      { $skip: parseInt(skip) },
      { $limit: parseInt(limit) }
    );

    const appointments = await db.collection("appointments_data").aggregate(pipeline).toArray();

    // นับจำนวนทั้งหมด
    const countPipeline = [...pipeline.slice(0, -2)]; // ลบ skip และ limit
    countPipeline.push({ $count: "total" });
    const countResult = await db.collection("appointments_data").aggregate(countPipeline).toArray();
    const total = countResult.length > 0 ? countResult[0].total : 0;

    res.json({
      success: true,
      appointments: appointments,
      pagination: {
        total: total,
        limit: parseInt(limit),
        skip: parseInt(skip),
        hasMore: total > (parseInt(skip) + appointments.length)
      }
    });

  } catch (err) {
    console.error("Error searching appointments:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// เพิ่มเข้ามาใหม่ 16/8/2568

// เพิ่ม API สำหรับปฏิเสธการขอเปลี่ยนวันนัด
app.post('/api/reject_appointment_change', async (req, res) => {
  const { username, step, rejectionReason, nurseUsername } = req.body;

  try {
    // ลบ request ออกจาก appointments_data (เปลี่ยนสถานะกลับเป็น scheduled)
    const result = await db.collection("appointments_data").updateOne(
      { username, step: parseInt(step) },
      {
        $set: {
          status: "scheduled",
          rejectedBy: nurseUsername,
          rejectedAt: new Date(),
          rejectionReason: rejectionReason,
          updatedAt: new Date()
        },
        $unset: {
          requestedDate: "",
          changeReason: "",
          requestedAt: ""
        }
      }
    );

    if (result.modifiedCount === 0) {
      return res.status(404).json({ success: false, message: "Appointment not found" });
    }

    // แจ้งเตือนผู้ป่วย
    const appointment = await db.collection("appointments_data").findOne({ username, step: parseInt(step) });
    await db.collection("notifications_data").insertOne({
      username: username,
      title: "คำขอเปลี่ยนวันนัดถูกปฏิเสธ",
      body: `คำขอเปลี่ยนวันนัด: ${appointment.stepTitle} ถูกปฏิเสธ\nเหตุผล: ${rejectionReason}`,
      timestamp: new Date(),
      type: "appointment_rejected",
      appointmentStep: parseInt(step),
      isRead: false
    });

    res.json({ success: true, message: "Appointment change rejected successfully" });
  } catch (err) {
    console.error("Error rejecting appointment change:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับดึงข้อมูลคำขอเปลี่ยนวันนัด (ปรับปรุงใหม่)
app.get('/api/get_change_requests', async (req, res) => {
  try {
    // ดึงข้อมูลจาก appointment_change_requests collection
    const changeRequests = await db.collection("appointment_change_requests").aggregate([
      {
        $match: {
          status: "pending"
        }
      },
      {
        $lookup: {
          from: "patients_data",
          localField: "username",
          foreignField: "username",
          as: "patientInfo"
        }
      },
      {
        $lookup: {
          from: "appointments_data",
          let: {
            requestUsername: "$username",
            requestStep: "$step"
          },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ["$username", "$$requestUsername"] },
                    { $eq: ["$step", "$$requestStep"] }
                  ]
                }
              }
            }
          ],
          as: "appointmentInfo"
        }
      },
      {
        $unwind: {
          path: "$patientInfo",
          preserveNullAndEmptyArrays: true
        }
      },
      {
        $unwind: {
          path: "$appointmentInfo",
          preserveNullAndEmptyArrays: true
        }
      },
      {
        $project: {
          username: 1,
          step: 1,
          requestedDate: 1,
          reason: 1,
          gaWeeks: 1,
          nextAppointmentWeek: 1,
          createdAt: 1,
          patientName: "$patientInfo.display_name",
          patientPhone: "$patientInfo.phone",
          stepTitle: "$appointmentInfo.stepTitle",
          nextAppointment: "$appointmentInfo.nextAppointment",
          changeReason: "$reason"  // alias for compatibility
        }
      },
      {
        $sort: { createdAt: -1 }
      }
    ]).toArray();

    res.json({
      success: true,
      changeRequests: changeRequests,
      count: changeRequests.length
    });

  } catch (err) {
    console.error("Error fetching change requests:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับอนุมัติการเปลี่ยนวันนัด (ปรับปรุงใหม่)
app.post('/api/approve_appointment_change', async (req, res) => {
  const { username, step, approvedDate, nurseUsername } = req.body;

  try {
    // อัพเดทการนัดหมายในฐานข้อมูล
    const result = await db.collection("appointments_data").updateOne(
      { username, step: parseInt(step) },
      {
        $set: {
          status: "scheduled",
          nextAppointment: new Date(approvedDate),
          approvedBy: nurseUsername,
          approvedAt: new Date(),
          updatedAt: new Date()
        }
      }
    );

    if (result.modifiedCount === 0) {
      return res.status(404).json({ success: false, message: "Appointment not found" });
    }

    // อัพเดทสถานะของคำขอใน appointment_change_requests
    await db.collection("appointment_change_requests").updateOne(
      {
        username: username,
        step: parseInt(step),
        status: "pending"
      },
      {
        $set: {
          status: "approved",
          approvedBy: nurseUsername,
          approvedDate: new Date(approvedDate),
          approvedAt: new Date()
        }
      }
    );

    // แจ้งเตือนผู้ป่วย
    const appointment = await db.collection("appointments_data").findOne({ username, step: parseInt(step) });
    await db.collection("notifications_data").insertOne({
      username: username,
      title: "วันนัดได้รับการอนุมัติ",
      body: `วันนัด: ${appointment.stepTitle} ได้ถูกเปลี่ยนเป็นวันที่ ${new Date(approvedDate).toLocaleDateString('th-TH')}`,
      timestamp: new Date(),
      type: "appointment_approved",
      appointmentStep: parseInt(step),
      isRead: false
    });

    res.json({ success: true, message: "Appointment change approved successfully" });
  } catch (err) {
    console.error("Error approving appointment change:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับดึงสถิติคำขอเปลี่ยนวันนัด
app.get('/api/change_requests_statistics', async (req, res) => {
  try {
    const [pendingCount, approvedCount, rejectedCount, totalToday] = await Promise.all([
      // คำขอที่รอการอนุมัติ
      db.collection("appointment_change_requests").countDocuments({ status: "pending" }),

      // คำขอที่ได้รับการอนุมัติ
      db.collection("appointment_change_requests").countDocuments({ status: "approved" }),

      // คำขอที่ถูกปฏิเสธ  
      db.collection("appointment_change_requests").countDocuments({ status: "rejected" }),

      // คำขอวันนี้
      db.collection("appointment_change_requests").countDocuments({
        createdAt: {
          $gte: new Date(new Date().setHours(0, 0, 0, 0)),
          $lt: new Date(new Date().setHours(23, 59, 59, 999))
        }
      })
    ]);

    res.json({
      success: true,
      statistics: {
        pending: pendingCount,
        approved: approvedCount,
        rejected: rejectedCount,
        today: totalToday,
        total: pendingCount + approvedCount + rejectedCount
      }
    });

  } catch (err) {
    console.error("Error fetching change request statistics:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับดึงประวัติการขอเปลี่ยนวันนัดของผู้ป่วยคนหนึ่ง
app.get('/api/get_patient_change_history', async (req, res) => {
  const { username } = req.query;

  try {
    const history = await db.collection("appointment_change_requests").aggregate([
      {
        $match: { username: username }
      },
      {
        $lookup: {
          from: "appointments_data",
          let: {
            requestUsername: "$username",
            requestStep: "$step"
          },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ["$username", "$$requestUsername"] },
                    { $eq: ["$step", "$$requestStep"] }
                  ]
                }
              }
            }
          ],
          as: "appointmentInfo"
        }
      },
      {
        $unwind: {
          path: "$appointmentInfo",
          preserveNullAndEmptyArrays: true
        }
      },
      {
        $project: {
          step: 1,
          requestedDate: 1,
          reason: 1,
          status: 1,
          createdAt: 1,
          approvedBy: 1,
          approvedDate: 1,
          approvedAt: 1,
          stepTitle: "$appointmentInfo.stepTitle"
        }
      },
      {
        $sort: { createdAt: -1 }
      }
    ]).toArray();

    res.json({
      success: true,
      history: history,
      count: history.length
    });

  } catch (err) {
    console.error("Error fetching patient change history:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับจัดการคำขอหลายรายการพร้อมกัน (bulk operations)
app.post('/api/bulk_handle_change_requests', async (req, res) => {
  const { requests, action, nurseUsername, approvedDates, rejectionReasons } = req.body;

  try {
    if (!Array.isArray(requests) || requests.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Invalid requests data"
      });
    }

    const results = [];

    for (let i = 0; i < requests.length; i++) {
      const request = requests[i];
      const { username, step } = request;

      try {
        if (action === 'approve') {
          const approvedDate = approvedDates[i];
          if (!approvedDate) continue;

          // อัพเดทการนัดหมาย
          await db.collection("appointments_data").updateOne(
            { username, step: parseInt(step) },
            {
              $set: {
                status: "scheduled",
                nextAppointment: new Date(approvedDate),
                approvedBy: nurseUsername,
                approvedAt: new Date(),
                updatedAt: new Date()
              }
            }
          );

          // อัพเดทสถานะคำขอ
          await db.collection("appointment_change_requests").updateOne(
            { username, step: parseInt(step), status: "pending" },
            {
              $set: {
                status: "approved",
                approvedBy: nurseUsername,
                approvedDate: new Date(approvedDate),
                approvedAt: new Date()
              }
            }
          );

          // ส่งการแจ้งเตือน
          const appointment = await db.collection("appointments_data").findOne({ username, step: parseInt(step) });
          await db.collection("notifications_data").insertOne({
            username: username,
            title: "วันนัดได้รับการอนุมัติ",
            body: `วันนัด: ${appointment.stepTitle} ได้ถูกเปลี่ยนเป็นวันที่ ${new Date(approvedDate).toLocaleDateString('th-TH')}`,
            timestamp: new Date(),
            type: "appointment_approved",
            appointmentStep: parseInt(step),
            isRead: false
          });

          results.push({ username, step, status: 'approved' });

        } else if (action === 'reject') {
          const rejectionReason = rejectionReasons[i] || 'ไม่ระบุเหตุผล';

          // อัพเดทสถานะคำขอ
          await db.collection("appointment_change_requests").updateOne(
            { username, step: parseInt(step), status: "pending" },
            {
              $set: {
                status: "rejected",
                rejectedBy: nurseUsername,
                rejectionReason: rejectionReason,
                rejectedAt: new Date()
              }
            }
          );

          // ส่งการแจ้งเตือน
          const appointment = await db.collection("appointments_data").findOne({ username, step: parseInt(step) });
          await db.collection("notifications_data").insertOne({
            username: username,
            title: "คำขอเปลี่ยนวันนัดถูกปฏิเสธ",
            body: `คำขอเปลี่ยนวันนัด: ${appointment.stepTitle} ถูกปฏิเสธ\nเหตุผล: ${rejectionReason}`,
            timestamp: new Date(),
            type: "appointment_rejected",
            appointmentStep: parseInt(step),
            isRead: false
          });

          results.push({ username, step, status: 'rejected' });
        }

      } catch (itemError) {
        console.error(`Error processing request ${username}-${step}:`, itemError);
        results.push({ username, step, status: 'error', error: itemError.message });
      }
    }

    res.json({
      success: true,
      message: `Processed ${results.length} requests`,
      results: results
    });

  } catch (err) {
    console.error("Error in bulk handle change requests:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});


// API สำหรับดึงข้อมูลการดิ้นของวันนี้
app.get("/kicks/today", async (req, res) => {
  const { username } = req.query;
  
  if (!username) {
    return res.status(400).json({ success: false, message: "Username is required" });
  }

  try {
    // สร้างวันที่ปัจจุบัน (เวลา 00:00:00)
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // ค้นหาข้อมูลการดิ้นของวันนี้
    const kickData = await db.collection("kick_counts").findOne({
      username: username,
      date: {
        $gte: today,
        $lt: tomorrow
      }
    });

    const count = kickData ? kickData.count : 0;
    
    res.json({
      success: true,
      count: count,
      date: today.toISOString().split('T')[0]
    });

  } catch (err) {
    console.error("Error fetching today's kick count:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับดึงข้อมูลการดิ้น 7 วันที่ผ่านมา
app.get("/kicks/weekly", async (req, res) => {
  const { username } = req.query;
  
  if (!username) {
    return res.status(400).json({ success: false, message: "Username is required" });
  }

  try {
    // สร้างวันที่ 7 วันที่ผ่านมา
    const today = new Date();
    today.setHours(23, 59, 59, 999);
    
    const sevenDaysAgo = new Date(today);
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6);
    sevenDaysAgo.setHours(0, 0, 0, 0);

    // ดึงข้อมูล 7 วันที่ผ่านมา
    const kickData = await db.collection("kick_counts").find({
      username: username,
      date: {
        $gte: sevenDaysAgo,
        $lte: today
      }
    }).sort({ date: 1 }).toArray();

    // สร้างข้อมูลสำหรับ 7 วัน (รวมวันที่ไม่มีข้อมูล)
    const weeklyData = [];
    const dayNames = ['อาทิตย์', 'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสฯ', 'ศุกร์', 'เสาร์'];
    
    for (let i = 0; i < 7; i++) {
      const currentDate = new Date(sevenDaysAgo);
      currentDate.setDate(currentDate.getDate() + i);
      
      const dateStr = currentDate.toISOString().split('T')[0];
      const dayName = dayNames[currentDate.getDay()];
      
      // ค้นหาข้อมูลการดิ้นของวันนี้
      const dayData = kickData.find(kick => {
        const kickDateStr = kick.date.toISOString().split('T')[0];
        return kickDateStr === dateStr;
      });
      
      weeklyData.push({
        date: dateStr,
        dayName: dayName,
        count: dayData ? dayData.count : 0
      });
    }

    res.json(weeklyData);

  } catch (err) {
    console.error("Error fetching weekly kick data:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับเพิ่มจำนวนการดิ้น
app.post("/kicks/increment", async (req, res) => {
  const { username } = req.body;
  
  if (!username) {
    return res.status(400).json({ success: false, message: "Username is required" });
  }

  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // ค้นหาข้อมูลของวันนี้
    const existingData = await db.collection("kick_counts").findOne({
      username: username,
      date: {
        $gte: today,
        $lt: tomorrow
      }
    });

    let newCount;
    
    if (existingData) {
      // อัพเดทข้อมูลที่มีอยู่
      newCount = existingData.count + 1;
      await db.collection("kick_counts").updateOne(
        { _id: existingData._id },
        { 
          $set: { 
            count: newCount,
            lastUpdated: new Date()
          }
        }
      );
    } else {
      // สร้างข้อมูลใหม่
      newCount = 1;
      await db.collection("kick_counts").insertOne({
        username: username,
        date: today,
        count: newCount,
        createdAt: new Date(),
        lastUpdated: new Date()
      });
    }

    // อัพเดทข้อมูลใน patients_data (เก็บข้อมูลล่าสุด)
    await db.collection("patients_data").updateOne(
      { username: username },
      { 
        $set: { 
          lastKickCount: newCount,
          lastKickDate: new Date().toISOString().split('T')[0],
          lastKickUpdated: new Date()
        }
      }
    );

    res.json({
      success: true,
      count: newCount,
      message: "Kick count incremented successfully"
    });

  } catch (err) {
    console.error("Error incrementing kick count:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับลดจำนวนการดิ้น
app.post("/kicks/decrement", async (req, res) => {
  const { username } = req.body;
  
  if (!username) {
    return res.status(400).json({ success: false, message: "Username is required" });
  }

  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // ค้นหาข้อมูลของวันนี้
    const existingData = await db.collection("kick_counts").findOne({
      username: username,
      date: {
        $gte: today,
        $lt: tomorrow
      }
    });

    if (!existingData || existingData.count <= 0) {
      return res.status(400).json({ 
        success: false, 
        message: "Cannot decrement: count is already 0 or no data found" 
      });
    }

    const newCount = existingData.count - 1;
    
    // อัพเดทข้อมูล
    await db.collection("kick_counts").updateOne(
      { _id: existingData._id },
      { 
        $set: { 
          count: newCount,
          lastUpdated: new Date()
        }
      }
    );

    // อัพเดทข้อมูลใน patients_data
    await db.collection("patients_data").updateOne(
      { username: username },
      { 
        $set: { 
          lastKickCount: newCount,
          lastKickDate: new Date().toISOString().split('T')[0],
          lastKickUpdated: new Date()
        }
      }
    );

    res.json({
      success: true,
      count: newCount,
      message: "Kick count decremented successfully"
    });

  } catch (err) {
    console.error("Error decrementing kick count:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับบันทึกข้อมูลการดิ้นแบบ manual
app.post("/kicks/save", async (req, res) => {
  const { username, count, date } = req.body;
  
  if (!username || count === undefined) {
    return res.status(400).json({ 
      success: false, 
      message: "Username and count are required" 
    });
  }

  try {
    const saveDate = date ? new Date(date) : new Date();
    saveDate.setHours(0, 0, 0, 0);
    
    const nextDay = new Date(saveDate);
    nextDay.setDate(nextDay.getDate() + 1);

    // ตรวจสอบว่ามีข้อมูลของวันนี้แล้วหรือไม่
    const existingData = await db.collection("kick_counts").findOne({
      username: username,
      date: {
        $gte: saveDate,
        $lt: nextDay
      }
    });

    if (existingData) {
      // อัพเดทข้อมูลที่มีอยู่
      await db.collection("kick_counts").updateOne(
        { _id: existingData._id },
        { 
          $set: { 
            count: parseInt(count),
            lastUpdated: new Date(),
            savedManually: true
          }
        }
      );
    } else {
      // สร้างข้อมูลใหม่
      await db.collection("kick_counts").insertOne({
        username: username,
        date: saveDate,
        count: parseInt(count),
        createdAt: new Date(),
        lastUpdated: new Date(),
        savedManually: true
      });
    }

    // อัพเดทข้อมูลใน patients_data
    await db.collection("patients_data").updateOne(
      { username: username },
      { 
        $set: { 
          lastKickCount: parseInt(count),
          lastKickDate: saveDate.toISOString().split('T')[0],
          lastKickUpdated: new Date()
        }
      }
    );

    res.json({
      success: true,
      message: "Kick count saved successfully",
      count: parseInt(count),
      date: saveDate.toISOString().split('T')[0]
    });

  } catch (err) {
    console.error("Error saving kick count:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับดึงประวัติการดิ้นทั้งหมด (สำหรับดูข้อมูลย้อนหลัง)
app.get("/kicks/history", async (req, res) => {
  const { username, limit = 30 } = req.query;
  
  if (!username) {
    return res.status(400).json({ success: false, message: "Username is required" });
  }

  try {
    const kickHistory = await db.collection("kick_counts")
      .find({ username: username })
      .sort({ date: -1 })
      .limit(parseInt(limit))
      .toArray();

    const formattedHistory = kickHistory.map(kick => ({
      date: kick.date.toISOString().split('T')[0],
      count: kick.count,
      lastUpdated: kick.lastUpdated,
      savedManually: kick.savedManually || false
    }));

    res.json({
      success: true,
      history: formattedHistory,
      totalRecords: kickHistory.length
    });

  } catch (err) {
    console.error("Error fetching kick history:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// API สำหรับลบข้อมูลการดิ้นของวันที่ระบุ
app.delete("/kicks/delete", async (req, res) => {
  const { username, date } = req.body;
  
  if (!username || !date) {
    return res.status(400).json({ 
      success: false, 
      message: "Username and date are required" 
    });
  }

  try {
    const deleteDate = new Date(date);
    deleteDate.setHours(0, 0, 0, 0);
    
    const nextDay = new Date(deleteDate);
    nextDay.setDate(nextDay.getDate() + 1);

    const result = await db.collection("kick_counts").deleteOne({
      username: username,
      date: {
        $gte: deleteDate,
        $lt: nextDay
      }
    });

    if (result.deletedCount === 0) {
      return res.status(404).json({ 
        success: false, 
        message: "No kick count data found for the specified date" 
      });
    }

    res.json({
      success: true,
      message: "Kick count data deleted successfully"
    });

  } catch (err) {
    console.error("Error deleting kick count:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// ================ AUTO SAVE FUNCTIONALITY ================

// Cron job สำหรับบันทึกข้อมูลอัตโนมัติทุกเที่ยงคืน
cron.schedule("0 0 * * *", async () => {
  console.log("🕛 Running daily kick count auto-save...");
  
  try {
    // ดึงข้อมูลผู้ป่วยทั้งหมดที่มีข้อมูล lastKickCount
    const patients = await db.collection("patients_data")
      .find({ 
        lastKickCount: { $exists: true },
        lastKickDate: { $exists: true }
      })
      .toArray();

    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let savedCount = 0;

    for (const patient of patients) {
      try {
        // ตรวจสอบว่าข้อมูลล่าสุดเป็นของเมื่อวาน
        const lastKickDate = new Date(patient.lastKickDate);
        lastKickDate.setHours(0, 0, 0, 0);

        if (lastKickDate.getTime() === yesterday.getTime()) {
          // ตรวจสอบว่ามีข้อมูลของเมื่อวานในฐานข้อมูลแล้วหรือไม่
          const existingData = await db.collection("kick_counts").findOne({
            username: patient.username,
            date: {
              $gte: yesterday,
              $lt: today
            }
          });

          if (!existingData && patient.lastKickCount > 0) {
            // บันทึกข้อมูลอัตโนมัติ
            await db.collection("kick_counts").insertOne({
              username: patient.username,
              date: yesterday,
              count: patient.lastKickCount,
              createdAt: new Date(),
              lastUpdated: new Date(),
              autoSaved: true
            });

            savedCount++;
            console.log(`Auto-saved kick count for ${patient.username}: ${patient.lastKickCount} kicks`);
          }
        }
      } catch (patientErr) {
        console.error(`Error auto-saving for patient ${patient.username}:`, patientErr);
      }
    }

    console.log(`✅ Auto-save completed. Saved ${savedCount} records.`);

  } catch (err) {
    console.error("❌ Error during kick count auto-save:", err);
  }
});

// API สำหรับ trigger การบันทึกอัตโนมัติแบบ manual (สำหรับ testing)
app.post("/kicks/trigger-auto-save", async (req, res) => {
  console.log("📥 Manual trigger for kick count auto-save");
  
  try {
    const patients = await db.collection("patients_data")
      .find({ 
        lastKickCount: { $exists: true },
        lastKickDate: { $exists: true }
      })
      .toArray();

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    let savedCount = 0;

    for (const patient of patients) {
      try {
        // ตรวจสอบว่ามีข้อมูลของวันนี้แล้วหรือไม่
        const existingData = await db.collection("kick_counts").findOne({
          username: patient.username,
          date: {
            $gte: today,
            $lt: tomorrow
          }
        });

        if (!existingData && patient.lastKickCount > 0) {
          await db.collection("kick_counts").insertOne({
            username: patient.username,
            date: today,
            count: patient.lastKickCount,
            createdAt: new Date(),
            lastUpdated: new Date(),
            manualAutoSave: true
          });

          savedCount++;
        }
      } catch (patientErr) {
        console.error(`Error in manual auto-save for ${patient.username}:`, patientErr);
      }
    }

    res.json({
      success: true,
      message: "Auto-save triggered successfully",
      savedCount: savedCount
    });

  } catch (err) {
    console.error("Error during manual auto-save trigger:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// ================ STATISTICS APIs ================

// API สำหรับดึงสถิติการดิ้นของผู้ป่วย
app.get("/kicks/statistics", async (req, res) => {
  const { username, days = 7 } = req.query;
  
  if (!username) {
    return res.status(400).json({ success: false, message: "Username is required" });
  }

  try {
    const endDate = new Date();
    endDate.setHours(23, 59, 59, 999);
    
    const startDate = new Date(endDate);
    startDate.setDate(startDate.getDate() - (parseInt(days) - 1));
    startDate.setHours(0, 0, 0, 0);

    const kickData = await db.collection("kick_counts")
      .find({
        username: username,
        date: {
          $gte: startDate,
          $lte: endDate
        }
      })
      .sort({ date: 1 })
      .toArray();

    const totalKicks = kickData.reduce((sum, day) => sum + day.count, 0);
    const averageKicks = kickData.length > 0 ? (totalKicks / kickData.length) : 0;
    const maxKicks = kickData.length > 0 ? Math.max(...kickData.map(day => day.count)) : 0;
    const minKicks = kickData.length > 0 ? Math.min(...kickData.map(day => day.count)) : 0;
    
    // หาวันที่มีการดิ้นมากที่สุด
    const maxKickDay = kickData.find(day => day.count === maxKicks);
    
    res.json({
      success: true,
      statistics: {
        totalKicks,
        averageKicks: parseFloat(averageKicks.toFixed(1)),
        maxKicks,
        minKicks,
        maxKickDate: maxKickDay ? maxKickDay.date.toISOString().split('T')[0] : null,
        totalDays: kickData.length,
        requestedDays: parseInt(days)
      },
      data: kickData.map(kick => ({
        date: kick.date.toISOString().split('T')[0],
        count: kick.count
      }))
    });

  } catch (err) {
    console.error("Error fetching kick statistics:", err);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
});

// เพิ่ม API นี้ใน server.js

// Get checklist data for a patient
// เพิ่มใน server.js
// ข้อมูล template สำหรับแต่ละครั้ง
const visitTemplates = {
  1: {
    title: "การแจ้งเตือนที่ 1",
    description: "อายุครรภ์น้อยกว่า 12 สัปดาห์",
    tasks: [
      { id: 1, task: "ตรวจ UPT Positive, ส่งตรวจ UA และ Amphetamine ในรายที่มีความเสี่ยง", completed: false },
      { id: 2, task: "ฝากครรภ์พร้อมออกสมุดบันทึกมซักประวัติเสี่ยงต่างๆ", completed: false },
      { id: 3, task: "ประเมินการให้วัคซีน dT1", completed: false },
      { id: 4, task: "ส่งตรวจ U/S ครั้งที่ 1", completed: false },
      { id: 5, task: "Lab 1", completed: false },
      { id: 6, task: "ตรวจสุขภาพช่องปาก", completed: false },
      { id: 7, task: "ประเมินสุขภาพจิต 1", completed: false },
      { id: 8, task: "โรงเรียนพ่อแม่ครั้งที่ 1", completed: false },
      { id: 9, task: "ให้ยา Triferdine, Calcium ตลอดการตั้งครรภ์", completed: false }
    ]
  },
  2: {
    title: "การแจ้งเตือนที่ 2",
    description: "อายุครรภ์น้อยกว่า 20 สัปดาห์ แต่มากกว่า 12 สัปดาห์",
    tasks: [
      { id: 1, task: "ตรวจ UPT Positive,ส่งตรวจ UA และ Amphetamine ในรายที่มีความเสี่ยง", completed: false },
      { id: 2, task: "ฝากครรภ์พร้อมออกสมุดบันทึกมซักประวัติเสี่ยงต่างๆ", completed: false },
      { id: 3, task: "ประเมินการให้วัคซีน dT1", completed: false },
      { id: 4, task: "ส่งตรวจ U/S ครั้งที่ 1", completed: false },
      { id: 5, task: "Lab 1", completed: false },
      { id: 6, task: "ตรวจสุขภาพช่องปาก", completed: false },
      { id: 7, task: "ประเมินสุขภาพจิต 1", completed: false },
      { id: 8, task: "โรงเรียนพ่อแม่ครั้งที่ 1", completed: false },
      { id: 9, task: "ให้ยา Triferdine, Calcium ตลอดการตั้งครรภ์", completed: false }
    ]
  },
  3: {
    title: "การแจ้งเตือนที่ 3",
    description: "อายุครรภ์เท่ากับ 26 สัปดาห์ แต่มากกว่า 20 สัปดาห์",
    tasks: [
      { id: 1, task: "ตรวจ UA", completed: false },
      { id: 2, task: "ประเมินความเสี่ยงการตั้งครรภ์", completed: false },
      { id: 3, task: "ส่งตรวจ U/S ครั้งที่ 2", completed: false },
      { id: 4, task: "ประเมินสุขภาพจิต ครั้งที่ 2", completed: false },
      { id: 5, task: "บันทึกการตรวจครรภ์", completed: false },
      { id: 6, task: "ให้สุขศึกษา", completed: false }
    ]
  },
  4: {
    title: "การแจ้งเตือนที่ 4",
    description: "อายุครรภ์เท่ากับ 32 สัปดาห์ แต่มากกว่า 26 สัปดาห์",
    tasks: [
      { id: 1, task: "ตรวจ UA", completed: false },
      { id: 2, task: "ประเมินความเสี่ยงการตั้งครรภ์", completed: false },
      { id: 3, task: "ประเมินสุขภาพจิต ครั้งที่ 4", completed: false },
      { id: 4, task: "Lab 2 (Anti HIV, VDRI, Hct, Hb)", completed: false },
      { id: 5, task: "บันทึกการตรวจครรภ์", completed: false },
      { id: 6, task: "โรงเรียนพ่อแม่ครั้งที่ 2", completed: false },
      { id: 7, task: "ให้สุขศึกษา เน้น อันตรายคลอดก่อนกำหนดและสัญญาณเตือน", completed: false }
    ]
  },
  5: {
    title: "การแจ้งเตือนที่ 5",
    description: "อายุครรภ์เท่ากับ 34 สัปดาห์ แต่มากกว่า 32 สัปดาห์",
    tasks: [
      { id: 1, task: "ตรวจ Multiple urine dipstip", completed: false },
      { id: 2, task: "ประเมินความเสี่ยงการตั้งครรภ์", completed: false },
      { id: 3, task: "ประเมินสุขภาพจิต ครั้งที่ 5", completed: false },
      { id: 4, task: "ส่งตรวจ U/S ครั้งที่ 3 ดูการเจริญเติบโต, ส่วนนำ", completed: false },
      { id: 5, task: "ประเมินการคลอด", completed: false },
      { id: 6, task: "ให้สุขศึกษาเน้นอันตรายคลอดก่อนกำหนดและสัญญาณเตือน", completed: false }
    ]
  },
  6: {
    title: "การแจ้งเตือนที่ 6",
    description: "อายุครรภ์เท่ากับ 36 สัปดาห์ แต่มากกว่า 34 สัปดาห์",
    tasks: [
      { id: 1, task: "ตรวจ Multiple urine dipstip", completed: false },
      { id: 2, task: "ประเมินความเสี่ยงการตั้งครรภ์", completed: false },
      { id: 3, task: "ประเมินสุขภาพจิต ครั้งที่ 6", completed: false },
      { id: 4, task: "บันทึกการตรวจครรภ์", completed: false },
      { id: 5, task: "ให้สุขศึกษา", completed: false }
    ]
  },
  7: {
    title: "การแจ้งเตือนที่ 7",
    description: "อายุครรภ์เท่ากับ 38 สัปดาห์ แต่มากกว่า 36 สัปดาห์",
    tasks: [
      { id: 1, task: "ตรวจ Multiple urine dipstip", completed: false },
      { id: 2, task: "ประเมินความเสี่ยงการตั้งครรภ์", completed: false },
      { id: 3, task: "ประเมินสุขภาพจิต ครั้งที่ 6", completed: false },
      { id: 4, task: "บันทึกการตรวจครรภ์", completed: false },
      { id: 5, task: "ให้สุขศึกษา", completed: false },
      { id: 6, task: "NST +PV", completed: false },
      { id: 7, task: "ประเมินการให้ dT3 ห่างจากเข็ม 2 นาน 6 เดือน", completed: false }
    ]
  },
  8: {
    title: "การแจ้งเตือนที่ 8",
    description: "อายุครรภ์เท่ากับ 40 สัปดาห์ แต่มากกว่า 38 สัปดาห์",
    tasks: [
      { id: 1, task: "ตรวจ Multiple urine dipstip", completed: false },
      { id: 2, task: "ประเมินความเสี่ยงการตั้งครรภ์", completed: false },
      { id: 3, task: "ประเมินสุขภาพจิต ครั้งที่ 6", completed: false },
      { id: 4, task: "บันทึกการตรวจครรภ์", completed: false },
      { id: 5, task: "ให้สุขศึกษา", completed: false },
      { id: 6, task: "ส่ง NST +PV ที่ LR NST non -reactive, PV: not dilation refer รพ.นครพนม", completed: false },
      { id: 7, task: "U/S ดูน้ำครำ", completed: false }
    ]
  }
};

// ฟังก์ชันสำหรับ migrate ข้อมูลเก่า
function migrateOldChecklistData(oldChecklist) {
  const migratedVisits = [];
  
  for (let i = 1; i <= 8; i++) {
    const template = visitTemplates[i];
    const existingVisit = oldChecklist.visits?.find(v => v.visit === i);
    
    let migratedVisit = {
      visit: i,
      title: template.title,
      description: template.description,
      tasks: [...template.tasks], // เริ่มต้นด้วย template tasks
      completed: false,
      completedTasks: 0,
      totalTasks: template.tasks.length,
      date: null
    };
    
    // ถ้ามีข้อมูลเก่า ให้นำมารวม
    if (existingVisit) {
      migratedVisit.completed = existingVisit.completed || false;
      migratedVisit.date = existingVisit.date || null;
      
      // ถ้ามี tasks เก่า ให้ merge กับ template
      if (existingVisit.tasks && Array.isArray(existingVisit.tasks)) {
        migratedVisit.tasks = template.tasks.map(templateTask => {
          const existingTask = existingVisit.tasks.find(t => t.id === templateTask.id);
          return existingTask ? { ...templateTask, completed: existingTask.completed } : templateTask;
        });
      }
      
      // คำนวณ completedTasks ใหม่
      migratedVisit.completedTasks = migratedVisit.tasks.filter(t => t.completed).length;
      
      // อัพเดทสถานะ completed ถ้าจำเป็น
      if (migratedVisit.completedTasks === migratedVisit.totalTasks && migratedVisit.completedTasks > 0) {
        migratedVisit.completed = true;
        if (!migratedVisit.date) {
          migratedVisit.date = new Date();
        }
      }
    }
    
    migratedVisits.push(migratedVisit);
  }
  
  return migratedVisits;
}

// API สำหรับ get checklist พร้อม data migration
app.post("/api/get_patient_checklist", async (req, res) => {
  const { username } = req.body;
  
  if (!username) {
    return res.status(400).json({ success: false, message: "Username is required" });
  }
  
  try {
    const patient = await db.collection("patients_data").findOne({ username });
    if (!patient) {
      return res.status(404).json({ success: false, message: "Patient not found" });
    }

    let checklist = await db.collection("patient_checklist").findOne({ username });
    let needsUpdate = false;
    
    if (!checklist) {
      // สร้าง checklist ใหม่พร้อม detailed tasks
      const visits = [];
      for (let i = 1; i <= 8; i++) {
        const template = visitTemplates[i];
        visits.push({
          visit: i,
          title: template.title,
          description: template.description,
          tasks: [...template.tasks], // copy tasks from template
          completed: false,
          completedTasks: 0,
          totalTasks: template.tasks.length,
          date: null
        });
      }

      checklist = {
        username,
        display_name: patient.display_name,
        GA: patient.GA,
        visits,
        lastUpdated: new Date()
      };
      
      await db.collection("patient_checklist").insertOne(checklist);
      console.log(`Created new checklist for ${username}`);
    } else {
      // ตรวจสอบว่าจำเป็นต้อง migrate หรือไม่
      const firstVisit = checklist.visits?.[0];
      const needsMigration = !firstVisit || 
                            !firstVisit.title || 
                            !firstVisit.description || 
                            !firstVisit.tasks || 
                            !Array.isArray(firstVisit.tasks) ||
                            firstVisit.tasks.length === 0;
      
      if (needsMigration) {
        console.log(`Migrating checklist data for ${username}`);
        
        // Migrate ข้อมูล
        const migratedVisits = migrateOldChecklistData(checklist);
        
        checklist.visits = migratedVisits;
        checklist.lastUpdated = new Date();
        needsUpdate = true;
        
        console.log(`Migration completed for ${username}`);
      }
      
      // อัพเดท display_name และ GA ถ้าจำเป็น
      if (checklist.display_name !== patient.display_name || checklist.GA !== patient.GA) {
        checklist.display_name = patient.display_name;
        checklist.GA = patient.GA;
        needsUpdate = true;
      }
      
      // บันทึกการเปลี่ยนแปลง
      if (needsUpdate) {
        await db.collection("patient_checklist").updateOne(
          { username },
          { $set: checklist }
        );
        console.log(`Updated checklist for ${username}`);
      }
    }

    res.json({ success: true, checklist });
  } catch (err) {
    console.error("Error fetching/creating checklist:", err);
    res.status(500).json({ success: false, message: "Internal server error", error: err.message });
  }
});

// API สำหรับ migrate ข้อมูลทั้งหมด (สำหรับ admin)
app.post("/api/migrate_all_checklists", async (req, res) => {
  try {
    const checklists = await db.collection("patient_checklist").find({}).toArray();
    let migratedCount = 0;
    
    for (const checklist of checklists) {
      const firstVisit = checklist.visits?.[0];
      const needsMigration = !firstVisit || 
                            !firstVisit.title || 
                            !firstVisit.description || 
                            !firstVisit.tasks || 
                            !Array.isArray(firstVisit.tasks) ||
                            firstVisit.tasks.length === 0;
      
      if (needsMigration) {
        console.log(`Migrating checklist for ${checklist.username}`);
        
        const migratedVisits = migrateOldChecklistData(checklist);
        
        await db.collection("patient_checklist").updateOne(
          { username: checklist.username },
          { 
            $set: { 
              visits: migratedVisits,
              lastUpdated: new Date()
            }
          }
        );
        
        migratedCount++;
      }
    }
    
    res.json({ 
      success: true, 
      message: `Migrated ${migratedCount} checklists successfully`,
      totalChecked: checklists.length,
      migrated: migratedCount
    });
  } catch (err) {
    console.error("Error migrating checklists:", err);
    res.status(500).json({ success: false, message: "Internal server error", error: err.message });
  }
});

// API สำหรับอัพเดท task แต่ละรายการ
app.post("/api/update_task_item", async (req, res) => {
  const { username, visitNumber, taskId, completed } = req.body;
  
  if (!username || !visitNumber || !taskId || completed === undefined) {
    return res.status(400).json({ success: false, message: "Missing required parameters" });
  }
  
  try {
    // อัพเดท task ที่เฉพาะเจาะจง
    const result = await db.collection("patient_checklist").updateOne(
      { 
        username, 
        "visits.visit": visitNumber,
        "visits.tasks.id": taskId 
      },
      { 
        $set: { 
          "visits.$[visit].tasks.$[task].completed": completed,
          lastUpdated: new Date()
        }
      },
      {
        arrayFilters: [
          { "visit.visit": visitNumber },
          { "task.id": taskId }
        ]
      }
    );

    if (result.modifiedCount > 0) {
      // คำนวณจำนวน task ที่เสร็จแล้ว และอัพเดทสถานะของ visit
      const checklist = await db.collection("patient_checklist").findOne({ username });
      const visit = checklist.visits.find(v => v.visit === visitNumber);
      
      if (visit) {
        const completedTasks = visit.tasks.filter(t => t.completed).length;
        const allTasksCompleted = completedTasks === visit.totalTasks;

        await db.collection("patient_checklist").updateOne(
          { username, "visits.visit": visitNumber },
          { 
            $set: { 
              "visits.$.completedTasks": completedTasks,
              "visits.$.completed": allTasksCompleted,
              "visits.$.date": allTasksCompleted ? new Date() : (completedTasks > 0 ? visit.date || new Date() : null),
              lastUpdated: new Date()
            }
          }
        );
      }

      res.json({ success: true, message: "Task updated successfully" });
    } else {
      res.status(404).json({ success: false, message: "Task not found or no changes made" });
    }
  } catch (err) {
    console.error("Error updating task:", err);
    res.status(500).json({ success: false, message: "Internal server error", error: err.message });
  }
});

// Update checklist item (legacy support)
app.post("/api/update_checklist_item", async (req, res) => {
  const { username, visitNumber, completed } = req.body;
  
  if (!username || !visitNumber || completed === undefined) {
    return res.status(400).json({ success: false, message: "Missing required parameters" });
  }
  
  try {
    const result = await db.collection("patient_checklist").updateOne(
      { username, "visits.visit": visitNumber },
      { 
        $set: { 
          "visits.$.completed": completed,
          "visits.$.date": completed ? new Date() : null,
          lastUpdated: new Date()
        }
      }
    );

    if (result.modifiedCount === 0) {
      return res.status(404).json({ success: false, message: "Checklist item not found" });
    }

    res.json({ success: true, message: "Checklist updated successfully" });
  } catch (err) {
    console.error("Error updating checklist:", err);
    res.status(500).json({ success: false, message: "Internal server error", error: err.message });
  }
});

// Get current visit status for patient dashboard
app.post("/api/get_patient_visit_status", async (req, res) => {
  const { username } = req.body;
  
  if (!username) {
    return res.status(400).json({ success: false, message: "Username is required" });
  }
  
  try {
    const checklist = await db.collection("patient_checklist").findOne({ username });
    
    if (!checklist) {
      return res.json({ 
        success: true, 
        currentVisit: 1,
        completedVisits: 0,
        nextVisitDue: true 
      });
    }

    const completedVisits = checklist.visits.filter(v => v.completed).length;
    const currentVisit = completedVisits + 1;
    const nextVisitDue = currentVisit <= 8;

    res.json({ 
      success: true, 
      currentVisit: currentVisit > 8 ? 8 : currentVisit,
      completedVisits,
      nextVisitDue,
      visits: checklist.visits
    });
  } catch (err) {
    console.error("Error fetching visit status:", err);
    res.status(500).json({ success: false, message: "Internal server error", error: err.message });
  }
});


app.post("/api/mark_visit_checkin", async (req, res) => {
  const { username, visitNumber, checkIn } = req.body;
  
  if (!username || !visitNumber || checkIn === undefined) {
    return res.status(400).json({ success: false, message: "Missing required parameters" });
  }

  try {
    const updateData = {
      "visits.$.checkedIn": checkIn,
      "visits.$.checkInDate": checkIn ? new Date() : null,
      lastUpdated: new Date()
    };

    const result = await db.collection("patient_checklist").updateOne(
      { username, "visits.visit": visitNumber },
      { $set: updateData }
    );

    if (result.modifiedCount > 0) {
      res.json({ success: true, message: "Check-in status updated successfully" });
    } else {
      res.status(404).json({ success: false, message: "Visit not found" });
    }
  } catch (err) {
    console.error("Error updating check-in status:", err);
    res.status(500).json({ success: false, message: "Internal server error", error: err.message });
  }
});
// Start the server
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});