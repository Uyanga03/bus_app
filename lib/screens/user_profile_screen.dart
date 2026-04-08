import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_room_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser; // Нэвтэрсэн хэрэглэгч
  final String userName;
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.currentUser,
    required this.userName,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  static const _orange = Color(0xFFF57C00);

  List<dynamic> _userPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserPosts();
  }

  Future<void> _fetchUserPosts() async {
    try {
      final res = await http
          .get(Uri.parse('http://localhost:3000/api/feedback'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final all = json.decode(res.body) as List;
        setState(() {
          _userPosts = all.where((p) =>
            p['userId'] == widget.userId ||
            p['userName'] == widget.userName
          ).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // Чат эхлүүлэх
  Future<void> _startChat() async {
    try {
      final res = await http.post(
        Uri.parse('http://localhost:3000/api/chat/conversations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId1': widget.currentUser['id'],
          'userName1': widget.currentUser['name'],
          'userId2': widget.userId,
          'userName2': widget.userName,
        }),
      );

      if (res.statusCode == 200 && mounted) {
        final conversation = json.decode(res.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              user: widget.currentUser,
              conversationId: conversation['_id'],
              otherUserName: widget.userName,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Чат эхлүүлэхэд алдаа гарлаа'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _fullMediaUrl(String url) {
    if (url.startsWith('http')) return url;
    return 'http://localhost:3000$url';
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Саяхан';
    if (diff.inMinutes < 60) return '${diff.inMinutes}м өмнө';
    if (diff.inHours < 24) return '${diff.inHours}ц өмнө';
    return '${diff.inDays}ө өмнө';
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
                const Spacer(),
              ],
            ),
          ),

          // ── Body ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Профайл зураг + нэр ──
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: _orange.withOpacity(0.15),
                    child: Text(
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Чат товч ──
                  if (widget.currentUser['id'] != widget.userId)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: _startChat,
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('Чат',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Түүх (постууд) ──
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Түүх',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: _orange),
                    )
                  else if (_userPosts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Одоогоор пост байхгүй',
                        style: TextStyle(color: Color(0xFF999999)),
                      ),
                    )
                  else
                    ..._userPosts.map((post) => _buildPostCard(post)),

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
    final commentCount = post['comments'] ?? 0;
    final timeAgo = _timeAgo(post['createdAt']?.toString());
    final mediaUrls = post['mediaUrls'] as List<dynamic>? ?? [];
    final type = post['type']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _orange.withOpacity(0.15),
                child: Text(
                  widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _orange,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (busNumber.isNotEmpty) ...[
                          const Text(' · ', style: TextStyle(color: Colors.grey)),
                          Flexible(
                            child: Text(
                              'Ч:$busNumber чиглэл',
                              style: const TextStyle(fontSize: 12, color: _orange),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(timeAgo,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                  ],
                ),
              ),
            ],
          ),

          // Зураг
          if (mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                _fullMediaUrl(mediaUrls[0].toString()),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ],

          // Мессеж
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],

          // Like + Comment + Share
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('$likes', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('$commentCount', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(width: 16),
              Icon(Icons.share_outlined, size: 16, color: Colors.grey.shade500),
            ],
          ),

          const SizedBox(height: 6),
          Divider(color: Colors.grey.shade200),
        ],
      ),
    );
  }
}