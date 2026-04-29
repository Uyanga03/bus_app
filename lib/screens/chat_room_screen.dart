import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

class ChatRoomScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String conversationId;
  final String otherUserName;

  const ChatRoomScreen({
    super.key,
    required this.user,
    required this.conversationId,
    required this.otherUserName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  static const _orange = Color(0xFFF57C00);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _markAsRead();
    // 3 секунд тутамд шинэ мессеж шалгах (polling)
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchMessages());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final res = await http.get(
        Uri.parse('http://localhost:3000/api/chat/messages/${widget.conversationId}'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        if (mounted && data.length != _messages.length) {
          setState(() {
            _messages = data;
            _isLoading = false;
          });
          _scrollToBottom();
        } else if (_isLoading) {
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead() async {
    try {
      await http.put(
        Uri.parse('http://localhost:3000/api/chat/messages/read'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'conversationId': widget.conversationId,
          'userId': widget.user['id'],
        }),
      );
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await http.post(
        Uri.parse('http://localhost:3000/api/chat/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'conversationId': widget.conversationId,
          'senderId': widget.user['id'],
          'senderName': widget.user['name'],
          'text': text,
        }),
      );
      _fetchMessages();
    } catch (_) {}
  }

  Future<void> _sendImage() async {
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:3000/api/feedback'),
      );
      request.fields['type'] = 'чат';
      request.fields['message'] = '';
      request.fields['userName'] = widget.user['name'] ?? '';
      request.files.add(http.MultipartFile.fromBytes('media', bytes, filename: file.name));
      final res = await request.send();

      if (res.statusCode == 201) {
        final resBody = await res.stream.bytesToString();
        final data = json.decode(resBody);
        final imageUrl = (data['mediaUrls'] as List?)?.first ?? '';

        await http.post(
          Uri.parse('http://localhost:3000/api/chat/messages'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'conversationId': widget.conversationId,
            'senderId': widget.user['id'],
            'senderName': widget.user['name'],
            'text': '',
            'imageUrl': imageUrl,
          }),
        );
        _fetchMessages();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── AppBar ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
              left: 4,
              right: 8,
            ),
            color: _orange,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.otherUserName.isNotEmpty
                        ? widget.otherUserName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _orange,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.otherUserName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        '',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),

          // ── Мессежүүд ──
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _orange))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildMessage(_messages[i]),
                  ),
          ),

          // ── Мессеж бичих хэсэг ──
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Камер icon
                  GestureDetector(
                    onTap: _sendImage,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.camera_alt, color: _orange, size: 20),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Зураг icon
                  GestureDetector(
                    onTap: _sendImage,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.photo, color: _orange, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Текст оруулах
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(fontSize: 14),
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Мессеж бичих...',
                          hintStyle: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Илгээх товч
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
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

  Widget _buildMessage(dynamic msg) {
    final isMe = msg['senderId'] == widget.user['id'];
    final text = msg['text']?.toString() ?? '';
    final imageUrl = msg['imageUrl']?.toString() ?? '';
    final time = _formatTime(msg['createdAt']?.toString());
    final isRead = msg['read'] == true;
    final msgId = msg['_id']?.toString() ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe ? () => _showMessageOptions(msgId, text) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Зураг
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'http://localhost:3000$imageUrl',
                    width: 200,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 200, height: 150, color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              // Текст
              if (text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? _orange : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
                  ),
                  child: Text(text, style: TextStyle(fontSize: 14, color: isMe ? Colors.white : Colors.black87)),
                ),
              const SizedBox(height: 2),
              // Цаг + харсан/хараагүй icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  if (isMe && isRead) ...[
                    const SizedBox(width: 3),
                    Icon(Icons.visibility, size: 12, color: const Color(0xFF4CAF50)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Мессеж засах/устгах popup
  void _showMessageOptions(String msgId, String currentText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFFF57C00)),
            title: const Text('Засах'),
            onTap: () { Navigator.pop(ctx); _editMessage(msgId, currentText); },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Устгах', style: TextStyle(color: Colors.red)),
            onTap: () { Navigator.pop(ctx); _deleteMessage(msgId); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // Мессеж засах
  Future<void> _editMessage(String msgId, String currentText) async {
    final editCtrl = TextEditingController(text: currentText);
    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Мессеж засах', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editCtrl,
          autofocus: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFF57C00))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Болих')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, editCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white),
            child: const Text('Хадгалах'),
          ),
        ],
      ),
    );
    if (newText == null || newText.isEmpty) return;
    try {
      await http.put(
        Uri.parse('http://localhost:3000/api/chat/messages/$msgId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': newText, 'senderId': widget.user['id']}),
      );
      _fetchMessages();
    } catch (_) {}
  }

  // Мессеж устгах
  Future<void> _deleteMessage(String msgId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Мессеж устгах', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Энэ мессежийг устгах уу?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Болих')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Устгах'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await http.delete(
        Uri.parse('http://localhost:3000/api/chat/messages/$msgId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'senderId': widget.user['id']}),
      );
      _fetchMessages();
    } catch (_) {}
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}