import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  static const _orange = Color(0xFFF57C00);
  final ImagePicker _picker = ImagePicker();
  List<XFile> _capturedPhotos = [];
  Uint8List? _previewBytes;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    // Камер шууд нээх
    _takePhoto();
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedPhotos.add(photo);
          _previewBytes = Uint8List.fromList(bytes);
          _showPreview = true;
        });
      } else {
        // Камер цуцалсан бол буцах
        if (_capturedPhotos.isEmpty && mounted) {
          Navigator.pop(context);
        }
      }
    } catch (_) {
      if (_capturedPhotos.isEmpty && mounted) {
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
                  if (_capturedPhotos.isNotEmpty)
                    Text(
                      '${_capturedPhotos.length} зураг',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                ],
              ),
            ),

            // ── Preview ──
            Expanded(
              child: _showPreview && _previewBytes != null
                  ? Center(
                      child: Image.memory(
                        _previewBytes!,
                        fit: BoxFit.contain,
                      ),
                    )
                  : const Center(
                      child: Text(
                        'Камер ачааллаж байна...',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ),
            ),

            // ── Bottom buttons ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Дахин зураг авах
                  _bottomBtn(Icons.camera_alt, 'Дахин авах', () => _takePhoto()),
                  // Галерей
                  _bottomBtn(Icons.photo_library, 'Галерей', () async {
                    try {
                      final files = await _picker.pickMultiImage(imageQuality: 85);
                      if (files.isNotEmpty) {
                        final bytes = await files.last.readAsBytes();
                        setState(() {
                          _capturedPhotos.addAll(files);
                          _previewBytes = Uint8List.fromList(bytes);
                          _showPreview = true;
                        });
                      }
                    } catch (_) {}
                  }),
                  // Болсон
                  GestureDetector(
                    onTap: () {
                      if (_capturedPhotos.isNotEmpty) {
                        Navigator.pop(context, _capturedPhotos);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'Болсон',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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