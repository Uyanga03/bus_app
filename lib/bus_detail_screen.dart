import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailScreen extends StatelessWidget {
  // Өмнөх дэлгэцээс дамжуулж ирэх дата
  final Map<String, dynamic> params;

  const DetailScreen({super.key, required this.params});

  //  Утас руу залгах функц (React Native-ийн Linking.openURL-тэй ижил)
  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print('Дугаар руу залгах боломжгүй: $phoneNumber');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Датаг авахад хялбар болгох үүднээс
    final String name = params['name'] ?? 'Мэдээлэлгүй';
    final String full = params['full'] ?? 'Чиглэлийн мэдээлэл байхгүй';
    final String phone = params['phone'] ?? 'Дугааргүй';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF57C00),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            //  CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  BUS INFO ROW
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/ulbarsharbus.png',
                        width: 40,
                        height: 40,
                        color: const Color(0xFFF57C00),
                        errorBuilder: (c, e, s) => const Icon(Icons.directions_bus, size: 40, color: Color(0xFFF57C00)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Чиглэлийн бүтэн зам
                  Text(
                    full,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 20),

                  //  PHONE BOX
                  InkWell(
                    onTap: () => _makeCall(phone),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE0B2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call, color: Color(0xFFF57C00), size: 22),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "ДИСПЕТЧЕРИЙН ДУГААР",
                                  style: TextStyle(fontSize: 10, color: Color(0xFFF57C00), fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  phone,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "* Тухайн чиглэлтэй холбоотой гомдол саналаа дээрх дугаарт холбогдож хэлнэ үү.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}