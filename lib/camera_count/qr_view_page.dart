import 'dart:convert';
import 'dart:io';
import 'package:fa_mobile_app/camera_count/qr_scanner_page.dart';
import 'package:fa_mobile_app/config.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fa_mobile_app/services/httpService.dart';

class QRViewPage extends StatefulWidget {
  final List<dynamic> qrText;
  final String usercode;
  final int branchID;
  final String depcode;
  final String time;
  final String branchName;
  final int periodID;

  const QRViewPage({
    Key? key,
    required this.usercode,
    required this.time,
    required this.qrText,
    required this.depcode,
    required this.branchID,
    required this.periodID,
    required this.branchName,
  }) : super(key: key);

  @override
  _QRViewPageState createState() => _QRViewPageState();
}

class _QRViewPageState extends State<QRViewPage> {
  static const String fallbackImageUrl =
      'https://thumb.ac-illust.com/b1/b170870007dfa419295d949814474ab2_t.jpeg';
  List<dynamic> radioListOptions = [
    'ยังไม่ได้ระบุสถานะ',
    'สภาพดี',
    'ชำรุดรอซ่อม',
    'รอตัดขาย',
    'รอตัดชำรุด',
    'อื่น ๆ'
  ];
  final ImagePicker _picker = ImagePicker();
  String selectedOption = "ยังไม่ได้ระบุสถานะ";
  List<String> listImage_count = [
    "https://thumb.ac-illust.com/b1/b170870007dfa419295d949814474ab2_t.jpeg",
    "https://thumb.ac-illust.com/b1/b170870007dfa419295d949814474ab2_t.jpeg"
  ];
  List<bool> isUploading = [false, false]; // สถานะการอัพโหลด

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (widget.qrText.isEmpty || widget.qrText[0] == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("ผลลัพธ์ QR Code")),
        body: const Center(child: Text("ไม่มีข้อมูล QR Code")),
      );
    }

    var qrData = widget.qrText[0];
    List<String> listImage = [
      qrData["ImagePath"].toString(),
      qrData["ImagePath_2"].toString()
    ];

    String createDate = "No Data Available";
    if (qrData["CreateDate"] != null &&
        qrData["CreateDate"].toString().isNotEmpty) {
      try {
        createDate = DateFormat('yyyy-MM-dd')
            .format(DateTime.parse(qrData["CreateDate"]).toLocal());
      } catch (_) {
        createDate = "Invalid Date Format";
      }
    }

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 246, 246, 246),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 48, 96, 96),
        title: Text(
          "ผลลัพธ์ QR Code",
          style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        leading: IconButton(
          color: Colors.white,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QRScannerCountPage(
                usercode: widget.usercode,
                time: widget.time,
                branchID: widget.branchID,
                branchName: widget.branchName,
                depcode: widget.depcode,
                peroioID: widget.periodID,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Card แสดงรูปภาพดั้งเดิม
            Card(
              elevation: 3,
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              shadowColor: Colors.grey.withAlpha(127),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "รูปภาพจากระบบ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: listImage.length,
                      itemBuilder: (context, index) {
                        return FutureBuilder<String>(
                          future: _isValidImagePath(listImage[index]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            String imageUrl = snapshot.data ?? fallbackImageUrl;
                            return InkWell(
                              onTap: () => _showImageDialog(imageUrl, "รูปภาพจากระบบ ${index + 1}"),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) => _buildPlaceholderImage(),
                                    ),
                                    // Overlay gradient to indicate viewable
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.3),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.zoom_in,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    _buildInfoText("รหัสทรัพย์สิน: ", qrData["Code"]),
                    _buildInfoText("ชื่อทรัพย์สิน: ", qrData["Name"]),
                    _buildInfoText("SerialNo: ", qrData["SerialNo"]),
                    _buildInfoText("ผู้ถือครอง: ",
                        "${qrData["ownerCode"] ?? ""} (${qrData["BranchName"] ?? "No Data"})"),
                    _buildInfoText("สถานะปัจจุบัน: ", qrData["Details"]),
                    _buildInfoText("วันที่ขึ้นทะเบียน: ", createDate),
                  ],
                ),
              ),
            ),
            
            // Card สำหรับอัพโหลดรูปภาพ (รวมการแสดงรูปและการอัพโหลด)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 3,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              shadowColor: Colors.grey.withAlpha(127),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud_upload, color: Colors.blue[600]),
                        SizedBox(width: 8),
                        Text(
                          "รูปภาพหลักฐานประกอบตรวจนับทรัพย์สิน",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: listImage_count.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            InkWell(
                              onTap: () {
                                if (!isUploading[index]) {
                                  if (_isDefaultImage(listImage_count[index])) {
                                    _pickImage(qrData["Code"], index);
                                  } else {
                                    _showImageDialog(listImage_count[index], "รูปภาพที่อัพโหลด ${index + 1}");
                                  }
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                    color: _isDefaultImage(listImage_count[index]) 
                                        ? Colors.blue.withOpacity(0.5)
                                        : Colors.transparent,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      FutureBuilder<String>(
                                        future: _isValidImagePath(listImage_count[index]),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting || isUploading[index]) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            );
                                          }
                                          String imageUrl = snapshot.data ?? fallbackImageUrl;
                                          return CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) =>
                                                _buildUploadPlaceholder(index),
                                          );
                                        },
                                      ),
                                      // Overlay สำหรับรูปเริ่มต้น
                                      if (_isDefaultImage(listImage_count[index]) && !isUploading[index])
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_a_photo,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  "อัพโหลดรูป",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      // ไอคอนแสดงสถานะ
                                      if (!_isDefaultImage(listImage_count[index]) && !isUploading[index])
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      // ปุ่มเปลี่ยนรูปสำหรับรูปที่อัพโหลดแล้ว
                                      if (!_isDefaultImage(listImage_count[index]) && !isUploading[index])
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: InkWell(
                                            onTap: () => _pickImage(qrData["Code"], index),
                                            child: Container(
                                              padding: EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[600],
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black26,
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // ป้ายกำกับตำแหน่งรูป
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "รูปที่ ${index + 1}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Card สำหรับเลือกสถานะ
            Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 3,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              shadowColor: Colors.grey.withAlpha(127),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.radio_button_checked, color: Colors.orange[600]),
                        SizedBox(width: 8),
                        Text(
                          "เลือกสถานะทรัพย์สิน",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ...radioListOptions.map((option) {
                      return RadioListTile<String>(
                        title: Text(option),
                        value: option,
                        groupValue: selectedOption,
                        onChanged: (value) async {
                          if (value == null) return;
                          
                          // ถ้าเลือก "ยังไม่ได้ระบุสถานะ" ให้บันทึกทันที
                          if (value == "ยังไม่ได้ระบุสถานะ") {
                            await _updateAssetStatus(value, qrData);
                          } else {
                            // สำหรับสถานะอื่นๆ ให้แสดง dialog ยืนยัน
                            _showStatusConfirmationDialog(value, qrData);
                          }
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ฟังก์ชั่นแสดง dialog ยืนยันการเปลี่ยนสถานะ
  void _showStatusConfirmationDialog(String newStatus, var qrData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[600], size: 28),
              SizedBox(width: 8),
              Text(
                "ยืนยันการเปลี่ยนสถานะ",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "คุณต้องการเปลี่ยนสถานะทรัพย์สินเป็น:",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  '"$newStatus"',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                "ทรัพย์สิน: ${qrData["Name"] ?? "ไม่ระบุ"}",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                "รหัส: ${qrData["Code"] ?? "ไม่ระบุ"}",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                "ยกเลิก",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // ไม่ต้องรีเซ็ตค่า selectedOption เพราะยังไม่ได้เปลี่ยน
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                "ตกลง",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateAssetStatus(newStatus, qrData);
              },
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชั่นอัพเดทสถานะทรัพย์สิน
  Future<void> _updateAssetStatus(String status, var qrData) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String url = '${Config.apiURL}/addAsset';
      
      var response = await HttpWithAuth.post(
        context: context,
        url: Uri.parse(url),
        headers: await Config.getAuthHeaders(),
        body: jsonEncode({
          "Name": qrData['Name'],
          "Code": qrData["Code"],
          "BranchID": qrData['BranchID'],
          "Date": DateTime.now().toLocal().toString(),
          "UserBranch": widget.branchID,
          "Reference": status,
          "Status": 1,
          "RoundID": widget.periodID,
          "UserID": pref.getString("userid"),
        }),
      );
      
      print(response.body);
      
      if (response.statusCode == 200) {
        setState(() {
          selectedOption = status;
        });
        
        // แสดง SnackBar แจ้งผลสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text("อัพเดทสถานะเป็น '$status' สำเร็จ!"),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        // Parse JSON response to get the message
        String errorMessage = 'ไม่สามารถแก้ไขข้อมูลได้';
        try {
          var responseJson = jsonDecode(response.body);
          if (responseJson['message'] != null) {
            errorMessage += ' เนื่องจาก ${responseJson['message']}';
          } else {
            errorMessage += ' (${response.statusCode})';
          }
        } catch (e) {
          errorMessage += ' (${response.statusCode})';
        }
        _showDialog('แจ้งเตือน', errorMessage);
      }
    } catch (e) {
      _showDialog('แจ้งเตือน', 'เกิดข้อผิดพลาด: ${e.toString()}');
    }
  }

  // ฟังก์ชั่นตรวจสอบว่าเป็นรูปเริ่มต้นหรือไม่
  bool _isDefaultImage(String imageUrl) {
    return imageUrl == fallbackImageUrl;
  }

  // Widget สำหรับรูป placeholder ที่สามารถอัพโหลดได้
  Widget _buildUploadPlaceholder(int index) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              color: Colors.grey[600],
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              "แตะเพื่ือเพิ่มรูป",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชั่นแสดงรูปแบบใหญ่
  void _showImageDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85), // พื้นหลังสีดำอ่อนๆ
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
              Center(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: InteractiveViewer( // เพิ่มการ zoom ได้
                    maxScale: 3.0,
                    minScale: 0.5,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                "กำลังโหลดรูปภาพ...",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 80, color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                "ไม่สามารถโหลดรูปได้",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // หัวข้อด้านบน
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20,
                right: 70,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // ปุ่มปิด
              Positioned(
                top: MediaQuery.of(context).padding.top + 15,
                right: 20,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              // คำแนะนำการใช้งาน
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.zoom_in, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "หยิกเพื่อซูม • แตะเพื่อปิด",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

  Future<String> _isValidImagePath(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return fallbackImageUrl;
    }
    try {
      imagePath = imagePath.replaceAll("vpnptec.dyndns.org", "10.15.100.227");
      final uri = Uri.parse(imagePath);
      if (!uri.isAbsolute) {
        return fallbackImageUrl;
      }
      final response = await http.head(uri);
      if (response.statusCode == 200) return imagePath;
    } catch (_) {}
    return fallbackImageUrl;
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, size: 50, color: Colors.white),
    );
  }

  Widget _buildInfoText(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Text(
        value != null && value.toString().isNotEmpty
            ? "$title$value"
            : "$title No Data Available",
        style: const TextStyle(
            fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black),
      ),
    );
  }

  Future<void> _pickImage(String code, int index) async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "เลือกรูปภาพ",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      label: 'เลือกจากแกลเลอรี',
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _getImage(ImageSource.gallery, code, index);
                      },
                    ),
                    _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      label: 'ถ่ายภาพ',
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _getImage(ImageSource.camera, code, index);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.blue[600]),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source, String code, int index) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85, // ลดคุณภาพเล็กน้อยเพื่อลดขนาดไฟล์
        maxWidth: 1920, // จำกัดขนาดความกว้าง
        maxHeight: 1080, // จำกัดขนาดความสูง
      );
      if (pickedFile != null) {
        await _uploadImage(File(pickedFile.path), code, index);
      }
    } catch (e) {
      print("Error picking image: $e");
      _showDialog('แจ้งเตือน', 'เกิดข้อผิดพลาดในการเลือกรูปภาพ: ${e.toString()}');
    }
  }

  Future<void> _uploadImage(File imageFile, String code, int index) async {
    setState(() {
      isUploading[index] = true;
    });

    try {
      // print("🔄 เริ่มอัปโหลดรูป: ${imageFile.path}");
      // print("📁 ขนาดไฟล์: ${await imageFile.length()} bytes");
      // print("🏷️ รหัสทรัพย์สิน: $code, ดัชนี: $index");
      
      String url_checkFiles = '${Config.apiURL}/check_files_NewNAC';
      // print("🌐 URL ตรวจสอบไฟล์: $url_checkFiles");

      var request = http.MultipartRequest('POST', Uri.parse(url_checkFiles));
      request.headers.addAll(await Config.getAuthHeaders());
      var file = await http.MultipartFile.fromPath('file', imageFile.path);
      request.files.add(file);
      
      // print("📤 กำลังส่งไฟล์...");
      var response = await request.send();
      print("📡 Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        // print("📋 Response Data: $responseData");
        
        var jsonData = json.decode(responseData);
        if (jsonData['attach'] != null && jsonData['attach'].isNotEmpty) {
          String attValue = jsonData['attach'][0]['ATT'];
          String extension = jsonData['extension'];
          String imageUrl = "https://nac.purethai.co.th/NEW_NAC/$attValue.$extension";
          
          // print("🔗 URL รูปภาพ: $imageUrl");
          
          var client = http.Client();
          var url = Uri.parse('${Config.apiURL}/FA_Mobile_UploadImage');
          // print("🌐 URL บันทึก: $url");
          
          var uploadResponse = await client.post(
            url,
            headers: await Config.getAuthHeaders(),
            body: jsonEncode({
              "Code": code,
              "RoundID": widget.periodID,
              "index": index,
              "url": imageUrl,
            }),
          );
          
          // print("💾 บันทึกข้อมูล Status: ${uploadResponse.statusCode}");
          // print("💾 บันทึกข้อมูล Response: ${uploadResponse.body}");
          
          if (uploadResponse.statusCode == 200) {
            setState(() {
              listImage_count[index] = imageUrl;
            });
            // print("✅ อัปโหลดสำเร็จ!");
            
            // แสดง SnackBar แจ้งผลสำเร็จ
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text("อัปโหลดรูปภาพสำเร็จ!"),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          } else {
            throw Exception('ไม่สามารถบันทึกข้อมูลรูปภาพได้ (${uploadResponse.statusCode})');
          }
        } else {
          throw Exception('ไม่พบข้อมูลไฟล์ในการตอบกลับ');
        }
      } else {
        var errorData = await response.stream.bytesToString();
        print("❌ Error Response: $errorData");
        throw Exception('การอัปโหลดล้มเหลว (${response.statusCode}): $errorData');
      }
    } catch (e) {
      print("❌ ข้อผิดพลาด: $e");
      
      // แสดง error ที่ละเอียดขึ้น
      String errorMessage = 'เกิดข้อผิดพลาด: ';
      if (e.toString().contains('SocketException')) {
        errorMessage += 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบอินเตอร์เน็ต';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage += 'การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่';
      } else if (e.toString().contains('FormatException')) {
        errorMessage += 'รูปแบบข้อมูลไม่ถูกต้อง';
      } else {
        errorMessage += e.toString();
      }
      
      _showDialog('แจ้งเตือน', errorMessage);
    } finally {
      setState(() {
        isUploading[index] = false;
      });
    }
  }
}