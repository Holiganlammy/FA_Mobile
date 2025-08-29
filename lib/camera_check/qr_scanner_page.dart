import 'dart:convert';
import 'package:fa_mobile_app/config.dart';
import 'package:fa_mobile_app/listMenu.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'qr_view_page.dart'; // นำเข้าไฟล์หน้าผลลัพธ์
import 'package:http/http.dart' as http;

class QRScannerPage extends StatefulWidget {
  final String usercode;
  final String depcode; // ✅ ต้องมีตัวแปรนี้
  final String time;

  const QRScannerPage({
    Key? key,
    required this.usercode,
    required this.depcode, // ✅ ต้องรับค่า depcode
    required this.time,
  }) : super(key: key);

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  String apiResponse = "รอผลลัพธ์จาก API...";
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose(); // ปิดการใช้งานกล้องเมื่อไม่ใช้งาน
    super.dispose();
  }

  Future<void> sendQRCodeToAPI(String qrText) async {
    const String url = '${Config.apiURL}/check_code_result'; // API URL
    final Map<String, String> data = {'Code': qrText};

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await Config.getAuthHeaders(),
        body: jsonEncode(data),
      );

      if (!mounted) return;

      setState(() {
        if (response.statusCode == 200) {
          if (jsonDecode(response.body)['data'] is List) {
            // แปลงข้อมูลเป็น List ของ String
            final List<dynamic> apiResponse = jsonDecode(response.body)['data'];
            print("data SUCCCESS: $apiResponse");
            // ไปที่หน้าแสดงผล QRViewPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => QRViewPage(
                  qrText: apiResponse,
                  usercode: '${widget.usercode}',
                  time: '${widget.time}',
                  depcode: widget.depcode,
                ),
              ),
            );
          }
        } else {
          _showDialog("ข้อผิดพลาด", "❌ Error: ไม่พบรหัส $qrText");
        }
      });
      cameraController.dispose();
    } catch (e) {
      if (!mounted) return;
      _showDialog("ข้อผิดพลาด", "🚨 Error: $e");
      cameraController.dispose();
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MenuPage(
                      usercode: '${widget.usercode}',
                      time: '${widget.time}',
                      depcode: '',
                    ),
                  ),
                );
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
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 246, 246, 246),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 48, 96, 96),
        title: Text(
          "สแกน QR Code",
          style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        leading: IconButton(
          color: Colors.white,
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MenuPage(
                  usercode: '${widget.usercode}',
                  time: '${widget.time}',
                  depcode: '',
                ),
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String qrText = barcodes.first.rawValue ?? "Unknown";
                sendQRCodeToAPI(qrText); // ส่ง QR Code ไปยัง API
              }
            },
          ),
          // กรอบสี่เหลี่ยมตรงกลางหน้าจอ
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // เอฟเฟกต์เส้นเลเซอร์
        ],
      ),
    );
  }
}
