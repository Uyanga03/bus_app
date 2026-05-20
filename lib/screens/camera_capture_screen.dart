import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class CameraCaptureScreen extends StatefulWidget {
  // required-ийг устгаж, хэрэв гаднаас утга өгөхгүй бол автоматаар false (нэвтрээгүй) болгов
  final bool isLoggedIn; 

  const CameraCaptureScreen({super.key, this.isLoggedIn = false});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  static const _orange = Color(0xFFF57C00);
  final ImagePicker _picker = ImagePicker();
  List<Uint8List> _capturedBytes = [];
  List<XFile> _capturedFiles = [];
  Uint8List? _previewBytes;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    // Нэвтэрсэн хэрэглэгч орж ирвэл шууд камераа нээнcurrent_user
    if (widget.isLoggedIn) {
      _takePhoto();
    }
  }

  Future<void> _takePhoto() async {
    XFile? photo;
    try {
      photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    } catch (_) {
      try {
        photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      } catch (_) {}
    }

    if (photo != null) {
      final bytes = Uint8List.fromList(await photo.readAsBytes());
      setState(() {
        _capturedFiles.add(photo!);
        _capturedBytes.add(bytes);
        _previewBytes = bytes;
        _showPreview = true;
      });
    } else {
      if (_capturedBytes.isEmpty && mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  if (_capturedBytes.isNotEmpty && widget.isLoggedIn)
                    Text('${_capturedBytes.length} зураг',
                        style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),

            // ── Preview эсвэл Хоосон дэлгэц ──
            Expanded(
              child: _showPreview && _previewBytes != null
                  ? Center(
                      child: Image.memory(
                        _previewBytes!,
                        fit: BoxFit.contain,
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF57C00),
                      ),
                    ),
            ),

            // ── Доод хэсэг: Нэвтрээгүй бол Банер, Нэвтэрсэн бол Товчлуурууд ──
       
          
              // Нэвтэрсэн үед хэвийн харагдах товчлуурууд
              Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _bottomBtn(Icons.camera_alt, 'Дахин авах', _takePhoto),
                    _bottomBtn(Icons.photo_library, 'Галерей', () async {
                      try {
                        final files = await _picker.pickMultiImage(imageQuality: 85);
                        for (final f in files) {
                          final bytes = Uint8List.fromList(await f.readAsBytes());
                          setState(() {
                            _capturedFiles.add(f);
                            _capturedBytes.add(bytes);
                            _previewBytes = bytes;
                            _showPreview = true;
                          });
                        }
                      } catch (_) {}
                    }),
                    GestureDetector(
                      onTap: () {
                        if (_capturedBytes.isNotEmpty) {
                          Navigator.pop(context, {
                            'files': _capturedFiles,
                            'bytes': _capturedBytes,
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: _orange,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text('Болсон',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}