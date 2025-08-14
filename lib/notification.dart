import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; 

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
      id:
          json['_id'] ??
          json['username'], // fallback to username if _id not available
      username: json['username'],
      displayname: json['display_name'],
    );
  }
}

// --------- Enhanced Step Model ----------
class AppointmentStep {
  final int stepNumber;
  final String title;
  final String description;
  final int weekGA;

  AppointmentStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.weekGA,
  });

  static List<AppointmentStep> getSteps() {
    return [
      AppointmentStep(
        stepNumber: 0,
        title: "การแจ้งเตือนที่ 1",
        description: "อายุครรภ์น้อยกว่า 12 สัปดาห์",
        weekGA: 12,
      ),
      AppointmentStep(
        stepNumber: 1,
        title: "การแจ้งเตือนที่ 2",
        description: "อายุครรภ์ 20 สัปดาห์",
        weekGA: 20,
      ),
      AppointmentStep(
        stepNumber: 2,
        title: "การแจ้งเตือนที่ 3",
        description: "อายุครรภ์ 26 สัปดาห์",
        weekGA: 26,
      ),
      AppointmentStep(
        stepNumber: 3,
        title: "การแจ้งเตือนที่ 4",
        description: "อายุครรภ์ 32 สัปดาห์",
        weekGA: 32,
      ),
      AppointmentStep(
        stepNumber: 4,
        title: "การแจ้งเตือนที่ 5",
        description: "อายุครrrรภ์ 34 สัปดาห์",
        weekGA: 34,
      ),
      AppointmentStep(
        stepNumber: 5,
        title: "การแจ้งเตือนที่ 6",
        description: "อายุครรภ์ 36 สัปดาห์",
        weekGA: 36,
      ),
      AppointmentStep(
        stepNumber: 6,
        title: "การแจ้งเตือนที่ 7",
        description: "อายุครรภ์ 38 สัปดาห์",
        weekGA: 38,
      ),
      AppointmentStep(
        stepNumber: 7,
        title: "การแจ้งเตือนที่ 8",
        description: "อายุครรภ์ 40 สัปดาห์",
        weekGA: 40,
      ),
    ];
  }
}

// --------- Fetch Users ----------
Future<List<User>> fetchUsers() async {
  try {
    print('Attempting to fetch users from: $baseUrl/api/users'); // Debug
    final response = await http.get(Uri.parse('$baseUrl/api/users'));

    print('Response status: ${response.statusCode}'); // Debug
    print('Response body: ${response.body}'); // Debug

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('Users data: $data'); // Debug
      return data.map((userJson) => User.fromJson(userJson)).toList();
    } else {
      print('Failed to load users: ${response.statusCode}'); // Debug
      throw Exception('Failed to load users');
    }
  } catch (e) {
    print('Error in fetchUsers: $e'); // Debug
    rethrow;
  }
}

class SendNotificationAndAppointment extends StatefulWidget {
  const SendNotificationAndAppointment({super.key});

  @override
  State<SendNotificationAndAppointment> createState() =>
      _SendNotificationAndAppointmentState();
}

