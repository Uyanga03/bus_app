import 'package:flutter/material.dart';
import 'package:BUS_APP/lost_found_search_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UB Smart Bus',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Container(height: 4, color: const Color(0xFFF57C00))),
                    Expanded(child: Container(height: 4, color: const Color(0xFF8E245F))),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.credit_card, color: Color(0xFF8E245F), size: 35),
                      Container(
                        width: 1, height: 30, color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Text('Улаан', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8E245F))),
                              Text('баатар', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF57C00))),
                            ],
                          ),
                          Text('Смарт Карт', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: const Text(
                    'НИЙТИЙН ТЭЭВРИЙН ҮЙЛЧИЛГЭЭНИЙ МЭДЭЭЛЭЛ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            // --- MENU ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                children: [
                  _buildMenuBtn(context, 'Чиглэл хайх', const Color(0xFF8E245F), Icons.directions_bus),
                  _buildMenuBtn(context, 'Автобусны буудал хайх', const Color(0xFF757575), Icons.location_on),
                  _buildMenuBtn(context, 'Мэдээ мэдээлэл', const Color(0xFFFB8C00), Icons.warning_amber_rounded),
                  _buildMenuBtn(context, 'Чиглэлийн сэтгэл ханамжийн судалгаа', const Color(0xFF546E7A), Icons.check_circle_outline),
                  _buildMenuBtn(context, 'Юм мартаж буусан уу?', const Color(0xFF6D4C41), Icons.search, isSearch: true),
                ],
              ),
            ),

            // --- BOTTOM NAV ---
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[300]!))),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  _navItem(Icons.star_border, 'Хялбар хэрэглээ'),
                  _navDivider(),
                  _navItem(Icons.location_searching, 'Ойролцоо буудал'),
                  _navDivider(),
                  _navItem(Icons.description_outlined, 'Хэрэглэгчийн форум'),
                  _navDivider(),
                  _navItem(Icons.settings_outlined, 'Тохиргоо'),
                ],
              ),
            ),

            // --- AD BANNER ---
            Container(
              width: screenWidth,
              height: 75,
              color: Colors.grey[200],
              child: const Center(child: Text("AD BANNER HERE")),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuBtn(
    BuildContext context,
    String title,
    Color color,
    IconData icon, {
    bool isSearch = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          if (isSearch) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LostFoundSearchScreen(),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: const Color(0xFF757575)),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: Color(0xFF616161)),
          ),
        ],
      ),
    );
  }

  Widget _navDivider() {
    return Container(width: 1, height: 25, color: Colors.grey[300]);
  }
}