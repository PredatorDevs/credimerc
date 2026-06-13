import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../data/company_user_model.dart';
import '../data/company_users_api.dart';
import '../data/permission_model.dart';
import '../data/rbac_api.dart';
import '../data/role_model.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({
    super.key,
    required this.companyUsersApi,
    required this.rbacApi,
  });

  final CompanyUsersApi companyUsersApi;
  final RbacApi rbacApi;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<CompanyUser> _users = const <CompanyUser>[];
  List<RoleItem> _roles = const <RoleItem>[];
  List<PermissionItem> _permissions = const <PermissionItem>[];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await widget.companyUsersApi.listCompanyUsers();
      final roles = await widget.rbacApi.listRoles();
      final permissions = await widget.rbacApi.listPermissions();

      if (!mounted) return;
      setState(() {
        _users = users;
        _roles = roles;
        _permissions = permissions;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No fue posible cargar administracion.';
        _loading = false;
      });
    }
  }

  Future<void> _openInviteDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _InviteCompanyUserDialog(companyUsersApi: widget.companyUsersApi),
    );

    if (created == true) {
      await _loadAll();
    }
  }

  Future<void> _openCreateRoleDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateRoleDialog(rbacApi: widget.rbacApi),
    );

    if (created == true) {
      await _loadAll();
    }
  }

  Future<void> _openRolePermissionsDialog(RoleItem role) async {
    final selected = await showDialog<List<int>>(
      context: context,
      builder: (_) => _RolePermissionsDialog(
        role: role,
        allPermissions: _permissions,
      ),
    );

    if (selected == null) return;

    try {
      await widget.rbacApi.setRolePermissions(roleId: role.id, permissionIds: selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permisos del rol actualizados.')),
      );
      await _loadAll();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _openUserRolesDialog(CompanyUser user) async {
    final selected = await showDialog<List<int>>(
      context: context,
      builder: (_) => _UserRolesDialog(
        user: user,
        roles: _roles,
      ),
    );

    if (selected == null) return;

    try {
      await widget.rbacApi.setCompanyUserRoles(companyUserId: user.id, roleIds: selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Roles del usuario actualizados.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _updateUserStatus(CompanyUser user, String status) async {
    try {
      await widget.companyUsersApi.updateCompanyUserStatus(
        companyUserId: user.id,
        status: status,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado de usuario actualizado.')),
      );
      await _loadAll();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administracion'),
          actions: [
            IconButton(
              tooltip: 'Recargar',
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.manage_accounts_outlined), text: 'Usuarios'),
              Tab(icon: Icon(Icons.admin_panel_settings_outlined), text: 'Roles'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withOpacity(0.08),
                Theme.of(context).scaffoldBackgroundColor,
                colorScheme.secondary.withOpacity(0.05),
              ],
            ),
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _loadAll)
                  : TabBarView(
                      children: [
                        _UsersTab(
                          users: _users,
                          onInvite: _openInviteDialog,
                          onUpdateStatus: _updateUserStatus,
                          onAssignRoles: _openUserRolesDialog,
                        ),
                        _RolesTab(
                          roles: _roles,
                          onCreateRole: _openCreateRoleDialog,
                          onAssignPermissions: _openRolePermissionsDialog,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab({
    required this.users,
    required this.onInvite,
    required this.onUpdateStatus,
    required this.onAssignRoles,
  });

  final List<CompanyUser> users;
  final Future<void> Function() onInvite;
  final Future<void> Function(CompanyUser user, String status) onUpdateStatus;
  final Future<void> Function(CompanyUser user) onAssignRoles;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_off_outlined, size: 48),
              const SizedBox(height: 12),
              const Text('No hay usuarios de empresa registrados.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onInvite,
                icon: const Icon(Icons.person_add),
                label: const Text('Invitar usuario'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onInvite,
            icon: const Icon(Icons.person_add),
            label: const Text('Invitar usuario'),
          ),
        ),
        const SizedBox(height: 10),
        ...users.map((user) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.userFullName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (user.isOwner) const Chip(label: Text('OWNER')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(user.userEmail),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetaChip(label: 'Estado: ${user.status}'),
                      if (user.employeeCode != null) _MetaChip(label: 'Codigo: ${user.employeeCode}'),
                      if (user.jobTitle != null) _MetaChip(label: 'Cargo: ${user.jobTitle}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onAssignRoles(user),
                          icon: const Icon(Icons.badge_outlined),
                          label: const Text('Asignar roles'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PopupMenuButton<String>(
                          onSelected: (status) => onUpdateStatus(user, status),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'ACTIVE', child: Text('Marcar ACTIVE')),
                            PopupMenuItem(value: 'INACTIVE', child: Text('Marcar INACTIVE')),
                            PopupMenuItem(value: 'REMOVED', child: Text('Marcar REMOVED')),
                          ],
                          child: const ListTile(
                            dense: true,
                            leading: Icon(Icons.swap_horiz),
                            title: Text('Cambiar estado'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _RolesTab extends StatelessWidget {
  const _RolesTab({
    required this.roles,
    required this.onCreateRole,
    required this.onAssignPermissions,
  });

  final List<RoleItem> roles;
  final Future<void> Function() onCreateRole;
  final Future<void> Function(RoleItem role) onAssignPermissions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onCreateRole,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Nuevo rol'),
          ),
        ),
        const SizedBox(height: 10),
        ...roles.map((role) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          role.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (role.isSystem) const Chip(label: Text('SYSTEM')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(role.description ?? 'Sin descripcion'),
                  const SizedBox(height: 10),
                  _MetaChip(label: 'Permisos: ${role.permissions.length} · Estado: ${role.status}'),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => onAssignPermissions(role),
                      icon: const Icon(Icons.rule_folder_outlined),
                      label: const Text('Asignar permisos'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 46),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCompanyUserDialog extends StatefulWidget {
  const _InviteCompanyUserDialog({required this.companyUsersApi});

  final CompanyUsersApi companyUsersApi;

  @override
  State<_InviteCompanyUserDialog> createState() => _InviteCompanyUserDialogState();
}

class _InviteCompanyUserDialogState extends State<_InviteCompanyUserDialog> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _employeeCodeController = TextEditingController();
  final _jobTitleController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _employeeCodeController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = 'Ingresa un correo valido.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.companyUsersApi.inviteCompanyUser(
        email: email,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        employeeCode: _employeeCodeController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'No se pudo invitar al usuario: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invitar usuario'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Nombre completo (opcional)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Telefono (opcional)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _employeeCodeController,
              decoration: const InputDecoration(labelText: 'Codigo empleado (opcional)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _jobTitleController,
              decoration: const InputDecoration(labelText: 'Cargo (opcional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_submitting ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}

class _CreateRoleDialog extends StatefulWidget {
  const _CreateRoleDialog({required this.rbacApi});

  final RbacApi rbacApi;

  @override
  State<_CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends State<_CreateRoleDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el nombre del rol.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await widget.rbacApi.createRole(
        name: name,
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo rol'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre del rol'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripcion (opcional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_submitting ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}

class _RolePermissionsDialog extends StatefulWidget {
  const _RolePermissionsDialog({
    required this.role,
    required this.allPermissions,
  });

  final RoleItem role;
  final List<PermissionItem> allPermissions;

  @override
  State<_RolePermissionsDialog> createState() => _RolePermissionsDialogState();
}

class _RolePermissionsDialogState extends State<_RolePermissionsDialog> {
  late final Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.role.permissions.map((item) => item.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Permisos: ${widget.role.name}'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: ListView.builder(
          itemCount: widget.allPermissions.length,
          itemBuilder: (context, index) {
            final permission = widget.allPermissions[index];
            final selected = _selectedIds.contains(permission.id);

            return CheckboxListTile(
              value: selected,
              title: Text(permission.code),
              subtitle: Text('${permission.module} · ${permission.action}'),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(permission.id);
                  } else {
                    _selectedIds.remove(permission.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedIds.toList(growable: false)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _UserRolesDialog extends StatefulWidget {
  const _UserRolesDialog({
    required this.user,
    required this.roles,
  });

  final CompanyUser user;
  final List<RoleItem> roles;

  @override
  State<_UserRolesDialog> createState() => _UserRolesDialogState();
}

class _UserRolesDialogState extends State<_UserRolesDialog> {
  final Set<int> _selectedRoleIds = <int>{};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Roles para ${widget.user.userFullName}'),
      content: SizedBox(
        width: 420,
        height: 360,
        child: ListView.builder(
          itemCount: widget.roles.length,
          itemBuilder: (context, index) {
            final role = widget.roles[index];
            final selected = _selectedRoleIds.contains(role.id);

            return CheckboxListTile(
              value: selected,
              title: Text(role.name),
              subtitle: Text(role.status),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedRoleIds.add(role.id);
                  } else {
                    _selectedRoleIds.remove(role.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedRoleIds.toList(growable: false)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
