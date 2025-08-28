import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: Countchild()));
}

class Countchild extends StatefulWidget {
  final String? username; // เพิ่ม parameter สำหรับ username
  
  const Countchild({super.key, this.username});

  @override
  State<Countchild> createState() => _Countchild();
}

class _Countchild extends State<Countchild> with SingleTickerProviderStateMixin {
  int number = 0;
  bool isLoading = false;
  List<Map<String, dynamic>> weeklyData = [];
  TabController? _tabController;
  String currentUsername = "default_user"; // ค่าเริ่มต้น - ควรได้มาจากระบบ login

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // ใช้ username ที่ส่งเข้ามา หรือใช้ค่าเริ่มต้น
    if (widget.username != null) {
      currentUsername = widget.username!;
    }
    
    _loadTodayData();
    _loadWeeklyData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // Load today's kick count from API
  Future<void> _loadTodayData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kicks/today?username=$currentUsername')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          number = data['count'];
        });
      }
    } catch (e) {
      print('Error loading today data: $e');
      // Fallback to local storage if API fails
    }
  }

  // Load weekly data for chart
  Future<void> _loadWeeklyData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kicks/weekly?username=$currentUsername')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          weeklyData = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      print('Error loading weekly data: $e');
    }
  }

  // Increment kick count via API
  Future<void> increment() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/kicks/increment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': currentUsername}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          number = data['count'];
        });
        _loadWeeklyData(); // Refresh chart data
      }
    } catch (e) {
      print('Error incrementing: $e');
      // Fallback to local increment
      setState(() {
        number++;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Decrement kick count via API
  Future<void> decrement() async {
    if (number <= 0) return;
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/kicks/decrement'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': currentUsername}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          number = data['count'];
        });
        _loadWeeklyData(); // Refresh chart data
      }
    } catch (e) {
      print('Error decrementing: $e');
      // Fallback to local decrement
      setState(() {
        if (number > 0) number--;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Save current kick count manually
  Future<void> saveCurrentCount() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/kicks/save'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': currentUsername,
          'count': number,
        }),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกข้อมูลเรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _loadWeeklyData(); // Refresh chart data
      }
    } catch (e) {
      print('Error saving: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildCounterTab() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  height: screenHeight * 0.25,
                  width: screenWidth * 0.9,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color.fromARGB(255, 255, 255, 255),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "จำนวนครั้งที่ลูกดิ้น",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: const Color.fromARGB(255, 132, 132, 132),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "วันนี้ ${_getCurrentDateThai()}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: const Color.fromARGB(255, 160, 160, 160),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "$number",
                        style: TextStyle(
                          fontSize: 70,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "ครั้ง",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: const Color.fromARGB(255, 132, 132, 132),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: isLoading ? null : increment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "เพิ่ม",
                              style: TextStyle(fontSize: 20, color: Colors.white),
                            ),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: (isLoading || number <= 0) ? null : decrement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "ลด",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // เพิ่มปุ่มบันทึกข้อมูล
                ElevatedButton.icon(
                  onPressed: isLoading ? null : saveCurrentCount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(Icons.save, color: Colors.white),
                  label: Text(
                    "บันทึกข้อมูล",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),
                _buildTodaySummary(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 25),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.green.withOpacity(0.1),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                "สรุปวันนี้",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            _getKickAdvice(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            "กราฟการดิ้น 7 วันที่ผ่านมา",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: weeklyData.isEmpty
                ? Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                : Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: BarChart(
                      BarChartData(
                        maxY: _getMaxKickCount().toDouble() + 5,
                        barGroups: _createBarGroups(),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < weeklyData.length) {
                                  return Text(
                                    weeklyData[value.toInt()]['dayName'],
                                    style: TextStyle(fontSize: 12),
                                  );
                                }
                                return Text('');
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipPadding: EdgeInsets.all(8),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toInt()} ครั้ง\n${weeklyData[group.x]['date']}',
                                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          SizedBox(height: 20),
          _buildWeeklySummary(),
        ],
      ),
    );
  }

  Widget _buildWeeklySummary() {
    if (weeklyData.isEmpty) return SizedBox.shrink();
    
    int totalKicks = weeklyData.fold(0, (sum, day) => sum + (day['count'] as int));
    double averageKicks = totalKicks / 7;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.blue.withOpacity(0.1),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                "$totalKicks",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              Text(
                "รวม 7 วัน",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                "${averageKicks.toStringAsFixed(1)}",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              Text(
                "เฉลี่ย/วัน",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups() {
    return weeklyData.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> data = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data['count'].toDouble(),
            color: index == 6 ? Colors.green : Colors.green.withOpacity(0.7), // Highlight today
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  int _getMaxKickCount() {
    if (weeklyData.isEmpty) return 10;
    return weeklyData.map((day) => day['count'] as int).reduce((a, b) => a > b ? a : b);
  }

  String _getCurrentDateThai() {
    final now = DateTime.now();
    final months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year + 543}';
  }

  String _getKickAdvice() {
    if (number < 6) {
      return "ปกติทารกจะดิ้นอย่างน้อย 6-10 ครั้งใน 2 ชั่วโมง หากน้อยกว่านี้ ควรสังเกตเพิ่มเติม";
    } else if (number <= 10) {
      return "ดีมาก! การดิ้นอยู่ในเกณฑ์ปกติ แสดงว่าลูกมีสุขภาพดี";
    } else {
      return "ลูกดิ้นค่อนข้างมาก อาจเป็นเพราะลูกกำลังเคลื่อนไหวมากหรือคุณแม่กำลังทำกิจกรรม";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "การนับลูกดิ้นของคุณแม่",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.touch_app), text: "นับลูกดิ้น"),
            Tab(icon: Icon(Icons.bar_chart), text: "กราฟ"),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCounterTab(),
          _buildChartTab(),
        ],
      ),
    );
  }
}