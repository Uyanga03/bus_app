import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  static const _orange = Color(0xFFF57C00);
  dynamic _post;
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _currentUser;
  final TextEditingController _commentController = TextEditingController();
  bool _hasLiked = false;
  bool _showCommentInput = false;
  final FocusNode _commentFocus = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _commentImage;
  Uint8List? _commentImageBytes;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('currentUser');
    if (userJson != null) {
      setState(() {
        _currentUser = json.decode(userJson) as Map<String, dynamic>;
      });
    }
  }

  Future<void> _fetchPost() async {
    try {
      final res = await http.get(
        Uri.parse('http://localhost:3000/api/feedback/${widget.postId}'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _post = data;
          _isLoading = false;
          if (_currentUser != null) {
            final likedBy = data['likedBy'] as List<dynamic>? ?? [];
            _hasLiked = likedBy.contains(_currentUser!['id']);
          }
        });
      } else {
        setState(() {
          _error = 'Пост олдсонгүй';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Сүлжээний алдаа';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_currentUser == null) {
      _showLoginPrompt();
      return;
    }
    if (_currentUser!['role'] == 'Админ' || _currentUser!['role'] == 'Жолооч') return;

    setState(() {
      _hasLiked = !_hasLiked;
      final current = (_post['likes'] ?? 0) as int;
      _post['likes'] = _hasLiked ? current + 1 : (current - 1).clamp(0, 999999);
    });

    try {
      final res = await http.put(
        Uri.parse('http://localhost:3000/api/feedback/${widget.postId}/like'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _currentUser!['id'],
          'userName': _currentUser!['name'] ?? '',
        }),
      );
      if (res.statusCode == 200) {
        setState(() => _post = json.decode(res.body));
      }
    } catch (_) {}
  }

  Future<void> _submitComment() async {
    final hasText = _commentController.text.trim().isNotEmpty;
    final hasImage = _commentImage != null;
    if (!hasText && !hasImage) return;
    if (_currentUser == null) {
      _showLoginPrompt();
      return;
    }
    if (_currentUser!['role'] == 'Админ' || _currentUser!['role'] == 'Жолооч') return;

    try {
      http.Response res;
      final url = 'http://localhost:3000/api/feedback/${widget.postId}/comment';
      if (hasImage) {
        final request = http.MultipartRequest('POST', Uri.parse(url));
        request.fields['message'] = _commentController.text.trim();
        request.fields['userName'] = _currentUser!['name'] ?? 'Хэрэглэгч';
        request.fields['userId'] = _currentUser!['id'] ?? '';
        final bytes = await _commentImage!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image', bytes, filename: _commentImage!.name,
        ));
        final streamed = await request.send();
        res = await http.Response.fromStream(streamed);
      } else {
        res = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'message': _commentController.text.trim(),
            'userName': _currentUser!['name'] ?? 'Хэрэглэгч',
            'userId': _currentUser!['id'] ?? '',
          }),
        );
      }
      if (res.statusCode == 200) {
        setState(() {
          _post = json.decode(res.body);
          _showCommentInput = false;
          _commentImage = null;
          _commentImageBytes = null;
        });
        _commentController.clear();
      }
    } catch (_) {}
  }

  Future<void> _pickCommentImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _commentImage = file;
          _commentImageBytes = Uint8List.fromList(bytes);
        });
      }
    } catch (_) {}
  }

  void _showLoginPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Нэвтрэнэ үү'),
        backgroundColor: Colors.grey.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showShareSheet() {
    final userName = _post['userName']?.toString() ?? '';
    final message = _post['message']?.toString() ?? '';
    final busNumber = _post['busNumber']?.toString() ?? '';
    final shareText = '$userName${busNumber.isNotEmpty ? ' · $busNumber-р чиглэл' : ''}\n$message';
    final shareUrl = 'http://localhost:3000/post/${widget.postId}';
    final fullText = '$shareText\n\n$shareUrl';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Холбоос хуваалцах', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Expanded(child: Text(shareUrl, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: shareUrl));
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Хуулагдлаа!'), backgroundColor: _orange),
                    );
                  }
                },
                child: const Icon(Icons.copy, size: 20, color: _orange),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await Share.share(fullText, subject: 'BusApp пост');
              },
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Бусад апп руу хуваалцах'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Шууд апп руу',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _shareIcon(
                icon: Icons.camera_alt,
                label: 'Instagram',
                color: const Color(0xFFE1306C),
                onTap: () => _openApp('instagram://app', fullText),
              ),
              _shareIcon(
                icon: Icons.music_note,
                label: 'TikTok',
                color: Colors.black,
                onTap: () => _openApp('snssdk1233://', fullText),
              ),
              _shareIcon(
                icon: Icons.chat,
                label: 'Messenger',
                color: const Color(0xFF0084FF),
                onTap: () => _openApp(
                  'fb-messenger://share?link=${Uri.encodeComponent(shareUrl)}',
                  fullText,
                ),
              ),
              _shareIcon(
                icon: Icons.email,
                label: 'Gmail',
                color: const Color(0xFFEA4335),
                onTap: () => _openApp(
                  'mailto:?subject=BusApp&body=${Uri.encodeComponent(fullText)}',
                  fullText,
                ),
              ),
              _shareIcon(
                icon: Icons.facebook,
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                onTap: () => _openApp(
                  'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareUrl)}&quote=${Uri.encodeComponent(shareText)}',
                  fullText,
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _shareIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Future<void> _openApp(String url, String fallbackText) async {
    Navigator.pop(context);
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Share.share(fallbackText);
      }
    } catch (_) {
      try {
        await Share.share(fallbackText);
      } catch (_) {}
    }
  }

  String _typeLabel(String? t) {
    switch (t) {
      case 'санал': return 'Санал';
      case 'гомдол': return 'Гомдол';
      case 'олдсон': return 'Олдсон';
      case 'мартсан': return 'Мартсан';
      default: return t ?? '';
    }
  }

  Color _typeColor(String? t) {
    switch (t) {
      case 'санал': return Colors.blue.shade400;
      case 'гомдол': return Colors.red.shade400;
      case 'олдсон': return Colors.green.shade400;
      case 'мартсан': return Colors.orange.shade400;
      default: return Colors.grey;
    }
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
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        title: const Text('Нийтлэл', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : _error.isNotEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(_error, style: TextStyle(color: Colors.grey.shade600)),
                  ]),
                )
              : Column(children: [
                  Expanded(child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Header
                      Row(children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: _typeColor(_post['type']?.toString()).withOpacity(0.15),
                          child: Text(
                            (_post['userName']?.toString() ?? 'Х')[0].toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.bold, color: _typeColor(_post['type']?.toString())),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_post['userName']?.toString() ?? 'Хэрэглэгч',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Row(children: [
                            if ((_post['busNumber']?.toString() ?? '').isNotEmpty)
                              Text('${_post['busNumber']}-р чиглэл',
                                  style: TextStyle(fontSize: 12, color: _orange, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 6),
                            Text(_timeAgo(_post['createdAt']?.toString()),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ]),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _typeColor(_post['type']?.toString()).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_typeLabel(_post['type']?.toString()),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                                  color: _typeColor(_post['type']?.toString()))),
                        ),
                      ]),
                      const SizedBox(height: 12),

                      if ((_post['category']?.toString() ?? '').isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(_post['category']?.toString() ?? '',
                              style: const TextStyle(fontSize: 11, color: _orange, fontWeight: FontWeight.w600)),
                        ),

                      Text(_post['message']?.toString() ?? '',
                          style: const TextStyle(fontSize: 15, height: 1.5)),
                      const SizedBox(height: 12),

                      if ((_post['mediaUrls'] as List<dynamic>? ?? []).isNotEmpty)
                        Column(children: (_post['mediaUrls'] as List<dynamic>).map((url) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network('http://localhost:3000${url}',
                              width: double.infinity, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, color: Colors.grey)),
                            ),
                          ),
                        )).toList()),

                      const SizedBox(height: 16),

                      // Like, Comment, Share товчнууд
                      if (_currentUser == null || (_currentUser!['role'] != 'Админ' && _currentUser!['role'] != 'Жолооч'))
                        Row(children: [
                          GestureDetector(
                            onTap: _toggleLike,
                            child: Row(children: [
                              Icon(_hasLiked ? Icons.favorite : Icons.favorite_border,
                                  size: 22, color: _hasLiked ? Colors.red.shade400 : Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text('${_post['likes'] ?? 0}',
                                  style: TextStyle(fontSize: 14, color: _hasLiked ? Colors.red.shade400 : Colors.grey.shade500)),
                            ]),
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: () {
                              if (_currentUser == null) {
                                _showLoginPrompt();
                                return;
                              }
                              setState(() => _showCommentInput = !_showCommentInput);
                              if (_showCommentInput) {
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  FocusScope.of(context).requestFocus(_commentFocus);
                                });
                              }
                            },
                            child: Row(children: [
                              Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text('${(_post['commentsList'] as List<dynamic>? ?? []).length}',
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                            ]),
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: _showShareSheet,
                            child: Icon(Icons.share_outlined, size: 20, color: Colors.grey.shade500),
                          ),
                        ]),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Сэтгэгдлүүд
                      ...(_post['commentsList'] as List<dynamic>? ?? []).map((c) {
                        final cName = c['userName']?.toString() ?? 'Хэрэглэгч';
                        final cMsg = c['message']?.toString() ?? '';
                        final cImg = c['imageUrl']?.toString() ?? '';
                        final cTime = _timeAgo(c['createdAt']?.toString());
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            CircleAvatar(radius: 14, backgroundColor: Colors.grey.shade400,
                              child: Text(cName.isNotEmpty ? cName[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white))),
                            const SizedBox(width: 8),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text(cName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                Text(cTime, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ]),
                              const SizedBox(height: 2),
                              if (cMsg.isNotEmpty)
                                Text(cMsg, style: const TextStyle(fontSize: 13)),
                              if (cImg.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    cImg.startsWith('http') ? cImg : 'http://localhost:3000$cImg',
                                    height: 140,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 140, width: 140,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ],
                            ])),
                          ]),
                        );
                      }),
                    ]),
                  )),

                  // Comment input хэсэг (зөвхөн icon дарсан үед)
                  if (_showCommentInput && (_currentUser == null || (_currentUser!['role'] != 'Админ' && _currentUser!['role'] != 'Жолооч')))
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: SafeArea(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        // Зургийн preview
                        if (_commentImage != null && _commentImageBytes != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(_commentImageBytes!,
                                    width: 50, height: 50, fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(child: Text('Зураг хавсаргасан',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)))),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _commentImage = null;
                                  _commentImageBytes = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300, shape: BoxShape.circle),
                                  child: Icon(Icons.close, size: 14, color: Colors.grey.shade700),
                                ),
                              ),
                            ]),
                          ),
                        Row(children: [
                          GestureDetector(
                            onTap: _currentUser == null ? null : _pickCommentImage,
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: _orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.image_outlined,
                                  color: _orange, size: 18),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: TextField(
                            controller: _commentController,
                            focusNode: _commentFocus,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: _currentUser != null ? 'Сэтгэгдэл бичих...' : 'Нэвтэрч сэтгэгдэл бичнэ үү',
                              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                              filled: true, fillColor: const Color(0xFFF5F5F5),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              isDense: true,
                            ),
                          )),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _submitComment,
                            child: Container(width: 36, height: 36,
                              decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(18)),
                              child: const Icon(Icons.send, color: Colors.white, size: 16)),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                ]),
    );
  }
}