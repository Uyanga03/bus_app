import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'camera_capture_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'change_phone_screen.dart';
import 'change_password_screen.dart';
import 'driver_post_screen.dart';
import 'admin_panel_screen.dart';
import 'chat_list_screen.dart';
import 'user_profile_screen.dart';
import 'notification_screen.dart';

class FeedbackContent extends StatefulWidget {
  const FeedbackContent({super.key});

  @override
  State<FeedbackContent> createState() => FeedbackContentState();
}

class FeedbackContentState extends State<FeedbackContent>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _busController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<dynamic> feedbacks = [];
  bool isFeedbackLoading = true;
  String? feedbackError;

  // Шинэ post-ийн зураг/бичлэг
  List<XFile> _selectedMedia = [];

  // Бүртгэлтэй хэрэглэгчийн мэдээлэл (null бол бүртгэлгүй)
  // TODO: Жинхэнэ auth системтэй холбох
  Map<String, dynamic>? _currentUser; // {'name': 'Батаа', 'id': '...'}

  // Нээлттэй comment хэсгийн post id
  String? _expandedCommentId;

  // Like дарсан post-уудын id жагсаалт (локал state)
  Set<String> _likedPostIds = {};

  // ═══════════════════════════════════════════════════════════════════
  //  ШИНЭ: Хайлт + Hamburger цэсний state
  // ═══════════════════════════════════════════════════════════════════
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isMenuOpen = false;
  Uint8List? _profileImageBytes; // Профайл зураг
  int _unreadNotifCount = 0; // Уншаагүй мэдэгдэл тоо

  static const List<String> _feedbackTabs = [
    'БҮГД',
    'ГОМДОЛ',
    'САНАЛ',
    'ОЛДСОН',
    'АЛДСАН',
    'ЧАТ',
  ];
  static const Map<int, String> _tabTypeMap = {
    1: 'гомдол',
    2: 'санал',
    3: 'олдсон',
    4: 'алдсан',
    5: 'чат',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _feedbackTabs.length, vsync: this);
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        // ЧАТ таб дарагдсан бол чат дэлгэц нээнэ
        if (_tabController!.index == 5 && _currentUser != null) {
          _tabController!.animateTo(0); // Буцаж БҮГД таб руу
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatListScreen(user: _currentUser!),
            ),
          );
          return;
        }
        if (_tabController!.index == 5 && _currentUser == null) {
          _tabController!.animateTo(0);
          _showLoginPrompt('Чат ашиглахын тулд нэвтэрнэ үү.');
          return;
        }
        fetchFeedbacks();
      }
    });
    _loadSavedUser(); // Хадгалсан хэрэглэгчийн мэдээлэл унших
    fetchFeedbacks();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Хэрэглэгчийн мэдээлэл хадгалах / унших (SharedPreferences)
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('currentUser');
    if (userJson != null) {
      setState(() {
        _currentUser = json.decode(userJson) as Map<String, dynamic>;
      });
    }
    // Профайл зураг унших
    final imageBase64 = prefs.getString('profileImage');
    if (imageBase64 != null) {
      setState(() {
        _profileImageBytes = base64Decode(imageBase64);
      });
    }
    // Мэдэгдлийн тоо авах
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    if (_currentUser == null) return;
    try {
      final res = await http.get(
        Uri.parse('http://localhost:3000/api/notifications/${_currentUser!['id']}/unread-count'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => _unreadNotifCount = data['count'] ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser', json.encode(user));
  }

  Future<void> _clearSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _busController.dispose();
    _commentController.dispose();
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  // =====================================================================
  //  API
  // =====================================================================
  Future<void> fetchFeedbacks() async {
    setState(() => isFeedbackLoading = true);

    String url = "http://localhost:3000/api/feedback";
    final tabIndex = _tabController?.index ?? 0;
    if (tabIndex > 0 && _tabTypeMap.containsKey(tabIndex)) {
      url += "?type=${_tabTypeMap[tabIndex]}";
    }

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Серверээс like дарсан мэдээлэл авах
        _likedPostIds.clear();
        if (_currentUser != null) {
          for (final item in data) {
            final likedBy = item['likedBy'] as List<dynamic>? ?? [];
            if (likedBy.contains(_currentUser!['id'])) {
              _likedPostIds.add(item['_id']?.toString() ?? '');
            }
          }
        }

        setState(() {
          feedbacks = data;
          isFeedbackLoading = false;
          feedbackError = null;
        });
        _fetchUnreadCount(); // Мэдэгдлийн тоо шинэчлэх
      } else {
        setState(() {
          isFeedbackLoading = false;
          feedbackError = 'Сервертэй холбогдож чадсангүй';
        });
      }
    } catch (e) {
      setState(() {
        isFeedbackLoading = false;
        feedbackError = 'Сүлжээний алдаа';
      });
    }
  }

  // ── Post илгээх ──
  Future<void> submitFeedback(String type, {bool anonymous = true}) async {
    if (_messageController.text.trim().isEmpty && _selectedMedia.isEmpty) {
      return;
    }
    const url = "http://localhost:3000/api/feedback";

    String userName;
    if (_currentUser != null && !anonymous) {
      userName = _currentUser!['name'] ?? 'Хэрэглэгч';
    } else {
      userName = 'Нууц хэрэглэгч';
    }

    try {
      if (_selectedMedia.isNotEmpty) {
        final request = http.MultipartRequest('POST', Uri.parse(url));
        request.fields['type'] = type;
        request.fields['message'] = _messageController.text.trim();
        request.fields['busNumber'] = _busController.text.trim();
        request.fields['userName'] = userName;
        if (_currentUser != null) {
          request.fields['userId'] = _currentUser!['id'] ?? '';
        }
        for (final file in _selectedMedia) {
          final bytes = await file.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'media',
            bytes,
            filename: file.name,
          ));
        }
        final res = await request.send();
        if (res.statusCode == 201) _onSubmitSuccess();
      } else {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'type': type,
            'message': _messageController.text.trim(),
            'busNumber': _busController.text.trim(),
            'userName': userName,
            if (_currentUser != null) 'userId': _currentUser!['id'] ?? '',
          }),
        );
        if (response.statusCode == 201) _onSubmitSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Алдаа: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onSubmitSuccess() {
    _messageController.clear();
    _busController.clear();
    _selectedMedia.clear();
    if (mounted) Navigator.pop(context);
    fetchFeedbacks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Амжилттай илгээгдлээ!'),
          backgroundColor: Color(0xFFF57C00),
        ),
      );
    }
  }

  // ── Like (1 account = 1 удаа) ──
  Future<void> likeFeedback(String id) async {
    if (_currentUser == null) {
      _showLoginPrompt('Зүрх дарахын тулд нэвтэрнэ үү.');
      return;
    }

    // Аль хэдийн дарсан бол буцаана
    if (_likedPostIds.contains(id)) return;

    final url = "http://localhost:3000/api/feedback/$id/like";
    try {
      await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _currentUser!['id'],
          'userName': _currentUser!['name'] ?? '',
        }),
      );
      setState(() => _likedPostIds.add(id));
      fetchFeedbacks();
    } catch (_) {}
  }

  // ── Comment ──
  Future<void> submitComment(String feedbackId) async {
    if (_commentController.text.trim().isEmpty) return;
    if (_currentUser == null) {
      _showLoginPrompt('Сэтгэгдэл бичихийн тулд нэвтэрнэ үү.');
      return;
    }
    final url = "http://localhost:3000/api/feedback/$feedbackId/comment";
    try {
      await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': _commentController.text.trim(),
          'userName': _currentUser!['name'] ?? 'Хэрэглэгч',
          'userId': _currentUser!['id'] ?? '',
        }),
      );
      _commentController.clear();
      fetchFeedbacks();
    } catch (_) {}
  }

  void _showLoginPrompt(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey.shade700,
        action: SnackBarAction(
          label: 'Нэвтрэх',
          textColor: const Color(0xFFF57C00),
          onPressed: () => _navigateToLogin(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Нэвтрэх / Бүртгүүлэх дэлгэц рүү navigate
  // ═══════════════════════════════════════════════════════════════════
  void _navigateToLogin() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _currentUser = result;
      });
      _saveUser(result); // Хадгалах
      fetchFeedbacks();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result['name']} нэвтэрлээ!'),
          backgroundColor: const Color(0xFFF57C00),
        ),
      );
    }
  }

  void _navigateToRegister() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _currentUser = result;
      });
      _saveUser(result); // Хадгалах
      fetchFeedbacks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result['name']} бүртгэгдлээ!'),
          backgroundColor: const Color(0xFFF57C00),
        ),
      );
    }
  }

  // =====================================================================
  //  Зураг / Бичлэг сонгох
  // =====================================================================
  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (file != null) _selectedMedia.add(file);
    } catch (_) {}
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final file = await _imagePicker.pickVideo(source: source);
      if (file != null) _selectedMedia.add(file);
    } catch (_) {}
  }

  Future<void> _pickMultiImage() async {
    try {
      final files = await _imagePicker.pickMultiImage(imageQuality: 80);
      _selectedMedia.addAll(files);
    } catch (_) {}
  }

  // Галерей icon дарахад шууд утасны зураг/бичлэг нээгдэнэ
  void _openGallery(StateSetter setModalState) async {
    try {
      final files = await _imagePicker.pickMultipleMedia(maxWidth: 1920);
      if (files.isNotEmpty) {
        _selectedMedia.addAll(files);
        setModalState(() {});
      }
    } catch (_) {
      // pickMultipleMedia дэмжихгүй бол pickMultiImage ашиглана
      try {
        final files = await _imagePicker.pickMultiImage(imageQuality: 85);
        if (files.isNotEmpty) {
          _selectedMedia.addAll(files);
          setModalState(() {});
        }
      } catch (_) {}
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ШИНЭ: Хайлтын шүүлтүүр (локал)
  // ═══════════════════════════════════════════════════════════════════
  List<dynamic> get _filteredFeedbacks {
    if (_searchQuery.isEmpty) return feedbacks;
    final q = _searchQuery.toLowerCase();
    return feedbacks.where((item) {
      final message = (item['message']?.toString() ?? '').toLowerCase();
      final userName = (item['userName']?.toString() ?? '').toLowerCase();
      final busNumber = (item['busNumber']?.toString() ?? '').toLowerCase();
      final type = (item['type']?.toString() ?? '').toLowerCase();
      return message.contains(q) ||
          userName.contains(q) ||
          busNumber.contains(q) ||
          type.contains(q);
    }).toList();
  }

  // =====================================================================
  //  BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // ═════════════════════════════════════════════════════════
            //  ШИНЭ: Хайлтын мөр + Hamburger icon
            // ═════════════════════════════════════════════════════════
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(
                  left: 14, right: 8, top: 8, bottom: 6),
              child: Row(
                children: [
                  // Хайлтын талбар
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Icon(Icons.search,
                              color: Colors.grey.shade500, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(() => _searchQuery = val.trim());
                              },
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Хайх',
                                hintStyle: TextStyle(
                                    fontSize: 14, color: Color(0xFFAAAAAA)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          // Хайлтын текст байвал цэвэрлэх товч
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.close,
                                    size: 18, color: Colors.grey.shade500),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Hamburger icon
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _isMenuOpen = true),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.menu,
                            color: const Color(0xFFF57C00), size: 26),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar (хуучин кодоор)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                    bottom:
                        BorderSide(color: Color(0xFFEEEEEE), width: 1)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xFFF57C00),
                unselectedLabelColor: const Color(0xFF999999),
                indicatorColor: const Color(0xFFF57C00),
                indicatorWeight: 2,
                labelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
                tabs: _feedbackTabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
            Expanded(child: _buildFeedbackBody()),
          ],
        ),

        // ═════════════════════════════════════════════════════════════
        //  ШИНЭ: Hamburger цэс (overlay)
        // ═════════════════════════════════════════════════════════════
        if (_isMenuOpen) _buildSideMenu(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ШИНЭ: Hamburger Side Menu Widget
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSideMenu() {
    return Stack(
      children: [
        // Бараан дэвсгэр (overlay)
        GestureDetector(
          onTap: () => setState(() => _isMenuOpen = false),
          child: Container(color: Colors.black.withOpacity(0.4)),
        ),
        // Цэсний хэсэг (зүүн талаас)
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: MediaQuery.of(context).size.width * 0.78,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                offset: Offset(4, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Header (Profile хэсэг) ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                  color: const Color(0xFFF57C00),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Хаах товч
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => setState(() => _isMenuOpen = false),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Хэрэглэгчийн зураг
                      if (_currentUser != null) ...[
                        GestureDetector(
                          onTap: () async {
                            setState(() => _isMenuOpen = false);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(user: _currentUser!),
                              ),
                            );
                            _loadSavedUser(); // Зураг дахин унших
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white,
                                backgroundImage: _profileImageBytes != null
                                    ? MemoryImage(_profileImageBytes!)
                                    : null,
                                child: _profileImageBytes == null
                                    ? Text(
                                        (_currentUser!['name'] ?? 'Х')[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF57C00),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _currentUser!['name'] ?? 'Хэрэглэгч',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Профайл харах →',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Нэвтрээгүй байна',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Цэсний жагсаалт ──
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (_currentUser != null) ...[
                        _menuItem(
                          icon: Icons.person_outline,
                          label: 'Миний профайл',
                          onTap: () async {
                            setState(() => _isMenuOpen = false);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(user: _currentUser!),
                              ),
                            );
                            _loadSavedUser();
                          },
                        ),
                        // Админ бол "Олдсон эд зүйлсийн удирдлага" харагдана
                        if (_currentUser!['role'] == 'Админ')
                          _menuItem(
                            icon: Icons.manage_search,
                            label: 'Олдсон эд зүйлсийн удирдлага',
                            onTap: () {
                              setState(() => _isMenuOpen = false);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminPanelScreen(user: _currentUser!),
                                ),
                              );
                            },
                          ),
                        _menuItem(
                          icon: Icons.settings_outlined,
                          label: 'Миний тохиргоо',
                          onTap: () async {
                            setState(() => _isMenuOpen = false);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SettingsScreen(user: _currentUser!),
                              ),
                            );
                            _loadSavedUser();
                          },
                        ),
                        _menuItem(
                          icon: Icons.article_outlined,
                          label: 'Миний постууд',
                          onTap: () {
                            setState(() => _isMenuOpen = false);
                            // TODO: Миний постууд дэлгэц
                          },
                        ),
                        _menuItem(
                          icon: Icons.notifications_outlined,
                          label: 'Мэдэгдэл',
                          badge: _unreadNotifCount > 0 ? _unreadNotifCount : null,
                          onTap: () async {
                            setState(() => _isMenuOpen = false);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotificationScreen(user: _currentUser!),
                              ),
                            );
                            _fetchUnreadCount(); // Буцахад тоог шинэчлэх
                          },
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _menuItem(
                          icon: Icons.swap_horiz,
                          label: 'Өөр бүртгэлээр нэвтрэх',
                          onTap: () {
                            setState(() {
                              _isMenuOpen = false;
                              _currentUser = null;
                            });
                            _clearSavedUser();
                            _navigateToLogin();
                          },
                        ),
                      ] else ...[
                        _menuItem(
                          icon: Icons.login,
                          label: 'Нэвтрэх',
                          onTap: () {
                            setState(() => _isMenuOpen = false);
                            _navigateToLogin();
                          },
                        ),
                        _menuItem(
                          icon: Icons.person_add_outlined,
                          label: 'Бүртгүүлэх',
                          onTap: () {
                            setState(() => _isMenuOpen = false);
                            _navigateToRegister();
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Системээс гарах ──
                if (_currentUser != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentUser = null;
                            _isMenuOpen = false;
                          });
                          _clearSavedUser(); // Хадгалсан мэдээлэл устгах
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Системээс гарах',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Hamburger цэсний нэг мөр
  Widget _menuItem({
    required IconData icon,
    required String label,
    int? badge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF333333), size: 22),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF57C00),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
        ],
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  /// Гаднаас FAB дарахад дуудна
  void showAddDialog() {
    // Жолооч бол тусгай дэлгэц нээнэ
    if (_currentUser != null && _currentUser!['role'] == 'Жолооч') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverPostScreen(user: _currentUser!),
        ),
      ).then((result) {
        if (result == true) fetchFeedbacks();
      });
    } else {
      _showAddDialog();
    }
  }

  /// Камер FAB дарахад → бүтэн камер дэлгэц нээгдэнэ
  void showCameraPicker() async {
    final result = await Navigator.push<List<XFile>>(
      context,
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );

    if (result != null && result.isNotEmpty) {
      _selectedMedia = result;
      _showAddDialog(); // Зураг аваад шууд post dialog нээнэ
    }
  }

  /// Gallery FAB / icon дарахад → утасны галерей нээгдэнэ
  void showGalleryPicker() async {
    try {
      final files = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (files.isNotEmpty) {
        _selectedMedia = files;
        _showAddDialog();
      }
    } catch (_) {}
  }

  // ── Body ──
  Widget _buildFeedbackBody() {
    if (isFeedbackLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF57C00)),
      );
    }

    if (feedbackError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 12),
            Text(feedbackError!,
                style:
                    const TextStyle(fontSize: 14, color: Color(0xFF999999))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isFeedbackLoading = true;
                  feedbackError = null;
                });
                fetchFeedbacks();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Дахин оролдох'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF57C00),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // ШИНЭ: Хайлтын шүүлтүүр ашиглана
    final displayList = _filteredFeedbacks;

    if (displayList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.chat_bubble_outline,
              size: 48,
              color: const Color(0xFFDDDDDD),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? '"$_searchQuery" илэрц олдсонгүй'
                  : 'Одоогоор санал гомдол алга байна.',
              style:
                  const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFF57C00),
      onRefresh: fetchFeedbacks,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: displayList.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (_, i) => _buildFeedbackCard(displayList[i]),
      ),
    );
  }

  // =====================================================================
  //  Feedback Card  (ХУУЧИН КОДООР — ӨӨРЧЛӨЛТГҮЙ)
  // =====================================================================
  Widget _buildFeedbackCard(dynamic item) {
    final type = item['type']?.toString() ?? '';
    final message = item['message']?.toString() ?? '';
    final userName = item['userName']?.toString() ?? 'Зочин';
    final busNumber = item['busNumber']?.toString() ?? '';
    final likes = item['likes'] ?? 0;
    final commentsList = item['commentsList'] as List<dynamic>? ?? [];
    final commentCount = item['comments'] ?? commentsList.length;
    final timeAgo = _timeAgo(item['createdAt']?.toString());
    final id = item['_id']?.toString() ?? '';
    final mediaUrls = item['mediaUrls'] as List<dynamic>? ?? [];
    final isCommentOpen = _expandedCommentId == id;
    final bool hasLiked = _likedPostIds.contains(id);
    final postUserId = item['userId']?.toString() ?? '';

    // Өөрийн пост мөн эсэх шалгах
    final bool isMyPost = _currentUser != null &&
        (postUserId == _currentUser!['id'] ||
         userName == _currentUser!['name']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Avatar + нэр + чиглэл + төрөл + цаг ──
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_currentUser == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(
                        currentUser: _currentUser!,
                        userName: userName,
                        userId: postUserId,
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: _typeColor(type).withOpacity(0.2),
                  backgroundImage: (isMyPost && _profileImageBytes != null)
                      ? MemoryImage(_profileImageBytes!)
                      : null,
                  child: (isMyPost && _profileImageBytes != null)
                      ? null
                      : Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'З',
                          style: TextStyle(
                              color: _typeColor(type), fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              if (_currentUser == null) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileScreen(
                                    currentUser: _currentUser!,
                                    userName: userName,
                                    userId: postUserId,
                                  ),
                                ),
                              );
                            },
                            child: Text(userName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        if (busNumber.isNotEmpty) ...[
                          const Text(' · ',
                              style: TextStyle(color: Colors.grey)),
                          Flexible(
                            child: Text('$busNumber-р чиглэл',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFF57C00),
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _typeColor(type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(_typeLabel(type),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _typeColor(type),
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(timeAgo,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF999999)),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Мессеж ──
          if (message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],

          // ── Зураг/бичлэг ──
          if (mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildMediaGrid(mediaUrls),
          ],

          const SizedBox(height: 10),

          // ── ♡ Like  +  💬 Comment  +  🔗 Share товчнууд ──
          Row(
            children: [
              // Like
              GestureDetector(
                onTap: () => likeFeedback(id),
                child: Row(
                  children: [
                    Icon(
                      hasLiked ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color:
                          hasLiked ? Colors.red.shade400 : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$likes',
                      style: TextStyle(
                        fontSize: 13,
                        color: hasLiked
                            ? Colors.red.shade400
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Comment
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedCommentId = isCommentOpen ? null : id;
                  });
                },
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 18, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('$commentCount',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Share
              GestureDetector(
                onTap: () => _showShareSheet(
                  userName: userName,
                  message: message,
                  busNumber: busNumber,
                  type: type,
                ),
                child: Icon(Icons.share_outlined,
                    size: 18, color: Colors.grey.shade500),
              ),
            ],
          ),

          // ── Comment хэсэг (нээгдсэн бол) ──
          if (isCommentOpen) ...[
            const SizedBox(height: 10),
            _buildCommentSection(id, commentsList),
          ],
        ],
      ),
    );
  }

  // ── Зураг grid ──
  String _fullMediaUrl(String url) {
    if (url.startsWith('http')) return url;
    return 'http://localhost:3000$url';
  }

  Widget _buildMediaGrid(List<dynamic> mediaUrls) {
    if (mediaUrls.length == 1) {
      return GestureDetector(
        onTap: () => _showFullImage(_fullMediaUrl(mediaUrls[0].toString())),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            _fullMediaUrl(mediaUrls[0].toString()),
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: Colors.grey.shade200,
              child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey)),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: mediaUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return GestureDetector(
            onTap: () => _showFullImage(_fullMediaUrl(mediaUrls[i].toString())),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                _fullMediaUrl(mediaUrls[i].toString()),
                width: 200,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 200,
                  height: 160,
                  color: Colors.grey.shade200,
                  child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Share bottom sheet ──
  void _showShareSheet({
    required String userName,
    required String message,
    required String busNumber,
    required String type,
  }) {
    final shareText = '$userName${busNumber.isNotEmpty ? ' · $busNumber-р чиглэл' : ''}\n$message';
    final shareUrl = 'https://bussmartbus.share/$type';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Холбоос хуваалцах',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // URL хуулах
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        shareUrl,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Clipboard хуулах
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Холбоос хуулагдлаа!'),
                            backgroundColor: Color(0xFFF57C00),
                          ),
                        );
                      },
                      child: const Icon(Icons.copy, size: 20, color: Color(0xFFF57C00)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Таалагдсан апп-ууд
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Таалагдсан',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _shareIcon(
                    icon: Icons.camera_alt,
                    label: 'Instagram',
                    color: const Color(0xFFE1306C),
                    onTap: () => _launchShare('https://www.instagram.com/', shareText),
                  ),
                  _shareIcon(
                    icon: Icons.tiktok,
                    label: 'TikTok',
                    color: Colors.black,
                    onTap: () => _launchShare('https://www.tiktok.com/', shareText),
                  ),
                  _shareIcon(
                    icon: Icons.chat,
                    label: 'Messenger',
                    color: const Color(0xFF0084FF),
                    onTap: () => _launchShare('https://m.me/', shareText),
                  ),
                  _shareIcon(
                    icon: Icons.email,
                    label: 'Gmail',
                    color: const Color(0xFFEA4335),
                    onTap: () => _launchShare(
                      'mailto:?subject=BusApp&body=${Uri.encodeComponent(shareText)}',
                      shareText,
                    ),
                  ),
                  _shareIcon(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    color: const Color(0xFF1877F2),
                    onTap: () => _launchShare(
                      'https://www.facebook.com/sharer/sharer.php?quote=${Uri.encodeComponent(shareText)}',
                      shareText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  void _launchShare(String url, String text) async {
    Navigator.pop(context);
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  // ── Comment section ──
  Widget _buildCommentSection(String feedbackId, List<dynamic> comments) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Одоо байгаа сэтгэгдлүүд
          if (comments.isNotEmpty)
            ...comments.map((c) {
              final cName = c['userName']?.toString() ?? 'Хэрэглэгч';
              final cMsg = c['message']?.toString() ?? '';
              final cTime = _timeAgo(c['createdAt']?.toString());
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey.shade400,
                      child: Text(
                        cName.isNotEmpty ? cName[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(cName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 6),
                              Text(cTime,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF999999))),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(cMsg,
                              style: const TextStyle(
                                  fontSize: 13, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

          if (comments.isNotEmpty)
            Divider(height: 16, color: Colors.grey.shade300),

          // Сэтгэгдэл бичих input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: _currentUser != null
                        ? 'Сэтгэгдэл бичих...'
                        : 'Нэвтэрч сэтгэгдэл бичнэ үү',
                    hintStyle:
                        TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Color(0xFFF57C00)),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => submitComment(feedbackId),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF57C00),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child:
                      const Icon(Icons.send, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================================
  //  Шинэ post нэмэх (+ товч дарахад)  — ХУУЧИН КОДООР
  // =====================================================================
  void _showAddDialog() {
    String selectedType = 'санал';
    bool isAnonymous = _currentUser == null;
    _selectedMedia = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Handle bar ──
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Header ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Мэдээлэл оруулах',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () {
                            _selectedMedia.clear();
                            Navigator.pop(context);
                          },
                          child: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Хэрэглэгчийн хаяг сонголт ──
                    if (_currentUser != null) ...[
                      const Text('Нийтлэх хэлбэр:',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _identityChip(
                            label: _currentUser!['name'] ?? 'Хэрэглэгч',
                            icon: Icons.person,
                            isSelected: !isAnonymous,
                            onTap: () =>
                                setModalState(() => isAnonymous = false),
                          ),
                          const SizedBox(width: 8),
                          _identityChip(
                            label: 'Нууц хэрэглэгч',
                            icon: Icons.visibility_off,
                            isSelected: isAnonymous,
                            onTap: () =>
                                setModalState(() => isAnonymous = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Төрөл ──
                    const Text('Төрөл:',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          ['гомдол', 'санал', 'олдсон', 'алдсан'].map((t) {
                        final sel = selectedType == t;
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedType = t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? _typeColor(t)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_typeLabel(t),
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      sel ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── Автобусны дугаар ──
                    _inputField(
                        _busController, 'Автобусны чиглэлийн дугаар'),
                    const SizedBox(height: 10),

                    // ── Мессеж ──
                    _inputField(
                        _messageController, 'Санал гомдлоо бичнэ үү...',
                        maxLines: 4),
                    const SizedBox(height: 12),

                    // ── Сонгосон зураг/бичлэг preview ──
                    if (_selectedMedia.isNotEmpty) ...[
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedMedia.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final file = _selectedMedia[i];
                            final isVid = file.path.endsWith('.mp4') ||
                                file.path.endsWith('.mov') ||
                                file.path.endsWith('.avi');
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: isVid
                                      ? Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.black87,
                                          child: const Center(
                                            child: Icon(
                                                Icons.play_circle_fill,
                                                color: Colors.white,
                                                size: 32),
                                          ),
                                        )
                                      : FutureBuilder<Uint8List>(
                                          future: file.readAsBytes().then((bytes) => Uint8List.fromList(bytes)),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              return Image.memory(
                                                snapshot.data!,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              );
                                            }
                                            return Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey.shade200,
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFFF57C00),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => setModalState(
                                        () => _selectedMedia.removeAt(i)),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── 🖼 Галерей + Нийтлэх товчнууд ──
                    Row(
                      children: [
                        // Галерей icon (дарахад зураг/бичлэг сонгоно)
                        _actionButton(
                          icon: Icons.photo_library_rounded,
                          onTap: () => _openGallery(setModalState),
                        ),
                        const Spacer(),
                        // Нийтлэх
                        SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () => submitFeedback(selectedType,
                                anonymous: isAnonymous),
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Нийтлэх',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF57C00),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _actionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF57C00).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFF57C00), size: 24),
      ),
    );
  }

  Widget _identityChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFFF57C00) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF57C00)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color:
                    isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF57C00)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  // ── Туслах функцүүд ──
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

  Color _typeColor(String? type) {
    switch (type) {
      case 'гомдол':
        return Colors.red.shade400;
      case 'санал':
        return Colors.blue.shade400;
      case 'олдсон':
        return Colors.green.shade400;
      case 'алдсан':
        return Colors.orange.shade400;
      case 'чат':
        return Colors.purple.shade400;
      default:
        return Colors.grey;
    }
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'гомдол':
        return 'Гомдол';
      case 'санал':
        return 'Санал';
      case 'олдсон':
        return 'Олдсон';
      case 'алдсан':
        return 'Алдсан';
      case 'чат':
        return 'Чат';
      default:
        return '';
    }
  }
}