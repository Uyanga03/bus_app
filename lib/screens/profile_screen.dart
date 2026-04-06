import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'settings_screen.dart';
import 'change_phone_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> _myPosts = [];
  bool _isLoading = true;

  static const _orange = Color(0xFFF57C00);

  @override
  void initState() {
    super.initState();
    _fetchMyPosts();
  }

  Future<void> _fetchMyPosts() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:3000/api/feedback'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final all = json.decode(response.body) as List;
        setState(() {
          _myPosts = all
              .where((p) =>
                  p['userName'] == widget.user['name'] ||
                  p['userId'] == widget.user['id'])
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
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
                      'Профайл',
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

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Профайл зураг + нэр ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: _orange.withOpacity(0.15),
                          child: Text(
                            (widget.user['name'] ?? 'Х')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _orange,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.user['name'] ?? 'Хэрэглэгч',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Миний тухай ──
                  const Padding(
                    padding: EdgeInsets.only(left: 20, bottom: 10),
                    child: Text(
                      'Миний тухай',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // ── Миний постууд ──
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: _orange),
                      ),
                    )
                  else if (_myPosts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Одоогоор пост байхгүй байна',
                          style: TextStyle(color: Color(0xFF999999)),
                        ),
                      ),
                    )
                  else
                    ..._myPosts.map((post) => _buildPostCard(post)),

                  const SizedBox(height: 16),

                  // ── Тохиргооны линкүүд ──
                  _settingTile(
                    icon: Icons.settings_outlined,
                    label: 'Миний тохиргоо',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(user: widget.user),
                      ),
                    ),
                  ),
                  _settingTile(
                    icon: Icons.phone_outlined,
                    label: 'Утасны дугаар солих',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangePhoneScreen(user: widget.user),
                      ),
                    ),
                  ),
                  _settingTile(
                    icon: Icons.lock_outline,
                    label: 'Нууц үг солих',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangePasswordScreen(user: widget.user),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    final message = post['message']?.toString() ?? '';
    final busNumber = post['busNumber']?.toString() ?? '';
    final likes = post['likes'] ?? 0;
    final comments = post['comments'] ?? 0;
    final mediaUrls = post['mediaUrls'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (busNumber.isNotEmpty)
            Text(
              '$busNumber-р чиглэл',
              style: const TextStyle(
                fontSize: 13,
                color: _orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
          if (mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                'http://localhost:3000${mediaUrls[0]}',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('$likes', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('$comments', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF333333), size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 22),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}