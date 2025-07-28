import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddNurse extends StatefulWidget {
  const AddNurse({super.key});

  @override
  _AddNurseState createState() => _AddNurseState();
}

class _AddNurseState extends State<AddNurse> {
  final TextEditingController _nurseIDController = TextEditingController();
  final TextEditingController _nursePasswordController =
      TextEditingController();
  final TextEditingController _nurseNameController = TextEditingController();
  final TextEditingController _telephoneNumberController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Nurse")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Nurse ID",
                border: OutlineInputBorder(),
              ),
              controller: _nurseIDController,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "Nurse Password",
                border: OutlineInputBorder(),
              ),
              controller: _nursePasswordController,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "Nurse Name",
                border: OutlineInputBorder(),
              ),
              controller: _nurseNameController,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "Telephone Number",
                border: OutlineInputBorder(),
              ),
              controller: _telephoneNumberController,
            ),
            SizedBox(height: 16),
            Spacer(), // Pushes the button to the bottom
            Padding(
              padding: const EdgeInsets.all(
                10.0,
              ), // Add padding around the button
              child: SizedBox(
                width: double.infinity, // Full width of the screen
                height: 50, // Height of the button
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Rounded edges
                    ),
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () async {
                    final nurseData = {
                      'username': _nurseIDController.text,
                      'password': _nursePasswordController.text,
                      'name': _nurseNameController.text,
                      'role': 'nurse',
                      'telephone': _telephoneNumberController.text,
                    };
                    // Simulate saving user details via an HTTP request
                    try {
                      final response = await http.post(
                        Uri.parse(
                          '$baseUrl/api/register',
                        ), // Replace with your API URL
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(nurseData),
                      );

                      if (response.statusCode == 200 ||
                          response.statusCode == 201) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("User details saved successfully!"),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to save user details"),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("An error occurred: $e")),
                      );
                    }
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
