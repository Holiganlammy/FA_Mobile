import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fa_mobile_app/config.dart';
import 'package:fa_mobile_app/listMenu.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
  bool isLoading = true; // To handle loading state
  TextEditingController searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchAssetsData(); // Fetch data from API when the widget is initialized

    // Add a listener to filter assets whenever the search query changes
    searchController.addListener(() {
      filterAssets();
    });
  }

  Future<void> _fetchAssetsData() async {
    String url = '${Config.apiURL}/FA_Control_Fetch_Assets';

    // Prepare data as JSON
    Map<String, String> request = {
      "usercode": widget.usercode,
    };

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: Config.headers,
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
          filteredAssets = assetsItems; // Initially, no filter
          isLoading = false; // Data is loaded, set loading to false
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print("Error fetching data: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  // Function to filter assets based on search input
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
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Show loading indicator while fetching data
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                              DateTime.parse(
                                      filteredAssets[indexList]["CreateDate"])
                                  .toLocal());
                        } catch (_) {
                          createDate = "Invalid Date Format";
                        }
                      }
                      return Card(
                          margin:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                                      future:
                                          _isValidImagePath(listImage[index]),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        }
                                        String imageUrl = snapshot.data ??
                                            'https://thumb.ac-illust.com/b1/b170870007dfa419295d949814474ab2_t.jpeg';
                                        return InkWell(
                                          onTap: () => _pickImage(
                                              filteredAssets[indexList]['Code'],
                                              index),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            child: CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                      child:
                                                          CircularProgressIndicator()),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      _buildPlaceholderImage(),
                                            ),
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
                                _buildInfoText(
                                    "วันที่ขึ้นทะเบียน: ", createDate),
                              ],
                            ),
                          ));
                    },
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
        String url = '${Config.apiURL}/FA_Control_Edit_EBook';
        // 🔹 ค้นหา asset ที่ตรงกับ `code`
        var matchingAssets = filteredAssets.where((res) {
          return res['Code']?.toLowerCase() == code.toLowerCase();
        }).toList(); // ✅ ป้องกัน Iterable error

        // 🔹 กำหนดค่าเริ่มต้นเป็น null ถ้าไม่มีข้อมูล
        String? image1 = index == 0
            ? "http://vpnptec.dyndns.org:33080/NEW_NAC/$attValue.$extension"
            : (matchingAssets.isNotEmpty
                ? matchingAssets.first["ImagePath"]
                : null);

        String? image2 = index == 1
            ? "http://vpnptec.dyndns.org:33080/NEW_NAC/$attValue.$extension"
            : (matchingAssets.isNotEmpty
                ? matchingAssets.first["ImagePath_2"]
                : null);

        var responseImg = await client.post(
          Uri.parse(url), // ✅ ใช้ Uri.parse() สำหรับ URL เต็ม
          headers: Config.headers,
          body: jsonEncode({
            "Code": code,
            "image_1": image1, // ✅ ป้องกัน null
            "image_2": image2,
          }),
        );
        if (responseImg.statusCode == 200) {
          _fetchAssetsData();
          filterAssets();
        }
        print("✅ อัปโหลดสำเร็จ!");
      } else {
        print("❌ อัปโหลดล้มเหลว!");
      }
    }
  }
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
