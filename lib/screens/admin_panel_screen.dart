import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPanelScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const AdminPanelScreen({super.key, required this.user});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  static const _orange = Color(0xFFEF962C);

  List<dynamic> _pendingPosts = [];
  List<dynamic> _approvedPosts = [];
  List<dynamic> _deletedPosts = [];
  bool _isLoading = true;
  String _filter = 'pending';

  int _totalFound = 0;
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _deletedCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final res = await http
          .get(Uri.parse('http://localhost:3000/api/feedback/admin'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        final notDeleted = data.where((p) => p['isDeleted'] != true).toList();
        final deleted = data.where((p) => p['isDeleted'] == true).toList();
        final pending = notDeleted.where((p) => p['status'] == 'pending' || p['status'] == null).toList();
        final approved = notDeleted.where((p) => p['status'] == 'approved').toList();
        setState(() {
          _pendingPosts = pending;
          _approvedPosts = approved;
          _deletedPosts = deleted;
          _totalFound = notDeleted.length;
          _pendingCount = pending.length;
          _approvedCount = approved.length;
          _deletedCount = deleted.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePost(String id) async {
    try {
      await http.delete(Uri.parse('http://localhost:3000/api/feedback/$id'));
      _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пост устгагдлаа'), backgroundColor: Colors.red),
        );
      }
    } catch (_) {}
  }

  Future<void> _approvePost(String id) async {
    try {
      final res = await http.put(
        Uri.parse('http://localhost:3000/api/feedback/$id/approve'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'adminId': widget.user['id'] ?? '',
          'adminName': widget.user['name'] ?? 'Админ',
        }),
      );
      if (res.statusCode == 200) {
        _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Баталгаажуулагдлаа! ✅'), backgroundColor: _orange),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _restorePost(String id) async {
    try {
      final res = await http.put(Uri.parse('http://localhost:3000/api/feedback/$id/restore'));
      if (res.statusCode == 200) {
        _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пост сэргээгдлээ ✅'), backgroundColor: Color(0xFF4CAF50)),
          );
        }
      }
    } catch (_) {}
  }

  List<dynamic> get _currentList {
    switch (_filter) {
      case 'approved': return _approvedPosts;
      case 'deleted': return _deletedPosts;
      default: return _pendingPosts;
    }
  }

  String get _currentTitle {
    switch (_filter) {
      case 'approved': return 'Баталгаажсан нийтлэлүүд';
      case 'deleted': return 'Устгасан нийтлэлүүд';
      default: return 'Баталгаажуулах шаардлагатай';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 14, left: 16, right: 16,
            ),
            color: _orange,
            child: Row(
              children: [
                const Icon(Icons.manage_search, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Удирдлагын самбар',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _orange))
                : RefreshIndicator(
                    color: _orange,
                    onRefresh: _fetchData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _statCircle('Нийт пост', _totalFound, const Color(0xFF2196F3), _filter == 'pending',
                                    () => setState(() => _filter = 'pending')),
                                _statCircle('Баталгаажсан', _approvedCount, const Color(0xFF4CAF50), _filter == 'approved',
                                    () => setState(() => _filter = 'approved')),
                                _statCircle('Устгасан', _deletedCount, Colors.red.shade400, _filter == 'deleted',
                                    () => setState(() => _filter = 'deleted')),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(_currentTitle,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          if (_filter == 'deleted')
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                              child: Text('20 хоногийн дотор сэргээх боломжтой',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ),
                          const SizedBox(height: 10),
                          if (_currentList.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(30),
                              child: Center(
                                child: Column(children: [
                                  Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Text('Пост байхгүй байна', style: TextStyle(color: Colors.grey.shade400)),
                                ]),
                              ),
                            )
                          else
                            ..._currentList.map((post) =>
                                _filter == 'deleted' ? _buildDeletedCard(post) : _buildPostCard(post)),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statCircle(String label, int value, Color color, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                  color: isActive ? color : Colors.grey.shade600)),
          const SizedBox(height: 8),
          Container(
            width: 84, height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isActive ? color : Colors.grey.shade200, width: isActive ? 3 : 2),
            ),
            child: Center(
              child: Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    final message = post['message']?.toString() ?? '';
    final userName = post['userName']?.toString() ?? '';
    final busNumber = post['busNumber']?.toString() ?? '';
    final id = post['_id']?.toString() ?? '';
    final mediaUrls = post['mediaUrls'] as List<dynamic>? ?? [];
    final type = post['type']?.toString() ?? '';
    final status = post['status']?.toString() ?? 'pending';

    return GestureDetector(
      onTap: () => _showPostDetail(post),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: mediaUrls.isNotEmpty
                  ? Image.network('http://localhost:3000${mediaUrls[0]}',
                      width: 70, height: 70, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder())
                  : _imgPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _badge(type.toUpperCase(), _typeColor(type)),
                    if (status == 'approved') ...[const SizedBox(width: 4), _badge('БАТАЛГААЖСАН', const Color(0xFF4CAF50))],
                  ]),
                  const SizedBox(height: 4),
                  Text(message, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, height: 1.3)),
                  const SizedBox(height: 3),
                  Text('$userName${busNumber.isNotEmpty ? ' · $busNumber' : ''}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  if (status == 'pending') ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _actionBtn('Баталгаажуулах', const Color(0xFF4CAF50), () => _approvePost(id))),
                      const SizedBox(width: 8),
                      Expanded(child: _actionBtn('Устгах', Colors.red.shade400, () => _deletePost(id))),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletedCard(dynamic post) {
    final message = post['message']?.toString() ?? '';
    final userName = post['userName']?.toString() ?? '';
    final id = post['_id']?.toString() ?? '';
    final type = post['type']?.toString() ?? '';
    final deletedAt = post['deletedAt']?.toString();
    String daysLeftText = '';
    if (deletedAt != null) {
      final d = DateTime.tryParse(deletedAt);
      if (d != null) {
        final left = d.add(const Duration(days: 20)).difference(DateTime.now()).inDays;
        daysLeftText = left > 0 ? '$left хоног үлдсэн' : 'Удахгүй устна';
      }
    }

    return GestureDetector(
      onTap: () => _showPostDetail(post),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [_badge('УСТГАСАН', Colors.red.shade400), const SizedBox(width: 6),
                Text(type.toUpperCase(), style: TextStyle(fontSize: 9, color: Colors.grey.shade500))]),
              const SizedBox(height: 4),
              Text(message.length > 60 ? '${message.substring(0, 60)}...' : message,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text('$userName · $daysLeftText', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ]),
          ),
          const SizedBox(width: 8),
          _actionBtn('Сэргээх', _orange, () => _restorePost(id), small: true),
        ]),
      ),
    );
  }

  void _showPostDetail(dynamic post) {
    final message = post['message']?.toString() ?? '';
    final userName = post['userName']?.toString() ?? '';
    final busNumber = post['busNumber']?.toString() ?? '';
    final type = post['type']?.toString() ?? '';
    final category = post['category']?.toString() ?? '';
    final status = post['status']?.toString() ?? '';
    final id = post['_id']?.toString() ?? '';
    final mediaUrls = post['mediaUrls'] as List<dynamic>? ?? [];
    final isDeleted = post['isDeleted'] == true;
    final createdAt = post['createdAt']?.toString() ?? '';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
          builder: (_, scrollCtrl) {
            return SingleChildScrollView(
              controller: scrollCtrl, padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  _badge(type.toUpperCase(), _typeColor(type)),
                  if (category.isNotEmpty) ...[const SizedBox(width: 6), _badge(category, _orange)],
                  const Spacer(),
                  if (isDeleted) _badge('УСТГАСАН', Colors.red.shade400)
                  else if (status == 'approved') _badge('БАТАЛГААЖСАН', const Color(0xFF4CAF50))
                  else if (status == 'pending') _badge('ХҮЛЭЭГДЭЖ БАЙНА', Colors.orange),
                ]),
                const SizedBox(height: 16),
                if (mediaUrls.isNotEmpty)
                  SizedBox(height: 220, child: ListView.separated(
                    scrollDirection: Axis.horizontal, itemCount: mediaUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(10),
                        child: Image.network('http://localhost:3000${mediaUrls[i]}',
                            height: 220, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 200, height: 220,
                                color: Colors.grey.shade200, child: const Icon(Icons.broken_image)))),
                  )),
                if (mediaUrls.isNotEmpty) const SizedBox(height: 16),
                Text(message, style: const TextStyle(fontSize: 15, height: 1.5)),
                const SizedBox(height: 16),
                _detailRow('Нийтлэгч', userName),
                if (busNumber.isNotEmpty) _detailRow('Чиглэл', busNumber),
                if (createdAt.isNotEmpty) _detailRow('Огноо', _formatDate(createdAt)),
                const SizedBox(height: 20),
                if (!isDeleted && status == 'pending')
                  Row(children: [
                    Expanded(child: _bigBtn('Баталгаажуулах', const Color(0xFF4CAF50), () { Navigator.pop(ctx); _approvePost(id); })),
                    const SizedBox(width: 12),
                    Expanded(child: _bigBtn('Устгах', Colors.red.shade400, () { Navigator.pop(ctx); _deletePost(id); })),
                  ]),
                if (!isDeleted && status == 'approved')
                  _bigBtn('Устгах', Colors.red.shade400, () { Navigator.pop(ctx); _deletePost(id); }),
                if (isDeleted)
                  _bigBtn('Сэргээх', _orange, () { Navigator.pop(ctx); _restorePost(id); }),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _imgPlaceholder() => Container(width: 70, height: 70, color: Colors.grey.shade200,
      child: const Icon(Icons.image, color: Colors.grey));

  Widget _badge(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)));

  Widget _actionBtn(String label, Color color, VoidCallback onTap, {bool small = false}) => SizedBox(
      height: small ? 30 : 34,
      child: ElevatedButton(onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: EdgeInsets.symmetric(horizontal: small ? 12 : 0), elevation: 0),
        child: Text(label, style: TextStyle(fontSize: small ? 11 : 12, fontWeight: FontWeight.w600))));

  Widget _bigBtn(String label, Color color, VoidCallback onTap) => SizedBox(
      width: double.infinity, height: 46,
      child: ElevatedButton(onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
        child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))));

  Widget _detailRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]));

  Color _typeColor(String type) {
    switch (type) {
      case 'гомдол': return Colors.red.shade400;
      case 'санал': return Colors.blue.shade400;
      case 'олдсон': return Colors.green.shade400;
      case 'алдсан': return Colors.orange.shade400;
      default: return Colors.grey;
    }
  }

  String _formatDate(String s) {
    final d = DateTime.tryParse(s);
    if (d == null) return s;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}