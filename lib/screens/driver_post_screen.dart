import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

class DriverPostScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<XFile>? initialPhotos;

  const DriverPostScreen({super.key, required this.user, this.initialPhotos});

  @override
  State<DriverPostScreen> createState() => _DriverPostScreenState();
}

class _DriverPostScreenState extends State<DriverPostScreen> {
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _busNumberController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  String _selectedCategory = '';

  static const _orange = Color(0xFFF57C00);
  static const _darkHeader = Color(0xFF5D4037);

  @override
  void initState() {
    super.initState();
    // Жолоочийн бүртгэлээс автоматаар бөглөх
    _routeController.text = widget.user['busRoute']?.toString() ?? '';
    _busNumberController.text = widget.user['busNumber']?.toString() ?? '';
    // Огноо автомат
    final now = DateTime.now();
    _dateController.text = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    // Авах газар = автобусны бааз (компанийн нэр)
    _locationController.text = widget.user['companyName']?.toString() ?? '';
    // Камераас ирсэн зургууд
    if (widget.initialPhotos != null && widget.initialPhotos!.isNotEmpty) {
      _selectedImages = List.from(widget.initialPhotos!);
    }
  }

  @override
  void dispose() {
    _routeController.dispose();
    _busNumberController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Зураг сонгох ──
  Future<void> _pickImages() async {
    try {
      final files = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (files.isNotEmpty) {
        setState(() => _selectedImages.addAll(files));
      }
    } catch (_) {
      try {
        final file = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (file != null) {
          setState(() => _selectedImages.add(file));
        }
      } catch (_) {}
    }
  }

  // ── Камераас зураг авах ──
  Future<void> _takePhoto() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() => _selectedImages.add(file));
      }
    } catch (_) {}
  }

  // ── Огноо сонгох ──
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _dateController.text =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      });
    }
  }

  // ── Нийтлэх ──
  Future<void> _submitPost() async {
    if (_routeController.text.trim().isEmpty) {
      _showSnackBar('Чиглэл оруулна уу');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:3000/api/feedback'),
      );

      request.fields['type'] = 'олдсон';
      request.fields['busNumber'] = _routeController.text.trim();
      request.fields['userName'] = widget.user['name'] ?? 'Жолооч';
      request.fields['userId'] = widget.user['id'] ?? '';
      if (_selectedCategory.isNotEmpty) {
        request.fields['category'] = _selectedCategory;
      }

      // Мессеж бүрдүүлэх
      final msgParts = <String>[];
      if (_busNumberController.text.trim().isNotEmpty) {
        msgParts.add('Автобус: ${_busNumberController.text.trim()}');
      }
      if (_dateController.text.trim().isNotEmpty) {
        msgParts.add('Огноо: ${_dateController.text.trim()}');
      }
      if (_locationController.text.trim().isNotEmpty) {
        msgParts.add('Авах газар: ${_locationController.text.trim()}');
      }
      if (_noteController.text.trim().isNotEmpty) {
        msgParts.add('Тайлбар: ${_noteController.text.trim()}');
      }
      request.fields['message'] = msgParts.join('\n');

      // Зурагнууд
      for (final file in _selectedImages) {
        final bytes = await file.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'media',
          bytes,
          filename: file.name,
        ));
      }

      final res = await request.send();
      if (res.statusCode == 201) {
        _showSnackBar('Нийтлэл амжилттай үүсгэгдлээ!', isError: false);
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnackBar('Нийтлэхэд алдаа гарлаа');
      }
    } catch (e) {
      _showSnackBar('Сүлжээний алдаа');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : _orange,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
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
                const Expanded(
                  child: Center(
                    child: Text(
                      'Нийтлэл үүсгэх',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Зураг оруулах хэсэг ──
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: double.infinity,
                      height: _selectedImages.isEmpty ? 180 : null,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _selectedImages.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  'Зураг оруулах',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.all(8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ..._selectedImages.asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final file = entry.value;
                                    return Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: FutureBuilder<Uint8List>(
                                            future: file.readAsBytes().then(
                                                (b) => Uint8List.fromList(b)),
                                            builder: (ctx, snap) {
                                              if (snap.hasData) {
                                                return Image.memory(
                                                  snap.data!,
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                );
                                              }
                                              return Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey.shade200,
                                              );
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () => setState(
                                                () => _selectedImages.removeAt(i)),
                                            child: Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(11),
                                              ),
                                              child: const Icon(Icons.close,
                                                  color: Colors.white, size: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                  // Нэмэх товч
                                  GestureDetector(
                                    onTap: _pickImages,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.add,
                                          size: 32, color: Colors.grey.shade500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Ангилал ──
                  const Text('Ангилал:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF5D4037))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      'Цахилгаан эд зүйл',
                      'Цүнх',
                      'Түлхүүр',
                      'Бичиг баримт',
                      'Түрийвч',
                      'Хувцас',
                      'Бусад эд зүйл',
                    ].map((c) {
                      final sel = _selectedCategory == c;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel ? _orange : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: sel ? _orange : Colors.grey.shade300),
                          ),
                          child: Text(c,
                              style: TextStyle(
                                fontSize: 12,
                                color: sel ? Colors.white : Colors.grey.shade700,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // ── Чиглэл ──
                  _buildField(
                    label: 'Чиглэл:',
                    controller: _routeController,
                    hint: 'Ч:19Б',
                  ),
                  const SizedBox(height: 12),

                  // ── Автобус ──
                  _buildField(
                    label: 'Автобус:',
                    controller: _busNumberController,
                    hint: '16-007',
                  ),
                  const SizedBox(height: 12),

                  // ── Огноо ──
                  _buildField(
                    label: 'Огноо:',
                    controller: _dateController,
                    hint: '2026-02-03',
                    onTap: _pickDate,
                    readOnly: true,
                  ),
                  const SizedBox(height: 12),

                  // ── Авах газар ──
                  _buildField(
                    label: 'Авах газар:',
                    controller: _locationController,
                    hint: '"Зорчигч тээвэр тав" ОНӨААТҮГ-ын байр',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),

                  // ── Нэмэлт тайлбар ──
                  _buildField(
                    label: 'Нэмэлт тайлбар:',
                    controller: _noteController,
                    hint: 'Нэмэлт мэдээлэл бичих...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),

                  // ── Анхааруулга текст ──
                  Text(
                    'Мэдээлэл зөв эсэхийг шалгана уу.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Нийтлэх товч ──
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _orange.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Нийтлэх',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
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

  // ═══════════════════════════════════════════════════════════════════
  //  Нэг мөрт label + input field (хүрээтэй)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              readOnly: readOnly,
              onTap: onTap,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}