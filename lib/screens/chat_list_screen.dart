import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ChatListScreen({super.key, required this.user});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  static const _orange = Color(0xFFF57C00);

  List<dynamic> _users = [];
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String _filter = 'Бүгд';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final usersRes = await http.get(
        Uri.parse('http://localhost:3000/api/chat/users'),
      );
      final convRes = await http.get(
        Uri.parse('http://localhost:3000/api/chat/conversations/${widget.user['id']}'),
      );

      if (usersRes.statusCode == 200) {
        final allUsers = json.decode(usersRes.body) as List;
        _users = allUsers.where((u) => u['_id'] != widget.user['id']).toList();
      }
      if (convRes.statusCode == 200) {
        _conversations = json.decode(convRes.body) as List;
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _openChat(String otherUserId, String otherUserName) async {
    try {
      final res = await http.post(
        Uri.parse('http://localhost:3000/api/chat/conversations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId1': widget.user['id'],
          'userName1': widget.user['name'],
          'userId2': otherUserId,
          'userName2': otherUserName,
        }),
      );

      if (res.statusCode == 200) {
        final conversation = json.decode(res.body);
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                user: widget.user,
                conversationId: conversation['_id'],
                otherUserName: otherUserName,
              ),
            ),
          );
          _fetchData();
        }
      }
    } catch (_) {}
  }

  // ── Чат устгах ──
  Future<void> _deleteConversation(String conversationId) async {
    try {
      await http.delete(
        Uri.parse('http://localhost:3000/api/chat/conversations/$conversationId'),
      );
      _fetchData();
    } catch (_) {}
  }

  // ── Урт дарахад гарч ирэх bottom sheet ──
  void _showDeleteSheet(String convId, String otherName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Чатын нэр
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  otherName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 20),
              // Устгах сонголт
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Устгах',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteConversation(convId);
                },
              ),
              // Болих сонголт
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey),
                title: const Text('Болих'),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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
              left: 16,
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
                      'Чат',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // ── Хайлт ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.trim().toLowerCase()),
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Хайх',
                        hintStyle:
                            TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Хэрэглэгчдийн дугуйнууд ──
          if (_users.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _users.length,
                itemBuilder: (_, i) {
                  final u = _users[i];
                  final name = u['name']?.toString() ?? '';
                  if (_searchQuery.isNotEmpty &&
                      !name.toLowerCase().contains(_searchQuery)) {
                    return const SizedBox.shrink();
                  }
                  return GestureDetector(
                    onTap: () => _openChat(u['_id'], name),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: _orange.withOpacity(0.15),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _orange,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 60,
                            child: Text(
                              name.split(' ').last,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── Шүүлтүүр ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: ['Бүгд', 'Уншаагүй'].map((f) {
                final isActive = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? _orange : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Чатууд ──
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Чатууд',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _orange))
                : _conversations.isEmpty
                    ? const Center(
                        child: Text('Одоогоор чат байхгүй',
                            style: TextStyle(color: Color(0xFF999999))),
                      )
                    : ListView.builder(
                        itemCount: _conversations.length,
                        itemBuilder: (_, i) {
                          final conv = _conversations[i];
                          final participants =
                              conv['participantNames'] as List<dynamic>? ?? [];
                          final otherName = participants
                              .firstWhere(
                                (n) => n != widget.user['name'],
                                orElse: () => 'Хэрэглэгч',
                              )
                              .toString();
                          final lastMsg =
                              conv['lastMessage']?.toString() ?? '';
                          final convId = conv['_id'].toString();

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _orange.withOpacity(0.15),
                              child: Text(
                                otherName.isNotEmpty
                                    ? otherName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _orange),
                              ),
                            ),
                            title: Text(
                              otherName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              lastMsg,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.grey),
                              onPressed: () =>
                                  _showDeleteSheet(convId, otherName),
                            ),
                            onTap: () {
                              final otherUserId =
                                  (conv['participants'] as List<dynamic>)
                                      .firstWhere(
                                        (id) => id != widget.user['id'],
                                        orElse: () => '',
                                      )
                                      .toString();
                              _openChat(otherUserId, otherName);
                            },
                            // ── Урт даралт (утсан дээр) ──
                            onLongPress: () =>
                                _showDeleteSheet(convId, otherName),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}