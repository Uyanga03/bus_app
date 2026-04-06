import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChangePasswordScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ChangePasswordScreen({super.key, required this.user});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  static const _orange = Color(0xFFF57C00);

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final current = _currentController.text.trim();
    final newPw = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    if (current.isEmpty) {
      _showSnackBar('Хуучин нууц үгээ оруулна уу');
      return;
    }
    if (newPw.isEmpty || newPw.length < 6) {
      _showSnackBar('Шинэ нууц үг 6-с дээш тэмдэгт байх ёстой');
      return;
    }
    if (newPw != confirm) {
      _showSnackBar('Шинэ нууц үг таарахгүй байна');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/api/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          if (widget.user['token'] != null)
            'Authorization': 'Bearer ${widget.user['token']}',
        },
        body: json.encode({
          'currentPassword': current,
          'newPassword': newPw,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Нууц үг амжилттай солигдлоо!', isError: false);
        if (mounted) Navigator.pop(context);
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
                      'Нууц үг солих',
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField(
                    controller: _currentController,
                    hint: 'Хуучин нууц үг',
                    obscure: _obscureCurrent,
                    onToggle: () => setState(
                        () => _obscureCurrent = !_obscureCurrent),
                  ),
                  const SizedBox(height: 14),

                  _buildField(
                    controller: _newController,
                    hint: 'Шинэ нууц үг',
                    obscure: _obscureNew,
                    onToggle: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                  const SizedBox(height: 14),

                  _buildField(
                    controller: _confirmController,
                    hint: 'Шинэ нууц үг давтах',
                    obscure: _obscureConfirm,
                    onToggle: () => setState(
                        () => _obscureConfirm = !_obscureConfirm),
                  ),
                  const SizedBox(height: 28),

                  // ── Нууц үг мартсан линк ──
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // Нэвтрэх дэлгэц рүү буцаж forgot password ашиглана
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Нууц үг мартсан?',
                        style: TextStyle(
                          color: _orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Солих товч ──
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
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
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 15, color: Colors.grey.shade400),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey.shade400,
            size: 20,
          ),
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
    );
  }
}