import 'dart:convert';
import 'package:fa_mobile_app/CountedList.dart';
import 'package:fa_mobile_app/camera_count/qr_scanner_page.dart';
import 'package:fa_mobile_app/config.dart';
import 'package:fa_mobile_app/listMenu_II.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyPeriodInTime extends StatefulWidget {
  final String usercode, time, branchName;
  final int branchID;

  MyPeriodInTime(
      {required this.usercode,
      required this.time,
      required this.branchID,
      required this.branchName});

  @override
  _MyPeriodState createState() => _MyPeriodState();
}

class _MyPeriodState extends State<MyPeriodInTime> {
  List<dynamic> peroidItems = [];
  List<dynamic> filteredPeroid = [];
  bool isLoading = true; // To handle loading state
  TextEditingController searchController = TextEditingController();
  String depcodeMain = '';

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
    final prefs = await SharedPreferences.getInstance();
    String? userCode = prefs.getString('userCode');
    String? depcode = prefs.getString('depcode');

    String url = '${Config.apiURL}/period_round';

    // Prepare data as JSON
    Map request = {
      "BranchID": widget.branchID,
      "depCode": depcode,
      "personID": userCode,
    };

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: await Config.getAuthHeaders(),
        body: jsonEncode(request),
      );
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          try {
            var jsonData = json.decode(response.body);
            setState(() {
              peroidItems = jsonData;
              filteredPeroid = peroidItems.where((res) {
                DateTime beginDate = DateTime.parse(res['BeginDate']).toLocal();
                DateTime endDate = DateTime.parse(res['EndDate']).toLocal();
                DateTime currentTime = DateTime.now().toLocal();
                return currentTime.isAfter(beginDate) &&
                    currentTime.isBefore(endDate);
              }).toList();
              isLoading = false; // Data is loaded, set loading to false
              depcodeMain = depcode ?? '';
            });
          } catch (e) {
            print("JSON Decode Error: $e");
          }
        } else {
          print("Error: Response body is empty.");
        }
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
      filteredPeroid = peroidItems.where((asset) {
        String searchTerm = searchController.text.toLowerCase();
        return asset['Description']?.toLowerCase().contains(searchTerm) ==
                true ||
            asset['BeginDate']?.toLowerCase().contains(searchTerm) == true ||
            asset['EndDate']?.toLowerCase().contains(searchTerm) == true ||
            asset['BranchID']?.toLowerCase().contains(searchTerm) == true;
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
          'รอบตรวจที่อยู่ในช่วงเปิดใช้งาน',
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
              builder: (context) => MenuPageII(
                usercode: widget.usercode,
                time: widget.time,
                branchID: widget.branchID,
                branchName: widget.branchName,
                depcode: depcodeMain,
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
                      labelText: "ค้นหารอบตรวจนับ",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredPeroid.length,
                    itemBuilder: (context, index) {
                      String beginDate = "No Data Available";
                      String endDate = "No Data Available";
                      if (filteredPeroid[index]["BeginDate"] != null &&
                          filteredPeroid[index]["BeginDate"]
                              .toString()
                              .isNotEmpty) {
                        try {
                          beginDate = DateFormat('yyyy-MM-dd HH:mm').format(
                              DateTime.parse(filteredPeroid[index]["BeginDate"])
                                  .toLocal());
                        } catch (_) {
                          beginDate = "Invalid Date Format";
                        }
                      }
                      if (filteredPeroid[index]["EndDate"] != null &&
                          filteredPeroid[index]["EndDate"]
                              .toString()
                              .isNotEmpty) {
                        try {
                          endDate = DateFormat('yyyy-MM-dd HH:mm').format(
                              DateTime.parse(filteredPeroid[index]["EndDate"])
                                  .toLocal());
                        } catch (_) {
                          endDate = "Invalid Date Format";
                        }
                      }
                      return Card(
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        elevation: 3,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side:
                              BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        shadowColor: Colors.grey.withAlpha(127),
                        child: InkWell(
                          onTap: () {
                            _showPeroidIDDialog(
                              context,
                              widget.usercode, // ใช้การตรวจสอบและแปลงค่า
                              widget.time,
                              depcodeMain,
                              int.parse(filteredPeroid[index]["PeriodID"]),
                              widget.branchID,
                              widget.branchName,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoText("คำอธิบาย: ",
                                    filteredPeroid[index]["Description"]),
                                _buildInfoText("วันที่เริ่มต้น: ", beginDate),
                                _buildInfoText("วันที่สิ้นสุด: ", endDate),
                                _buildInfoText(
                                    "สถานที่ตรวจนับ: ", widget.branchName),
                              ],
                            ),
                          ),
                        ),
                      );
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
}

void _showPeroidIDDialog(BuildContext context, String usercode, String time,
    String depcode, int peroioID, int branchID, String branchName) {
  if (peroioID > 0) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerCountPage(
          usercode: usercode,
          time: time,
          depcode: depcode,
          peroioID: peroioID,
          branchID: branchID,
          branchName: branchName,
        ),
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("เกิดข้อผิดพลาด"),
          content: Text("ไม่พบ PeroidID"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text("ปิด"),
            ),
          ],
        );
      },
    );
  }
}
