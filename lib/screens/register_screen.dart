import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const _orange = Color(0xFFF57C00);

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  API: Бүртгүүлэх
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _register() async {
    final lastName = _lastNameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final phone = _phoneController.text.trim();
    final pw = _passwordController.text.trim();
    final pw2 = _confirmPasswordController.text.trim();

    if (lastName.isEmpty || firstName.isEmpty) {
      _showSnackBar('Овог, нэрээ оруулна уу');
      return;
    }
    if (phone.isEmpty) {
      _showSnackBar('Утасны дугаараа оруулна уу');
      return;
    }
    if (phone.length != 8 || int.tryParse(phone) == null) {
      _showSnackBar('');
      return;
    }
    if (pw.isEmpty || pw.length < 6) {
      _showSnackBar('Нууц үг 6-с дээш тэмдэгт байх ёстой');
      return;
    }
    if (pw != pw2) {
      _showSnackBar('Нууц үг таарахгүй байна');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'lastName': lastName,
          'firstName': firstName,
          'phone': phone,
          'password': pw,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        _showSnackBar('Бүртгэл амжилттай!', isError: false);
        if (mounted) {
          Navigator.pop(context, {
            'name': data['user']?['name'] ?? '$lastName $firstName',
            'id': data['user']?['_id'] ?? '',
            'phone': phone,
          });
        }
      } else {
        final data = json.decode(response.body);
        _showSnackBar(data['message'] ?? 'Бүртгэл амжилтгүй');
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

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── AppBar (улбар шар) ──
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
                      'Бүртгүүлэх',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // balance the back button
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
                  // Овог
                  _buildUnderlineField(
                    controller: _lastNameController,
                    hint: 'Овог',
                  ),
                  const SizedBox(height: 8),

                  // Нэр
                  _buildUnderlineField(
                    controller: _firstNameController,
                    hint: 'Нэр',
                  ),
                  const SizedBox(height: 8),

                  // Утас
                  _buildUnderlineField(
                    controller: _phoneController,
                    hint: 'Утасны дугаар',
                    keyboardType: TextInputType.phone,
                    maxLength: 8,
                  ),
                  const SizedBox(height: 6),

                  // Тайлбар текст
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '',
                      style: TextStyle(
                        fontSize: 12,
                        color: _orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Нууц үг
                  _buildUnderlineField(
                    controller: _passwordController,
                    hint: 'Нууц үг (6-с дээш тэмдэгт)',
                    obscure: _obscurePassword,
                    suffixIcon: GestureDetector(
                      onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Нууц үг давтах
                  _buildUnderlineField(
                    controller: _confirmPasswordController,
                    hint: 'Нууц үг давтах',
                    obscure: _obscureConfirm,
                    suffixIcon: GestureDetector(
                      onTap: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                      child: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Бүртгүүлэх товч
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
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
                              'Бүртгүүлэх',
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

  // ═══════════════════════════════════════════════════════════════════
  //  Доод зураастай input field (зурган дээрх загвараар)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildUnderlineField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 15,
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w400,
        ),
        counterText: '',
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
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