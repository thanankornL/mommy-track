import 'package:carebellmom/config.dart';
import 'package:flutter/material.dart';
import 'package:slide_action/slide_action.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'preview.dart';
import 'secondDetails.dart';

class ViewDetails extends StatefulWidget {
  const ViewDetails({super.key});

  @override
  _ViewDetailsState createState() => _ViewDetailsState();
}

class _ViewDetailsState extends State<ViewDetails> {
  bool _isLoading = true;

  int _currentStep = 0; // Make it nullable
  Future<void> loadStepFromServer() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');

    if (username != null) {
      final step = await fetchAction(username);
      if (step != null) {
        if (step <= 8) {
          setState(() {
            _currentStep = step;
            _isLoading = false;
          });
        } else {
          if (mounted) {
            int? validiation = await getBaby(username);
            if (validiation != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => secondState()),
              );
            } else {
              Navigator.pushReplacement(
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

  @override
  void initState() {
    super.initState();
    loadStepFromServer(); // Call the function to load the step on init
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
              : Center(child: _buildStepperView()),
    );
  }

  Widget _buildStepperView() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Text(
          "แจ้งเตือนก่อนคลอดบุตร",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Stepper(
                connectorThickness: 3,
                connectorColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (_currentStep > 0 &&
                      states.contains(WidgetState.selected)) {
                    return Colors.green;
                  } else if (states.contains(WidgetState.selected)) {
                    return const Color.fromARGB(255, 255, 88, 130);
                  } else {
                    return Colors.grey.shade300;
                  }
                }),
                currentStep: _currentStep,
                onStepTapped: null,
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
        _buildSlideAction(),
        const SizedBox(height: 40),
      ],
    );
  }

  List<Step> _getSteps() {
    return [
      customStep("การแจ้งเตือนที่ 1", "อายุครรภ์น้อยกว่า 12 สัปดาห์", 0),
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
        
        """,
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
3. ประเมิณสุขภาพจิต ครั้งที่ 6
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

  Widget _buildSlideAction() {
    return SizedBox(
      width: 300,
      child: SlideAction(
        stretchThumb: true,
        trackBuilder: (context, state) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: Colors.white,
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8),
              ],
            ),
            child: const Center(
              child: Text("ยืนยันการคลอด", style: TextStyle(fontSize: 18)),
            ),
          );
        },
        thumbBuilder: (context, state) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: state.isPerformingAction ? Colors.grey : Colors.black,
              borderRadius: BorderRadius.circular(100),
            ),
            child:
                state.isPerformingAction
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Icon(Icons.send, color: Colors.white),
          );
        },
        action: () async {
          final prefs = await SharedPreferences.getInstance();
          final username = prefs.getString('username');

          if (username == null) {
            print("⚠️ Username not found");
            return;
          }

          final result = await updateAction(
            username,
            9,
          ); // Send update to your Node.js backend
          debugPrint(result.toString());
          if (result != null) {
            showModalBottomSheet(
              context: context,
              clipBehavior: Clip.antiAlias,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              builder: (BuildContext context) {
                return GiffyBottomSheet.image(
                  Image.asset(
                    "assets/jk/1.gif",
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  title: Text('ยืนยันเรียบร้อย', textAlign: TextAlign.center),
                  content: Text(
                    'ข้อมูลได้รับการอัปเดต',
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PreviewState(),
                          ),
                        );
                      },
                      child: const Text('OK'),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              builder: (BuildContext context) {
                return GiffyBottomSheet.image(
                  Image.asset(
                    "assets/jk/2.gif",
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  title: Text('เกิดข้อผิดพลาด', textAlign: TextAlign.center),
                  content: Text(
                    'อัปเดตข้อมูลไม่สำเร็จ',
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Try Again'),
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }

  Step customStep(String title, String content, int stepIndex) {
    final isActive = _currentStep >= stepIndex;
    final isCurrent = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;

    return Step(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          fontSize: isCurrent ? 16.0 : 14.0,
          color:
              isCurrent
                  ? Colors.blue
                  : (isCompleted ? Colors.green : Colors.black),
        ),
      ),
      content: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: isCurrent ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
          border: isCurrent ? Border.all(color: Colors.blue, width: 1.0) : null,
        ),
        child: Text(
          content,
          style: TextStyle(color: isCurrent ? Colors.black87 : Colors.black54),
        ),
      ),
      isActive: isActive,
      state:
          isCompleted
              ? StepState.complete
              : (isCurrent ? StepState.editing : StepState.indexed),
    );
  }
}

Future<int?> fetchAction(String username) async {
  final uri = Uri.parse('$baseUrl/api/getAction?username=$username');

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data['action']; // This should be an int
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
        return data['action']; // This should be an int
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
  final uri = Uri.parse('$baseUrl/api/get_baby_data'); // Your API endpoint
  try {
    // Make a POST request with the 'mother' in the body
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mother': username,
      }), // Send username as 'mother' in the body
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data['data']['action']; // Return the action if the response is successful
      } else {
        debugPrint("⚠️ Server responded with an error: ${data['message']}");
      }
    } else if (response.statusCode == 404) {
      debugPrint("No data found for mother $username");
      // Handle 404 response (No data found)
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
