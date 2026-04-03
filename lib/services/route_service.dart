import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/route_model.dart';

class RouteService {
  // Эмулятор → 10.0.2.2, Бодит утас → компьютерийн IP
  static const String baseUrl = 'http:// 10.128.216.73/api';

  // GET /api/routes — бүгдийг татах
  static Future<List<BusRoute>> getAllRoutes() async {
    final res = await http.get(Uri.parse('$baseUrl/routes'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((r) => BusRoute.fromJson(r)).toList();
    }
    throw Exception('Өгөгдөл татахад алдаа гарлаа');
  }

  // GET /api/routes/:id — нэгийг татах
  static Future<BusRoute> getRouteById(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/routes/$id'));
    if (res.statusCode == 200) {
      return BusRoute.fromJson(jsonDecode(res.body));
    }
    throw Exception('Чиглэл олдсонгүй');
  }

  // POST /api/routes — нэмэх
  static Future<BusRoute> createRoute(BusRoute route) async {
    final res = await http.post(
      Uri.parse('$baseUrl/routes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(route.toJson()),
    );
    if (res.statusCode == 201) {
      return BusRoute.fromJson(jsonDecode(res.body));
    }
    throw Exception('Нэмэхэд алдаа гарлаа');
  }

  // PUT /api/routes/:id — засах
  static Future<BusRoute> updateRoute(String id, BusRoute route) async {
    final res = await http.put(
      Uri.parse('$baseUrl/routes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(route.toJson()),
    );
    if (res.statusCode == 200) {
      return BusRoute.fromJson(jsonDecode(res.body));
    }
    throw Exception('Засахад алдаа гарлаа');
  }

  // DELETE /api/routes/:id — устгах
  static Future<void> deleteRoute(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/routes/$id'));
    if (res.statusCode != 200) {
      throw Exception('Устгахад алдаа гарлаа');
    }
  }
}