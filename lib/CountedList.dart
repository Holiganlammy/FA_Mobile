import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fa_mobile_app/Peroid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fa_mobile_app/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Countedlist extends StatefulWidget {
  final String usercode;
  final String time;
  final int branchID;
  final String branchName;
  final String description;
  final String beginDate;
  final String endDate;
  final int periodID;

  Countedlist(
      {required this.usercode,
      required this.time,
      required this.description,
      required this.branchID,
      required this.branchName,
      required this.beginDate,
      required this.endDate,
      required this.periodID});

  @override
  _CountedlistState createState() => _CountedlistState();
}

class _CountedlistState extends State<Countedlist> {
  List<dynamic> assetsItems = [];
  List<dynamic> filteredAssets = [];
  bool isLoading = true; // To handle loading state
  TextEditingController searchController = TextEditingController();
  String statusFilter =
      'ตรวจนับแล้ว'; // To store the selected filter ("ตรวจนับแล้ว" or "ยังไม่ได้ตรวจนับ")
  List<dynamic> radioListOptions = [
    'สภาพดี',
    'ชำรุดรอซ่อม',
    'รอตัดขาย',
    'รอตัดชำรุด',
    'อื่น ๆ'
  ];

  List<dynamic> radioListOptionsII = [
    'QR Code ไม่สมบูรณ์ (สภาพดี)',
    'QR Code ไม่สมบูรณ์ (ชำรุดรอซ่อม)',
    'QR Code ไม่สมบูรณ์ (รอตัดขาย)',
    'QR Code ไม่สมบูรณ์ (รอตัดชำรุด)',
  ];
  final ImagePicker _picker = ImagePicker();
  String selectedValue = '';

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
    String url =
        '${Config.apiURL}/FA_Control_Report_All_Counted_by_Description';

