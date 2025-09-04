import 'dart:convert';

import 'package:fa_mobile_app/camera_count/ListPeroid_in_time.dart';
import 'package:fa_mobile_app/config.dart';
import 'package:fa_mobile_app/listMenu.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'qr_view_page.dart'; // นำเข้าไฟล์หน้าผลลัพธ์
import 'package:http/http.dart' as http;
import 'package:fa_mobile_app/services/httpService.dart';
import 'package:image_picker/image_picker.dart';

class QRScannerCountPage extends StatefulWidget {
  final String usercode;
  final int branchID;
  final String depcode; // ✅ ต้องมีตัวแปรนี้
  final String time;
  final String branchName;
  final int peroioID;

  const QRScannerCountPage({
    Key? key,
    required this.usercode,
    required this.depcode, // ✅ ต้องรับค่า depcode
    required this.time,
    required this.peroioID,
    required this.branchID,
    required this.branchName,
  }) : super(key: key);

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerCountPage> {
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
      final response = await HttpWithAuth.post(
        context: context,
        url: Uri.parse(url),
        headers: await Config.getAuthHeaders(),
        body: jsonEncode(data),
      );

      if (!mounted) return;

      setState(() {
        if (response.statusCode == 200) {
          if (jsonDecode(response.body)['data'] is List) {
            // แปลงข้อมูลเป็น List ของ String
            final List<dynamic> apiResponse = jsonDecode(response.body)['data'];

            // ไปที่หน้าแสดงผล QRViewPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => QRViewPage(
                  qrText: apiResponse,
                  usercode: '${widget.usercode}',
                  time: '${widget.time}',
                  depcode: widget.depcode,
                  branchID: widget.branchID,
                  periodID: widget.peroioID,
                  branchName: widget.branchName,
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

  // // ฟังก์ชันเลือกรูปจากแกลเลอรี่และสแกน QR
  // Future<void> scanQRFromGallery() async {
  //   try {
  //     final ImagePicker picker = ImagePicker();
  //     final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
  //     if (pickedFile == null) return;

  //     // สร้าง controller ใหม่สำหรับอ่านรูปจากแกลเลอรี่
  //     final MobileScannerController galleryController = MobileScannerController();
      
  //     try {
  //       // ใช้ analyzeImage ของ mobile_scanner
  //       final BarcodeCapture? result = await galleryController.analyzeImage(pickedFile.path);
        
  //       if (result != null && result.barcodes.isNotEmpty) {
  //         String qrResult = result.barcodes.first.rawValue ?? "ไม่พบข้อมูล";
  //         print("QR Code from gallery: $qrResult");
  //         await sendQRCodeToAPI(qrResult);
  //       } else {
  //         _showDialog("แจ้งเตือน", "ไม่พบ QR Code ในรูปภาพที่เลือก");
  //       }
  //     } catch (e) {
  //       print("Error analyzing image: $e");
  //       _showDialog("เกิดข้อผิดพลาด", "ไม่สามารถอ่าน QR Code จากรูปภาพได้");
  //     } finally {
  //       galleryController.dispose();
  //     }
  //   } catch (e) {
  //     _showDialog("เกิดข้อผิดพลาด", "เกิดข้อผิดพลาดในการเลือกรูปภาพ: ${e.toString()}");
  //   }
  // }

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
                    builder: (context) => MyPeriodInTime(
                      usercode: '${widget.usercode}',
                      time: '${widget.time}',
                      branchID: widget.branchID,
                      branchName: widget.branchName,
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
                builder: (context) => MyPeriodInTime(
                  usercode: '${widget.usercode}',
                  time: '${widget.time}',
                  branchID: widget.branchID,
                  branchName: widget.branchName,
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
          // // ปุ่มเลือกรูปจากแกลเลอรี่
          // Positioned(
          //   bottom: 16,
          //   left: 16,
          //   right: 16,
          //   child: ElevatedButton(
          //     onPressed: scanQRFromGallery,
          //     child: Text("เลือกรูปจากแกลเลอรี่"),
          //   ),
          // ),
        ],
      ),
    );
  }
}