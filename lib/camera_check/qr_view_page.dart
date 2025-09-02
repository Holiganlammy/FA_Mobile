import 'package:fa_mobile_app/listMenu.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

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
                              onTap: () => _showImageDialog(listImage[index], "รูปภาพทรัพย์สิน ${index + 1}"),
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
                                          // ไอคอนแสดงว่าสามารถดูได้
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
    );
  }

  // ฟังก์ชั่นแสดงรูปแบบเต็มหน้าจอ
  void _showImageDialog(String imagePath, String title) async {
    String imageUrl = await _isValidImagePath(imagePath);
    
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