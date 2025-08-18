import 'package:carebellmom/config.dart';
import 'package:flutter/material.dart';
import 'package:slide_action/slide_action.dart';
import 'package:flutter/cupertino.dart' hide LinearGradient;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:giffy_dialog/giffy_dialog.dart' hide LinearGradient;
import 'preview.dart';
import 'secondDetails.dart';

class ViewDetails extends StatefulWidget {
  final bool isReadOnly;
  const ViewDetails({super.key, this.isReadOnly = false});

  @override
  _ViewDetailsState createState() => _ViewDetailsState();
}

class _ViewDetailsState extends State<ViewDetails> {
  bool _isLoading = true;
  int _currentStep = 0;
  int _selectedStep = 0;
  DateTime? _pregnancyStartDate;
  String? _currentUserRole;

  // เพิ่ม map สำหรับวันนัดแต่ละ step
  Map<int, Map<String, dynamic>> _appointments = {};

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    loadStepFromServer();
    loadAppointments(); // โหลดวันนัดในแต่ละ step
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserRole = prefs.getString('role');
    });
  }

  Future<void> loadStepFromServer() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');

    if (username != null) {
      final step = await fetchAction(username);
      if (step != null) {
        if (step <= 8) {
          setState(() {
            _currentStep = step;
            _selectedStep = step;
            _pregnancyStartDate = DateTime.now().subtract(Duration(days: 280 - (step * 5 * 7)));
            _isLoading = false;
          });
        } else {
          if (mounted) {
            int? validation = await getBaby(username);
            if (validation != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => secondState()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PreviewState()),
              );
            }
          }
        }
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      print('⚠️ Username not found in SharedPreferences');
      setState(() => _isLoading = false);
    }
  }

  // ฟังก์ชันโหลดวันนัดจาก API appointments_data
  Future<void> loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (username == null) return;

    final uri = Uri.parse('$baseUrl/api/get_appointments?username=$username');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _appointments = {
              for (var appt in data['appointments'])
                appt['step']: {
                  'nextAppointment': DateTime.parse(appt['nextAppointment']),
                  'status': appt['status'] ?? 'scheduled',
                  'stepTitle': appt['stepTitle'] ?? 'การแจ้งเตือนที่ ${(appt['step'] ?? 0) + 1}',
                  'note': appt['note'] ?? '',
                  'requestedDate': appt['requestedDate'] != null ? DateTime.parse(appt['requestedDate']) : null,
                  'changeReason': appt['changeReason'] ?? '',
                }
            };
          });
        }
      }
    } catch (e) {
      print('Error loading appointments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "แจ้งเตือนก่อนคลอดบุตร",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Colors.white),
            onPressed: () => _showHistoryDialog(),
            tooltip: 'ดูประวัติการติดตาม',
          ),
          // เพิ่มปุ่มสำหรับพยาบาล
          if (_currentUserRole == 'nurse')
            IconButton(
              icon: Icon(Icons.calendar_today, color: Colors.white),
              onPressed: () => _showAllAppointmentsDialog(),
              tooltip: 'ดูวันนัดทั้งหมด',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Center(child: _buildStepperView()),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.history, color: Colors.green),
              SizedBox(width: 8),
              Text('ประวัติการติดตาม', 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _currentStep + 1,
              itemBuilder: (context, index) {
                final appointmentData = _appointments[index];
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: index < _currentStep 
                          ? Colors.green 
                          : (index == _currentStep ? Colors.orange : Colors.grey),
                      child: Text('${index + 1}', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('การแจ้งเตือนที่ ${index + 1}',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                        if (appointmentData != null)
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(appointmentData['status']),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getStatusBorderColor(appointmentData['status'])),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getStatusIcon(appointmentData['status']), size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'นัดหน้า: ${appointmentData['nextAppointment'].day}/${appointmentData['nextAppointment'].month}/${appointmentData['nextAppointment'].year}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(_getStepDescription(index),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ),
                    trailing: index < _currentStep 
                        ? Icon(Icons.check_circle, color: Colors.green, size: 28)
                        : (index == _currentStep 
                            ? Icon(Icons.play_circle, color: Colors.orange, size: 28)
                            : Icon(Icons.circle_outlined, color: Colors.grey, size: 28)),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _selectedStep = index;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ปิด', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green[600]!;
      case 'requested_change':
        return Colors.orange[600]!;
      case 'scheduled':
      default:
        return Colors.blue[600]!;
    }
  }

  Color _getStatusBorderColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green[200]!;
      case 'requested_change':
        return Colors.orange[200]!;
      case 'scheduled':
      default:
        return Colors.blue[200]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'requested_change':
        return Icons.schedule;
      case 'scheduled':
      default:
        return Icons.calendar_today;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'ยืนยันแล้ว';
      case 'requested_change':
        return 'ขอแก้ไข';
      case 'scheduled':
      default:
        return 'นัดแล้ว';
    }
  }

  // เพิ่มฟังก์ชันสำหรับแสดงวันนัดทั้งหมด (สำหรับพยาบาล)
  void _showAllAppointmentsDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/get_all_appointments'));
      Navigator.of(context).pop(); // ปิด loading

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _showAppointmentsListDialog(data['appointments']);
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // ปิด loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล')),
      );
    }
  }

  void _showAppointmentsListDialog(List appointments) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.blue[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'วันนัดตรวจทั้งหมด',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${appointments.length} รายการ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // List
                Expanded(
                  child: appointments.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'ไม่มีข้อมูลวันนัด',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          final appointment = appointments[index];
                          final appointmentDate = DateTime.parse(appointment['nextAppointment']);
                          final isUpcoming = appointmentDate.isAfter(DateTime.now());
                          final isToday = DateTime.now().difference(appointmentDate).inDays.abs() == 0;
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isToday 
                                      ? Colors.red 
                                      : (isUpcoming ? Colors.green[200]! : Colors.grey[300]!),
                                  width: isToday ? 2 : 1,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: isToday 
                                      ? LinearGradient(
                                          colors: [Colors.red[50]!, Colors.red[100]!],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : (isUpcoming 
                                          ? LinearGradient(
                                              colors: [Colors.green[50]!, Colors.green[100]!],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.all(16),
                                  leading: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: isToday 
                                          ? Colors.red[600]
                                          : (isUpcoming ? Colors.green[600] : Colors.grey[500]),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${appointmentDate.day}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _getMonthShort(appointmentDate.month),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          appointment['patientName'] ?? 'ไม่ทราบชื่อ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isToday ? Colors.red[800] : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isToday)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red[600],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'วันนี้',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.medical_services, 
                                            size: 16, color: Colors.blue[600]),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              appointment['stepTitle'] ?? 'การแจ้งเตือนที่ ${(appointment['step'] ?? 0) + 1}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.blue[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                          SizedBox(width: 6),
                                          Text(
                                            appointment['patientPhone'] ?? 'ไม่มีเบอร์โทร',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (appointment['note'] != null && appointment['note'].isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.note, size: 14, color: Colors.orange[600]),
                                              SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  appointment['note'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.orange[700],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isUpcoming ? Icons.upcoming : Icons.history,
                                        color: isToday 
                                            ? Colors.red[600]
                                            : (isUpcoming ? Colors.green[600] : Colors.grey[500]),
                                        size: 20,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        isToday ? 'วันนี้' : (isUpcoming ? 'กำลังมา' : 'ผ่านแล้ว'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isToday 
                                              ? Colors.red[600]
                                              : (isUpcoming ? Colors.green[600] : Colors.grey[500]),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                ),
                
                // Footer
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      label: Text('ปิด', style: TextStyle(color: Colors.grey[600])),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getMonthShort(int month) {
    const months = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return months[month];
  }

  String _getStepDescription(int step) {
    final descriptions = [
      "อายุครรภ์น้อยกว่า 12 สัปดาห์",
      "อายุครรภ์ 12-20 สัปดาห์",
      "อายุครรภ์ 20-26 สัปดาห์", 
      "อายุครรภ์ 26-32 สัปดาห์",
      "อายุครรภ์ 32-34 สัปดาห์",
      "อายุครรภ์ 34-36 สัปดาห์",
      "อายุครรภ์ 36-38 สัปดาห์",
      "อายุครรภ์ 38-40 สัปดาห์",
    ];
    return step < descriptions.length ? descriptions[step] : "";
  }

  Widget _buildStepperView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Stepper(
                connectorThickness: 3,
                connectorColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (_currentStep > 0 && states.contains(WidgetState.selected)) {
                    return Colors.green;
                  } else if (states.contains(WidgetState.selected)) {
                    return const Color.fromARGB(255, 255, 88, 130);
                  } else {
                    return Colors.grey.shade300;
                  }
                }),
                currentStep: _selectedStep,
                onStepTapped: (int step) {
                  if (step <= _currentStep) {
                    setState(() {
                      _selectedStep = step;
                    });
                  }
                },
                controlsBuilder: (context, details) => const SizedBox.shrink(),
                physics: const BouncingScrollPhysics(),
                elevation: 2,
                type: StepperType.vertical,
                steps: List.generate(8, (index) => _getSteps()[index]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (!widget.isReadOnly) _buildSlideAction(),
        const SizedBox(height: 40),
      ],
    );
  }

  List<Step> _getSteps() {
    return [
      customStep("การแจ้งเตือนที่ 1", """อายุครรภ์น้อยกว่า 12 สัปดาห์
      1. ตรวจ UPT Positive, ส่งตรวจ UA และ Amphetamine ในรายที่มีความเสี่ยง
      2. ฝากครรภ์พร้อมออกสมุดบันทึกมซักประวัติเสี่ยงต่างๆ
      3. ประเมินการให้วัคซีน dT1
      4. ส่งตรวจ U/S ครั้งที่ 1
      5. Lab 1
      6. ตรวจสุขภาพช่องปาก
      7. ประเมินสุขภาพจิต 1
      8. โรงเรียนพ่อแม่ครั้งที่ 1
      9. ให้ยา Triferdine, Calcium ตลอดการตั้งครรภ์
      """, 0),
      customStep(
        "การแจ้งเตือนที่ 2",
        """อายุครรภ์น้อยกว่า 20 สัปดาห์ แต่มากกว่า 12 สัปดาห์
        1. ตรวจ UPT Positive,ส่งตรวจ UA และ Amphetamineในรายที่มีความเสี่ยง
        2. ฝากครรภ์พร้อมออกสมุดบันทึกมซักประวัติเสี่ยงต่างๆ
        3. ประเมินการให้วัคซีน dT1
        4. ส่งตรวจ U/S ครั้งที่ 1 
        5. Lab 1
        6. ตรวจสุขภาพช่องปาก
        7. ประเมินสุขภาพจิต 1
        8. โรงเรียนพ่อแม่ครั้งที่ 1
        9. ให้ยา Triferdine, Calcium ตลอดการตั้งครรภ์
        """,
        1,
      ),
      customStep(
        "การแจ้งเตือนที่ 3",
        """อายุครรภ์เท่ากับ 26 สัปดาห์ แต่มากกว่า 20 สัปดาห์
        1. ตรวจ UA
        2. ประเมินความเสี่ยงการตั้งครรภ์
        3. ส่งตรวจ U/S ครั้งที่ 2
        4. ประเมินสุขภาพจิต ครั้งที่ 2
        5. บันทึกการตรวจครรภ์
        6. ให้สุขศึกษา""",
        2,
      ),
      customStep(
        "การแจ้งเตือนที่ 4",
        """อายุครรภ์เท่ากับ 32 สัปดาห์ แต่มากกว่า 26 สัปดาห์
1. ตรวจ UA
2. ประเมิณความเสี่ยงการตั้งครรภ์
3. ประเมิณสุขภาพจิต ครั้งที่ 4
4.Lab 2 (Anti HIV, VDRI, Hct, Hb)
5. บันทึกการตรวจครรภ์
6. โรงเรียนพ่อแม่ครั้งที่ 2
7. ให้สุขศึกษา เน้น อันตรายคลอดก่อนกำหนดและสัญญาณเตือน""",
        3,
      ),
      customStep(
        "การแจ้งเตือนที่ 5",
        """อายุครรภ์เท่ากับ 34 สัปดาห์ แต่มากกว่า 32 สัปดาห์
1. ตรวจ Multiple urine dipstip
2, ประเมิณความเสี่ยงการตั้งครรภ์
3. ประเมิณสุขภาพจิต ครั้งที่ 5
4. ส่งตรวจ U/S ครั้งที่ 3 ดูการเจริญเติบโต, ส่วนนำ
5. ประเมิณการคลอด
6. ให้สุขศึกษาเน้นอันตรายคลอดก่อนกำหนดและสัญญาณเตือน""",
        4,
      ),
      customStep(
        "การแจ้งเตือนที่ 6",
        """อายุครรภ์เท่ากับ 36 สัปดาห์ แต่มากกว่า 34 สัปดาห์
1. ตรวจ Multiple urine dipstip
2. ประเมิณความเสี่ยงการตั้งครรภ์
3. ประเมิณสุขภาพจิต ครั้งที่ 6
4. บันทึกการตรวจครรภ์
5. ให้สุขศึกษา""",
        5,
      ),
      customStep(
        "การแจ้งเตือนที่ 7",
        """อายุครรภ์เท่ากับ 38 สัปดาห์ แต่มากกว่า 36 สัปดาห์
1. ตรวจ Multiple urine dipstip
2. ประเมิณความเสี่ยงการตั้งครรภ์
3. ประเมิณสุขภาพจิt ครั้งที่ 6
4. บันทึกการตรวจครรภ์
5. ให้สุขศึกษา
6. NST +PV
7. ประเมิณการให้ dT3 ห่างจากเข็ม 2 นาน 6 เดือน""",
        6,
      ),
      customStep(
        "การแจ้งเตือนที่ 8",
        """อายุครรภ์เท่ากับ 40 สัปดาห์ แต่มากกว่า 38 สัปดาห์
1. ตรวจ Multiple urine dipstip
2. ประเมิณความเสี่ยงการตั้งครรภ์
3. ประเมิณสุขภาพจิต ครั้งที่ 6
4. บันทึกการตรวจครรภ์
5. ให้สุขศึกษา
6. ส่ง NST +PV ที่ LR NST non -reactive, PV: not dilation refer รพ.นครพนม
7. U/S ดูน้ำครำ""",
        7,
      ),
    ];
  }

  bool _isEarlyBirth() {
    if (_pregnancyStartDate == null) return false;
    final currentWeeks = DateTime.now().difference(_pregnancyStartDate!).inDays / 7;
    return _currentStep < 6; 
  }

  int _getCurrentWeeks() {
    if (_pregnancyStartDate == null) {
      return 12 + (_currentStep * 4);
    }
    return (DateTime.now().difference(_pregnancyStartDate!).inDays / 7).floor();
  }

  Widget _buildSlideAction() {
    final isEarly = _isEarlyBirth();
    final currentWeeks = _getCurrentWeeks();
    return Column(
      children: [
        if (_pregnancyStartDate != null || _currentStep > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            
          ),
        Container(
          width: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SlideAction(
            stretchThumb: true,
            trackBuilder: (context, state) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: LinearGradient(
                    colors: isEarly 
                        ? [Colors.orange[300]!, Colors.orange[100]!]
                        : [Colors.green[300]!, Colors.green[100]!],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  border: Border.all(
                    color: isEarly ? Colors.orange[200]! : Colors.green[200]!,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    isEarly ? "ยืนยันการคลอดก่อนกำหนด" : "ยืนยันการคลอด",
                    style: TextStyle(
                      fontSize: 18,
                      color: isEarly ? Colors.orange[800] : Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
            thumbBuilder: (context, state) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: state.isPerformingAction 
                      ? LinearGradient(colors: [Colors.grey[400]!, Colors.grey[600]!])
                      : (isEarly 
                          ? LinearGradient(colors: [Colors.orange[600]!, Colors.orange[800]!])
                          : LinearGradient(colors: [Colors.green[600]!, Colors.green[800]!])),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: state.isPerformingAction
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Icon(Icons.send, color: Colors.white, size: 24),
              );
            },
            action: () async {
              if (isEarly) {
                final shouldProceed = await _showEarlyBirthConfirmation();
                if (!shouldProceed) return;
              }
              final prefs = await SharedPreferences.getInstance();
              final username = prefs.getString('username');
              if (username == null) {
                print("⚠️ Username not found");
                return;
              }
              final result = await updateAction(username, 9);
              debugPrint(result.toString());
              if (result != null) {
                showModalBottomSheet(
                  context : context,
                  clipBehavior: Clip.antiAlias,
                  isScrollControlled: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (BuildContext context) {
                    return GiffyBottomSheet.image(
                      Image.asset(
                        "assets/jk/1.gif",
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      title: Text(
                        isEarly ? 'ยืนยันการคลอดก่อนกำหนดเรียบร้อย' : 'ยืนยันเรียบร้อย',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isEarly ? Colors.orange[700] : Colors.green[700],
                        ),
                      ),
                      content: Text(
                        isEarly 
                            ? 'ข้อมูลการคลอดก่อนกำหนดได้รับการบันทึกแล้ว\n(อายุครรภ์ $currentWeeks สัปดาห์)'
                            : 'ข้อมูลได้รับการอัปเดต',
                        textAlign: TextAlign.center,
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PreviewState(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEarly ? Colors.orange[600] : Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                );
              } else {
                showModalBottomSheet(
                  context: context,
                  clipBehavior: Clip.antiAlias,
                  isScrollControlled: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (BuildContext context) {
                    return GiffyBottomSheet.image(
                      Image.asset(
                        "assets/jk/2.gif",
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      title: Text('เกิดข้อผิดพลาด', 
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      content: Text(
                        'อัปเดตข้อมูลไม่สำเร็จ',
                        textAlign: TextAlign.center,
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Future<bool> _showEarlyBirthConfirmation() async {
    final currentWeeks = _getCurrentWeeks();
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[600], size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'การคลอดก่อนกำหนด',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.baby_changing_station, 
                  size: 48, color: Colors.orange[600]),
                SizedBox(height: 12),
                Text(
                  'อายุครรภ์ปัจจุบัน $currentWeeks สัปดาห์\n'
                  'ซึ่งน้อยกว่า 37 สัปดาห์ (คลอดก่อนกำหนด)\n\n'
                  'คุณแน่ใจหรือไม่ที่จะยืนยันการคลอด?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('ยกเลิก', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('ยืนยันการคลอดก่อนกำหนด', 
                style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Step customStep(String title, String content, int stepIndex) {
    final isCompleted = _currentStep > stepIndex;
    final isCurrent = _currentStep == stepIndex;
    final isSelected = _selectedStep == stepIndex;
    final canNavigate = stepIndex <= _currentStep;
    final appointmentData = _appointments[stepIndex];

    return Step(
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: isSelected ? 16.0 : 14.0,
                color: isSelected
                    ? Colors.blue[700]
                    : (isCompleted ? Colors.green[700] : Colors.black87),
              ),
            ),
          ),
          if (appointmentData != null)
            Container(
              margin: const EdgeInsets.only(left: 8.0),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getStatusColor(appointmentData['status']), _getStatusColor(appointmentData['status']).withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor(appointmentData['status']).withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getStatusIcon(appointmentData['status']), size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    '${appointmentData['nextAppointment'].day}/${appointmentData['nextAppointment'].month}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      content: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [Colors.blue[50]!, Colors.blue[100]!.withOpacity(0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(12.0),
          border: isSelected 
              ? Border.all(color: Colors.blue[300]!, width: 2.0) 
              : Border.all(color: Colors.grey[200]!, width: 1.0),
          boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(
                color: isSelected ? Colors.black87 : Colors.black54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            
            // Appointment Information Card
            if (appointmentData != null)
              Container(
                margin: const EdgeInsets.only(top: 16.0),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor(appointmentData['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor(appointmentData['status']).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 20, color: _getStatusColor(appointmentData['status'])),
                        SizedBox(width: 8),
                        Text(
                          'วันนัดหน้าตรวจ: ${appointmentData['nextAppointment'].day}/${appointmentData['nextAppointment'].month}/${appointmentData['nextAppointment'].year}',
                          style: TextStyle(
                            color: _getStatusColor(appointmentData['status']), 
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(appointmentData['status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(appointmentData['status']),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (appointmentData['note'] != null && appointmentData['note'].isNotEmpty)
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: 8),
                              child: Text(
                                'หมายเหตุ: ${appointmentData['note']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Appointment action buttons for patients
                    if (_currentUserRole != 'nurse' && appointmentData['status'] != 'confirmed')
                      Container(
                        margin: EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            if (appointmentData['status'] == 'scheduled')
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _confirmAppointment(stepIndex),
                                  icon: Icon(Icons.check, size: 16),
                                  label: Text('ยืนยัน'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _requestChangeAppointment(stepIndex),
                                icon: Icon(Icons.edit_calendar, size: 16),
                                label: Text('ขอแก้ไข'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[600],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Show change request info
                    if (appointmentData['status'] == 'requested_change')
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ขอเปลี่ยนวันนัดเป็น: ${appointmentData['requestedDate']?.day ?? ''}/${appointmentData['requestedDate']?.month ?? ''}/${appointmentData['requestedDate']?.year ?? ''}',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            if (appointmentData['changeReason'] != null && appointmentData['changeReason'].isNotEmpty)
                              Text(
                                'เหตุผล: ${appointmentData['changeReason']}',
                                style: TextStyle(
                                  color: Colors.orange[600],
                                  fontSize: 11,
                                ),
                              ),
                            SizedBox(height: 4),
                            Text(
                              'รอพยาบาลอนุมัติ...',
                              style: TextStyle(
                                color: Colors.orange[500],
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            
            // Completed step indicator
            if (canNavigate && stepIndex < _currentStep)
              Container(
                margin: const EdgeInsets.only(top: 12.0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[100]!, Colors.green[50]!],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                    SizedBox(width: 6),
                    Text(
                      'เสร็จสิ้นแล้ว',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      isActive: stepIndex <= _currentStep,
      state: isCompleted
          ? StepState.complete
          : (isCurrent ? StepState.editing : StepState.indexed),
    );
  }

  // Patient confirm appointment
  Future<void> _confirmAppointment(int step) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/confirm_appointment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'step': step,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ยืนยันวันนัดเรียบร้อย')),
        );
        loadAppointments(); // Refresh appointments
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการยืนยัน')),
      );
    }
  }

  // Patient request appointment change
  Future<void> _requestChangeAppointment(int step) async {
    DateTime? selectedDate;
    String reason = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.edit_calendar, color: Colors.orange[600]),
                  SizedBox(width: 8),
                  Text('ขอแก้ไขวันนัด'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current appointment info
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[600]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'วันนัดปัจจุบัน: ${_appointments[step]?['nextAppointment']?.day}/${_appointments[step]?['nextAppointment']?.month}/${_appointments[step]?['nextAppointment']?.year}',
                              style: TextStyle(color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Date picker
                    InkWell(
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(DateTime.now().year + 1),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey[600]),
                            SizedBox(width: 12),
                            Text(
                              selectedDate == null
                                  ? 'เลือกวันนัดใหม่'
                                  : 'วันที่: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                              style: TextStyle(
                                color: selectedDate == null ? Colors.grey[600] : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Reason input
                    TextField(
                      onChanged: (value) => reason = value,
                      decoration: InputDecoration(
                        labelText: 'เหตุผลในการขอแก้ไข',
                        border: OutlineInputBorder(),
                        hintText: 'ระบุเหตุผล...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: selectedDate != null
                      ? () async {
                          Navigator.of(context).pop();
                          await _submitChangeRequest(step, selectedDate!, reason);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                  child: Text('ส่งคำขอ'),
                ),
              ],
            );

          },
        );
      },
    );
  }

Future<void> _submitChangeRequest(int step, DateTime requestedDate, String reason) async {
  final prefs = await SharedPreferences.getInstance();
  final username = prefs.getString('username');

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/request_appointment_change'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'step': step,
        'requestedDate': requestedDate.toIso8601String(),
        'reason': reason,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งคำขอแก้ไขเรียบร้อย รอพยาบาลอนุมัติ')),
      );
      loadAppointments();
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งคำขอ')),
    );
  }
}




}

// เดิม
Future<int?> fetchAction(String username) async {
  final uri = Uri.parse('$baseUrl/api/getAction?username=$username');
  try {
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data['action'];
      } else {
        print("⚠️ Server responded with an error: ${data['message']}");
      }
    } else {
      print("❌ Failed to fetch action. Status code: ${response.statusCode}");
    }
  } catch (e) {
    print("🚨 Error while fetching action: $e");
  }
  return null;
}

Future<int?> updateAction(String username, int action) async {
  final uri = Uri.parse('$baseUrl/api/updateAction');
  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'action': action}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data['action'];
      } else {
        debugPrint("⚠️ Server responded with an error: ${data['message']}");
      }
    } else {
      debugPrint(
        "❌ Failed to fetch action. Status code: ${response.statusCode}",
      );
    }
  } catch (e) {
    debugPrint("🚨 Error while fetching action: $e");
  }
  return null;
}

Future<int?> getBaby(String username) async {
  final uri = Uri.parse('$baseUrl/api/get_baby_data');
  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mother': username,
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data['data']['action'];
      } else {
        debugPrint("⚠️ Server responded with an error: ${data['message']}");
      }
    } else if (response.statusCode == 404) {
      debugPrint("No data found for mother $username");
    } else {
      debugPrint(
        "❌ Failed to fetch action. Status code: ${response.statusCode}",
      );
    }
  } catch (e) {
    debugPrint("🚨 Error while fetching action: $e");
  }
  return null;
}