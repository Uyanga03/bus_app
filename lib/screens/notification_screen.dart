import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const NotificationScreen({super.key, required this.user});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const _orange = Color(0xFFF57C00);

  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _markAllRead();
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await http.get(
        Uri.parse('http://localhost:3000/api/notifications/${widget.user['id']}'),
      );
      if (res.statusCode == 200) {
        setState(() {
          _notifications = json.decode(res.body) as List;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await http.put(
        Uri.parse('http://localhost:3000/api/notifications/${widget.user['id']}/read-all'),
      );
    } catch (_) {}
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

  IconData _typeIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble;
      case 'chat':
        return Icons.send;
      default:
        return Icons.notifications;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'like':
        return Colors.red.shade400;
      case 'comment':
        return Colors.blue.shade400;
      case 'chat':
        return _orange;
      default:
        return Colors.grey;
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
                      'Мэдэгдэл',
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

          // ── Body ──
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _orange))
                : _notifications.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 48, color: Color(0xFFDDDDDD)),
                            SizedBox(height: 12),
                            Text('Мэдэгдэл байхгүй байна',
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF999999))),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: _orange,
                        onRefresh: _fetchNotifications,
                        child: ListView.separated(
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (_, i) {
                            final notif = _notifications[i];
                            final type = notif['type']?.toString() ?? '';
                            final msg = notif['message']?.toString() ?? '';
                            final fromName = notif['fromName']?.toString() ?? '';
                            final time = _timeAgo(notif['createdAt']?.toString());
                            final isRead = notif['isRead'] == true;

                            return Container(
                              color: isRead
                                  ? Colors.white
                                  : _orange.withOpacity(0.05),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      _typeColor(type).withOpacity(0.15),
                                  child: Icon(_typeIcon(type),
                                      color: _typeColor(type), size: 20),
                                ),
                                title: Text(
                                  msg,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        isRead ? FontWeight.normal : FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  time,
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF999999)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}