import 'permission_model.dart';

class RoleItem {
  const RoleItem({
    required this.id,
    required this.companyId,
    required this.name,
    required this.description,
    required this.status,
    required this.isSystem,
    required this.permissions,
  });

  final int id;
  final int companyId;
  final String name;
  final String? description;
  final String status;
  final bool isSystem;
  final List<PermissionItem> permissions;

  factory RoleItem.fromMap(Map<String, dynamic> map) {
    final rawPermissions = map['permissions'];

    return RoleItem(
      id: _asInt(map['id']),
      companyId: _asInt(map['company_id']),
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
      status: map['status']?.toString() ?? 'INACTIVE',
      isSystem: map['is_system'] == 1 || map['is_system'] == true || map['isSystem'] == true,
      permissions: rawPermissions is List
          ? rawPermissions
              .whereType<Map>()
              .map((item) => PermissionItem.fromMap(item.cast<String, dynamic>()))
              .toList(growable: false)
          : const <PermissionItem>[],
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
