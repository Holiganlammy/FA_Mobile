import 'package:fa_mobile_app/camera_count/ListPeroid_in_time.dart';
import 'package:fa_mobile_app/listMenu.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fa_mobile_app/Peroid.dart';

class MenuPageII extends StatefulWidget {
  final String usercode, time, branchName, depcode;
  final int branchID;
  const MenuPageII(
      {required this.usercode,
      required this.time,
      Key? key,
      required this.branchID,
      required this.branchName,
      required this.depcode})
      : super(key: key);

  @override
  _MenuPageIIState createState() => _MenuPageIIState();
}

class _MenuPageIIState extends State<MenuPageII> {
  String? selectedAssetOption;
  List<dynamic> dataBranchList = [];

  final List<Map<String, String>> menuItems = [
    {
      'title': 'สแกนตรวจนับทรัพย์สิน',
      'subtitle': 'Scan QR Code to Count Asset.',
      'icon': 'qr_code'
    },
    {
      'title': 'รายงานการตรวจนับทรัพย์สิน',
      'subtitle': 'Report Assets Counted.',
      'icon': 'report'
    },
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: Text('Menu List 2 (${widget.branchName})',
            style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MenuPage(
                usercode: widget.usercode,
                depcode: widget.time,
                time: widget.time,
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            backgroundColor: Colors.teal.shade700,
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
      case 'สแกนตรวจนับทรัพย์สิน':
        _navigateTo(MyPeriodInTime(
          usercode: widget.usercode,
          time: widget.time,
          branchID: widget.branchID,
          branchName: widget.branchName,
        ));
        break;
      case 'รายงานการตรวจนับทรัพย์สิน':
        _navigateTo(MyPeriod(
          usercode: widget.usercode,
          time: widget.time,
          branchID: widget.branchID,
          branchName: widget.branchName,
        ));
        break;
    }
  }

  void _navigateTo(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'qr_code':
        return Icons.qr_code;
      case 'account_circle':
        return Icons.account_circle;
      case 'verified':
        return Icons.verified;
      case 'report':
        return Icons.report;
      default:
        return Icons.help;
    }
  }
}
