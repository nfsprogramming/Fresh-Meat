import 'package:flutter/material.dart';

enum MeatType { mutton, chicken, beef }

extension MeatTypeX on MeatType {
  String get label => switch (this) {
        MeatType.mutton => 'Mutton',
        MeatType.chicken => 'Chicken',
        MeatType.beef => 'Beef',
      };

  /// Background gradient colours for hero cards and the product screen.
  List<Color> get heroColors => switch (this) {
        MeatType.mutton => const [Color(0xFFFF5A3C), Color(0xFFC2182F), Color(0xFF5A0716)],
        MeatType.chicken => const [Color(0xFFFFB347), Color(0xFFE8751A), Color(0xFF7A3A08)],
        MeatType.beef => const [Color(0xFFC0392B), Color(0xFF7A1220), Color(0xFF2A0509)],
      };

  /// Centre / mid / edge colours for the illustrated cut.
  List<Color> get steakColors => switch (this) {
        MeatType.mutton => const [Color(0xFFFF7D68), Color(0xFFD0261F), Color(0xFF5B0A0C)],
        MeatType.chicken => const [Color(0xFFFFE0B8), Color(0xFFE9A96A), Color(0xFF9A5A2A)],
        MeatType.beef => const [Color(0xFFC8453A), Color(0xFF7A1A14), Color(0xFF2E0606)],
      };
}

class Product {
  final String id;
  final String name;
  final MeatType type;
  final String butcher;
  final double pricePerKg;
  final double rating;
  final String cutAgo;
  final String? photo;
  final String? description;
  final String? pieces;
  final String? serves;
  final String? source;

  const Product({
    required this.id,
    required this.name,
    required this.type,
    required this.butcher,
    required this.pricePerKg,
    this.rating = 4.8,
    this.cutAgo = '2 hrs ago',
    this.photo,
    this.description,
    this.pieces,
    this.serves,
    this.source,
  });

  double priceFor(int grams) => pricePerKg * grams / 1000;

  Product copyWith({
    String? id,
    String? name,
    MeatType? type,
    String? butcher,
    double? pricePerKg,
    double? rating,
    String? cutAgo,
    String? photo,
    String? description,
    String? pieces,
    String? serves,
    String? source,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      butcher: butcher ?? this.butcher,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      rating: rating ?? this.rating,
      cutAgo: cutAgo ?? this.cutAgo,
      photo: photo ?? this.photo,
      description: description ?? this.description,
      pieces: pieces ?? this.pieces,
      serves: serves ?? this.serves,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'butcher': butcher,
        'pricePerKg': pricePerKg,
        'rating': rating,
        'cutAgo': cutAgo,
        'photo': photo,
        'description': description,
        'pieces': pieces,
        'serves': serves,
        'source': source,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        type: MeatType.values.byName(json['type'] as String),
        butcher: json['butcher'] as String,
        pricePerKg: (json['pricePerKg'] as num).toDouble(),
        rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
        cutAgo: json['cutAgo'] as String? ?? '2 hrs ago',
        photo: json['photo'] as String?,
        description: json['description'] as String?,
        pieces: json['pieces'] as String?,
        serves: json['serves'] as String?,
        source: json['source'] as String?,
      );
}

String gramsLabel(int g) => g % 1000 == 0 ? '${g ~/ 1000} kg' : '$g g';
String rupees(double v) => '₹${v.round()}';

List<String> getDynamicSlots() {
  final now = DateTime.now();
  final currentHour = now.hour;
  final currentMinute = now.minute;

  // After 8:30 PM, offer morning slots for next day
  if (currentHour >= 21 || (currentHour == 20 && currentMinute >= 30)) {
    return ['Tomorrow 7:30 AM', 'Tomorrow 8:30 AM', 'Tomorrow 9:30 AM', 'Tomorrow 11:00 AM'];
  }

  // Calculate upcoming 30-min window slots for today
  final slots = <String>[];
  var start = now.add(const Duration(minutes: 35));
  for (int i = 0; i < 4; i++) {
    final slotTime = start.add(Duration(minutes: i * 35));
    final h = slotTime.hour;
    final m = slotTime.minute < 30 ? '00' : '30';
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    slots.add('$displayH:$m $period');
  }
  return slots;
}

class CartItem {
  final Product product;
  final int grams;
  final int qty;
  const CartItem({required this.product, required this.grams, required this.qty});

