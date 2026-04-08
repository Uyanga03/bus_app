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
  String _filter = 'Бүгд'; // Бүгд, Уншаагүй
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
      // Хэрэглэгчдийн жагсаалт
      final usersRes = await http.get(
        Uri.parse('http://localhost:3000/api/chat/users'),
      );
      // Миний яриануудын жагсаалт
      final convRes = await http.get(
        Uri.parse('http://localhost:3000/api/chat/conversations/${widget.user['id']}'),
      );

      if (usersRes.statusCode == 200) {
        final allUsers = json.decode(usersRes.body) as List;
        // Өөрийгөө хасах
        _users = allUsers.where((u) => u['_id'] != widget.user['id']).toList();
      }
      if (convRes.statusCode == 200) {
        _conversations = json.decode(convRes.body) as List;
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  // Яриа эхлүүлэх / байгааг нээх
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
          _fetchData(); // Буцахад шинэчлэх
        }
      }
    } catch (_) {}
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
                      onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Хайх',
                        hintStyle: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
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

          // ── Хэрэглэгчдийн дугуйнууд (хэвтээ scroll) ──
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
                  if (_searchQuery.isNotEmpty && !name.toLowerCase().contains(_searchQuery)) {
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                ? Center(child: CircularProgressIndicator(color: _orange))
                : _conversations.isEmpty
                    ? const Center(
                        child: Text('Одоогоор чат байхгүй',
                            style: TextStyle(color: Color(0xFF999999))),
                      )
                    : ListView.builder(
                        itemCount: _conversations.length,
                        itemBuilder: (_, i) {
                          final conv = _conversations[i];
                          final participants = conv['participantNames'] as List<dynamic>? ?? [];
                          final otherName = participants.firstWhere(
                            (n) => n != widget.user['name'],
                            orElse: () => 'Хэрэглэгч',
                          );
                          final lastMsg = conv['lastMessage']?.toString() ?? '';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _orange.withOpacity(0.15),
                              child: Text(
                                otherName.toString().isNotEmpty
                                    ? otherName.toString()[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, color: _orange),
                              ),
                            ),
                            title: Text(
                              otherName.toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: Text(
                              lastMsg,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              final otherUserId = (conv['participants'] as List<dynamic>)
                                  .firstWhere((id) => id != widget.user['id'], orElse: () => '');
                              _openChat(otherUserId, otherName.toString());
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}