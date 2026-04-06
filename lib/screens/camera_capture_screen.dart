import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';

// ═══════════════════════════════════════════════════════════════════════
//  1. КАМЕР ДЭЛГЭЦ — Зураг авах / Бичлэг хийх (PHOTO / VIDEO)
// ═══════════════════════════════════════════════════════════════════════
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isPhotoMode = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    try {
      XFile? file;
      if (_isPhotoMode) {
        file = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
        );
      } else {
        file = await _picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 3),
        );
      }

      if (file != null && mounted) {
        // → Засварлах дэлгэц рүү
        final result = await Navigator.push<List<XFile>>(
          context,
          MaterialPageRoute(
            builder: (_) => MediaEditScreen(
              file: file!,
              isVideo: !_isPhotoMode,
            ),
          ),
        );
        if (mounted) Navigator.pop(context, result);
      } else if (mounted) {
        Navigator.pop(context, null);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context, null);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 90);
      if (files.isNotEmpty && mounted) {
        // 1 зураг бол edit, олон бол шууд буцаана
        if (files.length == 1) {
          final result = await Navigator.push<List<XFile>>(
            context,
            MaterialPageRoute(
              builder: (_) => MediaEditScreen(file: files.first, isVideo: false),
            ),
          );
          if (mounted) Navigator.pop(context, result);
        } else {
          if (mounted) Navigator.pop(context, files);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Дээд: X + flip ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, null),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child:
                        const Icon(Icons.sync, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),

            // ── Preview placeholder ──
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF57C00)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── PHOTO / VIDEO toggle ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (!_isPhotoMode) {
                      setState(() => _isPhotoMode = true);
                    }
                  },
                  child: Text(
                    'PHOTO',
                    style: TextStyle(
                      color: _isPhotoMode ? Colors.white : Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight:
                          _isPhotoMode ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 30),
                GestureDetector(
                  onTap: () {
                    if (_isPhotoMode) {
                      setState(() => _isPhotoMode = false);
                    }
                  },
                  child: Text(
                    'VIDEO',
                    style: TextStyle(
                      color:
                          !_isPhotoMode ? Colors.white : Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight:
                          !_isPhotoMode ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Доод: Галерей + Capture + Flip ──
            Padding(
              padding:
                  const EdgeInsets.only(bottom: 30, left: 30, right: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Галерей
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.photo_library,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  // Capture товч
                  GestureDetector(
                    onTap: _capture,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isPhotoMode
                              ? Colors.white
                              : Colors.red.shade400,
                        ),
                      ),
                    ),
                  ),
                  // Flip camera
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flip_camera_ios,
                          color: Colors.white, size: 20),
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
}

// ═══════════════════════════════════════════════════════════════════════
//  2. ЗАСВАРЛАХ ДЭЛГЭЦ — Crop, Draw, Aa текст, Save
// ═══════════════════════════════════════════════════════════════════════
class MediaEditScreen extends StatefulWidget {
  final XFile file;
  final bool isVideo;

  const MediaEditScreen({super.key, required this.file, required this.isVideo});

  @override
  State<MediaEditScreen> createState() => _MediaEditScreenState();
}

class _MediaEditScreenState extends State<MediaEditScreen> {
  // ── Crop ──
  bool _isCropping = false;
  double _cropTop = 0.0;
  double _cropBottom = 0.0;
  double _cropLeft = 0.0;
  double _cropRight = 0.0;

  // ── Draw ──
  bool _isDrawing = false;
  Color _drawColor = Colors.red;
  double _drawStrokeWidth = 3.0;
  List<_DrawStroke> _strokes = [];
  List<Offset> _currentStroke = [];

  // ── Text overlay ──
  List<_TextOverlay> _textOverlays = [];
  int? _activeOverlayIndex;

  // ── Toolbar state ──
  _EditTool _activeTool = _EditTool.none;

  static const List<Color> _drawColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.white,
    Colors.black,
    Color(0xFFF57C00),
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Дээд toolbar ──
            _buildTopBar(),
            // ── Зураг + overlay ──
            Expanded(child: _buildImageArea()),
            // ── Доод toolbar ──
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Дээд toolbar: X, Crop, Draw, Aa ──
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Хаах
          GestureDetector(
            onTap: () => Navigator.pop(context, null),
            child: const Icon(Icons.close, color: Colors.white, size: 28),
          ),
          const Spacer(),
          // Crop
          _toolButton(
            icon: Icons.crop,
            isActive: _activeTool == _EditTool.crop,
            onTap: () {
              setState(() {
                if (_activeTool == _EditTool.crop) {
                  _activeTool = _EditTool.none;
                  _isCropping = false;
                } else {
                  _activeTool = _EditTool.crop;
                  _isCropping = true;
                  _isDrawing = false;
                }
              });
            },
          ),
          const SizedBox(width: 16),
          // Draw
          _toolButton(
            icon: Icons.brush,
            isActive: _activeTool == _EditTool.draw,
            onTap: () {
              setState(() {
                if (_activeTool == _EditTool.draw) {
                  _activeTool = _EditTool.none;
                  _isDrawing = false;
                } else {
                  _activeTool = _EditTool.draw;
                  _isDrawing = true;
                  _isCropping = false;
                }
              });
            },
          ),
          const SizedBox(width: 16),
          // Aa текст
          _toolButton(
            icon: null,
            label: 'Aa',
            isActive: false,
            onTap: _addTextOverlay,
          ),
        ],
      ),
    );
  }

  Widget _toolButton({
    IconData? icon,
    String? label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF57C00) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFFF57C00) : Colors.white30,
          ),
        ),
        child: Center(
          child: label != null
              ? Text(label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ))
              : Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  // ── Зураг area (crop + draw + text) ──
  Widget _buildImageArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Зураг
            widget.isVideo
                ? Container(
                    color: Colors.grey.shade900,
                    child: const Center(
                      child: Icon(Icons.play_circle_fill,
                          color: Colors.white54, size: 64),
                    ),
                  )
                : Image.file(
                    File(widget.file.path),
                    fit: BoxFit.contain,
                  ),

            // Crop overlay
            if (_isCropping) _buildCropOverlay(),

            // Drawing layer
            if (_isDrawing)
              GestureDetector(
                onPanStart: (d) {
                  _currentStroke = [d.localPosition];
                },
                onPanUpdate: (d) {
                  setState(() {
                    _currentStroke.add(d.localPosition);
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    _strokes.add(_DrawStroke(
                      points: List.from(_currentStroke),
                      color: _drawColor,
                      strokeWidth: _drawStrokeWidth,
                    ));
                    _currentStroke = [];
                  });
                },
                child: CustomPaint(
                  painter: _DrawPainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    currentColor: _drawColor,
                    currentStrokeWidth: _drawStrokeWidth,
                  ),
                  size: Size.infinite,
                ),
              ),

            // Drawing preview (зурахгүй горимд ч харагдана)
            if (!_isDrawing && _strokes.isNotEmpty)
              CustomPaint(
                painter: _DrawPainter(
                  strokes: _strokes,
                  currentStroke: [],
                  currentColor: _drawColor,
                  currentStrokeWidth: _drawStrokeWidth,
                ),
                size: Size.infinite,
              ),

            // Text overlays
            ..._textOverlays.asMap().entries.map((e) {
              final i = e.key;
              final overlay = e.value;
              return Positioned(
                left: overlay.x,
                top: overlay.y,
                child: GestureDetector(
                  onTap: () => _editTextOverlay(i),
                  onPanUpdate: (d) {
                    setState(() {
                      _textOverlays[i] = overlay.copyWith(
                        x: overlay.x + d.delta.dx,
                        y: overlay.y + d.delta.dy,
                      );
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: overlay.bgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      overlay.text,
                      style: TextStyle(
                        color: overlay.textColor,
                        fontSize: overlay.fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Crop overlay ──
  Widget _buildCropOverlay() {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return Stack(
        children: [
          // Бараан хэсэг (crop-ийн гадна)
          Positioned.fill(
            child: CustomPaint(
              painter: _CropOverlayPainter(
                cropRect: Rect.fromLTRB(
                  _cropLeft,
                  _cropTop,
                  w - _cropRight,
                  h - _cropBottom,
                ),
              ),
            ),
          ),
          // Crop хүрээ чирэх
          // Дээд
          Positioned(
            top: _cropTop - 15,
            left: w / 2 - 20,
            child: GestureDetector(
              onVerticalDragUpdate: (d) {
                setState(() {
                  _cropTop = (_cropTop + d.delta.dy).clamp(0.0, h - _cropBottom - 50);
                });
              },
              child: _cropHandle(),
            ),
          ),
          // Доод
          Positioned(
            bottom: _cropBottom - 15,
            left: w / 2 - 20,
            child: GestureDetector(
              onVerticalDragUpdate: (d) {
                setState(() {
                  _cropBottom = (_cropBottom - d.delta.dy).clamp(0.0, h - _cropTop - 50);
                });
              },
              child: _cropHandle(),
            ),
          ),
          // Зүүн
          Positioned(
            left: _cropLeft - 15,
            top: h / 2 - 20,
            child: GestureDetector(
              onHorizontalDragUpdate: (d) {
                setState(() {
                  _cropLeft = (_cropLeft + d.delta.dx).clamp(0.0, w - _cropRight - 50);
                });
              },
              child: _cropHandle(),
            ),
          ),
          // Баруун
          Positioned(
            right: _cropRight - 15,
            top: h / 2 - 20,
            child: GestureDetector(
              onHorizontalDragUpdate: (d) {
                setState(() {
                  _cropRight = (_cropRight - d.delta.dx).clamp(0.0, w - _cropLeft - 50);
                });
              },
              child: _cropHandle(),
            ),
          ),
        ],
      );
    });
  }

  Widget _cropHandle() {
    return Container(
      width: 40,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.drag_handle, color: Colors.black54, size: 18),
    );
  }

  // ── Текст overlay нэмэх ──
  void _addTextOverlay() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Текст нэмэх',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Текстээ бичнэ үү...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade600),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFF57C00)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Болих',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _textOverlays.add(_TextOverlay(
                    text: controller.text.trim(),
                    x: 40,
                    y: 100 + (_textOverlays.length * 50.0),
                  ));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Нэмэх',
                style: TextStyle(color: Color(0xFFF57C00))),
          ),
        ],
      ),
    );
  }

  void _editTextOverlay(int index) {
    final overlay = _textOverlays[index];
    final controller = TextEditingController(text: overlay.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Текст засах',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade600),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFF57C00)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _textOverlays.removeAt(index));
              Navigator.pop(ctx);
            },
            child:
                const Text('Устгах', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _textOverlays[index] = overlay.copyWith(
                  text: controller.text.trim(),
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Хадгалах',
                style: TextStyle(color: Color(0xFFF57C00))),
          ),
        ],
      ),
    );
  }

  // ── Доод bar ──
  Widget _buildBottomBar() {
    return Column(
      children: [
        // Draw горимд өнгө сонголт
        if (_activeTool == _EditTool.draw) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _drawColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final c = _drawColors[i];
                final isSelected = c == _drawColor;
                return GestureDetector(
                  onTap: () => setState(() => _drawColor = c),
                  child: Container(
                    width: isSelected ? 32 : 28,
                    height: isSelected ? 32 : 28,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white24,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Зузаан слайдер
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.line_weight, color: Colors.white38, size: 16),
                Expanded(
                  child: Slider(
                    value: _drawStrokeWidth,
                    min: 1,
                    max: 12,
                    activeColor: const Color(0xFFF57C00),
                    inactiveColor: Colors.white24,
                    onChanged: (v) => setState(() => _drawStrokeWidth = v),
                  ),
                ),
              ],
            ),
          ),
          // Undo товч
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: () {
                if (_strokes.isNotEmpty) {
                  setState(() => _strokes.removeLast());
                }
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.undo, color: Colors.white70, size: 20),
                  SizedBox(width: 4),
                  Text('Буцаах',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],

        // ── Хадгалах / Дахин / Бэлдсэн ──
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Хадгалах
              _bottomAction(
                icon: Icons.save_alt,
                label: 'Хадгалах',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Хадгалагдлаа!'),
                      backgroundColor: Color(0xFFF57C00),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              // Дахин авах
              _bottomAction(
                icon: Icons.refresh,
                label: 'Дахин',
                onTap: () => Navigator.pop(context, null),
              ),
              // Бэлдсэн → файлыг буцаана
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, [widget.file]);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF57C00),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Text('Бэлдсэн',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

enum _EditTool { none, crop, draw }

// ── Draw stroke ──
class _DrawStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  const _DrawStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

// ── Draw painter ──
class _DrawPainter extends CustomPainter {
  final List<_DrawStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentStrokeWidth;

  _DrawPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke.points, stroke.color, stroke.strokeWidth);
    }
    if (currentStroke.isNotEmpty) {
      _paintStroke(canvas, currentStroke, currentColor, currentStrokeWidth);
    }
  }

  void _paintStroke(
      Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawPainter old) => true;
}