  String get key => '${product.id}_$grams';
  double get lineTotal => product.priceFor(grams) * qty;
  CartItem copyWith({Product? product, int? grams, int? qty}) => CartItem(
        product: product ?? this.product,
        grams: grams ?? this.grams,
        qty: qty ?? this.qty,
      );

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'grams': grams,
        'qty': qty,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        product: Product.fromJson(json['product'] as Map<String, dynamic>),
        grams: json['grams'] as int,
        qty: json['qty'] as int,
      );
}

enum OrderStatus { placed, accepted, cutting, onTheWay, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.placed => 'Placed',
        OrderStatus.accepted => 'Accepted',
        OrderStatus.cutting => 'Cutting',
        OrderStatus.onTheWay => 'On the way',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };

  int get etaMinutes => switch (this) {
        OrderStatus.placed => 35,
        OrderStatus.accepted => 30,
        OrderStatus.cutting => 22,
        OrderStatus.onTheWay => 8,
        OrderStatus.delivered => 0,
        OrderStatus.cancelled => 0,
      };
}

class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final OrderStatus status;
  final String slot;
  final String idempotencyKey;
  final String paymentMethod;
  final String deliveryAddress;
  final String customerName;
  final String customerPhone;
  final String driverName;
  final String driverPhone;
  final String driverVehicle;
  final double? deliveryLat;
  final double? deliveryLon;
  final DateTime createdAt;
  final DateTime updatedAt;

  final DateTime cancellationDeadline;
  final bool isDeliveryVerified;
  final DateTime? verifiedAt;
  final String? verificationExecutive;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    required this.slot,
    required this.idempotencyKey,
    this.paymentMethod = 'Cash on delivery',
    this.deliveryAddress = 'Tap to add delivery address',
    this.customerName = 'Guest Gourmet',
    this.customerPhone = '+91 98765 00000',
    this.driverName = 'Rashid Khan',
    this.driverPhone = '+91 98450 12345',
    this.driverVehicle = 'KA 01 AB 1234',
    this.deliveryLat,
    this.deliveryLon,
    required this.createdAt,
    required this.updatedAt,
    DateTime? cancellationDeadline,
    this.isDeliveryVerified = false,
    this.verifiedAt,
    this.verificationExecutive,
  }) : cancellationDeadline = cancellationDeadline ?? createdAt.add(const Duration(minutes: 5));

  Order copyWith({
    OrderStatus? status,
    String? paymentMethod,
    String? deliveryAddress,
    String? customerName,
    String? customerPhone,
    String? driverName,
    String? driverPhone,
    String? driverVehicle,
    double? deliveryLat,
    double? deliveryLon,
    DateTime? updatedAt,
    DateTime? cancellationDeadline,
    bool? isDeliveryVerified,
    DateTime? verifiedAt,
    String? verificationExecutive,
  }) =>
      Order(
        id: id,
        items: items,
        total: total,
        status: status ?? this.status,
        slot: slot,
        idempotencyKey: idempotencyKey,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        deliveryAddress: deliveryAddress ?? this.deliveryAddress,
        customerName: customerName ?? this.customerName,
        customerPhone: customerPhone ?? this.customerPhone,
        driverName: driverName ?? this.driverName,
        driverPhone: driverPhone ?? this.driverPhone,
        driverVehicle: driverVehicle ?? this.driverVehicle,
        deliveryLat: deliveryLat ?? this.deliveryLat,
        deliveryLon: deliveryLon ?? this.deliveryLon,
        createdAt: createdAt,
        updatedAt: updatedAt ?? (status == null ? this.updatedAt : DateTime.now()),
        cancellationDeadline: cancellationDeadline ?? this.cancellationDeadline,
        isDeliveryVerified: isDeliveryVerified ?? this.isDeliveryVerified,
        verifiedAt: verifiedAt ?? this.verifiedAt,
        verificationExecutive: verificationExecutive ?? this.verificationExecutive,
      );

  bool get canCancel {
    if (status != OrderStatus.placed && status != OrderStatus.accepted) {
      return false;
    }
    final now = DateTime.now();
    // Tamper detection: if device clock is set before createdAt or updatedAt has already crossed deadline
    if (now.isBefore(createdAt) || updatedAt.isAfter(cancellationDeadline)) {
      return false;
    }
    return now.isBefore(cancellationDeadline);
  }

  String get title => items.map((i) => i.product.name).join(' + ');
  String get subtitle => items.map((i) => '${i.product.name} · ${gramsLabel(i.grams)}').join(', ');
  MeatType get type => items.isNotEmpty ? items.first.product.type : MeatType.mutton;
  String get invoiceNumber => 'FM-INV-2026-${id.padLeft(4, '0')}';
  String get verificationToken => 'freshmeat://verify?order=$id&sig=${idempotencyKey.hashCode.abs().toRadixString(16).toUpperCase()}';
  String get deliveryPin => ((idempotencyKey.hashCode.abs() % 9000) + 1000).toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((i) => i.toJson()).toList(),
        'total': total,
        'status': status.name,
        'slot': slot,
        'idempotencyKey': idempotencyKey,
        'paymentMethod': paymentMethod,
        'deliveryAddress': deliveryAddress,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'driverVehicle': driverVehicle,
        'deliveryLat': deliveryLat,
        'deliveryLon': deliveryLon,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'cancellationDeadline': cancellationDeadline.toIso8601String(),
        'isDeliveryVerified': isDeliveryVerified,
        'verifiedAt': verifiedAt?.toIso8601String(),
        'verificationExecutive': verificationExecutive,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        items: (json['items'] as List<dynamic>)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num).toDouble(),
        status: OrderStatus.values.byName(json['status'] as String),
        slot: json['slot'] as String,
        idempotencyKey: json['idempotencyKey'] as String,
        paymentMethod: json['paymentMethod'] as String? ?? 'Cash on delivery',
        deliveryAddress: json['deliveryAddress'] as String? ?? 'Tap to add delivery address',
        customerName: json['customerName'] as String? ?? 'Guest Gourmet',
        customerPhone: json['customerPhone'] as String? ?? '+91 98765 00000',
        driverName: json['driverName'] as String? ?? 'Rashid Khan',
        driverPhone: json['driverPhone'] as String? ?? '+91 98450 12345',
        driverVehicle: json['driverVehicle'] as String? ?? 'KA 01 AB 1234',
        deliveryLat: (json['deliveryLat'] as num?)?.toDouble(),
        deliveryLon: (json['deliveryLon'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        cancellationDeadline: json['cancellationDeadline'] != null
            ? DateTime.parse(json['cancellationDeadline'] as String)
            : null,
        isDeliveryVerified: json['isDeliveryVerified'] as bool? ?? false,
        verifiedAt: json['verifiedAt'] != null
            ? DateTime.parse(json['verifiedAt'] as String)
            : null,
        verificationExecutive: json['verificationExecutive'] as String?,
      );
}

