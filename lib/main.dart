import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fa_mobile_app/Login.dart';
import 'package:fa_mobile_app/ListMenu.dart'; // เพิ่มการนำเข้า ListMenu
import 'package:intl/intl.dart'; // ใช้จัดการวันที่และเวลา

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder(
        future: _checkLoginStatus(), // ตรวจสอบสถานะการล็อกอิน
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator()); // รอการโหลดข้อมูล
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return snapshot.data ??
                LoginPage(); // ถ้ายังไม่ได้ล็อกอินให้แสดง LoginPage
          }
        },
      ),
    );
  }

  // ฟังก์ชันตรวจสอบสถานะการล็อกอิน
  Future<Widget?> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? userCode = prefs.getString('userCode');
    String? depcode = prefs.getString('depcode');
    String? loginTime = prefs.getString('loginTime');

    if (depcode != null) {
      DateTime lastLogin = DateTime.parse(loginTime!).toLocal();
      DateTime now = DateTime.now().toLocal();

      // คำนวณระยะห่างของเวลา
      if (now.difference(lastLogin).inHours >= 24) {
        // ถ้าต่างกันเกิน 24 ชั่วโมง ให้เคลียร์ prefs และกลับไปหน้า Login
        await prefs.clear();
        return LoginPage();
      }

      // ถ้าเวลาไม่เกิน 24 ชั่วโมง ให้ไปที่หน้า ListMenu
      return MenuPage(
        usercode: userCode ?? '',
        depcode: depcode ?? '',
        time: loginTime ?? '',
      );
    } else {
      // ถ้ายังไม่มีการล็อกอิน ให้แสดงหน้า Login
      return LoginPage();
    }
  }
}