class _SendNotificationAndAppointmentState
    extends State<SendNotificationAndAppointment>
    with SingleTickerProviderStateMixin {
  // Notification form controllers
  User? selectedUser;
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  // Smart appointment form controllers
  User? selectedUserForAppointment;
  AppointmentStep? selectedStep;
  DateTime? _selectedDate;
  DateTime? _lmpDate;
  int? currentGA;
  DateTime? _suggestedDate;
  DateTime? _minSelectableDate;
  DateTime? _maxSelectableDate;
  final TextEditingController _noteController = TextEditingController();

  // List of available steps
  final List<AppointmentStep> availableSteps = AppointmentStep.getSteps();

  // Loading states
  bool isLoadingNotification = false;
  bool isLoadingAppointment = false;
  bool isLoadingPatientData = false;

  // Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // คำนวณอายุครรภ์จาก LMP
  int calculateGA(DateTime lmp) {
    final now = DateTime.now();
    final difference = now.difference(lmp).inDays;
    return (difference / 7).floor();
  }

  // คำนวณวันนัดที่แนะนำตาม GA
  DateTime calculateAppointmentDate(DateTime lmp, int targetWeekGA) {
    return lmp.add(Duration(days: targetWeekGA * 7));
  }

  // ตรวจสอบว่าวันที่เลือกอยู่ในช่วงที่อนุญาต (±3 วัน)
  bool isDateInAllowedRange(DateTime selectedDate, DateTime suggestedDate) {
    final minDate = suggestedDate.subtract(const Duration(days: 3));
    final maxDate = suggestedDate.add(const Duration(days: 3));
    return selectedDate.isAfter(minDate.subtract(const Duration(days: 1))) &&
        selectedDate.isBefore(maxDate.add(const Duration(days: 1)));
  }

  // ดึงข้อมูล LMP ของผู้ป่วย
   Future<void> fetchPatientLMP() async {
    if (selectedUserForAppointment == null) return;

    setState(() => isLoadingPatientData = true);

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/patients_data/${selectedUserForAppointment!.username}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['LMP'] != null) {
          setState(() {
            // แก้ไข: ใช้ DateFormat เพื่อแปลงวันที่ให้ถูกต้อง
            // D/M/Y -> วัน/เดือน/ปี
            _lmpDate = DateFormat('d/M/yyyy').parse(data['LMP']);
            currentGA = calculateGA(_lmpDate!);
          });

          if (selectedStep != null) {
            updateSuggestedDate();
          }
        } else {
          _showSnackBar('ไม่พบข้อมูล LMP ของผู้ป่วย', Colors.orange);
        }
      } else {
        _showSnackBar('ไม่สามารถดึงข้อมูลผู้ป่วยได้', Colors.red);
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการดึงข้อมูล: $e', Colors.red);
    } finally {
      setState(() => isLoadingPatientData = false);
    }
  }

  // อัพเดทวันนัดที่แนะนำ
  void updateSuggestedDate() {
    if (_lmpDate != null && selectedStep != null) {
      setState(() {
        _suggestedDate = calculateAppointmentDate(
          _lmpDate!,
          selectedStep!.weekGA,
        );
        _minSelectableDate = _suggestedDate!.subtract(const Duration(days: 3));
        _maxSelectableDate = _suggestedDate!.add(const Duration(days: 3));

        // ถ้ายังไม่เลือกวันนัด ให้เลือกวันที่แนะนำเป็นค่าเริ่มต้น
        if (_selectedDate == null) {
          _selectedDate = _suggestedDate;
        }
      });
    }
  }

  // เลือกวันที่จากปฏิทิน
  Future<void> _pickDate(BuildContext context) async {
    if (_suggestedDate == null) {
      _showSnackBar('กรุณาเลือกผู้ป่วยและการแจ้งเตือนก่อน', Colors.orange);
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? _suggestedDate!,
      firstDate: _minSelectableDate!,
      lastDate: _maxSelectableDate!,
      selectableDayPredicate: (DateTime date) {
        // ไม่อนุญาตให้เลือกวันเสาร์และอาทิตย์
        return date.weekday != DateTime.saturday &&
            date.weekday != DateTime.sunday;
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isDateInAllowedRange(picked, _suggestedDate!)) {
        setState(() {
          _selectedDate = picked;
        });
      } else {
        _showSnackBar(
          'วันที่เลือกควรอยู่ในช่วง ±3 วันจากวันที่แนะนำ',
          Colors.orange,
        );
      }
    }
  }

  // ส่งการแจ้งเตือน
  void sendNotification() async {
    if (selectedUser == null ||
        _titleController.text.isEmpty ||
        _messageController.text.isEmpty) {
      _showSnackBar("กรุณากรอกข้อมูลให้ครบถ้วน", Colors.orange);
      return;
    }

    setState(() => isLoadingNotification = true);

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
        _showSnackBar("ส่งการแจ้งเตือนสำเร็จ!", Colors.green);
        // Clear notification form
        setState(() {
          selectedUser = null;
          _titleController.clear();
          _messageController.clear();
        });
      } else {
        _showSnackBar("ส่งการแจ้งเตือนไม่สำเร็จ", Colors.red);
      }
    } catch (e) {
      _showSnackBar("เกิดข้อผิดพลาดในการส่งการแจ้งเตือน", Colors.red);
    } finally {
      setState(() => isLoadingNotification = false);
    }
  }

  // บันทึกการนัดหมาย
  Future<void> saveAppointment() async {
    if (selectedUserForAppointment == null ||
        selectedStep == null ||
        _selectedDate == null) {
      _showSnackBar('กรุณากรอกข้อมูลให้ครบถ้วน', Colors.orange);
      return;
    }

    setState(() => isLoadingAppointment = true);

    try {
      final appointmentData = {
        "username": selectedUserForAppointment!.username,
        "step": selectedStep!.stepNumber,
        "stepTitle": selectedStep!.title,
        "stepDescription": selectedStep!.description,
        "nextAppointment": _selectedDate!.toIso8601String(),
        "note": _noteController.text.trim(),
        "suggestedDate": _suggestedDate!.toIso8601String(),
        "currentGA": currentGA,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/save_appointment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(appointmentData),
      );

      if (response.statusCode == 200) {
        _showSnackBar('บันทึกวันนัดสำเร็จ!', Colors.green);
        _clearAppointmentForm();
      } else {
        final errorData = json.decode(response.body);
        _showSnackBar(
          errorData['message'] ?? 'บันทึกวันนัดไม่สำเร็จ',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e', Colors.red);
    } finally {
      setState(() => isLoadingAppointment = false);
    }
  }

  // ล้างฟอร์มการนัดหมาย
  void _clearAppointmentForm() {
    setState(() {
      selectedUserForAppointment = null;
      selectedStep = null;
      _selectedDate = null;
      _lmpDate = null;
      _suggestedDate = null;
      _minSelectableDate = null;
      _maxSelectableDate = null;
      currentGA = null;
      _noteController.clear();
    });
  }

  // แสดง SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ระบบแจ้งเตือนและการนัดหมาย"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: Icon(Icons.notifications), text: "ส่งการแจ้งเตือน"),
            Tab(icon: Icon(Icons.calendar_month), text: "จองการนัดหมาย"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Notification
          _buildNotificationTab(),

          // Tab 2: Smart Appointment Booking
          _buildSmartAppointmentTab(),
        ],
      ),
    );
  }

  Widget _buildNotificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // หัวข้อ
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      size: 48,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "ส่งการแจ้งเตือน",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // เลือกผู้ป่วย
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
                    prefixIcon: Icon(Icons.person, color: Colors.blue),
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
                  prefixIcon: Icon(Icons.title, color: Colors.blue),
                ),
              ),

              SizedBox(height: 16),

              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: "ข้อความแจ้งเตือน",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message, color: Colors.blue),
                ),
                maxLines: 3,
              ),

              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: isLoadingNotification ? null : sendNotification,
                  icon:
                      isLoadingNotification
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Icon(Icons.send, color: Colors.white),
                  label: Text(
                    isLoadingNotification ? 'กำลังส่ง...' : 'ส่งการแจ้งเตือน',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartAppointmentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวข้อ
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 48,
                      color: Colors.green[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ระบบจองการนัดหมายอัจฉริยะ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'คำนวณตามอายุครรภ์จาก LMP',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // เลือกผู้ป่วย
              Text(
                'เลือกผู้ป่วย',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
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
                selectedItem: selectedUserForAppointment,
                itemAsString: (User u) => u.displayname,
                onChanged: (User? user) {
                  setState(() {
                    selectedUserForAppointment = user;
                    // ล้างข้อมูลเดิมเมื่อเปลี่ยนผู้ป่วย
                    selectedStep = null;
                    _selectedDate = null;
                    _lmpDate = null;
                    _suggestedDate = null;
                    currentGA = null;
                  });

                  if (user != null) {
                    fetchPatientLMP();
                  }
                },
                compareFn: (User a, User b) => a.username == b.username,
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                    hintText: 'ค้นหาและเลือกผู้ป่วย...',
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: "ค้นหาผู้ป่วย...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // แสดงข้อมูล LMP และ GA ถ้ามี
              if (isLoadingPatientData)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('กำลังโหลดข้อมูลผู้ป่วย...'),
                    ],
                  ),
                )
              else if (_lmpDate != null && currentGA != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ข้อมูลผู้ป่วย',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LMP: ${_lmpDate!.day}/${_lmpDate!.month}/${_lmpDate!.year}',
                      ),
                      Text('อายุครรภ์ปัจจุบัน: $currentGA สัปดาห์'),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // เลือกการแจ้งเตือน
              Text(
                'เลือกการแจ้งเตือน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<AppointmentStep>(
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.notifications,
                    color: Colors.green,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  hintText: 'เลือกการแจ้งเตือน...',
                ),
                value: selectedStep,
                items:
                    availableSteps.map((step) {
                      bool isRecommended =
                          currentGA != null &&
                          currentGA! >= step.weekGA - 2 &&
                          currentGA! <= step.weekGA + 2;

                      return DropdownMenuItem<AppointmentStep>(
                        value: step,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 280),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      step.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isRecommended
                                                ? Colors.green[700]
                                                : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isRecommended) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green[300]!,
                                        ),
                                      ),
                                      child: Text(
                                        'แนะนำ',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                step.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (AppointmentStep? step) async {
                  if (_lmpDate == null) {
                    await fetchPatientLMP();
                  }
                  setState(() {
                    selectedStep = step;
                    _selectedDate = null;
                  });
                  updateSuggestedDate();
                },
              ),

              const SizedBox(height: 16),

              // แสดงวันที่แนะนำ
              if (_suggestedDate != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'วันนัดที่แนะนำ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      Text(
                        '${_suggestedDate!.day}/${_suggestedDate!.month}/${_suggestedDate!.year}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'สามารถเลือกได้ในช่วง ±3 วัน (ยกเว้นเสาร์-อาทิตย์)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ปุ่มเลือกวันที่
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed:
                      _suggestedDate != null ? () => _pickDate(context) : null,
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  label: Text(
                    _selectedDate == null
                        ? 'เลือกวันนัด'
                        : 'วันนัด: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // หมายเหตุ
              Text(
                'หมายเหตุ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.note, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  hintText: 'กรอกหมายเหตุเพิ่มเติม...',
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // แสดงข้อมูลการนัดที่เลือก
              if (selectedStep != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
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
                      const SizedBox(height: 4),
                      Text(
                        selectedStep!.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        selectedStep!.description,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (currentGA != null && _selectedDate != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'สรุปการนัดหมาย:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                              Text(
                                'ผู้ป่วย: ${selectedUserForAppointment?.displayname ?? ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'วันนัด: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'อายุครรภ์เมื่อวันนัด: ${selectedStep!.weekGA} สัปดาห์',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ปุ่มบันทึก
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed:
                      (selectedUserForAppointment != null &&
                              selectedStep != null &&
                              _selectedDate != null &&
                              !isLoadingAppointment)
                          ? saveAppointment
                          : null,
                  icon:
                      isLoadingAppointment
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    isLoadingAppointment
                        ? 'กำลังบันทึก...'
                        : 'บันทึกการนัดหมาย',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ปุ่มล้างฟอร์ม
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed:
                      !isLoadingAppointment ? _clearAppointmentForm : null,
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  label: const Text(
                    'ล้างฟอร์ม',
                    style: TextStyle(color: Colors.grey),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