class DeliveryPartner {
  final String id;
  final String name;
  final String phone;
  final String vehicle;
  final double rating;
  final String photoUrl;
  final bool isAvailable;

  const DeliveryPartner({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicle,
    this.rating = 4.9,
    this.photoUrl = 'assets/images/avatar_rider.jpg',
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'vehicle': vehicle,
        'rating': rating,
        'photoUrl': photoUrl,
        'isAvailable': isAvailable,
      };

  factory DeliveryPartner.fromJson(Map<String, dynamic> json) => DeliveryPartner(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        vehicle: json['vehicle'] as String,
        rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
        photoUrl: json['photoUrl'] as String? ?? 'assets/images/avatar_rider.jpg',
        isAvailable: json['isAvailable'] as bool? ?? true,
      );
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String role;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.role = 'customer',
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? role,
  }) =>
      UserProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role ?? this.role,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'role': role,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        photoUrl: json['photoUrl'] as String?,
        role: json['role'] as String? ?? 'customer',
      );

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'G';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color get avatarBgColor {
    const colors = [
      Color(0xFF4285F4), // Google Blue
      Color(0xFFEA4335), // Google Red
      Color(0xFFFBBC05), // Google Amber
      Color(0xFF34A853), // Google Green
      Color(0xFF8E24AA), // Purple
      Color(0xFF00897B), // Teal
      Color(0xFFE65100), // Deep Orange
    ];
    final seed = email.isNotEmpty ? email : name;
    final index = seed.codeUnits.fold(0, (sum, c) => sum + c) % colors.length;
    return colors[index];
  }
}

