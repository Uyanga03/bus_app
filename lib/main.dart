import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'screens/home_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/post_detail_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UB Smart Bus',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/admin') {
          return MaterialPageRoute(builder: (_) => const AdminLoginPage());
        }
        if (settings.name != null && settings.name!.startsWith('/post/')) {
          final postId = settings.name!.replaceFirst('/post/', '');
          return MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId));
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      },
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  static const _orange = Color(0xFFF57C00);
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  String _error = '';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (phone.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Утас болон нууц үгээ оруулна уу');
      return;
    }
    setState(() { _isLoading = true; _error = ''; });
    try {
      final res = await http.post(
        Uri.parse('http://localhost:3000/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone, 'password': pass, 'role': 'Админ'}),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => AdminPanelScreen(user: {
              'name': data['user']?['name'] ?? 'Админ',
              'id': data['user']?['_id'] ?? '',
              'phone': phone,
              'role': 'Админ',
            }),
          ));
        }
      } else {
        final data = json.decode(res.body);
        setState(() => _error = data['message'] ?? 'Нэвтрэх амжилтгүй');
      }
    } catch (e) {
      setState(() => _error = 'Сүлжээний алдаа');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.admin_panel_settings, size: 40, color: _orange),
                ),
                const SizedBox(height: 16),
                const Text('Админ нэвтрэх', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                const SizedBox(height: 6),
                Text('BusApp удирдлагын систем', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                const SizedBox(height: 32),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Утас',
                    prefixIcon: Icon(Icons.phone, color: Colors.grey.shade400, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _orange, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'Нууц үг',
                    prefixIcon: Icon(Icons.lock, color: Colors.grey.shade400, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey.shade400),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _orange, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),
                if (_error.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(_error, style: TextStyle(fontSize: 13, color: Colors.red.shade600)),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Нэвтрэх', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/'),
                  child: Text('← Нүүр хуудас руу буцах', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}