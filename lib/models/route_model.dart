class BusRoute {
  final String id;
  final String name;   // "23"
  final String full;   // "ЗУРХ УУЛ - Ард кино театр"
  final String phone;  // "70112345"

  BusRoute({
    required this.id,
    required this.name,
    required this.full,
    required this.phone,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) => BusRoute(
    id:    json['_id']   ?? '',
    name:  json['name']  ?? '',
    full:  json['full']  ?? '',
    phone: json['phone'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'name':  name,
    'full':  full,
    'phone': phone,
  };
}