/// Profile model for the meat market storefront / artisan butcher shop.
class ShopProfile {
  final String id;
  final String name;
  final String photoUrl;
  final String address;
  final String phone;
  final String email;
  final String openingHours;
  final String fssaiLicense;
  final String halalCertNumber;
  final double rating;
  final bool isOpen;

  const ShopProfile({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.address,
    required this.phone,
    this.email = 'alnoor.butchery@freshmeatmarket.in',
    this.openingHours = '06:00 AM – 09:30 PM (Daily)',
    this.fssaiLicense = 'FSSAI-11223344556677',
    this.halalCertNumber = 'HAL-2026-IND-8841',
    this.rating = 4.9,
    this.isOpen = true,
  });

  ShopProfile copyWith({
    String? id,
    String? name,
    String? photoUrl,
    String? address,
    String? phone,
    String? email,
    String? openingHours,
    String? fssaiLicense,
    String? halalCertNumber,
    double? rating,
    bool? isOpen,
  }) =>
      ShopProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        photoUrl: photoUrl ?? this.photoUrl,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        openingHours: openingHours ?? this.openingHours,
        fssaiLicense: fssaiLicense ?? this.fssaiLicense,
        halalCertNumber: halalCertNumber ?? this.halalCertNumber,
        rating: rating ?? this.rating,
        isOpen: isOpen ?? this.isOpen,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photoUrl': photoUrl,
        'address': address,
        'phone': phone,
        'email': email,
        'openingHours': openingHours,
        'fssaiLicense': fssaiLicense,
        'halalCertNumber': halalCertNumber,
        'rating': rating,
        'isOpen': isOpen,
      };

  factory ShopProfile.fromJson(Map<String, dynamic> json) => ShopProfile(
        id: json['id'] as String? ?? 'shop_primary',
        name: json['name'] as String? ?? 'Al-Noor Halal Cuts & Central Butchery',
        photoUrl: json['photoUrl'] as String? ?? 'assets/images/splash_hero.jpg',
        address: json['address'] as String? ??
            'Shop #4, Halal Meat Market, Russell Market, Shivaji Nagar, Bengaluru, Karnataka 560051',
        phone: json['phone'] as String? ?? '+91 98450 12345',
        email: json['email'] as String? ?? 'alnoor.butchery@freshmeatmarket.in',
        openingHours: json['openingHours'] as String? ?? '06:00 AM – 09:30 PM (Daily)',
        fssaiLicense: json['fssaiLicense'] as String? ?? 'FSSAI-11223344556677',
        halalCertNumber: json['halalCertNumber'] as String? ?? 'HAL-2026-IND-8841',
        rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
        isOpen: json['isOpen'] as bool? ?? true,
      );

  static const defaultShop = ShopProfile(
    id: 'shop_primary',
    name: 'Al-Noor Halal Cuts & Central Butchery',
    photoUrl: 'assets/images/splash_hero.jpg',
    address:
        'Shop #4, Halal Meat Market, Russell Market, Shivaji Nagar, Bengaluru, Karnataka 560051',
    phone: '+91 98450 12345',
    email: 'alnoor.butchery@freshmeatmarket.in',
    openingHours: '06:00 AM – 09:30 PM (Daily)',
    fssaiLicense: 'FSSAI-11223344556677',
    halalCertNumber: 'HAL-2026-IND-8841',
    rating: 4.9,
    isOpen: true,
  );
}

