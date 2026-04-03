import 'package:flutter/material.dart';
import 'package:BUS_APP/screens/lost_found_search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Дэлгэцийн өргөнийг авах (Dimensions.get('window').width-тэй ижил)
    final double screenWidth = MediaQuery.of(context).size.width;

    // Цэсний дата
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Чиглэл хайх', 'color': const Color(0xFF8E245F), 'icon': Icons.directions_bus},
      {'title': 'Автобусны буудал хайх', 'color': const Color(0xFF757575), 'icon': Icons.location_on},
      {'title': 'Мэдээ мэдээлэл', 'color': const Color(0xFFFB8C00), 'icon': Icons.warning_amber_rounded},
      {'title': 'Чиглэлийн сэтгэл ханамжийн судалгаа', 'color': const Color(0xFF546E7A), 'icon': Icons.check_circle_outline},
      {'title': 'Юм мартаж буусан уу?', 'color': const Color(0xFF6D4C41), 'icon': Icons.search},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Column(
              children: [
                // Top Bar (Шар болон Ягаан зураас)
                Row(
                  children: [
                    Expanded(child: Container(height: 4, color: const Color(0xFFF57C00))),
                    Expanded(child: Container(height: 4, color: const Color(0xFF8E245F))),
                  ],
                ),
                // Logo Row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/u_money_logo.png', width: 50, height: 35, errorBuilder: (c, e, s) => const Icon(Icons.credit_card)),
                      Container(width: 1, height: 30, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 10)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Улаан', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF8E245F))),
                              Text('баатар', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFF57C00))),
                            ],
                          ),
                          const Text('Смарт Карт', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
                        ],
                      ),
                    ],
                  ),
                ),
                // Sub Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () {
                        if (item['title'] == 'Юм мартаж буусан уу?') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LostFoundSearchScreen()),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: item['color'],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            // Цагаан дугуй доторх дүрс
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                              ),
                              child: Icon(item['icon'], color: item['color'], size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item['title'],
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- BOTTOM NAV ---
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[300]!))),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  _navItem(Icons.star_border, 'Хялбар хэрэглээ'),
                  _divider(),
                  _navItem(Icons.location_searching, 'Ойролцоо буудал'),
                  _divider(),
                  _navItem(Icons.description_outlined, 'Хэрэглэгчийн форум'),
                  _divider(),
                  _navItem(Icons.settings_outlined, 'Тохиргоо'),
                ],
              ),
            ),

            // --- BANNER ---
            Container(
              width: screenWidth,
              height: 75,
              color: Colors.white,
              child: Image.asset(
                'assets/images/ad_banner.png',
                fit: BoxFit.fill,
                errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Туслах Widget-үүд
  Widget _navItem(IconData icon, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: const Color(0xFF757575)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Color(0xFF616161))),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 25, color: Colors.grey[300]);
  }
}