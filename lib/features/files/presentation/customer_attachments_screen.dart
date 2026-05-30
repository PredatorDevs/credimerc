import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/permissions/permission_service.dart';
import '../../customers/data/customer_model.dart';
import '../data/attachment_model.dart';
import '../data/files_api.dart';

class CustomerAttachmentsScreen extends StatefulWidget {
  const CustomerAttachmentsScreen({
    super.key,
    required this.customer,
    required this.filesApi,
    required this.permissionService,
  });

  final Customer customer;
  final FilesApi filesApi;
  final PermissionService permissionService;

  @override
  State<CustomerAttachmentsScreen> createState() => _CustomerAttachmentsScreenState();
}

class _CustomerAttachmentsScreenState extends State<CustomerAttachmentsScreen> {
  static const List<String> _categories = <String>[
    'PROFILE_PHOTO',
    'ID_FRONT',
    'ID_BACK',
    'SELFIE_VERIFICATION',
    'SUPPORTING_DOCUMENT',
  ];

  final ImagePicker _picker = ImagePicker();

  List<AttachmentItem> _items = const <AttachmentItem>[];
  String _selectedCategory = 'PROFILE_PHOTO';
  bool _loading = true;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.filesApi.listFiles(
        ownerType: 'CUSTOMER',
        ownerId: widget.customer.id,
      );

      if (!mounted) return;
      setState(() {
        _items = items;
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
        _error = 'No fue posible cargar adjuntos.';
        _loading = false;
      });
    }
  }

  Future<void> _uploadFrom(ImageSource source) async {
    final permissionResult = source == ImageSource.camera
        ? await widget.permissionService.requestCameraPermission()
        : await widget.permissionService.requestPhotosPermission();

    if (!mounted) return;

    if (permissionResult == MediaPermissionResult.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso denegado.')),
      );
      return;
    }

    if (permissionResult == MediaPermissionResult.permanentlyDenied) {
      final opened = await widget.permissionService.openSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            opened
                ? 'Permiso bloqueado. Revisa Configuracion de la app.'
                : 'No se pudo abrir Configuracion automaticamente.',
          ),
        ),
      );
      return;
    }

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2200,
      maxHeight: 2200,
    );

    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();
    final mimeType =
        lookupMimeType(picked.name, headerBytes: bytes.take(16).toList()) ??
        'image/jpeg';

    setState(() => _uploading = true);

    try {
      await widget.filesApi.uploadAttachment(
        ownerType: 'CUSTOMER',
        ownerId: widget.customer.id,
        category: _selectedCategory,
        mimeType: mimeType,
        fileName: picked.name,
        bytes: bytes,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adjunto subido correctamente.')),
      );
      await _loadFiles();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      setState(() => _uploading = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo subir el adjunto.')),
      );
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adjuntos - ${widget.customer.fullName}'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _loadFiles,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories
                      .map(
                        (String category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _uploading
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _selectedCategory = value);
                        },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Categoria de adjunto',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _uploading ? null : () => _uploadFrom(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camara'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _uploading ? null : () => _uploadFrom(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeria'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_items.isEmpty) {
      return const Center(child: Text('No hay adjuntos para este cliente.'));
    }

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _items[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.attachment)),
          title: Text(item.category),
          subtitle: Text(
            'Estado: ${item.status} | ${item.mimeType} | ${(item.sizeBytes / 1024).toStringAsFixed(1)} KB',
          ),
          trailing: Text('#${item.id}'),
        );
      },
    );
  }
}
