import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'Зорчигч';

  // Нууц үг мартсан flow
  bool _showForgotPassword = false;
  final TextEditingController _forgotPhoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  int _forgotStep = 1; // 1: утас оруулах, 2: код оруулах, 3: шинэ нууц үг

  static const _orange = Color(0xFFF57C00);
  static const _orangeLight = Color(0xFFFFF3E0);

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _forgotPhoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  API: Нэвтрэх
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showSnackBar('Утас болон нууц үгээ оруулна уу');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': phone,
          'password': password,
          'role': _selectedRole,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          Navigator.pop(context, {
            'name': data['user']?['name'] ?? _selectedRole,
            'id': data['user']?['_id'] ?? '',
            'phone': phone,
            'role': _selectedRole,
          });
        }
      } else {
        final data = json.decode(response.body);
        _showSnackBar(data['message'] ?? 'Нэвтрэх амжилтгүй');
      }
    } catch (e) {
      _showSnackBar('Сүлжээний алдаа: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  API: Нууц үг сэргээх
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _sendForgotOtp() async {
    final phone = _forgotPhoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar('Утасны дугаараа оруулна уу');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone}),
      );

      if (response.statusCode == 200) {
        setState(() => _forgotStep = 2);
        _showSnackBar('Код илгээгдлээ', isError: false);
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

  Future<void> _verifyForgotOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('Кодоо оруулна уу');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': _forgotPhoneController.text.trim(),
          'otp': code,
        }),
      );

      if (response.statusCode == 200) {
        setState(() => _forgotStep = 3);
      } else {
        final data = json.decode(response.body);
        _showSnackBar(data['message'] ?? 'Код буруу байна');
      }
    } catch (e) {
      _showSnackBar('Сүлжээний алдаа');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final pw = _newPasswordController.text.trim();
    final pw2 = _confirmPasswordController.text.trim();

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
        Uri.parse('http://localhost:3000/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': _forgotPhoneController.text.trim(),
          'otp': _otpController.text.trim(),
          'newPassword': pw,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Нууц үг амжилттай солигдлоо!', isError: false);
        setState(() {
          _showForgotPassword = false;
          _forgotStep = 1;
        });
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

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── AppBar ──
          _buildAppBar(
            title: _showForgotPassword
                ? (_forgotStep == 1
                    ? 'Нууц үгээ мартсан уу?'
                    : _forgotStep == 2
                        ? 'Нэг удаагийн код оруулна уу?'
                        : 'Нууц үг сэргээх')
                : 'Юмаа мартаж буусан уу?',
            onBack: () {
              if (_showForgotPassword) {
                if (_forgotStep > 1) {
                  setState(() => _forgotStep--);
                } else {
                  setState(() => _showForgotPassword = false);
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),

          // ── Body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _showForgotPassword
                  ? _buildForgotPasswordBody()
                  : _buildLoginBody(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Нэвтрэх form
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildLoginBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Роль сонголт ──
        Row(
          children: ['Жолооч', 'Зорчигч', 'Админ'].map((role) {
            final isSelected = _selectedRole == role;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => setState(() => _selectedRole = role),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? _orange : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _orange,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? _orange : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // ── Утас ──
        _buildLabel('Утас'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _phoneController,
          hint: 'Утасны дугаар',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: 16),

        // ── Нууц үг ──
        _buildLabel('Нууц үг'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _passwordController,
          hint: 'Нууц үг',
          obscure: _obscurePassword,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade500,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 24),

        // ── Нэвтрэх товч ──
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
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
                    'Нэвтрэх',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Бүртгүүлэх линк ──
        Center(
          child: GestureDetector(
            onTap: () async {
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
              if (result != null && mounted) {
                Navigator.pop(context, result);
              }
            },
            child: const Text(
              'Бүртгүүлэх',
              style: TextStyle(
                color: _orange,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Нууц үг мартсан линк ──
        Center(
          child: GestureDetector(
            onTap: () => setState(() {
              _showForgotPassword = true;
              _forgotStep = 1;
            }),
            child: Text(
              'Нууц үгээ мартсан уу?',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Нууц үг сэргээх flow (3 алхам)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildForgotPasswordBody() {
    switch (_forgotStep) {
      case 1:
        return _buildForgotStep1();
      case 2:
        return _buildForgotStep2();
      case 3:
        return _buildForgotStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  // Алхам 1: Утасны дугаар оруулах
  Widget _buildForgotStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Утасны дугаар'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _forgotPhoneController,
          hint: 'Утасны дугаар оруулна уу',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: 'Код авах',
          onPressed: _isLoading ? null : _sendForgotOtp,
        ),
      ],
    );
  }

  // Алхам 2: OTP код оруулах
  Widget _buildForgotStep2() {
    final phone = _forgotPhoneController.text.trim();
    final maskedPhone = phone.length >= 4
        ? '${phone.substring(0, 4)}${'*' * (phone.length - 4)}'
        : phone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Мэдээлэл хайрцаг
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _orangeLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Таньд илгээсэн',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                maskedPhone,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Нэг удаагийн код оруулан Sms / Бялоос нэвтрэнэ үү.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildLabel('Код'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _otpController,
          hint: 'Код оруулна уу',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.sms_outlined,
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: 'Үргэлжлүүлэх',
          onPressed: _isLoading ? null : _verifyForgotOtp,
        ),
      ],
    );
  }

  // Алхам 3: Шинэ нууц үг оруулах
  Widget _buildForgotStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Бүтэн нэрээ оруулна уу'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: TextEditingController(),
          hint: 'Бүтэн нэрээ оруулна уу',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 16),

        _buildLabel('Шинэ нууц үг'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _newPasswordController,
          hint: 'Нууц үг оруулна уу',
          obscure: true,
          prefixIcon: Icons.lock_outline,
        ),
        const SizedBox(height: 24),

        _buildPrimaryButton(
          label: 'Сартаах',
          onPressed: _isLoading ? null : _resetPassword,
        ),
        const SizedBox(height: 16),

        // Мэдээллийн хайрцаг
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _orangeLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Заавал тэмдэгт тоо 6-с дээш нууц код оруулна уу.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 14),

        Center(
          child: GestureDetector(
            onTap: () => setState(() {
              _showForgotPassword = false;
              _forgotStep = 1;
            }),
            child: const Text(
              'Нууц үг дамжих →',
              style: TextStyle(
                color: _orange,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Shared UI widgets
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAppBar({
    required String title,
    required VoidCallback onBack,
  }) {
    return Container(
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
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF666666),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey.shade400, size: 20)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _orange, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
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
            : Text(
                label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}