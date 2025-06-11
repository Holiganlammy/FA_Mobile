import 'package:fa_mobile_app/listMenu.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class QRViewPage extends StatefulWidget {
  final List<dynamic> qrText;
  final String usercode;
  final String depcode; // ✅ ต้องมีตัวแปรนี้
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
          ],
        ),
      ),
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
}
