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

class QRViewPage extends StatefulWidget {
  final List<dynamic> qrText;
  final String usercode;
  final int branchID;
  final String depcode; // ✅ ต้องมีตัวแปรนี้
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
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            String imageUrl = snapshot.data ?? fallbackImageUrl;
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    _buildPlaceholderImage(),
                              ),
                            );
                          },
                        );
                      },
                    ),
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
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 3,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
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
                    return FutureBuilder<String>(
                      future: _isValidImagePath(listImage_count[index]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        String imageUrl = snapshot.data ??
                            'https://thumb.ac-illust.com/b1/b170870007dfa419295d949814474ab2_t.jpeg';
                        return InkWell(
                          onTap: () {
                            _pickImage(qrData["Code"], index);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  _buildPlaceholderImage(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
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
                  children: radioListOptions.map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: selectedOption,
                      onChanged: (value) async {
                        if (value == null) return;
                        SharedPreferences pref =
                            await SharedPreferences.getInstance();
                        String url = '${Config.apiURL}/addAsset';
                        var response = await http.post(
                          Uri.parse(url),
                          headers: Config.headers,
                          body: jsonEncode({
                            "Name": qrData['Name'],
                            "Code": qrData["Code"],
                            "BranchID": qrData['BranchID'],
                            "Date": DateTime.now().toLocal().toString(),
                            "UserBranch": widget.branchID,
                            "Reference": value,
                            "Status": 1,
                            "RoundID": widget.periodID,
                            "UserID": pref.getString("userid"),
                          }),
                        );
                        if (response.statusCode == 200) {
                          setState(() {
                            selectedOption = value;
                          });
                        } else {
                          _showDialog('แจ้งเตือน',
                              'ไม่สามารถแก้ไขข้อมูลได่ กรุณาลองใหม่อีกครั้ง');
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            )
          ],
        ),
      ),
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
                Navigator.of(context).pop(); // ปิด Dialog และอยู่หน้าเดิม
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> _isValidImagePath(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return 'https://thumb.ac-illust.com/b1/b170870007dfa419295d949814474ab2_t.jpeg';
    }
    try {
      // แทนที่โดเมน "vpnptec.dyndns.org" ด้วย "49.0.64.71"
      imagePath = imagePath.replaceAll("vpnptec.dyndns.org", "10.15.100.227");
      final uri = Uri.parse(imagePath);
      if (!uri.isAbsolute) {
        return 'https://thumb.ac-illust.com/b1/b170870007dfa419295d949814474ab2_t.jpeg';
      }
      final response = await http.head(uri);
      if (response.statusCode == 200) return imagePath;
    } catch (_) {}
    return 'https://thumb.ac-illust.com/b1/b170870007dfa419295d949814474ab2_t.jpeg';
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
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกจากแกลเลอรี'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _getImage(ImageSource.gallery, code, index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('ถ่ายภาพ'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _getImage(ImageSource.camera, code, index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source, String code, int index) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (pickedFile != null) {
      await _uploadImage(File(pickedFile.path), code, index);
    }
  }

  Future<void> _uploadImage(File imageFile, String code, int index) async {
    String url_checkFiles = '${Config.apiURL}/check_files_NewNAC';

    var request = http.MultipartRequest('POST', Uri.parse(url_checkFiles));
    // เพิ่มไฟล์รูปภาพใน request
    var file = await http.MultipartFile.fromPath('file', imageFile.path);
    request.files.add(file);
    // ส่งคำขอไปยัง API
    var response = await request.send();

    // ตรวจสอบผลลัพธ์
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);
      if (jsonData['attach'] != null && jsonData['attach'].isNotEmpty) {
        String attValue = jsonData['attach'][0]['ATT'];
        String extension = jsonData['extension'];
        var client = http.Client();
        var url = Uri.parse('${Config.apiURL}/FA_Mobile_UploadImage');
        await client.post(
          url,
          headers: Config.headers,
          body: jsonEncode({
            "Code": code,
            "RoundID": widget.periodID,
            "index": index,
            "url":
                "http://vpnptec.dyndns.org:33080/NEW_NAC/$attValue.$extension",
          }),
        );
        setState(() {
          if (index == 0) {
            listImage_count[0] =
                "http://vpnptec.dyndns.org:33080/NEW_NAC/$attValue.$extension";
          } else if (index == 1) {
            listImage_count[1] =
                "http://vpnptec.dyndns.org:33080/NEW_NAC/$attValue.$extension";
          }
        });
        print("✅ อัปโหลดสำเร็จ!");
      } else {
        _showDialog('แจ้งเตือน', '❌ อัปโหลดล้มเหลว! กรุณาลองใหม่อีกครั้ง');
      }
    }
  }
}
