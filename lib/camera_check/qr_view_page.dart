import 'package:fa_mobile_app/listMenu.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:fa_mobile_app/config.dart';

class QRViewPage extends StatefulWidget {
  final List<dynamic> qrText;
  final String usercode;
  final String depcode;
  final String time;

  const QRViewPage({
    Key? key,
    required this.usercode,
    required this.time,
    required this.qrText,
    required this.depcode,
  }) : super(key: key);

  @override
  _QRViewPageState createState() => _QRViewPageState();
}

class _QRViewPageState extends State<QRViewPage> {
  static const String fallbackImageUrl =
      'https://thumb.ac-illust.com/b1/b170870007dfa419295d949814474ab2_t.jpeg';

  // เพิ่มตัวแปรสำหรับฟังก์ชั่นอัปโหลด
  final ImagePicker _picker = ImagePicker();
  bool isUploading = false;
  bool isLoadingBehindUpload = false;
  List<dynamic> filteredAssets = [];

  @override
  void initState() {
    super.initState();
    // กำหนดค่าเริ่มต้นให้ filteredAssets
    filteredAssets = widget.qrText;
  }

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
              builder: (context) => MenuPage(
                usercode: widget.usercode,
                time: widget.time,
                depcode: widget.depcode,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                        Row(
                          children: [
                            Icon(Icons.photo_library, color: Colors.blue[600]),
                            SizedBox(width: 8),
                            Text(
                              "รูปภาพทรัพย์สิน",
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
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: listImage.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                InkWell(
                                  onTap: () => _showImageOptionsDialog(
                                    listImage[index], 
                                    "รูปภาพทรัพย์สิน ${index + 1}",
                                    qrData["Code"].toString(),
                                    index
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      child: FutureBuilder<String>(
                                        future: _isValidImagePath(listImage[index]),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            );
                                          }
                                          String imageUrl = snapshot.data ?? fallbackImageUrl;
                                          return Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: CircularProgressIndicator(),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) =>
                                                    _buildPlaceholderImage(),
                                              ),
                                              // Overlay บอกว่าดูได้
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
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  padding: EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withOpacity(0.6),
                                                    borderRadius: BorderRadius.circular(15),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.camera_alt,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 2),
                                                      Icon(
                                                        Icons.zoom_in,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
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
              ],
            ),
          ),
          // Loading overlay
          if (isUploading || isLoadingBehindUpload)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        isUploading ? 'กำลังอัปโหลดรูปภาพ...' : 'กำลังโหลดข้อมูล...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ฟังก์ชั่นแสดงตัวเลือกสำหรับรูปภาพ
  void _showImageOptionsDialog(String imagePath, String title, String code, int index) async {
    String imageUrl = await _isValidImagePath(imagePath);
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 20),
                // ตัวเลือกต่างๆ
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.zoom_in, color: Colors.blue[600]),
                  ),
                  title: Text('ดูรูปภาพขนาดเต็ม'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showFullScreenImage(imageUrl, title);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.photo_library, color: Colors.green[600]),
                  ),
                  title: Text('เลือกจากแกลเลอรี'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _getImage(ImageSource.gallery, code, index);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.camera_alt, color: Colors.orange[600]),
                  ),
                  title: Text('ถ่ายภาพ'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _getImage(ImageSource.camera, code, index);
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ฟังก์ชั่นแสดงรูปแบบเต็มหน้าจอ
  void _showFullScreenImage(String imageUrl, String title) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Background ที่สามารถแตะเพื่อปิดได้
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
              // รูปภาพเต็มหน้าจอ
              Center(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: InteractiveViewer(
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

  // ฟังก์ชั่นสำหรับเลือกรูปจาก Gallery หรือ Camera
  Future<void> _getImage(ImageSource source, String code, int index) async {
    // ป้องกันการกดซ้ำขณะที่กำลังอัปโหลด
    if (isUploading) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 70, // ลดคุณภาพภาพเพื่อให้อัปโหลดเร็วขึ้น
      );
      
      if (pickedFile != null) {
        print("📷 เลือกรูปภาพแล้ว: ${pickedFile.path}");
        await _uploadImage(File(pickedFile.path), code, index);
      } else {
        print("❌ ไม่ได้เลือกรูปภาพ");
      }
    } catch (e) {
      print("❌ Error picking image: $e");
      _showErrorMessage("เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e");
    }
  }

  // ฟังก์ชั่นสำหรับอัปโหลดรูปภาพ
  Future<void> _uploadImage(File imageFile, String code, int index) async {
    // ตั้งค่า loading state
    setState(() {
      isUploading = true;
    });

    try {
      print("🚀 เริ่มอัปโหลดรูปภาพ...");
      // แทนที่ด้วย URL ของ API ที่เหมาะสม
      String url_checkFiles = '${Config.apiURL}/check_files_NewNAC';

      var request = http.MultipartRequest('POST', Uri.parse(url_checkFiles));
      
      // เพิ่ม headers (ต้องปรับแต่งตาม Config ที่ใช้งานจริง)
      // var headers = await Config.getAuthHeaders();
      // request.headers.addAll(headers);
      
      // เพิ่มไฟล์รูปภาพ
      var file = await http.MultipartFile.fromPath('file', imageFile.path);
      request.files.add(file);
      
      print("📤 ส่งคำขอไปยัง: $url_checkFiles");
      
      // ส่งคำขอพร้อม timeout
      var response = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('การอัปโหลดใช้เวลานานเกินไป');
        },
      );

      print("📡 Response status: ${response.statusCode}");
      
      // อ่าน response data ก่อน
      var responseData = await response.stream.bytesToString();
      print("📄 Response data: $responseData");

      if (response.statusCode == 200) {
        var jsonData = json.decode(responseData);
        
        if (jsonData['attach'] != null && jsonData['attach'].isNotEmpty) {
          String attValue = jsonData['attach'][0]['ATT'];
          String extension = jsonData['extension'];
          
          print("✅ อัปโหลดไฟล์สำเร็จ: $attValue.$extension");
          
          // อัปเดตข้อมูลในฐานข้อมูล
          await _updateAssetImage(code, index, attValue, extension);
        } else {
          print("❌ ไม่พบข้อมูล attach ใน response");
          _showDialog("การอัปโหลดล้มเหลว", "ไม่พบข้อมูล attach ใน response");
          setState(() {
            isUploading = false;
          });
        }
      } else {
        print("❌ Upload failed with status: ${response.statusCode}");
        
        // พยายาม parse JSON response แม้ว่าจะเป็น error
        try {
          var jsonData = json.decode(responseData);
          String errorMessage = jsonData['message'] ?? "ไม่สามารถอัปโหลดได้ในขณะนี้";
          _showDialog("การอัปโหลดล้มเหลว", errorMessage);
        } catch (e) {
          // ถ้า parse JSON ไม่ได้ ให้แสดงข้อความทั่วไป
          _showDialog("การอัปโหลดล้มเหลว", "เกิดข้อผิดพลาด: รหัสข้อผิดพลาด ${response.statusCode}");
        }
        setState(() {
          isUploading = false;
        });
      }
    } catch (e) {
      print("❌ Upload error: $e");
      _showDialog("เกิดข้อผิดพลาด", "ไม่สามารถอัปโหลดได้: $e");
      setState(() {
        isUploading = false;
      });
    }
  }

  // ฟังก์ชั่นสำหรับอัปเดตข้อมูลรูปภาพในฐานข้อมูล
  Future<void> _updateAssetImage(String code, int index, String attValue, String extension) async {
    try {
      print("🔄 กำลังอัปเดตข้อมูลภาพ...");
      
      var client = http.Client();
      // แทนที่ด้วย URL ของ API ที่เหมาะสม
      String url = '${Config.apiURL}/FA_Control_Edit_EBook';
      
      // ค้นหา asset ที่ตรงกับ code
      var matchingAssets = filteredAssets.where((res) {
        return res['Code']?.toLowerCase() == code.toLowerCase();
      }).toList();

      if (matchingAssets.isEmpty) {
        _showErrorMessage("ไม่พบทรัพย์สินที่ต้องการอัปเดต");
        return;
      }

      // กำหนดค่า image paths
      String? image1 = index == 0
          ? "https://nac.purethai.co.th/NEW_NAC/$attValue.$extension"
          : matchingAssets.first["ImagePath"];

      String? image2 = index == 1
          ? "https://nac.purethai.co.th/NEW_NAC/$attValue.$extension"
          : matchingAssets.first["ImagePath_2"];

      print("🖼️ Image 1: $image1");
      print("🖼️ Image 2: $image2");

      var responseImg = await client.post(
        Uri.parse(url),
        // headers: await Config.getAuthHeaders(),
        body: jsonEncode({
          "Code": code,
          "image_1": image1,
          "image_2": image2,
        }),
      );

      print("📊 Update response status: ${responseImg.statusCode}");
      print("📄 Update response body: ${responseImg.body}");

      if (responseImg.statusCode == 200) {
        print("✅ อัปเดตภาพสำเร็จ!");
        _showDialog("อัปโหลดสำเร็จ", "อัปโหลดรูปภาพเรียบร้อยแล้ว");
        
        // เปลี่ยนจาก isUploading เป็น isLoadingBehindUpload
        setState(() {
          isUploading = false;
          isLoadingBehindUpload = true;
        });
        
        // รีเฟรชข้อมูล (สำหรับการใช้งานจริง อาจต้องเรียก API ใหม่)
        await _fetchUpdatedData();
        
        setState(() {
          isLoadingBehindUpload = false;
        });
      } else {
        print("❌ อัปเดตล้มเหลว: ${responseImg.statusCode}");
        
        // พยายาม parse response เพื่อดู error message
        try {
          var updateJsonData = json.decode(responseImg.body);
          String updateErrorMessage = updateJsonData['message'] ?? "การอัปเดตภาพล้มเหลว";
          _showDialog("การอัปเดตล้มเหลว", updateErrorMessage);
        } catch (e) {
          _showDialog("การอัปเดตล้มเหลว", "รหัสข้อผิดพลาด: ${responseImg.statusCode}");
        }
        setState(() {
          isUploading = false;
        });
      }
    } catch (e) {
      print("❌ Update error: $e");
      _showDialog("เกิดข้อผิดพลาด", "ไม่สามารถอัปเดตภาพได้: $e");
      setState(() {
        isUploading = false;
      });
    }
  }

  // ฟังก์ชั่นสำหรับรีเฟรชข้อมูล (ต้องปรับแต่งตามการใช้งานจริง)
  Future<void> _fetchUpdatedData() async {
    // TODO: เรียก API เพื่อดึงข้อมูลใหม่
    // ตัวอย่าง: รีเฟรชหน้า หรือ เรียก API ใหม่
    await Future.delayed(Duration(seconds: 1)); // Simulate API call
  }

  // ฟังก์ชั่นสำหรับแสดง error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // ฟังก์ชั่นสำหรับแสดง dialog
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('ตกลง'),
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
}