// ── Crop overlay painter ──
class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  _CropOverlayPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);

    // Дээд
    canvas.drawRect(
        Rect.fromLTRB(0, 0, size.width, cropRect.top), paint);
    // Доод
    canvas.drawRect(
        Rect.fromLTRB(0, cropRect.bottom, size.width, size.height), paint);
    // Зүүн
    canvas.drawRect(
        Rect.fromLTRB(0, cropRect.top, cropRect.left, cropRect.bottom), paint);
    // Баруун
    canvas.drawRect(
        Rect.fromLTRB(
            cropRect.right, cropRect.top, size.width, cropRect.bottom),
        paint);

    // Хүрээ
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(cropRect, borderPaint);

    // Grid шугамууд
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 0.5;
    final thirdW = cropRect.width / 3;
    final thirdH = cropRect.height / 3;
    for (int i = 1; i <= 2; i++) {
      canvas.drawLine(
        Offset(cropRect.left + thirdW * i, cropRect.top),
        Offset(cropRect.left + thirdW * i, cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + thirdH * i),
        Offset(cropRect.right, cropRect.top + thirdH * i),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter old) =>
      old.cropRect != cropRect;
}

// ── Text overlay data ──
class _TextOverlay {
  final String text;
  final double x;
  final double y;
  final double fontSize;
  final Color textColor;
  final Color bgColor;

  const _TextOverlay({
    required this.text,
    required this.x,
    required this.y,
    this.fontSize = 22,
    this.textColor = Colors.white,
    this.bgColor = const Color(0x88000000),
  });

  _TextOverlay copyWith({
    String? text,
    double? x,
    double? y,
    double? fontSize,
    Color? textColor,
    Color? bgColor,
  }) {
    return _TextOverlay(
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      bgColor: bgColor ?? this.bgColor,
    );
  }
}