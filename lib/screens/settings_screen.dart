import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'change_phone_screen.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _orange = Color(0xFFF57C00);

  Uint8List? _profileImageBytes;
  bool _hasNewImage = false;
  bool _showPhone = false;
  bool _showPassword = false;

  String get _name => widget.user['name']?.toString() ?? 'Хэрэглэгч';
  String get _phone => widget.user['phone']?.toString() ?? '';
  String get _lastName {
    final parts = _name.split(' ');
    return parts.isNotEmpty ? parts[0] : '';
  }
  String get _firstName {
    final parts = _name.split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  @override
  void initState() {
    super.initState();
    _loadSavedProfileImage();
  }

  // Хадгалсан профайл зураг унших
  Future<void> _loadSavedProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imageBase64 = prefs.getString('profileImage');
    if (imageBase64 != null) {
      setState(() {
        _profileImageBytes = base64Decode(imageBase64);
      });
    }
  }

  // Зураг сонгох
  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _profileImageBytes = Uint8List.fromList(bytes);
          _hasNewImage = true;
        });
      }
    } catch (_) {}
  }

  // Зураг хадгалах
  Future<void> _saveProfileImage() async {
    if (_profileImageBytes == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImage', base64Encode(_profileImageBytes!));

    setState(() => _hasNewImage = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Профайл зураг хадгалагдлаа!'),
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
                      'Миний тохиргоо',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // ── Профайл зураг ──
                  if (widget.user['role'] == 'Жолооч') ...[
                    // Жолооч: зураг солих боломжгүй
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(Icons.person_outline, size: 40, color: Colors.grey.shade500),
                    ),
                  ] else ...[
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _profileImageBytes != null
                              ? MemoryImage(_profileImageBytes!)
                              : null,
                          child: _profileImageBytes == null
                              ? Icon(Icons.person_outline,
                                  size: 40, color: Colors.grey.shade500)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // ── Хадгалах + Болих товч (шинэ зураг сонгосон үед) ──
                  if (_hasNewImage) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Болих
                        SizedBox(
                          width: 120,
                          height: 38,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _hasNewImage = false;
                                _loadSavedProfileImage(); // Хуучин зураг руу буцах
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              side: BorderSide(color: Colors.grey.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Болих',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Хадгалах
                        SizedBox(
                          width: 120,
                          height: 38,
                          child: ElevatedButton.icon(
                            onPressed: _saveProfileImage,
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Хадгалах',
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
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Овог ──
                  if (widget.user['role'] == 'Жолооч')
                    _infoCard(label: 'Овог', value: _lastName)
                  else
                    _infoCard(label: 'Овог', value: _lastName),
                  const SizedBox(height: 10),

                  // ── Нэр ──
                  if (widget.user['role'] == 'Жолооч')
                    _infoCard(label: 'Нэр', value: _firstName)
                  else
                    _infoCard(label: 'Нэр', value: _firstName),
                  const SizedBox(height: 10),

                  // ── Утасны дугаар ──
                  _infoCard(
                    label: 'Утасны дугаар',
                    value: _showPhone ? _phone : '••••••••',
                    onEdit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangePhoneScreen(user: widget.user),
                        ),
                      );
                    },
                    onToggleVisibility: () {
                      setState(() => _showPhone = !_showPhone);
                    },
                    isHidden: !_showPhone,
                  ),
                  const SizedBox(height: 10),

                  // ── Нууц үг ──
                  _infoCard(
                    label: 'Нууц үг',
                    value: _showPassword ? (widget.user['password']?.toString() ?? '••••••••') : '••••••••',
                    onEdit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChangePasswordScreen(user: widget.user),
                        ),
                      );
                    },
                    onToggleVisibility: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                    isHidden: !_showPassword,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String label,
    required String value,
    VoidCallback? onEdit,
    VoidCallback? onToggleVisibility,
    bool isHidden = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (onEdit != null) ...[
            GestureDetector(
              onTap: onEdit,
              child: Icon(Icons.edit, size: 20, color: Colors.grey.shade500),
            ),
            const SizedBox(width: 12),
          ],
          if (onToggleVisibility != null)
            GestureDetector(
              onTap: onToggleVisibility,
              child: Icon(
                isHidden ? Icons.visibility_off : Icons.visibility,
                size: 20,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }
}