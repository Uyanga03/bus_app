import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:BUS_APP/screens/bus_detail_screen.dart';

class LostFoundSearchScreen extends StatefulWidget {
  const LostFoundSearchScreen({super.key});

  @override
  State<LostFoundSearchScreen> createState() => _LostFoundSearchScreenState();
}

class _LostFoundSearchScreenState extends State<LostFoundSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String query = '';
  List<dynamic> routes = [];
  List<dynamic> filteredRoutes = [];
  bool isLoading = true;
  String? errorMessage; // ← Алдааны мессеж хадгалах

  // ── Топ навигацийн icon-ууд ────────────────────────────────────────────
  // PNG asset байхгүй бол fallback Material icon ашиглана
  static const List<_NavIcon> _navIcons = [
    _NavIcon(asset: 'assets/icons/ulbarsharod.png',     fallback: Icons.home_outlined,      index: 0),
    _NavIcon(asset: 'assets/icons/ulbarsharbus.png',    fallback: Icons.directions_bus,      index: 1),
    _NavIcon(asset: 'assets/icons/ulbarsharstop.png',   fallback: Icons.place_outlined,      index: 2),
    _NavIcon(asset: 'assets/icons/ulbarsharmap.png',    fallback: Icons.map_outlined,        index: 3),
    _NavIcon(asset: 'assets/icons/ulbarsharhaih.png',   fallback: Icons.search,              index: 4),
    _NavIcon(asset: 'assets/icons/ulbarsharnote.png',   fallback: Icons.note_alt_outlined,   index: 5),
    _NavIcon(asset: 'assets/icons/ulbarsharsett.png',   fallback: Icons.settings_outlined,   index: 6),
  ];

  static const int _activeIndex = 4;

  @override
  void initState() {
    super.initState();
    fetchRoutes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── API-аас чиглэлүүд татах (алдааны мессежтэй) ──────────────────────
  Future<void> fetchRoutes() async {
    const String url = "http://localhost:3000/api/routes";
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10)); // ← Timeout нэмсэн

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          routes = data;
          isLoading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Сервертэй холбогдож чадсангүй (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Сүлжээний алдаа: $e';
      });
      debugPrint('fetchRoutes алдаа: $e');
    }
  }

  // ── Хайлт ─────────────────────────────────────────────────────────────────
  void _onSearchChanged(String text) {
    setState(() {
      query = text;
      if (query.trim().isEmpty) {
        filteredRoutes = [];
      } else {
        filteredRoutes = routes.where((r) {
          final name = r['name']?.toString().toLowerCase() ?? '';
          final full = r['full']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              full.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ──────────────────────────────────────────────
                  // ЗАСВАР: PNG олдохгүй бол fallback Icon ашиглана
                  // ──────────────────────────────────────────────
                  _buildNavIcon(nav),
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
            );
          }).toList(),
        ),
      ),
    );
  }

  /// PNG asset-г уншихыг оролдоно, алдаа гарвал fallback Material icon харуулна
  Widget _buildNavIcon(_NavIcon nav) {
    return Image.asset(
      nav.asset,
      width: 22,
      height: 22,
      color: Colors.white,
      colorBlendMode: BlendMode.srcIn,
      errorBuilder: (_, __, ___) => Icon(
        nav.fallback,        // ← Тус бүрдээ тохирох fallback icon
        color: Colors.white,
        size: 22,
      ),
    );
  }

  // ── Search input ──────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFCCCCCC), width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: const InputDecoration(
                  hintText: 'Чиглэлийн дугаараа оруулна уу.',
                  hintStyle:
                      TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
            if (query.isNotEmpty)
              GestureDetector(
                onTap: _clearSearch,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child:
                      Icon(Icons.cancel, size: 18, color: Color(0xFFAAAAAA)),
                ),
              ),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                border: Border(
                    left: BorderSide(color: Color(0xFFCCCCCC), width: 1)),
              ),
              child: const Icon(Icons.search,
                  color: Color(0xFF555555), size: 22),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF57C00)),
      );
    }

    // ──────────────────────────────────────────────
    // ЗАСВАР: Алдааны мессеж + дахин оролдох товч
    // ──────────────────────────────────────────────
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Color(0xFFCCCCCC)),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  fetchRoutes();
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
        ),
      );
    }

    if (query.isEmpty) {
      return const SizedBox();
    }

    if (filteredRoutes.isEmpty) {
      return const Center(
        child: Text(
          'Хайсан дүн байхгүй байна.',
          style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredRoutes.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFEEEEEE),
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final item = filteredRoutes[index];
        final name = item['name']?.toString() ?? '';
        final full = item['full']?.toString() ?? '';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailScreen(
                  params: {
                    'name': name,
                    'full': full,
                    'phone': item['phone'] ?? '',
                  },
                ),
              ),
            );
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              '$name ($full)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Helper ───────────────────────────────────────────────────────────────────
class _NavIcon {
  final String asset;
  final IconData fallback;  // ← Нэмсэн
  final int index;
  const _NavIcon({
    required this.asset,
    required this.fallback,
    required this.index,
  });
}