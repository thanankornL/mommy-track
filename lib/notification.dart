import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<String> getSessionUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'user';
  }

  Future<void> fetchNotifications() async {
    final String username = await getSessionUsername();
    final Uri url = Uri.parse('$baseUrl/api/notifications?username=$username');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          notifications = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        children: [
          SizedBox(height: 20),
          Card(
            margin: EdgeInsets.all(5.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            color: Colors.white,
            child: SizedBox(
              height: screenHeight * 0.8,
              child:
                  isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                      : ListView.separated(
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) => Divider(),
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          return ListTile(
                            leading: Icon(Icons.notifications),
                            title: Text(item['title'] ?? 'No title'),
                            subtitle: Text(item['body'] ?? 'No message'),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

// --------- User Model ----------
class User {
  final String id;
  final String username;
  final String displayname;

  User({required this.id, required this.username, required this.displayname});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['username'],
      username: json['username'],
      displayname: json['display_name'],
    );
  }
}

// --------- Step Model ----------
class AppointmentStep {
  final int stepNumber;
  final String title;
  final String description;
  final int targetWeeks; // เพิ่มสัปดาห์เป้าหมาย

  AppointmentStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.targetWeeks,
  });

  static List<AppointmentStep> getSteps() {
    return [
      AppointmentStep(
        stepNumber: 0,
        title: "การแจ้งเตือนที่ 1",
        description: "อายุครรภ์น้อยกว่า 12 สัปดาห์",
        targetWeeks: 12,
      ),
      AppointmentStep(
        stepNumber: 1,
        title: "การแจ้งเตือนที่ 2",
        description: "อายุครรภ์ 12-20 สัปดาห์",
        targetWeeks: 20,
      ),
      AppointmentStep(
        stepNumber: 2,
        title: "การแจ้งเตือนที่ 3",
        description: "อายุครรภ์ 20-26 สัปดาห์",
        targetWeeks: 26,
      ),
      AppointmentStep(
        stepNumber: 3,
        title: "การแจ้งเตือนที่ 4",
        description: "อายุครรภ์ 26-32 สัปดาห์",
        targetWeeks: 32,
      ),
      AppointmentStep(
        stepNumber: 4,
        title: "การแจ้งเตือนที่ 5",
        description: "อายุครรภ์ 32-34 สัปดาห์",
        targetWeeks: 34,
      ),
      AppointmentStep(
        stepNumber: 5,
        title: "การแจ้งเตือนที่ 6",
        description: "อายุครรภ์ 34-36 สัปดาห์",
        targetWeeks: 36,
      ),
      AppointmentStep(
        stepNumber: 6,
        title: "การแจ้งเตือนที่ 7",
        description: "อายุครรภ์ 36-38 สัปดาห์",
        targetWeeks: 38,
      ),
      AppointmentStep(
        stepNumber: 7,
        title: "การแจ้งเตือนที่ 8",
        description: "อายุครรภ์ 38-40 สัปดาห์",
        targetWeeks: 40,
      ),
    ];
  }
}

// --------- Fetch Users ----------
Future<List<User>> fetchUsers() async {
  final response = await http.get(Uri.parse('$baseUrl/api/users'));

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((userJson) => User.fromJson(userJson)).toList();
  } else {
    throw Exception('Failed to load users');
  }
}

class sendNotification extends StatefulWidget {
  const sendNotification({super.key});

  @override
  State<sendNotification> createState() => _SendNotificationState();
}

class _SendNotificationState extends State<sendNotification> {
  User? selectedUser;
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  // Appointment form controllers
  User? selectedUserForAppointment;
  AppointmentStep? selectedStep;
  DateTime? _selectedDate;
  final TextEditingController _noteController = TextEditingController();

  // เพิ่มตัวแปรสำหรับข้อมูลผู้ป่วย
  Map<String, dynamic>? patientData;
  DateTime? calculatedAppointmentDate;
  DateTime? minAllowedDate;
  DateTime? maxAllowedDate;
  bool isLoadingPatientData = false;
  String? patientDataError;

  // List of available steps
  final List<AppointmentStep> availableSteps = AppointmentStep.getSteps();

DateTime? calculateAppointmentDate(dynamic lmp, int targetWeeks) {
  if (lmp == null) return null;

  try {
    DateTime lmpDate;
    
    if (lmp is DateTime) {
      lmpDate = lmp;
    } else if (lmp is String) {
      lmpDate = DateTime.parse(lmp);
    } else {
      return null;
    }

    return lmpDate.add(Duration(days: targetWeeks * 7));
  } catch (e) {
    print('Error calculating appointment date: $e');
    return null;
  }
}




 Future<void> fetchPatientData(String username) async {
  setState(() {
    isLoadingPatientData = true;
    patientDataError = null;
    patientData = null;
  });

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/get_user_data'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'role': 'patient'}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // ตรวจสอบและแปลงรูปแบบข้อมูล LMP
      if (data['LMP'] != null && data['LMP'].toString().isNotEmpty) {
        try {
          // พยายามแปลงเป็น DateTime ถ้าเป็น String
          if (data['LMP'] is String) {
            data['LMP'] = DateTime.parse(data['LMP']);
          }
        } catch (e) {
          print('Error parsing LMP date: $e');
          data['LMP'] = null;
        }
      } else {
        data['LMP'] = null;
      }

      // ตรวจสอบและแปลง GA เป็นตัวเลข
      if (data['GA'] != null) {
        try {
          data['GA'] = int.tryParse(data['GA'].toString()) ?? 0;
        } catch (e) {
          print('Error parsing GA: $e');
          data['GA'] = 0;
        }
      } else {
        data['GA'] = 0;
      }

      setState(() {
        patientData = data;
        isLoadingPatientData = false;
      });

      updateAllowedDateRange();
    } else {
      final errorData = json.decode(response.body);
      setState(() {
        patientDataError = errorData['message'] ?? 'Failed to fetch patient data';
        isLoadingPatientData = false;
      });
    }
  } catch (e) {
    setState(() {
      patientDataError = 'Error: ${e.toString()}';
      isLoadingPatientData = false;
    });
  }
}

 
  void updateAllowedDateRange() {
    print('Updating allowed date range...');
    print(
      'selectedUserForAppointment: ${selectedUserForAppointment?.username}',
    );
    print('selectedStep: ${selectedStep?.stepNumber}');
    print('patientData: $patientData');

    if (selectedUserForAppointment != null &&
        selectedStep != null &&
        patientData != null) {
      final lmp = patientData!['LMP'];
      print('LMP value: $lmp (type: ${lmp.runtimeType})');

      if (lmp != null && lmp.toString().isNotEmpty) {

        calculatedAppointmentDate = calculateAppointmentDate(
          lmp,
          selectedStep!.targetWeeks,
        );

        print('Calculated appointment date: $calculatedAppointmentDate');

        if (calculatedAppointmentDate != null) {
      
          minAllowedDate = calculatedAppointmentDate!.subtract(
            Duration(days: 3),
          );
          maxAllowedDate = calculatedAppointmentDate!.add(Duration(days: 3));

          print('Date range: $minAllowedDate to $maxAllowedDate');

       
          if (_selectedDate != null) {
            if (_selectedDate!.isBefore(minAllowedDate!) ||
                _selectedDate!.isAfter(maxAllowedDate!)) {
              setState(() {
                _selectedDate = null;
              });
            }
          }
        } else {
        
          print('Error calculating appointment date from LMP');
          setState(() {
            calculatedAppointmentDate = null;
            minAllowedDate = DateTime.now().subtract(
              Duration(days: 365),
            ); // 1 ปีที่ผ่านมา
            maxAllowedDate = DateTime.now().add(
              Duration(days: 365),
            ); // 1 ปีนับจากนี้
            _selectedDate = null;
            patientDataError =
                'ไม่สามารถคำนวณช่วงวันที่ที่แนะนำได้ (LMP ผิดรูปแบบ)';
          });
        }
      } else {
        print('LMP is null or empty');
        // ถ้า LMP เป็นค่าว่าง ให้กำหนดช่วงวันที่ที่กว้างและแสดงคำเตือน
        setState(() {
          calculatedAppointmentDate = null;
          minAllowedDate = DateTime.now().subtract(
            Duration(days: 365),
          ); // 1 ปีที่ผ่านมา
          maxAllowedDate = DateTime.now().add(
            Duration(days: 365),
          ); // 1 ปีนับจากนี้
          _selectedDate = null;
          patientDataError =
              'ไม่พบข้อมูล LMP ของผู้ป่วย ไม่สามารถตรวจสอบช่วงวันที่ที่แนะนำได้';
        });
      }
    } else {
      // ถ้าข้อมูลผู้ป่วยหรือขั้นตอนการนัดหมายยังไม่ถูกเลือก
      setState(() {
        calculatedAppointmentDate = null;
        minAllowedDate = null;
        maxAllowedDate = null;
        _selectedDate = null;
        patientDataError = null;
      });
    }
  }

  // ฟังก์ชันตรวจสอบว่าวันนั้นสามารถเลือกได้หรือไม่
  // ฟังก์ชันตรวจสอบว่าวันนั้นสามารถเลือกได้หรือไม่
  bool isDateSelectable(DateTime date) {
    // หากไม่มีช่วงวันที่ที่แนะนำ ให้ถือว่าเลือกได้ทุกวัน
    if (minAllowedDate == null || maxAllowedDate == null) {
      return true;
    }
    // ตรวจสอบว่าวันนั้นอยู่ในช่วงที่กำหนด
    return date.isAfter(minAllowedDate!.subtract(Duration(days: 1))) &&
        date.isBefore(maxAllowedDate!.add(Duration(days: 1)));
  }

  void sendNotification() async {
    if (selectedUser == null ||
        _titleController.text.isEmpty ||
        _messageController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please complete all fields")));
      return;
    }

    final notificationData = {
      'username': selectedUser!.username,
      'title': _titleController.text,
      'body': _messageController.text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/send_notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(notificationData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Notification sent successfully!")),
        );
        // Clear form
        setState(() {
          selectedUser = null;
          _titleController.clear();
          _messageController.clear();
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to send notification")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error sending notification")));
      return;
    }
  }

  Future<void> saveAppointment() async {
    if (selectedUserForAppointment == null ||
        selectedStep == null ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาเลือกผู้ป่วย, การแจ้งเตือน และวันนัด')),
      );
      return;
    }

    // ตรวจสอบว่ามีข้อมูล LMP หรือไม่
    if (patientData == null || patientData!['LMP'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่พบข้อมูล LMP ของผู้ป่วย ไม่สามารถตรวจสอบช่วงวันที่ได้',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      // ตรวจสอบช่วงวันที่เฉพาะเมื่อมี LMP
      if (calculatedAppointmentDate != null &&
          !isDateSelectable(_selectedDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'วันที่เลือกไม่อยู่ในช่วงที่แนะนำ (±3 วันจากวันที่คำนวณได้)',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    final appointmentData = {
      "username": selectedUserForAppointment!.username,
      "step": selectedStep!.stepNumber,
      "stepTitle": selectedStep!.title,
      "stepDescription": selectedStep!.description,
      "nextAppointment": _selectedDate!.toIso8601String(),
      "note": _noteController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/save_appointment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(appointmentData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('บันทึกวันนัดสำเร็จ')));
        // Clear form
        setState(() {
          selectedUserForAppointment = null;
          selectedStep = null;
          _selectedDate = null;
          _noteController.clear();
          patientData = null;
          calculatedAppointmentDate = null;
          minAllowedDate = null;
          maxAllowedDate = null;
          patientDataError = null;
        });
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'บันทึกวันนัดไม่สำเร็จ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดขณะบันทึกวันนัด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ส่งแจ้งเตือนและนัดหมาย")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Notification Section
            Card(
              margin: EdgeInsets.all(5.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "ส่งการแจ้งเตือน",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownSearch<User>(
                      items: (String filter, _) async {
                        final users = await fetchUsers();
                        if (filter.isEmpty) return users;
                        return users
                            .where(
                              (u) => u.displayname.toLowerCase().contains(
                                filter.toLowerCase(),
                              ),
                            )
                            .toList();
                      },
                      selectedItem: selectedUser,
                      itemAsString: (User u) => u.displayname,
                      onChanged: (User? user) {
                        setState(() => selectedUser = user);
                      },
                      compareFn: (User a, User b) => a.username == b.username,
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "เลือกผู้ป่วย",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: "ค้นหาผู้ป่วย...",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: "หัวข้อการแจ้งเตือน",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: "ข้อความแจ้งเตือน",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: sendNotification,
                        child: Text(
                          'ส่งการแจ้งเตือน',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Appointment Section
            Card(
              margin: EdgeInsets.all(5.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "บันทึกวันนัดหน้าตรวจ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Patient Selection
                    DropdownSearch<User>(
                      selectedItem: selectedUserForAppointment,
                      items: (String filter, dynamic _) async {
                        final users = await fetchUsers();
                        if (filter.isEmpty) return users;
                        return users
                            .where(
                              (u) => u.displayname.toLowerCase().contains(
                                filter.toLowerCase(),
                              ),
                            )
                            .toList();
                      },
                      itemAsString: (User u) => u.displayname,
                      onChanged: (User? user) async {
                        setState(() {
                          selectedUserForAppointment = user;
                          // รีเซ็ตค่าอื่นๆ เมื่อเปลี่ยนผู้ป่วย
                          selectedStep = null;
                          _selectedDate = null;
                          patientData = null;
                          calculatedAppointmentDate = null;
                          minAllowedDate = null;
                          maxAllowedDate = null;
                          patientDataError = null;
                        });

                        if (user != null) {
                          await fetchPatientData(user.username);
                        }
                      },
                      compareFn: (User a, User b) => a.username == b.username,
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "เลือกผู้ป่วย (วันนัด)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: "ค้นหาผู้ป่วย...",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // แสดงสถานะการโหลดข้อมูลผู้ป่วย
                    if (isLoadingPatientData)
                      Container(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('กำลังดึงข้อมูลผู้ป่วย...'),
                          ],
                        ),
                      ),

                    // แสดง error ถ้ามี
                    if (patientDataError != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ข้อผิดพลาด:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[800],
                              ),
                            ),
                            Text(patientDataError!),
                            SizedBox(height: 4),
                            Text(
                              'สามารถสร้างวันนัดได้ แต่ไม่สามารถตรวจสอบช่วงวันที่ที่แนะนำได้',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (patientDataError != null) SizedBox(height: 16),

                    // Step Selection
                    DropdownButtonFormField<AppointmentStep>(
                      decoration: InputDecoration(
                        labelText: "เลือกการแจ้งเตือน",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.list_alt),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 12,
                        ),
                      ),
                      value: selectedStep,
                      items:
                          availableSteps.map((step) {
                            return DropdownMenuItem<AppointmentStep>(
                              value: step,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    step.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    step.description,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged:
                          selectedUserForAppointment != null &&
                                  !isLoadingPatientData
                              ? (AppointmentStep? step) {
                                setState(() {
                                  selectedStep = step;
                                  _selectedDate = null; // รีเซ็ตวันที่เลือก
                                });
                                updateAllowedDateRange();
                              }
                              : null, // <--- แก้ไขตรงนี้
                    ),
                    SizedBox(height: 16),

                    // Date Selection with Restrictions
                    InkWell(
                      onTap: () async {
                        if (selectedUserForAppointment == null ||
                            selectedStep == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'กรุณาเลือกผู้ป่วยและการแจ้งเตือนก่อน',
                              ),
                            ),
                          );
                          return;
                        }

                        DateTime initialDate = DateTime.now().add(
                          Duration(days: 1),
                        );
                        DateTime firstDate = DateTime.now();
                        DateTime lastDate = DateTime.now().add(
                          Duration(days: 365),
                        );

                        // ถ้ามีการคำนวณจาก LMP ให้ใช้ค่าที่คำนวณได้
                        if (calculatedAppointmentDate != null) {
                          initialDate = calculatedAppointmentDate!;
                        }

                        if (minAllowedDate != null && maxAllowedDate != null) {
                          firstDate = minAllowedDate!;
                          lastDate = maxAllowedDate!;
                        }

                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          selectableDayPredicate: (DateTime date) {
                            if (calculatedAppointmentDate == null) return true;
                            return isDateSelectable(date);
                          },
                          helpText: 'เลือกวันนัด',
                          cancelText: 'ยกเลิก',
                          confirmText: 'ตกลง',
                        );

                        if (picked != null) {
                          // ถ้าไม่มีข้อมูล LMP หรือวันที่ที่เลือกอยู่ในช่วงที่อนุญาต
                          if (calculatedAppointmentDate == null ||
                              isDateSelectable(picked)) {
                            setState(() => _selectedDate = picked);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'วันที่เลือกไม่อยู่ในช่วงที่แนะนำ',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            setState(() => _selectedDate = picked);
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey[600]),
                            SizedBox(width: 12),
                            Text(
                              _selectedDate == null
                                  ? 'เลือกวันนัดหน้าตรวจ'
                                  : 'วันนัด: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    _selectedDate == null
                                        ? Colors.grey[600]
                                        : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'หมายเหตุ/กิจกรรม',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 2,
                    ),

                    SizedBox(height: 16),

                    // Selected Step Preview
                    if (selectedStep != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          border: Border.all(color: Colors.blue[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'การแจ้งเตือนที่เลือก:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              selectedStep!.title,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              selectedStep!.description,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              'เป้าหมาย: ${selectedStep!.targetWeeks} สัปดาห์',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 16),

                    // Patient Data Status
                    if (selectedUserForAppointment != null &&
                        !isLoadingPatientData)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              patientData != null
                                  ? Colors.green[50]
                                  : Colors.grey[50],
                          border: Border.all(
                            color:
                                patientData != null
                                    ? Colors.green[200]!
                                    : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ข้อมูลผู้ป่วย:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    patientData != null
                                        ? Colors.green[800]
                                        : Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 4),
                            if (patientData != null) ...[
                              Text(
                                'ชื่อ: ${patientData!['display_name'] ?? 'ไม่ระบุ'}',
                              ),
                              Text('LMP: ${patientData!['LMP'] ?? 'ไม่ระบุ'}'),
                              Text(
                                'GA: ${patientData!['GA'] ?? 'ไม่ระบุ'} วัน',
                              ),
                              Text('EDC: ${patientData!['EDC'] ?? 'ไม่ระบุ'}'),
                            ] else ...[
                              Text('ไม่สามารถดึงข้อมูลได้'),
                            ],
                          ],
                        ),
                      ),

                    SizedBox(height: 16),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.green,
                        ),
                        onPressed:
                            isLoadingPatientData ? null : saveAppointment,
                        child: Text(
                          isLoadingPatientData
                              ? 'กำลังโหลด...'
                              : 'บันทึกวันนัด',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
