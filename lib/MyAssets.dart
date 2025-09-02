import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fa_mobile_app/config.dart';
import 'package:fa_mobile_app/listMenu.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:fa_mobile_app/services/httpService.dart';

class MyAssets extends StatefulWidget {
  final String usercode;
  final String time;
  final String depcode;

  MyAssets({required this.usercode, required this.time, required this.depcode});

  @override
  _MyAssetsState createState() => _MyAssetsState();
}

class _MyAssetsState extends State<MyAssets> {
  List<dynamic> assetsItems = [];
  List<dynamic> filteredAssets = [];
  bool isLoading = true;
  bool isUploading = false; // เพิ่ม loading state สำหรับการอัปโหลด
  bool isLoadingBehindUpload = false; // loading state หลังอัปโหลด
  TextEditingController searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchAssetsData();
    searchController.addListener(() {
      filterAssets();
    });
  }

  Future<void> _fetchAssetsData() async {
    String url = '${Config.apiURL}/FA_Control_Fetch_Assets';

    Map<String, String> request = {
      "usercode": widget.usercode,
    };

    try {
      var response = await HttpWithAuth.post(
        context: context,
        url: Uri.parse(url),
        headers: await Config.getAuthHeaders(),
        body: jsonEncode(request),
      );

      if (response.statusCode == 200) {
        List<dynamic> responseData = json
            .decode(response.body)
            .where((asset) =>
                asset['OwnerID']?.toString().toLowerCase() == widget.usercode)
            .toList();

        print("✅ Success: ${responseData}");
        setState(() {
          assetsItems = responseData;
          filteredAssets = assetsItems;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print("Error fetching data: ${response.statusCode}");
        _showErrorMessage("เกิดข้อผิดพลาดในการโหลดข้อมูล: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
      _showErrorMessage("เกิดข้อผิดพลาด: $e");
    }
  }

  void filterAssets() {
    setState(() {
      filteredAssets = assetsItems.where((asset) {
        String searchTerm = searchController.text.toLowerCase();
        return asset['Code']?.toLowerCase().contains(searchTerm) == true ||
            asset['Name']?.toLowerCase().contains(searchTerm) == true ||
            asset['SerialNo']?.toLowerCase().contains(searchTerm) == true ||
            asset['OwnerID']?.toLowerCase().contains(searchTerm) == true;
      }).toList();
    });
  }

  // เพิ่มฟังก์ชันแสดงข้อความผิดพลาด
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // เพิ่มฟังก์ชันแสดงข้อความสำเร็จ
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // เพิ่มฟังก์ชันแสดง Dialog
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: title.contains('สำเร็จ') ? Colors.green : Colors.red,
            ),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'ตกลง',
                style: TextStyle(color: Colors.blue),
              ),
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
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 48, 96, 96),
        title: Text(
          'ทรัพย์สินของฉัน (${filteredAssets.length})',
          style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        leading: IconButton(
          color: Colors.white,
          icon: Icon(Icons.arrow_back),
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
      backgroundColor: Color.fromARGB(255, 246, 246, 246),
      // เพิ่ม Loading Overlay สำหรับการอัปโหลด
      body: Stack(
        children: [
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: "ค้นหาทรัพย์สิน",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredAssets.length,
                        itemBuilder: (context, indexList) {
                          List<String> listImage = [
                            filteredAssets[indexList]["ImagePath"].toString(),
                            filteredAssets[indexList]["ImagePath_2"].toString()
                          ];
                          String createDate = "No Data Available";
                          if (filteredAssets[indexList]["CreateDate"] != null &&
                              filteredAssets[indexList]["CreateDate"]
                                  .toString()
                                  .isNotEmpty) {
                            try {
                              createDate = DateFormat('yyyy-MM-dd').format(
                                  DateTime.parse(filteredAssets[indexList]
                                          ["CreateDate"])
                                      .toLocal());
                            } catch (_) {
                              createDate = "Invalid Date Format";
                            }
                          }
                          return Card(
                              margin: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              elevation: 3,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: Colors.grey.shade300, width: 1),
                              ),
                              shadowColor: Colors.grey.withAlpha(127),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
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
                                            String imageUrl = snapshot.data ??
                                                'https://thumb.ac-illust.com/b1/b170870007dfa419295d949814474ab2_t.jpeg';
                                            return InkWell(
                                              onTap: () => _pickImage(
                                                  filteredAssets[indexList]['Code'],
                                                  index),
                                              child: Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(10.0),
                                                    child: CachedNetworkImage(
                                                      imageUrl: imageUrl,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      placeholder: (context, url) =>
                                                          const Center(
                                                              child:
                                                                  CircularProgressIndicator()),
                                                      errorWidget: (context, url,
                                                              error) =>
                                                          _buildPlaceholderImage(),
                                                    ),
                                                  ),
                                                  // เพิ่มไอคอนกล้องเพื่อบอกว่าสามารถกดได้
                                                  Positioned(
                                                    bottom: 5,
                                                    right: 5,
                                                    child: Container(
                                                      padding: EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black54,
                                                        borderRadius: BorderRadius.circular(15),
                                                      ),
                                                      child: Icon(
                                                        Icons.camera_alt,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    _buildInfoText("รหัสทรัพย์สิน: ",
                                        filteredAssets[indexList]["Code"]),
                                    _buildInfoText("ชื่อทรัพย์สิน: ",
                                        filteredAssets[indexList]["Name"]),
                                    _buildInfoText("SerialNo: ",
                                        filteredAssets[indexList]["SerialNo"]),
                                    _buildInfoText("ผู้ถือครอง: ",
                                        "${filteredAssets[indexList]["OwnerID"] ?? ""} (${filteredAssets[indexList]["Position"] ?? "No Data"})"),
                                    _buildInfoText("สถานะปัจจุบัน: ",
                                        filteredAssets[indexList]["Details"]),
                                    _buildInfoText("วันที่ขึ้นทะเบียน: ", createDate),
                                  ],
                                ),
                              ));
                        },
                      ),
                    ),
                  ],
                ),
          // Loading overlay สำหรับการอัปโหลด
          if (isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'กำลังอัปโหลดรูปภาพ...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          if (isLoadingBehindUpload)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'กำลังดึงรูปภาพที่อัพโหลด...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoText(String title, dynamic value) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Text(
        value != null && value.toString().isNotEmpty
            ? "$title$value"
            : "$title No Data Available",
        style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: screenWidth * 0.035,
            color: Colors.black),
      ),
    );
  }

  Future<void> _pickImage(String code, int index) async {
    // ป้องกันการกดซ้ำขณะที่กำลังอัปโหลด
    if (isUploading) return;
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('เลือกจากแกลเลอรี'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _getImage(ImageSource.gallery, code, index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('ถ่ายภาพ'),
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

  Future<void> _uploadImage(File imageFile, String code, int index) async {
    // ตั้งค่า loading state
    setState(() {
      isUploading = true;
    });

    try {
      print("🚀 เริ่มอัปโหลดรูปภาพ...");
      String url_checkFiles = '${Config.apiURL}/check_files_NewNAC';

      var request = http.MultipartRequest('POST', Uri.parse(url_checkFiles));
      
      // เพิ่ม headers
      var headers = await Config.getAuthHeaders();
      request.headers.addAll(headers);
      
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

  Future<void> _updateAssetImage(String code, int index, String attValue, String extension) async {
    try {
      print("🔄 กำลังอัปเดตข้อมูลภาพ...");
      
      var client = http.Client();
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
        headers: await Config.getAuthHeaders(),
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
        
        // รีเฟรชข้อมูล
        await _fetchAssetsData();
        filterAssets();
        
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
      }
    } catch (e) {
      print("❌ Update error: $e");
      _showDialog("เกิดข้อผิดพลาด", "ไม่สามารถอัปเดตภาพได้: $e");
    }
  }
}

Future<String> _isValidImagePath(String? imagePath) async {
  if (imagePath == null || imagePath.isEmpty) {
    return 'https://thumb.ac-illust.com/b1/b170870007dfa419295d949814474ab2_t.jpeg';
  }
  try {
    // แทนที่โดเมน
    imagePath = imagePath.replaceAll("vpnptec.dyndns.org", "10.15.100.227");
    final uri = Uri.parse(imagePath);
    if (!uri.isAbsolute) {
      return 'https://thumb.ac-illust.com/b1/b170870007dfa419295d949814474ab2_t.jpeg';
    }
    
    // เพิ่ม timeout สำหรับการตรวจสอบรูปภาพ
    final response = await http.head(uri).timeout(
      Duration(seconds: 10),
      onTimeout: () => http.Response('', 404),
    );
    
    if (response.statusCode == 200) return imagePath;
  } catch (e) {
    print("❌ Image validation error: $e");
  }
  return 'https://thumb.ac-illust.com/b1/b170870007dfa419295d949814474ab2_t.jpeg';
}

Widget _buildPlaceholderImage() {
  return Container(
    color: Colors.grey[300],
    child: const Icon(Icons.broken_image, size: 50, color: Colors.white),
  );
}