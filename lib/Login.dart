import 'package:fa_mobile_app/ListMenu.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fa_mobile_app/config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ฟังก์ชันเก็บข้อมูล User และเวลา Login
  Future<void> _saveLoginData(
      String userCode, String depcode, String userid) async {
    final prefs = await SharedPreferences.getInstance();
    DateTime currentTime = DateTime.now().toLocal();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(currentTime);

    await prefs.setString('userCode', userCode); // เก็บ userCode
    await prefs.setString('userid', userid); // เก็บ userCode
    await prefs.setString('depcode', depcode);
    await prefs.setString(
        'loginTime', formattedDate.toString()); // เก็บเวลา login
  }

  // ฟังก์ชัน Login API
  Future<void> _login() async {
    String url = '${Config.apiURL}/login';

    // เตรียมข้อมูลเป็น JSON
    Map<String, String> data = {
      "UserCode": _usernameController.text,
      "Password": _passwordController.text
    };

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: Config.headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body)["data"];
        var depcode = jsonDecode(response.body)["data"][0]["depcode"];
        var userid = jsonDecode(response.body)["data"][0]["userid"];

        print("✅ Login Success: ${responseData}");

        _saveLoginData(_usernameController.text, depcode, userid);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MenuPage(
              usercode: _usernameController.text,
              depcode: depcode,
              time: DateFormat('yyyy-MM-dd HH:mm')
                  .format(DateTime.now().toLocal())
                  .toString(),
            ),
          ),
        );
      } else {
        print("❌ Login Failed: ${response.body}");
        _showDialog("Login ผิดพลาด", "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง");
      }
    } catch (e) {
      print("🚨 Error: $e");
      _showDialog("ข้อผิดพลาด", "ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้");
    }
  }

  // ฟังก์ชันแสดง Dialog แจ้งเตือน
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 246, 246, 246),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Welcome to FA Mobile 2025',
                style: TextStyle(
                    fontSize: screenWidth * 0.08, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: screenHeight * 0.04),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    print("ลืมรหัสผ่าน?");
                  },
                  child: Text(
                    'ลืมรหัสผ่าน?',
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              ElevatedButton(
                onPressed: _login, // กดแล้วส่ง API
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 48, 96, 96),
                  minimumSize: Size(screenWidth * 0.8, screenHeight * 0.06),
                ),
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
