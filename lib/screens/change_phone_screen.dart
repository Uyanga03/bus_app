import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChangePhoneScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ChangePhoneScreen({super.key, required this.user});

  @override
  State<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  static const _orange = Color(0xFFF57C00);

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _changePhone() async {
    final newPhone = _phoneController.text.trim();
    if (newPhone.isEmpty) {
      _showSnackBar('Шинэ утасны дугаар оруулна уу');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/api/auth/change-phone'),
        headers: {
          'Content-Type': 'application/json',
          if (widget.user['token'] != null)
            'Authorization': 'Bearer ${widget.user['token']}',
        },
        body: json.encode({
          'newPhone': newPhone,
          'currentPhone': widget.user['phone'] ?? '',
          'userId': widget.user['id'] ?? '',
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Утасны дугаар амжилттай солигдлоо!', isError: false);
        if (mounted) Navigator.pop(context, newPhone);
      } else {
        final data = json.decode(response.body);
        _showSnackBar(data['message'] ?? 'Алдаа гарлаа');
      }
    } catch (e) {
      _showSnackBar('Сүлжээний алдаа');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : _orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── AppBar ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 14,
              left: 4,
              right: 16,
            ),
            color: _orange,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Утасны дугаар солих',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // ── Form ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Шинэ утасны дугаар',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade400,
                    ),
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: _orange, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _orange.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Солих',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}