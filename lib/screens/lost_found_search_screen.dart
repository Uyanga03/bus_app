import 'package:flutter/material.dart';
import 'search_content.dart';
import 'feedback_screen.dart';

class LostFoundSearchScreen extends StatefulWidget {
  const LostFoundSearchScreen({super.key});

  @override
  State<LostFoundSearchScreen> createState() => _LostFoundSearchScreenState();
}

class _LostFoundSearchScreenState extends State<LostFoundSearchScreen> {
  // ── Дээд icon bar ─────────────────────────────────────────────────────
  static const List<_NavIcon> _navIcons = [
    _NavIcon(asset: 'assets/ulbarsharod.png',   index: 0),
    _NavIcon(asset: 'assets/ulbarsharbus.png',  index: 1),
    _NavIcon(asset: 'assets/ulbarsharstop.png', index: 2),
    _NavIcon(asset: 'assets/ulbarsharmap.png',  index: 3),
    _NavIcon(asset: 'assets/ulbarsharhaih.png', index: 4),
    _NavIcon(asset: 'assets/ulbarsharnote.png', index: 5),
    _NavIcon(asset: 'assets/ulbarsharsett.png', index: 6),
  ];

  int _activeIndex = 4;

  /// FeedbackContent-ийн GlobalKey - FAB дарахад showAddDialog дуудна
  final GlobalKey<FeedbackContentState> _feedbackKey = GlobalKey();

  void _onNavTap(int index) {
    if (index == _activeIndex) return;
    setState(() {
      _activeIndex = index;
    });
  }

  // =====================================================================
  //  BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: _buildContent(),
      floatingActionButton: _activeIndex == 5
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── 📷 Камер icon (дээд) ──
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: FloatingActionButton(
                      heroTag: 'camera_fab',
                      onPressed: () =>
                          _feedbackKey.currentState?.showCameraPicker(),
                      backgroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Color(0xFF555555), size: 22),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── ➕ Нэмэх товч (доод, ногоон) ──
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: FloatingActionButton(
                      heroTag: 'add_fab',
                      onPressed: () =>
                          _feedbackKey.currentState?.showAddDialog(),
                      backgroundColor: const Color(0xFF2E7D32),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 30),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildContent() {
    switch (_activeIndex) {
      case 4:
        return const SearchContent();
      case 5:
        return FeedbackContent(key: _feedbackKey);
      default:
        return Center(
          child: Text(
            'Тун удахгүй...',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        );
    }
  }

  // ── AppBar: icon bar ──────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return PreferredSize(
      preferredSize: Size.fromHeight(topPad + 50),
      child: Container(
        color: const Color(0xFFF57C00),
        padding: EdgeInsets.only(
          top: topPad + 6,
          left: 8,
          right: 8,
          bottom: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _navIcons.map((nav) {
            final isActive = nav.index == _activeIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => _onNavTap(nav.index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      nav.asset,
                      width: 22,
                      height: 22,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.circle_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 2,
                      width: isActive ? 22 : 0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavIcon {
  final String asset;
  final int index;
  const _NavIcon({required this.asset, required this.index});
}