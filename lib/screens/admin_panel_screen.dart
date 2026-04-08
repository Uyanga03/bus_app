import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class AdminPanelScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminPanelScreen({super.key, required this.user});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  static const _orange = Color(0xFFEF962C);

  List<dynamic> _allPosts = [];
  List<dynamic> _pendingPosts = [];
  bool _isLoading = true;
  int _currentTab = 0; // 0: Нийтгүй, 1: Баталгаажуулах, 2: Чиглэл, 3: Тохиргоо

  // Статистик
  int _totalFound = 0;
  int _pendingCount = 0;
  int _approvedCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http
          .get(Uri.parse('http://localhost:3000/api/feedback'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final found = data.where((p) => p['type'] == 'олдсон').toList();
        setState(() {
          _allPosts = data;
          _pendingPosts = found;
          _totalFound = found.length;
          _pendingCount = (found.length * 0.12).ceil();
          _approvedCount = found.length - _pendingCount;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ── Пост устгах ──
  Future<void> _deletePost(String id) async {
    try {
      await http.delete(Uri.parse('http://localhost:3000/api/feedback/$id'));
      _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пост устгагдлаа'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {}
  }

  // ── Пост баталгаажуулах ──
  void _approvePost(String id) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Баталгаажуулагдлаа!'),
          backgroundColor: _orange,
        ),
      );
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
              left: 16,
              right: 16,
            ),
            color: _orange,
            child: Row(
              children: [
                const Icon(Icons.manage_search, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Олдсон эд зүйлсийн удирдлага',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ── Body ──
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _orange))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Статистик дугуйнууд ──
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _statCircle(
                                label: 'Нийт олдсон',
                                value: _totalFound,
                                color: const Color(0xFF2196F3),
                                progress: 1.0,
                              ),
                              _statCircle(
                                label: 'Баталгаажуулах\nшаардлагатай',
                                value: _pendingCount,
                                color: _orange,
                                progress: _totalFound > 0
                                    ? _pendingCount / _totalFound
                                    : 0,
                              ),
                              _statCircle(
                                label: 'Эзэнд нь\nөгсөн',
                                value: _approvedCount,
                                color: const Color(0xFF4CAF50),
                                progress: _totalFound > 0
                                    ? _approvedCount / _totalFound
                                    : 0,
                              ),
                            ],
                          ),
                        ),

                        // ── Жолооч нарын оруулсан шинэ хүсэлтүүд ──
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Жолооч нарын оруулсан шинэ хүсэлтүүд',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (_pendingPosts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'Одоогоор хүсэлт байхгүй байна',
                                style: TextStyle(color: Color(0xFF999999)),
                              ),
                            ),
                          )
                        else
                          ..._pendingPosts.map((post) => _buildPostCard(post)),
                      ],
                    ),
                  ),
          ),

          // ── Bottom Nav ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _bottomNavItem(Icons.home, 'Нийтгүй', 0),
                _bottomNavItem(Icons.verified_outlined, 'Баталгаажуулах', 1),
                _bottomNavItem(Icons.directions_bus, 'Чиглэл', 2),
                _bottomNavItem(Icons.settings, 'Тохиргоо', 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Статистик дугуй
  // ═══════════════════════════════════════════════════════════════════
  Widget _statCircle({
    required String label,
    required int value,
    required Color color,
    required double progress,
  }) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Пост карт
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPostCard(dynamic post) {
    final message = post['message']?.toString() ?? '';
    final userName = post['userName']?.toString() ?? '';
    final busNumber = post['busNumber']?.toString() ?? '';
    final id = post['_id']?.toString() ?? '';
    final mediaUrls = post['mediaUrls'] as List<dynamic>? ?? [];
    final createdAt = post['createdAt']?.toString() ?? '';

    // Мессежээс мэдээлэл задлах
    final lines = message.split('\n');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Зураг
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: mediaUrls.isNotEmpty
                ? Image.network(
                    'http://localhost:3000${mediaUrls[0]}',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 12),

          // Мэдээлэл
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...lines.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    line,
                    style: const TextStyle(fontSize: 13, height: 1.3),
                  ),
                )),
                if (busNumber.isNotEmpty)
                  Text(
                    'Чиглэл: $busNumber',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                if (userName.isNotEmpty)
                  Text(
                    'Жолооч: $userName',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                const SizedBox(height: 8),

                // Товчнууд
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () => _approvePost(id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                            elevation: 0,
                          ),
                          child: const Text('Баталгаажуулах',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () => _deletePost(id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                            elevation: 0,
                          ),
                          child: const Text('Устгах',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Bottom Nav Item
  // ═══════════════════════════════════════════════════════════════════
  Widget _bottomNavItem(IconData icon, String label, int index) {
    final isActive = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isActive ? _orange : Colors.grey.shade500),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? _orange : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}