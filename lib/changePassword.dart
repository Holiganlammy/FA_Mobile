import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fa_mobile_app/Login.dart';
import 'package:fa_mobile_app/config.dart';
import 'package:fa_mobile_app/services/httpService.dart';

class ChangePasswordPage extends StatefulWidget {
  final String usercode;
  final String depcode;
  final String time;

  const ChangePasswordPage({
    Key? key,
    required this.usercode,
    required this.depcode,
    required this.time,
  }) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: Text('เปลี่ยนรหัสผ่าน',
            style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ผู้ใช้: ${widget.usercode}',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              SizedBox(height: 30),
              
              // รหัสผ่านปัจจุบัน
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'รหัสผ่านปัจจุบัน',
                isVisible: _isCurrentPasswordVisible,
                onVisibilityToggle: () => setState(() => 
                    _isCurrentPasswordVisible = !_isCurrentPasswordVisible),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกรหัสผ่านปัจจุบัน';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              
              // รหัสผ่านใหม่
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'รหัสผ่านใหม่',
                isVisible: _isNewPasswordVisible,
                onVisibilityToggle: () => setState(() => 
                    _isNewPasswordVisible = !_isNewPasswordVisible),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกรหัสผ่านใหม่';
                  }
                  if (value.length < 8) {
                    return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                  }
                  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>-_]').hasMatch(value)) {
                    return 'รหัสผ่านต้องมีอักขระพิเศษ 1 ตัว';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return 'รหัสผ่านต้องมีตัวอักษรใหญ่ 1 ตัว';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              
              // ยืนยันรหัสผ่านใหม่
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'ยืนยันรหัสผ่านใหม่',
                isVisible: _isConfirmPasswordVisible,
                onVisibilityToggle: () => setState(() => 
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณายืนยันรหัสผ่านใหม่';
                  }
                  if (value != _newPasswordController.text) {
                    return 'รหัสผ่านไม่ตรงกัน';
                  }
                  return null;
                },
              ),
              SizedBox(height: 40),
              
              // ปุ่มเปลี่ยนรหัสผ่าน
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'เปลี่ยนรหัสผ่าน',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // คำแนะนำ (ตรงกลาง)
              Center(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'คำแนะนำในการตั้งรหัสผ่าน',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        '• รหัสผ่านควรมีอย่างน้อย 8 ตัวอักษร\n• ควรมีตัวอักษรใหญ่ 1 ตัว (A-Z)\n• ควรมีอักขระพิเศษ 1 ตัว (!@#\$%^&*_-)\n• หลีกเลี่ยงการใช้ข้อมูลส่วนตัว\n• เก็บรหัสผ่านไว้เป็นความลับ',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.teal.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey.shade600,
          ),
          onPressed: onVisibilityToggle,
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      var response = await HttpWithAuth.post(
        context: context,
        url: Uri.parse('${Config.apiURL}/change_password'),
        headers: await Config.getAuthHeaders(),
        body: jsonEncode({
          'userCode': widget.usercode,
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
          'confirmPassword': _confirmPasswordController.text,
        }),
      );

      setState(() => _isLoading = false);
      print("📩 Response Code: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");
      var responseData = jsonDecode(response.body);
      print("📩 Response Data: $responseData");
      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        _showDialog('ผิดพลาด', responseData['message'] ?? 'เกิดข้อผิดพลาด');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("❌ Exception: $e");
      _showDialog('ข้อผิดพลาด', 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('สำเร็จ'),
          ],
        ),
        content: Text('เปลี่ยนรหัสผ่านเรียบร้อยแล้ว\nกรุณาเข้าสู่ระบบใหม่'),
        actions: [
          TextButton(
            child: Text('ตกลง'),
            onPressed: () {
              Navigator.of(context).pop(); // ปิด dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
                (route) => false,
              );
            },
          )
        ],
      ),
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