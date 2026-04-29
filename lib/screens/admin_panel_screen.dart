import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPanelScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String initialPage;
  const AdminPanelScreen({super.key, required this.user, this.initialPage = 'posts'});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  static const _orange = Color(0xFFEF962C);

  // ── Нийтлэлийн state ──
  List<dynamic> _allPosts = [];
  List<dynamic> _deletedPosts = [];
  bool _isLoading = true;
  String _postFilter = 'all';
  int _totalCount = 0;
  int _deletedCount = 0;
  Set<String> _selectedForDelete = {};
  bool _isSelectMode = false;

  // ── Жолоочийн state ──
  List<dynamic> _allDrivers = [];
  List<dynamic> _deletedDrivers = [];
  String _driverSearchQuery = '';
  Set<String> _selectedDriversForDelete = {};
  bool _isDriverSelectMode = false;

  // ── Цэсний state ──
  String _currentPage = 'posts';

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _fetchData();
  }

  // ════════════════════════════════════════════
  //  DATA FETCH
  // ════════════════════════════════════════════
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchPosts(), _fetchDrivers()]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchPosts() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:3000/api/feedback/admin')).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        setState(() {
          _allPosts = data.where((p) => p['isDeleted'] != true).toList();
          _deletedPosts = data.where((p) => p['isDeleted'] == true).toList();
          _totalCount = _allPosts.length;
          _deletedCount = _deletedPosts.length;
          _selectedForDelete.clear();
          _isSelectMode = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchDrivers() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:3000/api/drivers')).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        setState(() {
          final data = json.decode(res.body) as List;
          _allDrivers = data.where((d) => d['isDeleted'] != true).toList();
          _deletedDrivers = data.where((d) => d['isDeleted'] == true).toList();
          _selectedDriversForDelete.clear();
          _isDriverSelectMode = false;
        });
      }
    } catch (_) {}
  }

  // ════════════════════════════════════════════
  //  POST ACTIONS
  // ════════════════════════════════════════════
  Future<void> _softDeletePost(String id) async {
    try {
      await http.delete(Uri.parse('http://localhost:3000/api/feedback/$id'));
      _fetchPosts();
      _snack('Пост устгагдлаа', Colors.red);
    } catch (_) {}
  }

  Future<void> _restorePost(String id) async {
    try {
      await http.put(Uri.parse('http://localhost:3000/api/feedback/$id/restore'));
      _fetchPosts();
      _snack('Сэргээгдлээ ✅', const Color(0xFF4CAF50));
    } catch (_) {}
  }

  Future<void> _permanentDeletePost(String id) async {
    if (await _confirm('Бүр мөсөн устгах уу?', 'Дахин сэргээх боломжгүй.') != true) return;
    try {
      await http.delete(Uri.parse('http://localhost:3000/api/feedback/$id/permanent'));
      _fetchPosts();
      _snack('Бүрмөсөн устгагдлаа', Colors.red);
    } catch (_) {}
  }

  Future<void> _permanentDeleteSelectedPosts() async {
    if (_selectedForDelete.isEmpty) return;
    if (await _confirm('${_selectedForDelete.length} пост устгах уу?', 'Дахин сэргээх боломжгүй.') != true) return;
    for (final id in _selectedForDelete.toList()) {
      try { await http.delete(Uri.parse('http://localhost:3000/api/feedback/$id/permanent')); } catch (_) {}
    }
    _fetchPosts();
    _snack('${_selectedForDelete.length} пост устгагдлаа', Colors.red);
  }

  Future<void> _permanentDeleteAllPosts() async {
    if (_deletedPosts.isEmpty) return;
    if (await _confirm('Бүх устгасан пост (${_deletedPosts.length}) устгах уу?', 'Дахин сэргээх боломжгүй!') != true) return;
    for (final p in _deletedPosts.toList()) {
      try { await http.delete(Uri.parse('http://localhost:3000/api/feedback/${p['_id']}/permanent')); } catch (_) {}
    }
    _fetchPosts();
    _snack('Бүгд устгагдлаа', Colors.red);
  }

  // ════════════════════════════════════════════
  //  DRIVER ACTIONS
  // ════════════════════════════════════════════
  Future<void> _softDeleteDriver(String id) async {
    try {
      await http.delete(Uri.parse('http://localhost:3000/api/drivers/$id'));
      _fetchDrivers();
      _snack('Жолооч устгагдлаа', Colors.red);
    } catch (_) {}
  }

  Future<void> _restoreDriver(String id) async {
    try {
      await http.put(Uri.parse('http://localhost:3000/api/drivers/$id/restore'));
      _fetchDrivers();
      _snack('Жолооч сэргээгдлээ ✅', const Color(0xFF4CAF50));
    } catch (_) {}
  }

  Future<void> _permanentDeleteDriver(String id) async {
    if (await _confirm('Жолоочийг бүрмөсөн устгах уу?', 'Дахин сэргээх боломжгүй.') != true) return;
    try {
      await http.delete(Uri.parse('http://localhost:3000/api/drivers/$id/permanent'));
      _fetchDrivers();
      _snack('Бүрмөсөн устгагдлаа', Colors.red);
    } catch (_) {}
  }

  Future<void> _permanentDeleteSelectedDrivers() async {
    if (_selectedDriversForDelete.isEmpty) return;
    if (await _confirm('${_selectedDriversForDelete.length} жолооч устгах уу?', 'Дахин сэргээх боломжгүй.') != true) return;
    for (final id in _selectedDriversForDelete.toList()) {
      try { await http.delete(Uri.parse('http://localhost:3000/api/drivers/$id/permanent')); } catch (_) {}
    }
    _fetchDrivers();
    _snack('Устгагдлаа', Colors.red);
  }

  // ════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════
  void _snack(String msg, Color color) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<bool?> _confirm(String title, String msg) {
    return showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: Text(msg, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Болих', style: TextStyle(color: Colors.grey.shade600))),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Устгах')),
      ],
    ));
  }

  // ════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        // AppBar
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 14, left: 16, right: 16),
          color: _orange,
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(_currentPage == 'posts' ? 'Нийтлэлийн удирдлага' : 'Жолоочийн бүртгэл',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            // Цэс солих
            IconButton(
              icon: Icon(_currentPage == 'posts' ? Icons.people : Icons.article_outlined, color: Colors.white),
              tooltip: _currentPage == 'posts' ? 'Жолоочийн бүртгэл' : 'Нийтлэлийн удирдлага',
              onPressed: () => setState(() {
                _currentPage = _currentPage == 'posts' ? 'drivers' : 'posts';
              }),
            ),
          ]),
        ),

        // Body
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: _orange))
              : _currentPage == 'posts' ? _buildPostsPage() : _buildDriversPage(),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════
  //  POSTS PAGE
  // ════════════════════════════════════════════
  Widget _buildPostsPage() {
    final list = _postFilter == 'deleted' ? _deletedPosts : _allPosts;
    return RefreshIndicator(
      color: _orange, onRefresh: _fetchPosts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Stats
          Padding(padding: const EdgeInsets.all(16), child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _statCircle('Нийт пост', _totalCount, const Color(0xFF2196F3), _postFilter == 'all',
                  () => setState(() { _postFilter = 'all'; _isSelectMode = false; })),
              _statCircle('Устгасан', _deletedCount, Colors.red.shade400, _postFilter == 'deleted',
                  () => setState(() { _postFilter = 'deleted'; _isSelectMode = false; })),
            ],
          )),
          // Title + actions
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
            Text(_postFilter == 'deleted' ? 'Устгасан нийтлэлүүд' : 'Бүх нийтлэлүүд',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_postFilter == 'deleted' && _deletedPosts.isNotEmpty) ...[
              _tapText(_isSelectMode ? 'Болих' : 'Сонгох', _orange, () => setState(() { _isSelectMode = !_isSelectMode; _selectedForDelete.clear(); })),
              const SizedBox(width: 12),
              _tapText('Бүгдийг устгах', Colors.red.shade400, _permanentDeleteAllPosts),
            ],
          ])),
          if (_isSelectMode && _selectedForDelete.isNotEmpty)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: SizedBox(width: double.infinity, height: 40,
              child: ElevatedButton.icon(onPressed: _permanentDeleteSelectedPosts,
                icon: const Icon(Icons.delete_forever, size: 18),
                label: Text('${_selectedForDelete.length} устгах'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))))),
          if (_postFilter == 'deleted')
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Text('20 хоногийн дотор сэргээх боломжтой', style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
          const SizedBox(height: 10),
          if (list.isEmpty) _emptyState('Пост байхгүй')
          else ...list.map((p) => _postFilter == 'deleted' ? _deletedPostCard(p) : _postCard(p)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════
  //  DRIVERS PAGE
  // ════════════════════════════════════════════
  Widget _buildDriversPage() {
    final searchCtrl = TextEditingController(text: _driverSearchQuery);
    final activeDrivers = _driverSearchQuery.isEmpty ? _allDrivers
        : _allDrivers.where((d) {
            final q = _driverSearchQuery.toLowerCase();
            return (d['firstName']?.toString() ?? '').toLowerCase().contains(q) ||
                   (d['lastName']?.toString() ?? '').toLowerCase().contains(q) ||
                   (d['driverLicense']?.toString() ?? '').toLowerCase().contains(q) ||
                   (d['phone']?.toString() ?? '').toLowerCase().contains(q) ||
                   (d['busRoute']?.toString() ?? '').toLowerCase().contains(q);
          }).toList();

    return RefreshIndicator(
      color: _orange, onRefresh: _fetchDrivers,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Хайлт + Бүртгэх товч
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Expanded(child: TextField(
              controller: searchCtrl,
              onChanged: (v) => setState(() => _driverSearchQuery = v.trim()),
              decoration: InputDecoration(
                hintText: 'Нэр, үнэмлэх, утас хайх',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                filled: true, fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            )),
            const SizedBox(width: 8),
            SizedBox(height: 44, child: ElevatedButton.icon(
              onPressed: () => _showDriverRegisterDialog(),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Бүртгэх', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            )),
          ])),

          // Идэвхтэй жолоочууд
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Бүртгэлтэй жолоочууд (${activeDrivers.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          if (activeDrivers.isEmpty) _emptyState('Жолооч олдсонгүй')
          else ...activeDrivers.map((d) => _driverCard(d)),

          // Устгасан жолоочууд
          if (_deletedDrivers.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
              Text('Устгасан (${_deletedDrivers.length})', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red.shade400)),
              const Spacer(),
              if (!_isDriverSelectMode)
                _tapText('Сонгох', _orange, () => setState(() { _isDriverSelectMode = true; _selectedDriversForDelete.clear(); }))
              else ...[
                _tapText('Болих', Colors.grey, () => setState(() { _isDriverSelectMode = false; _selectedDriversForDelete.clear(); })),
                if (_selectedDriversForDelete.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _tapText('Устгах (${_selectedDriversForDelete.length})', Colors.red, _permanentDeleteSelectedDrivers),
                ],
              ],
            ])),
            const SizedBox(height: 8),
            ..._deletedDrivers.map((d) => _deletedDriverCard(d)),
          ],
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════
  //  DRIVER REGISTER DIALOG
  // ════════════════════════════════════════════
  void _showDriverRegisterDialog({Map<String, dynamic>? editDriver}) {
    final isEdit = editDriver != null;
    final lastNameCtrl = TextEditingController(text: isEdit ? editDriver!['lastName'] : '');
    final firstNameCtrl = TextEditingController(text: isEdit ? editDriver!['firstName'] : '');
    final phoneCtrl = TextEditingController(text: isEdit ? editDriver!['phone'] : '');
    final passwordCtrl = TextEditingController();
    final licenseCtrl = TextEditingController(text: isEdit ? editDriver!['driverLicense'] : '');
    final codeCtrl = TextEditingController(text: isEdit ? editDriver!['companyCode'] : '');
    final companyCtrl = TextEditingController(text: isEdit ? editDriver!['companyName'] : '');
    final routeCtrl = TextEditingController(text: isEdit ? editDriver!['busRoute'] : '');
    final busNumCtrl = TextEditingController(text: isEdit ? editDriver!['busNumber'] : '');

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        bool loading = false;
        return StatefulBuilder(builder: (context, ss) {
          return Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Row(children: [
                Icon(isEdit ? Icons.edit : Icons.person_add, color: _orange, size: 24),
                const SizedBox(width: 8),
                Text(isEdit ? 'Жолооч засах' : 'Жолооч бүртгэх', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, color: Colors.grey)),
              ]),
              const SizedBox(height: 16),
              _sectionLabel('Хувийн мэдээлэл'),
              const SizedBox(height: 8),
              Row(children: [Expanded(child: _field(lastNameCtrl, 'Овог')), const SizedBox(width: 8), Expanded(child: _field(firstNameCtrl, 'Нэр'))]),
              const SizedBox(height: 8),
              _field(phoneCtrl, 'Утас (8 оронтой)', keyboard: TextInputType.phone, maxLen: 8),
              const SizedBox(height: 8),
              _field(passwordCtrl, isEdit ? 'Шинэ нууц үг (хоосон бол өөрчлөхгүй)' : 'Нууц үг (6+ тэмдэгт)', obscure: true),
              const SizedBox(height: 16),
              _sectionLabel('Жолоочийн мэдээлэл'),
              const SizedBox(height: 8),
              _field(licenseCtrl, 'Үнэмлэхний дугаар'),
              const SizedBox(height: 8),
              Row(children: [Expanded(child: _field(codeCtrl, 'Компанийн код')), const SizedBox(width: 8), Expanded(child: _field(companyCtrl, 'Компани / Бааз'))]),
              const SizedBox(height: 16),
              _sectionLabel('Автобусны мэдээлэл'),
              const SizedBox(height: 8),
              Row(children: [Expanded(child: _field(routeCtrl, 'Чиглэл (Ч:19Б)')), const SizedBox(width: 8), Expanded(child: _field(busNumCtrl, 'Автобус дугаар'))]),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
                onPressed: loading ? null : () async {
                  if (lastNameCtrl.text.trim().isEmpty || firstNameCtrl.text.trim().isEmpty) { _snack('Овог, нэр оруулна уу', Colors.red); return; }
                  if (phoneCtrl.text.trim().length != 8) { _snack('Утас 8 оронтой', Colors.red); return; }
                  if (!isEdit && passwordCtrl.text.trim().length < 6) { _snack('Нууц үг 6+ тэмдэгт', Colors.red); return; }
                  if (licenseCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) { _snack('Үнэмлэх, код оруулна уу', Colors.red); return; }
                  ss(() => loading = true);
                  try {
                    final body = {
                      'lastName': lastNameCtrl.text.trim(), 'firstName': firstNameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(), 'driverLicense': licenseCtrl.text.trim(),
                      'companyCode': codeCtrl.text.trim(), 'companyName': companyCtrl.text.trim(),
                      'busRoute': routeCtrl.text.trim(), 'busNumber': busNumCtrl.text.trim(),
                    };
                    if (passwordCtrl.text.trim().isNotEmpty) body['password'] = passwordCtrl.text.trim();
                    final res = isEdit
                        ? await http.put(Uri.parse('http://localhost:3000/api/drivers/${editDriver!['_id']}'),
                            headers: {'Content-Type': 'application/json'}, body: json.encode(body))
                        : await http.post(Uri.parse('http://localhost:3000/api/drivers'),
                            headers: {'Content-Type': 'application/json'}, body: json.encode(body));
                    if (res.statusCode == 200 || res.statusCode == 201) {
                      Navigator.pop(ctx);
                      _fetchDrivers();
                      _snack(isEdit ? 'Засагдлаа ✅' : '${firstNameCtrl.text.trim()} бүртгэгдлээ ✅', const Color(0xFF4CAF50));
                    } else {
                      final data = json.decode(res.body);
                      _snack(data['message'] ?? data['error'] ?? 'Алдаа', Colors.red);
                    }
                  } catch (_) { _snack('Сүлжээний алдаа', Colors.red); }
                  ss(() => loading = false);
                },
                icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(isEdit ? Icons.save : Icons.person_add, size: 20),
                label: Text(loading ? 'Хадгалж байна...' : (isEdit ? 'Хадгалах' : 'Бүртгэх'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
              )),
            ])),
          );
        });
      },
    );
  }

  // ════════════════════════════════════════════
  //  CARDS
  // ════════════════════════════════════════════
  Widget _postCard(dynamic post) {
    final id = post['_id']?.toString() ?? '';
    final message = post['message']?.toString() ?? '';
    final userName = post['userName']?.toString() ?? '';
    final busNumber = post['busNumber']?.toString() ?? '';
    final type = post['type']?.toString() ?? '';
    final mediaUrls = post['mediaUrls'] as List<dynamic>? ?? [];
    final daysAgo = _daysAgo(post['createdAt']?.toString());

    return GestureDetector(
      onTap: () => _showPostDetail(post),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(8),
            child: mediaUrls.isNotEmpty
                ? Image.network('http://localhost:3000${mediaUrls[0]}', width: 70, height: 70, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgBox())
                : _imgBox()),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [_badge(type.toUpperCase(), _typeColor(type)), const Spacer(), Text(daysAgo, style: TextStyle(fontSize: 10, color: Colors.grey.shade400))]),
            const SizedBox(height: 4),
            Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.3)),
            const SizedBox(height: 3),
            Text('$userName${busNumber.isNotEmpty ? ' · $busNumber' : ''}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            _smallBtn('Устгах', Colors.red.shade400, () => _softDeletePost(id)),
          ])),
        ]),
      ),
    );
  }

  Widget _deletedPostCard(dynamic post) {
    final id = post['_id']?.toString() ?? '';
    final message = post['message']?.toString() ?? '';
    final sel = _selectedForDelete.contains(id);
    final daysLeft = _daysLeft(post['deletedAt']?.toString());

    return GestureDetector(
      onTap: () => _isSelectMode ? setState(() { sel ? _selectedForDelete.remove(id) : _selectedForDelete.add(id); }) : _showPostDetail(post),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: sel ? Colors.red.shade50 : Colors.grey.shade50, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? Colors.red.shade300 : Colors.grey.shade300)),
        child: Row(children: [
          if (_isSelectMode) ...[Checkbox(value: sel, onChanged: (v) => setState(() { v == true ? _selectedForDelete.add(id) : _selectedForDelete.remove(id); }),
            activeColor: Colors.red, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact), const SizedBox(width: 4)],
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _badge('УСТГАСАН', Colors.red.shade400),
            const SizedBox(height: 4),
            Text(message.length > 60 ? '${message.substring(0, 60)}...' : message, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            Text(daysLeft, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ])),
          if (!_isSelectMode) ...[const SizedBox(width: 6), Column(children: [
            _smallBtn('Сэргээх', _orange, () => _restorePost(id)),
            const SizedBox(height: 4),
            _smallBtn('Бүрмөсөн', Colors.red.shade700, () => _permanentDeletePost(id)),
          ])],
        ]),
      ),
    );
  }

  Widget _driverCard(dynamic d) {
    final id = d['_id']?.toString() ?? '';
    final name = '${d['lastName'] ?? ''} ${d['firstName'] ?? ''}'.trim();
    final phone = d['phone']?.toString() ?? '';
    final route = d['busRoute']?.toString() ?? '';
    final license = d['driverLicense']?.toString() ?? '';
    final company = d['companyName']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        CircleAvatar(radius: 22, backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
          child: Text(name.isNotEmpty ? name[0] : 'Ж', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Text('$phone · $route${company.isNotEmpty ? ' · $company' : ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          Text('Үнэмлэх: $license', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ])),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') _showDriverRegisterDialog(editDriver: d);
            if (v == 'delete') _softDeleteDriver(id);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Засах')),
            const PopupMenuItem(value: 'delete', child: Text('Устгах', style: TextStyle(color: Colors.red))),
          ],
        ),
      ]),
    );
  }

  Widget _deletedDriverCard(dynamic d) {
    final id = d['_id']?.toString() ?? '';
    final name = '${d['lastName'] ?? ''} ${d['firstName'] ?? ''}'.trim();
    final sel = _selectedDriversForDelete.contains(id);

    return GestureDetector(
      onTap: _isDriverSelectMode ? () => setState(() { sel ? _selectedDriversForDelete.remove(id) : _selectedDriversForDelete.add(id); }) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3), padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: sel ? Colors.red.shade50 : Colors.grey.shade50, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? Colors.red.shade300 : Colors.grey.shade300)),
        child: Row(children: [
          if (_isDriverSelectMode) ...[Checkbox(value: sel, onChanged: (v) => setState(() { v == true ? _selectedDriversForDelete.add(id) : _selectedDriversForDelete.remove(id); }),
            activeColor: Colors.red, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact), const SizedBox(width: 4)],
          Expanded(child: Text(name, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
          if (!_isDriverSelectMode) ...[
            _smallBtn('Сэргээх', _orange, () => _restoreDriver(id)),
            const SizedBox(width: 4),
            _smallBtn('Устгах', Colors.red.shade700, () => _permanentDeleteDriver(id)),
          ],
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════
  //  POST DETAIL
  // ════════════════════════════════════════════
  void _showPostDetail(dynamic post) {
    final message = post['message']?.toString() ?? '';
    final userName = post['userName']?.toString() ?? '';
    final busNumber = post['busNumber']?.toString() ?? '';
    final type = post['type']?.toString() ?? '';
    final category = post['category']?.toString() ?? '';
    final id = post['_id']?.toString() ?? '';
    final mediaUrls = post['mediaUrls'] as List<dynamic>? ?? [];
    final isDeleted = post['isDeleted'] == true;
    final createdAt = post['createdAt']?.toString() ?? '';

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (_, sc) => SingleChildScrollView(controller: sc, padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [_badge(type.toUpperCase(), _typeColor(type)),
              if (category.isNotEmpty) ...[const SizedBox(width: 6), _badge(category, _orange)],
              const Spacer(), if (isDeleted) _badge('УСТГАСАН', Colors.red.shade400)]),
            const SizedBox(height: 16),
            if (mediaUrls.isNotEmpty) SizedBox(height: 220, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: mediaUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(10),
                child: Image.network('http://localhost:3000${mediaUrls[i]}', height: 220, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 200, height: 220, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)))))),
            if (mediaUrls.isNotEmpty) const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 16),
            _detailRow('Нийтлэгч', userName),
            if (busNumber.isNotEmpty) _detailRow('Чиглэл', busNumber),
            if (createdAt.isNotEmpty) _detailRow('Огноо', _fmtDate(createdAt)),
            const SizedBox(height: 20),
            if (!isDeleted) _bigBtn('Устгах', Colors.red.shade400, () { Navigator.pop(ctx); _softDeletePost(id); }),
            if (isDeleted) ...[
              _bigBtn('Сэргээх', _orange, () { Navigator.pop(ctx); _restorePost(id); }),
              const SizedBox(height: 10),
              _bigBtn('Бүрмөсөн устгах', Colors.red.shade700, () { Navigator.pop(ctx); _permanentDeletePost(id); }),
            ],
          ])),
      ),
    );
  }

  // ════════════════════════════════════════════
  //  SHARED WIDGETS
  // ════════════════════════════════════════════
  Widget _statCircle(String l, int v, Color c, bool a, VoidCallback t) => GestureDetector(onTap: t, child: Column(children: [
    Text(l, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: a ? c : Colors.grey.shade600)),
    const SizedBox(height: 8),
    Container(width: 84, height: 84, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: a ? c : Colors.grey.shade200, width: a ? 3 : 2)),
      child: Center(child: Text('$v', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c)))),
  ]));
  Widget _imgBox() => Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey));
  Widget _badge(String t, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
    child: Text(t, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: c)));
  Widget _smallBtn(String l, Color c, VoidCallback t) => SizedBox(height: 28, child: ElevatedButton(onPressed: t,
    style: ElevatedButton.styleFrom(backgroundColor: c, foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), padding: const EdgeInsets.symmetric(horizontal: 10), elevation: 0,
      textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)), child: Text(l)));
  Widget _bigBtn(String l, Color c, VoidCallback t) => SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: t,
    style: ElevatedButton.styleFrom(backgroundColor: c, foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
    child: Text(l, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))));
  Widget _tapText(String l, Color c, VoidCallback t) => GestureDetector(onTap: t, child: Text(l, style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w600)));
  Widget _emptyState(String t) => Padding(padding: const EdgeInsets.all(30), child: Center(child: Column(children: [
    Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade300), const SizedBox(height: 8),
    Text(t, style: TextStyle(color: Colors.grey.shade400))])));
  Widget _detailRow(String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
    Text('$l: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
    Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))]));
  Widget _sectionLabel(String t) => Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF555555)));
  Widget _field(TextEditingController c, String h, {TextInputType? keyboard, bool obscure = false, int? maxLen}) => TextField(
    controller: c, keyboardType: keyboard, obscureText: obscure, maxLength: maxLen, style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(hintText: h, hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400), counterText: '',
      filled: true, fillColor: const Color(0xFFFAFAFA), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _orange))));
  Color _typeColor(String t) { switch(t) { case 'гомдол': return Colors.red.shade400; case 'санал': return Colors.blue.shade400;
    case 'олдсон': return Colors.green.shade400; case 'алдсан': return Colors.orange.shade400; default: return Colors.grey; } }
  String _daysAgo(String? s) { if (s == null) return ''; final d = DateTime.tryParse(s); if (d == null) return '';
    final diff = DateTime.now().difference(d).inDays; return diff == 0 ? 'Өнөөдөр' : diff == 1 ? 'Өчигдөр' : '$diff хоногийн өмнө'; }
  String _daysLeft(String? s) { if (s == null) return ''; final d = DateTime.tryParse(s); if (d == null) return '';
    final left = d.add(const Duration(days: 20)).difference(DateTime.now()).inDays; return left > 0 ? '$left хоног үлдсэн' : 'Удахгүй устна'; }
  String _fmtDate(String s) { final d = DateTime.tryParse(s); if (d == null) return s;
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}'; }
}