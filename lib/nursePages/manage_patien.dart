import 'dart:async';
import 'dart:convert';
import 'package:carebellmom/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// =======================
/// หน้า Detailed Checklist
/// =======================
class DetailedPatientChecklistPage extends StatefulWidget {
  final String username;
  final String displayName;

  const DetailedPatientChecklistPage({
    Key? key,
    required this.username,
    required this.displayName,
  }) : super(key: key);

  @override
  State<DetailedPatientChecklistPage> createState() =>
      _DetailedPatientChecklistPageState();
}

class _DetailedPatientChecklistPageState
    extends State<DetailedPatientChecklistPage> {
  Map<String, dynamic>? checklistData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    loadChecklist();
  }

  Future<void> loadChecklist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Loading checklist for username: ${widget.username}'); // Debug log
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/get_patient_checklist'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': widget.username}),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['checklist'] != null) {
          setState(() {
            checklistData = data['checklist'];
            _isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'ไม่พบข้อมูล checklist');
        }
      } else if (response.statusCode == 404) {
        // ถ้าไม่พบคนไข้ ให้แสดงข้อความที่เหมาะสม
        setState(() {
          _errorMessage = 'ไม่พบข้อมูลคนไข้ในระบบ';
          _isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'เกิดข้อผิดพลาดในการโหลดข้อมูล');
      }
    } catch (e) {
      print('Error loading checklist: $e'); // Debug log
      setState(() {
        _isLoading = false;
        _errorMessage = 'ไม่สามารถโหลดข้อมูลได้: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> updateTask(int visitNumber, int taskId, bool completed) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/update_task_item'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': widget.username,
          'visitNumber': visitNumber,
          'taskId': taskId,
          'completed': completed,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await loadChecklist(); // รีโหลดข้อมูล
        } else {
          throw Exception(data['message'] ?? 'ไม่สามารถอัพเดทได้');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'เกิดข้อผิดพลาดในการอัพเดท');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถอัพเดทได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // เพิ่มฟังก์ชันสำหรับมาร์กว่ามาตรวจครรภ์แล้ว
  Future<void> markVisitCheckIn(int visitNumber, bool checkIn) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/mark_visit_checkin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': widget.username,
          'visitNumber': visitNumber,
          'checkIn': checkIn,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await loadChecklist(); // รีโหลดข้อมูล
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(checkIn 
                  ? 'บันทึกการมาตรวจครรภ์เรียบร้อยแล้ว' 
                  : 'ยกเลิกการบันทึกการมาตรวจเรียบร้อยแล้ว'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'ไม่สามารถบันทึกได้');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'เกิดข้อผิดพลาดในการบันทึก');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถบันทึกได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เช็คลิสต์ - ${widget.displayName}'),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadChecklist,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('กำลังโหลดข้อมูล...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadChecklist,
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      );
    }

    if (checklistData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text('ไม่มีข้อมูล checklist'),
          ],
        ),
      );
    }

    // ตรวจสอบว่ามีข้อมูล visits หรือไม่
    final visits = checklistData!['visits'] as List?;
    if (visits == null || visits.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text('ไม่มีข้อมูลการเยี่ยม'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header Section
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green, Colors.green.shade400],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.displayName.isNotEmpty 
                          ? widget.displayName[0].toUpperCase()
                          : 'P',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (checklistData!['GA'] != null)
                            Text(
                              'GA: ${checklistData!['GA']} สัปดาห์',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildProgressSummary(),
              ],
            ),
          ),
        ),

        // Visits List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final visit = visits[index];
              return _buildVisitCard(visit);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSummary() {
    final visits = (checklistData?['visits'] as List?) ?? [];

    int _toInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final totalTasks =
        visits.fold<int>(0, (sum, v) => sum + _toInt(v['totalTasks']));
    final completedTasks =
        visits.fold<int>(0, (sum, v) => sum + _toInt(v['completedTasks']));
    final checkedInVisits = 
        visits.fold<int>(0, (sum, v) => sum + (v['checkedIn'] == true ? 1 : 0));

    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('งานทั้งหมด', '$completedTasks/$totalTasks'),
          _buildSummaryItem('ความก้าวหน้า', '${(progress * 100).toInt()}%'),
          _buildSummaryItem('มาตรวจแล้ว', '$checkedInVisits/${visits.length} ครั้ง'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit) {
    final visitNumber = visit['visit'] ?? 0;
    final title = visit['title'] ?? 'การเยี่ยมครั้งที่ $visitNumber';
    final description = visit['description'] ?? '';
    final tasks = (visit['tasks'] as List?) ?? [];
    final completedTasks = visit['completedTasks'] ?? 0;
    final totalTasks = visit['totalTasks'] ?? tasks.length;
    final isCompleted = visit['completed'] ?? false;
    final isCheckedIn = visit['checkedIn'] ?? false; // เพิ่มข้อมูลการ check-in
    final checkInDate = visit['checkInDate']; // เพิ่มข้อมูลวันที่ check-in
    final date = visit['date'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? Colors.green
              : completedTasks > 0
                  ? Colors.orange
                  : Colors.grey[300],
          child: Text(
            '$visitNumber',
            style: TextStyle(
              color: isCompleted || completedTasks > 0
                  ? Colors.white
                  : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: visitNumber == 7 ? Colors.red[700] : null,
                ),
              ),
            ),
            // แสดงไอคอนสถานะการมาตรวจ
            if (isCheckedIn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, 
                         color: Colors.blue[700], 
                         size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'มาตรวจแล้ว',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) ...[
              Text(description, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: totalTasks > 0 ? completedTasks / totalTasks : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$completedTasks/$totalTasks',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (checkInDate != null && checkInDate.toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'มาตรวจเมื่อ: ${_formatDate(checkInDate)}',
                style: TextStyle(fontSize: 11, color: Colors.blue[600]),
              ),
            ],
            if (date != null && date.toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'อัพเดทล่าสุด: ${_formatDate(date)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        children: [
          // เพิ่มปุ่มการมาตรวจครรภ์
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCheckInDialog(visitNumber, isCheckedIn),
                    icon: Icon(isCheckedIn ? Icons.check_circle : Icons.schedule),
                    label: Text(isCheckedIn ? 'มาตรวจแล้ว' : 'มาตรวจครรภ์'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCheckedIn ? Colors.blue : Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (tasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'รายการตรวจ:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ...tasks
                      .map<Widget>((task) => _buildTaskItem(visitNumber, task))
                      .toList(),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'ไม่มีงานในการเยี่ยมนี้',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  // เพิ่มฟังก์ชันแสดงไดอะล็อกยืนยันการมาตรวจ
  void _showCheckInDialog(int visitNumber, bool isCurrentlyCheckedIn) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isCurrentlyCheckedIn 
            ? 'ยกเลิกการบันทึกการมาตรวจ' 
            : 'ยืนยันการมาตรวจครรภ์'),
          content: Text(isCurrentlyCheckedIn 
            ? 'คุณต้องการยกเลิกการบันทึกการมาตรวจครรภ์ครั้งที่ $visitNumber หรือไม่?' 
            : 'คุณต้องการบันทึกว่าคนไข้มาตรวจครรภ์ครั้งที่ $visitNumber หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                markVisitCheckIn(visitNumber, !isCurrentlyCheckedIn);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentlyCheckedIn ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(isCurrentlyCheckedIn ? 'ยกเลิกการบันทึก' : 'ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskItem(int visitNumber, Map<String, dynamic> task) {
    final taskId = task['id'] ?? 0;
    final taskText = task['task'] ?? 'งานไม่ระบุ';
    final isCompleted = task['completed'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? Colors.green[200]! : Colors.grey[200]!,
        ),
      ),
      child: CheckboxListTile(
        value: isCompleted,
        onChanged: (bool? value) {
          if (value != null && taskId > 0) {
            updateTask(visitNumber, taskId, value);
          }
        },
        title: Text(
          taskText,
          style: TextStyle(
            fontSize: 14,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey[600] : null,
          ),
        ),
        activeColor: Colors.green,
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
      ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      DateTime parsedDate;
      if (date is String) {
        parsedDate = DateTime.parse(date);
      } else if (date is DateTime) {
        parsedDate = date;
      } else {
        return 'ไม่ระบุ';
      }
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return 'ไม่ระบุ';
    }
  }
}

/// ===============
/// หน้า SearchPage  
/// ===============
class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  Future<List<Map<String, dynamic>>> fetchPatients() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/users'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => {
                  'username': e['username']?.toString() ?? '',
                  'display_name': e['display_name']?.toString() ?? 'ไม่ระบุชื่อ',
                  'telephone': e['telephone']?.toString() ?? ''
                })
            .where((item) => item['username']!.isNotEmpty) // กรองเฉพาะที่มี username
            .toList();
      } else {
        throw Exception("โหลดข้อมูลไม่สำเร็จ (${response.statusCode})");
      }
    } catch (e) {
      print('Error fetching patients: $e');
      throw Exception("เกิดข้อผิดพลาด: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
    _controller.addListener(_onTextChanged);
  }

  void loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await fetchPatients();
      setState(() {
        _allItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถโหลดข้อมูลได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (text.isEmpty) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      } else {
        _filterLocal(text);
      }
    });
  }

  void _filterLocal(String query) {
    final q = query.toLowerCase();
    final results = _allItems
        .where((item) => 
          item['display_name'].toLowerCase().contains(q) ||
          item['username'].toLowerCase().contains(q))
        .toList();
    setState(() {
      _suggestions = results;
      _showSuggestions = results.isNotEmpty;
    });
  }

  void _onSuggestionTap(Map<String, dynamic> patient) {
    // ตรวจสอบว่ามี username หรือไม่
    if (patient['username'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ข้อมูลคนไข้ไม่สมบูรณ์ ไม่สามารถดำเนินการได้'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _controller.text = patient['display_name'];
    _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: patient['display_name'].length));
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailedPatientChecklistPage(
          username: patient['username'],
          displayName: patient['display_name'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการข้อมูลการเข้ารับ'),
        backgroundColor: Colors.green,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            _showSuggestions = false;
          });
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ชื่อคนไข้เพื่อค้นหา...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: hasText
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {
                                    _suggestions = [];
                                    _showSuggestions = false;
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isLoading ? null : loadData,
                    tooltip: 'รีเฟรชข้อมูล',
                  ),
                ],
              ),
            ),
            if (_isLoading) const LinearProgressIndicator(),
            if (_showSuggestions)
              Expanded(
                child: ListView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, i) {
                    final patient = _suggestions[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          patient['display_name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Username: ${patient['username']}'),
                            if (patient['telephone'].isNotEmpty)
                              Text('เบอร์โทร: ${patient['telephone']}'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _onSuggestionTap(patient),
                      ),
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        hasText
                            ? 'ไม่พบผลการค้นหา'
                            : 'พิมพ์ชื่อคนไข้เพื่อเริ่มค้นหา',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      if (_allItems.isNotEmpty && !hasText) ...[
                        const SizedBox(height: 8),
                        Text(
                          'มีคนไข้ทั้งหมด ${_allItems.length} คน',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ]
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