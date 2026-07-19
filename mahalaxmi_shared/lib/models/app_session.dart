enum AuthRole { none, admin, labour, customer }

class AppSession {
  final AuthRole role;
  final int? customerId;
  final String? customerShopName;
  final String? customerMobile;
  final String? customerOwnerName;
  final String? username;

  const AppSession._({
    required this.role,
    this.customerId,
    this.customerShopName,
    this.customerMobile,
    this.customerOwnerName,
    this.username,
  });

  static const loggedOut = AppSession._(role: AuthRole.none);

  factory AppSession.customer({
    required int customerId,
    required String customerShopName,
    String customerMobile = '',
    String customerOwnerName = '',
  }) {
    return AppSession._(
      role: AuthRole.customer,
      customerId: customerId,
      customerShopName: customerShopName,
      customerMobile: customerMobile,
      customerOwnerName: customerOwnerName,
    );
  }

  factory AppSession.admin(String username) {
    return AppSession._(role: AuthRole.admin, username: username);
  }

  factory AppSession.labour(String username) {
    return AppSession._(role: AuthRole.labour, username: username);
  }

  bool get isLoggedIn => role != AuthRole.none;
  bool get isCustomer => role == AuthRole.customer;
  bool get isAdmin => role == AuthRole.admin;
  bool get isLabour => role == AuthRole.labour;

  Map<String, dynamic> toJson() {
    return {
      'role': role.name,
      'customerId': customerId,
      'customerShopName': customerShopName,
      'customerMobile': customerMobile,
      'customerOwnerName': customerOwnerName,
      'username': username,
    };
  }

  factory AppSession.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String?;
    if (roleStr == null || roleStr == 'none') return AppSession.loggedOut;

    final role = AuthRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => AuthRole.none,
    );
    if (role == AuthRole.none) return AppSession.loggedOut;

    if (role == AuthRole.customer) {
      return AppSession.customer(
        customerId: json['customerId'] as int? ?? 0,
        customerShopName: json['customerShopName'] as String? ?? '',
        customerMobile: json['customerMobile'] as String? ?? '',
        customerOwnerName: json['customerOwnerName'] as String? ?? '',
      );
    }

    return AppSession._(
      role: role,
      username: json['username'] as String?,
    );
  }
}
