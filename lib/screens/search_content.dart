import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:BUS_APP/screens/bus_detail_screen.dart';

class SearchContent extends StatefulWidget {
  const SearchContent({super.key});

  @override
  State<SearchContent> createState() => _SearchContentState();
}

class _SearchContentState extends State<SearchContent> {
  final TextEditingController _searchController = TextEditingController();
  String query = '';
  List<dynamic> routes = [];
  List<dynamic> filteredRoutes = [];
  bool isRoutesLoading = true;

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

  // =====================================================================
  //  API: Чиглэлүүд
  // =====================================================================
  Future<void> fetchRoutes() async {
    const String url = "http://localhost:3000/api/routes";
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          routes = data;
          isRoutesLoading = false;
        });
      } else {
        setState(() => isRoutesLoading = false);
      }
    } catch (e) {
      setState(() => isRoutesLoading = false);
    }
  }

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

  // =====================================================================
  //  BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildSearchBody()),
      ],
    );
  }

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
                autofocus: false,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: const InputDecoration(
                  hintText: 'Чиглэлийн дугаараа оруулна уу.',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
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
                  child: Icon(Icons.cancel, size: 18, color: Color(0xFFAAAAAA)),
                ),
              ),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Color(0xFFCCCCCC), width: 1)),
              ),
              child: const Icon(Icons.search, color: Color(0xFF555555), size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBody() {
    if (isRoutesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF57C00)),
      );
    }
    if (query.isEmpty) return const SizedBox();
    if (filteredRoutes.isEmpty) {
      return const Center(
        child: Text('Хайсан дүн байхгүй байна.',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
      );
    }

    return ListView.separated(
      itemCount: filteredRoutes.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1, thickness: 1, color: Color(0xFFEEEEEE), indent: 16, endIndent: 16,
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
                  params: {'name': name, 'full': full, 'phone': item['phone'] ?? ''},
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text('$name ($full)',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
          ),
        );
      },
    );
  }
}