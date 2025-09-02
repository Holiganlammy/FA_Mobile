// lib/services/http_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fa_mobile_app/Login.dart';
import '../config.dart';

class HttpWithAuth {
  static Future<http.Response> post({
    required BuildContext context,
    required Uri url,
    required Map<String, String> headers,
    Object? body,
  }) async {
    final response = await http.post(url, headers: headers, body: body);

    await _handle401IfNeeded(context, response);

    return response;
  }

  static Future<http.Response> get({
    required BuildContext context,
    required Uri url,
    required Map<String, String> headers,
  }) async {
    final response = await http.get(url, headers: headers);

    await _handle401IfNeeded(context, response);

    return response;
  }

  static Future<void> _handle401IfNeeded(
      BuildContext context, http.Response response) async {
    if (response.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('resetToken');

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Session หมดอายุ'),
            content: const Text('กรุณาเข้าสู่ระบบใหม่อีกครั้ง'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(),
                    ),
                  );
                },
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
      }
    }
  }
}
