import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
class Config {
  static Future<Map<String, String>> getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> getResetTokenHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final resetToken = prefs.getString('resetToken') ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $resetToken',
    };
  }

  static const Map<String, String> headerUploadFile = {
    'Content-Type': 'multipart/form-data'
  };

  static const String appName = "แจ้งเตือน";
  static const String apiURL_Home = "http://172.16.4.164:33052/api";
  static const String apiURL_Local =
      "http://10.20.100.29:33052/api"; //Ipconfig 49.0.64.71:32001
  static const String apiURL_Server =
      "https://nac.purethai.co.th/api";
  static const String apiURL_Test = "http://10.20.100.3:32001/api";
  static const String apiURL = apiURL_Server;
}


// class MyHttpOverrides extends HttpOverrides {
//   @override
//   HttpClient createHttpClient(SecurityContext? context) {
//     return super.createHttpClient(context)
//       ..badCertificateCallback = (X509Certificate cert, String host, int port) {
//         print("❗️Bypassing SSL verification for $host");
//         return true; // ยอมรับ cert ทุกกรณี (ไม่ปลอดภัย)
//       };
//   }
// }
