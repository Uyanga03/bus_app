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
  String query = '';
  List<dynamic> routes = [];
  List<dynamic> filteredRoutes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRoutes();
  }

  Future<void> fetchRoutes() async {
    const String url = "http://localhost:3000/api/routes";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          routes = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
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
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || full.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF57C00),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Гээгдсэн эд зүйлс хайх",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: "Чиглэлийн дугаар эсвэл нэр...",
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredRoutes.isEmpty && query.isNotEmpty
                    ? const Center(child: Text("Илэрц олдсонгүй."))
                    : ListView.builder(
                        itemCount: filteredRoutes.length,
                        itemBuilder: (context, index) {
                          final item = filteredRoutes[index];
                          return ListTile(
                            title: Text("${item['name']} - ${item['full']}"),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailScreen(
                                    params: {
                                      'name': item['name'] ?? '',
                                      'full': item['full'] ?? '',
                                      'phone': item['phone'] ?? '',
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
