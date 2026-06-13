class PermissionItem {
  const PermissionItem({
    required this.id,
    required this.code,
    required this.module,
    required this.action,
    required this.description,
    required this.isActive,
  });

  final int id;
  final String code;
  final String module;
  final String action;
  final String? description;
  final bool isActive;

  factory PermissionItem.fromMap(Map<String, dynamic> map) {
    return PermissionItem(
      id: _asInt(map['id']),
      code: map['code']?.toString() ?? '',
      module: map['module']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      description: map['description']?.toString(),
      isActive: map['is_active'] == 1 || map['is_active'] == true || map['isActive'] == true,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