    // Prepare data as JSON
    Map<String, String> request = {
      "Description": widget.description,
    };

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: await Config.getAuthHeaders(),
        body: jsonEncode(request),
      );

      if (response.statusCode == 200) {
        List<dynamic> responseData = json
            .decode(response.body)
            .where((asset) => asset['BranchID'] == widget.branchID)
            .toList();

        setState(() {
          assetsItems = responseData;
          filteredAssets = assetsItems.where((asset) {
            bool matchesSearchTerm =
                asset['remarker']?.toLowerCase().contains(statusFilter) == true;
            return matchesSearchTerm;
          }).toList();
          ; // Initially, no filter
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
      String searchTerm = searchController.text.toLowerCase();

      filteredAssets = assetsItems.where((asset) {
        bool matchesSearchTerm =
            asset['Code']?.toLowerCase().contains(searchTerm) == true ||
                asset['Name']?.toLowerCase().contains(searchTerm) == true ||
                asset['SerialNo']?.toLowerCase().contains(searchTerm) == true ||
                asset['Date']?.toLowerCase().contains(searchTerm) == true ||
                asset['OwnerID']?.toLowerCase().contains(searchTerm) == true ||
                asset['typeCode']?.toLowerCase().contains(searchTerm) == true ||
                asset['Reference']?.toLowerCase().contains(searchTerm) ==
                    true ||
                asset['remarker']?.toLowerCase().contains(searchTerm) == true;

        bool matchesStatus = statusFilter == 'ตรวจนับแล้ว'
            ? asset['Status'] == true
            : statusFilter == 'ยังไม่ได้ตรวจนับ'
                ? asset['Status'] == false
                : true; // ถ้า statusFilter เป็น null จะผ่านเงื่อนไขทั้งหมด

        return matchesSearchTerm && matchesStatus;
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
              builder: (context) => MyPeriod(
                usercode: widget.usercode,
                time: widget.time,
                branchID: widget.branchID,
                branchName: widget.branchName,
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
                // Filter Radio Buttons for Status
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'ตรวจนับแล้ว',
                        groupValue: statusFilter,
                        onChanged: (value) {
                          setState(() {
                            statusFilter = value!;
                            filterAssets(); // Apply filter after selection
                          });
                        },
                      ),
                      Text(
                        "ตรวจนับแล้ว (${assetsItems.where((asset) => asset['Status'] == true).length})",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: screenWidth * 0.035,
                          color: Colors.black,
                        ),
                      ),
                      Radio<String>(
                        value: 'ยังไม่ได้ตรวจนับ',
                        groupValue: statusFilter,
                        onChanged: (value) {
                          setState(() {
                            statusFilter = value!;
                            filterAssets(); // Apply filter after selection
                          });
                        },
                      ),
                      Text(
                        "ยังไม่ได้ตรวจนับ (${assetsItems.where((asset) => asset['Status'] == false).length})",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: screenWidth * 0.035,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                // Search TextField
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredAssets.length,
                    itemBuilder: (context, indexList) {
                      List<String> listImage = [
                        filteredAssets[indexList]["ImagePath"].toString(),
                        filteredAssets[indexList]["ImagePath_2"].toString()
                      ];
                      String date = "No Data Available";
                      if (filteredAssets[indexList]["Date"] != null &&
                          filteredAssets[indexList]["Date"]
                              .toString()
                              .isNotEmpty) {
                        try {
                          date = DateFormat('yyyy-MM-dd').format(
                              DateTime.parse(filteredAssets[indexList]["Date"])
                                  .toLocal());
                        } catch (_) {
                          date = "Invalid Date Format";
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
                                              index,
                                              indexList,
                                              () => setState(() {})),
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
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, left: 8.0, right: 8.0),
                                  child: Row(
                                    children: [
                                      // Widget ที่ชิดซ้าย
                                      Text(
                                        filteredAssets[indexList]['Code'],
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            //fontStyle: FontStyle.italic,
                                            fontSize: screenWidth * 0.05,
                                            color: Colors.black),
                                      ),
                                      // Spacer เพื่อเพิ่มช่องว่าง
                                      const Spacer(),
                                      // Widget ที่ชิดขวา
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.black),
                                        onPressed: () {
                                          print(filteredAssets[indexList]
                                              ['Status']);
                                          if (filteredAssets[indexList]
                                                  ['Status'] ==
                                              true) {
                                            showReferenceDialog(
                                                context,
                                                indexList,
                                                filteredAssets,
                                                radioListOptions,
                                                () => setState(() {}));
                                          } else if (filteredAssets[indexList]
                                                  ['Status'] ==
                                              false) {
                                            showReferenceNewCountedDialog(
                                                context,
                                                indexList,
                                                filteredAssets,
                                                radioListOptionsII,
                                                () => setState(() {}));
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  child: Divider(
                                    color: Colors.black,
                                    thickness: 1,
                                    height: 5,
                                  ),
                                ),
                                _buildInfoText("ชื่อทรัพย์สิน: ",
                                    filteredAssets[indexList]["Name"]),
                                _buildInfoText("SerialNo: ",
                                    filteredAssets[indexList]["SerialNo"]),
                                _buildInfoText("ผู้ถือครอง: ",
                                    "${filteredAssets[indexList]["OwnerID"] ?? ""}"),
                                _buildInfoText("ประเภท: ",
                                    filteredAssets[indexList]["typeCode"]),
                                _buildInfoText("สถานะปัจจุบัน: ",
                                    filteredAssets[indexList]["detail"]),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  child: Divider(
                                    color: Colors.black,
                                    thickness: 1,
                                    height: 5,
                                  ),
                                ),
                                _buildInfoText("ผู้ตรวจนับ: ",
                                    filteredAssets[indexList]["UserID"]),
                                _buildInfoText("วันที่ตรวจนับ: ", date),
                                _buildInfoText("สถานะครั้งนี้: ",
                                    filteredAssets[indexList]["Reference"]),
                                _buildInfoText("หมายเหตุ: ",
                                    filteredAssets[indexList]["remarker"]),
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

  Future<void> _pickImage(
      String code, int index, int assetIndex, Function setStateCallback) async {
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
                  await _getImage(ImageSource.gallery, code, index, assetIndex,
                      setStateCallback);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('ถ่ายภาพ'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _getImage(ImageSource.camera, code, index, assetIndex,
                      setStateCallback);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source, String code, int index,
      int assetIndex, Function setStateCallback) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (pickedFile != null) {
      await _uploadImage(
          File(pickedFile.path), code, index, assetIndex, setStateCallback);
    }
  }

  Future<void> _uploadImage(File imageFile, String code, int index,
      int assetIndex, Function setStateCallback) async {
    String url_checkFiles = '${Config.apiURL}/check_files_NewNAC';

    var request = http.MultipartRequest('POST', Uri.parse(url_checkFiles));
    var file = await http.MultipartFile.fromPath('file', imageFile.path);
    request.files.add(file);
    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (jsonData['attach'] != null && jsonData['attach'].isNotEmpty) {
        String attValue = jsonData['attach'][0]['ATT'];
        String extension = jsonData['extension'];
        String imageUrl =
            "https://nac.purethai.co.th/NEW_NAC/$attValue.$extension";

        var client = http.Client();
        var url = Uri.parse('${Config.apiURL}/FA_Mobile_UploadImage');

        await client.post(
          url,
          headers: await Config.getAuthHeaders(),
          body: jsonEncode({
            "Code": code,
            "RoundID": widget.periodID,
            "index": index,
            "url": imageUrl,
          }),
        );

        // ✅ อัปเดตค่า ImagePath หรือ ImagePath_2 ใน filteredAssets
        if (index == 0) {
          filteredAssets[assetIndex]['ImagePath'] = imageUrl;
        } else if (index == 1) {
          filteredAssets[assetIndex]['ImagePath_2'] = imageUrl;
        }

        // ✅ ใช้ setStateCallback เพื่ออัปเดต UI
        setStateCallback();

        print("✅ อัปโหลดสำเร็จ! Image URL: $imageUrl");
      } else {
        _showDialog('แจ้งเตือน', '❌ อัปโหลดล้มเหลว! กรุณาลองใหม่อีกครั้ง');
      }
    }
  }

  Future<void> showReferenceDialog(
      BuildContext context,
      int index,
      List<dynamic> filteredAssets,
      List<dynamic> radioListOptions,
      Function setStateCallback) async {
    String selectedOption =
        filteredAssets[index]['Reference'] ?? "ยังไม่ได้ตรวจนับ";
    // แปลง String เป็น DateTime
    DateTime beginDate = DateTime.parse(widget.beginDate).toLocal();
    DateTime endDate = DateTime.parse(widget.endDate).toLocal();
    DateTime currentTime = DateTime.now().toLocal();

    // ตรวจสอบช่วงเวลา
    if (beginDate.isBefore(currentTime) && currentTime.isBefore(endDate)) {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (radioListOptionsII
                              .contains(filteredAssets[index]['Reference'])
                          ? radioListOptionsII
                          : radioListOptions)
                      .map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: selectedOption,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedOption = value;
                        });
                      },
                    );
                  }).toList(),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      SharedPreferences pref =
                          await SharedPreferences.getInstance();
                      String url = '${Config.apiURL}/updateReference';

                      var response = await http.post(
                        Uri.parse(url),
                        headers: await Config.getAuthHeaders(),
                        body: jsonEncode({
                          "Reference": selectedOption,
                          "Code": filteredAssets[index]['Code'],
                          "RoundID": filteredAssets[index]['RoundID'],
                          "UserID": pref.getString("userid"),
                          "BranchID": filteredAssets[index]['BranchID'],
                          "Date": DateTime.now().toLocal().toString(),
                        }),
                      );
                      if (response.statusCode == 200) {
                        // ✅ อัปเดตค่าของ filteredAssets[index]['Reference']
                        filteredAssets[index]['Reference'] = selectedOption;

                        // ✅ รีเฟรช UI โดยเรียก setState ที่ส่งมาจาก parent
                        setStateCallback();
                        Navigator.of(context).pop();
                      } else {
                        print("error ${response.body}");
                      }
                    },
                    child: const Text('บันทึก'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('ยกเลิก'),
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      // แสดงข้อความแจ้งเตือนหากอยู่นอกช่วงเวลาที่กำหนด
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('ไม่สามารถแก้ไขข้อมูลได้ เนื่องจากอยู่นอกช่วงเวลาที่กำหนด'),
        ),
      );
    }
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

  Future<void> showReferenceNewCountedDialog(
      BuildContext context,
      int index,
      List<dynamic> filteredAssets,
      List<dynamic> radioListOptions,
      Function setStateCallback) async {
    String selectedOption =
        filteredAssets[index]['Reference'] ?? "ยังไม่ได้ตรวจนับ";

    DateTime beginDate = DateTime.parse(widget.beginDate).toLocal();
    DateTime endDate = DateTime.parse(widget.endDate).toLocal();
    DateTime currentTime = DateTime.now().toLocal();

    if (beginDate.isBefore(currentTime) && currentTime.isBefore(endDate)) {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: radioListOptions.map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: selectedOption,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedOption = value;
                        });
                      },
                    );
                  }).toList(),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      SharedPreferences pref =
                          await SharedPreferences.getInstance();
                      String url = '${Config.apiURL}/addAsset';

                      var response = await http.post(
                        Uri.parse(url),
                        headers: await Config.getAuthHeaders(),
                        body: jsonEncode({
                          "Name": filteredAssets[index]['Name'],
                          "Code": filteredAssets[index]['Code'],
                          "BranchID": filteredAssets[index]['BranchID'],
                          "Date": DateTime.now().toLocal().toString(),
                          "UserBranch": widget.branchID,
                          "Reference": selectedOption,
                          "Status": 1,
                          "RoundID": filteredAssets[index]['RoundID'],
                          "UserID": pref.getString("userid"),
                        }),
                      );

                      if (response.statusCode == 200) {
                        _fetchAssetsData();
                        filterAssets();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    child: const Text('บันทึก'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('ยกเลิก'),
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('ไม่สามารถแก้ไขข้อมูลได้ เนื่องจากอยู่นอกช่วงเวลาที่กำหนด'),
        ),
      );
    }
  }

  Widget _buildInfoText(String title, dynamic value) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Define the color for "ตรวจนับแล้ว" and "ยังไม่ได้ตรวจนับ"
    Color statusColor = (value == 'ตรวจนับแล้ว')
        ? Colors.green
        : (value == 'ยังไม่ได้ตรวจนับ')
            ? Colors.red
            : (value == 'ต่างสาขา')
                ? Colors.orangeAccent
                : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: RichText(
        text: TextSpan(
          text: title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: screenWidth * 0.035,
            color: Colors.black,
          ),
          children: [
            TextSpan(
              text: value != null && value.toString().isNotEmpty
                  ? value
                  : 'No Data Available',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: screenWidth * 0.035,
                color: statusColor, // Apply color conditionally
              ),
            ),
          ],
        ),
      ),
    );
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
