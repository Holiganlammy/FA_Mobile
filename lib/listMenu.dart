import 'dart:convert';
import 'package:fa_mobile_app/camera_check/qr_scanner_page.dart';
import 'package:fa_mobile_app/listMenu_II.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fa_mobile_app/MyAssets.dart';
import 'package:fa_mobile_app/config.dart';
import 'package:fa_mobile_app/Login.dart';
import 'package:fa_mobile_app/services/httpService.dart';
import 'package:fa_mobile_app/changePassword.dart';

class MenuPage extends StatefulWidget {
  final String usercode;
  final String depcode;
  final String time;

  const MenuPage({
    Key? key,
    required this.usercode,
    required this.depcode,
    required this.time,
  }) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int? selectedAssetOption;
  List<dynamic> dataBranchList = [];

  final List<Map<String, String>> menuItems = [
    {
      'title': 'ตรวจนับทรัพย์สิน',
      'subtitle': 'Go to Count Assets.',
      'icon': 'qr_code'
    },
    {
      'title': 'ทรัพย์สินทั้งหมดของฉัน',
      'subtitle': 'View My Assets.',
      'icon': 'account_circle'
    },
    {
      'title': 'ตรวจสอบคิวอาร์โค้ด',
      'subtitle': 'Verify QR Code.',
      'icon': 'verified'
    },
    {
      'title': 'เปลี่ยนรหัสผ่าน',
      'subtitle': 'Change Password.',
      'icon': 'lock'
    },
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: Text('Menu List',
            style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => LoginPage())),
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text('Welcome, ${widget.usercode}! (${widget.time})',
                style: TextStyle(
                    fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) => _buildMenuItem(menuItems[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(Map<String, String> item) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
            backgroundColor: const Color.fromRGBO(0, 121, 107, 1),
            child: Icon(_getIcon(item['icon']!), color: Colors.white)),
        title:
            Text(item['title']!, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(item['subtitle']!),
        onTap: () => _handleMenuTap(item['title']!),
      ),
    );
  }

  void _handleMenuTap(String title) {
    switch (title) {
      case 'ตรวจนับทรัพย์สิน':
        _permissionBranch();
        break;
      case 'ตรวจสอบคิวอาร์โค้ด':
        _navigateTo(QRScannerPage(
          usercode: widget.usercode,
          time: widget.time,
          depcode: widget.depcode,
        ));
        break;
      case 'ทรัพย์สินทั้งหมดของฉัน':
        _navigateTo(MyAssets(
          usercode: widget.usercode,
          time: widget.time,
          depcode: widget.depcode,
        ));
        break;
      case 'เปลี่ยนรหัสผ่าน':
        _navigateTo(ChangePasswordPage(
          usercode: widget.usercode,
          time: widget.time,
          depcode: widget.depcode,
        ));
        break;
    }
  }

  void _navigateTo(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> _permissionBranch() async {
    try {
      var response = await HttpWithAuth.post(
        context: context,
        url: Uri.parse('${Config.apiURL}/permission_branch'),
        headers: await Config.getAuthHeaders(),
        body: jsonEncode({'userCode': widget.usercode}),
      );
      if (response.statusCode == 200) {
        setState(() => dataBranchList = jsonDecode(response.body)['data']);
        _showDropdown(context);
      } else {
        _showDialog('ผิดพลาด', 'ข้อมูลไม่ถูกต้อง');
      }
    } catch (e) {
      _showDialog('ข้อผิดพลาด', 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้');
    }
  }

  void _showDropdown(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int? tempSelectedOption = selectedAssetOption; // ใช้ตัวแปรชั่วคราว

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("เลือกสาขาที่ต้องการ"),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height *
                        0.6, // สูงสุด 60% ของหน้าจอ
                    maxWidth: MediaQuery.of(context).size.width *
                        0.9, // กว้างสุด 90% ของหน้าจอ
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<int>(
                        value: tempSelectedOption,
                        hint: Text('เลือกตรวจนับทรัพย์สิน'),
                        items: dataBranchList.map((option) {
                          int branchID = option["BranchID"];
                          return DropdownMenuItem<int>(
                            value: branchID,
                            child: Text(option["Name"] ?? "สาขา $branchID"),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setStateDialog(() {
                            tempSelectedOption = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("ยกเลิก"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedAssetOption = tempSelectedOption; // อัปเดตค่าหลัก
                    });
                    if (selectedAssetOption != null) {
                      // ค้นหาชื่อสาขาจาก BranchID ที่เลือก
                      final selectedBranch = dataBranchList.firstWhere(
                          (res) => res["BranchID"] == selectedAssetOption!,
                          orElse: () => {
                                "Name": "ไม่พบชื่อสาขา"
                              } // ป้องกัน error ถ้าไม่มีค่า match
                          );
                      Navigator.pop(context); // ปิด Dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MenuPageII(
                            usercode: widget.usercode,
                            time: widget.time,
                            branchID:
                                selectedAssetOption!, // ส่งค่า BranchID (int)
                            branchName: selectedBranch["Name"],
                            depcode: widget.depcode, // ส่งชื่อสาขาไปด้วย
                          ),
                        ),
                      );
                    } else {
                      Navigator.pop(context); // ปิด Dialog
                      _showDialog("แจ้งเตือน", "กรุณาเลือกสาขาก่อนกดยืนยัน!");
                    }
                  },
                  child: Text("ยืนยัน"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              child: Text('OK'), onPressed: () => Navigator.of(context).pop())
        ],
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'qr_code':
        return Icons.qr_code;
      case 'account_circle':
        return Icons.account_circle;
      case 'verified':
        return Icons.verified;
      case 'lock':
        return Icons.lock;
      case 'report':
        return Icons.report;
      default:
        return Icons.help;
    }
  }
}