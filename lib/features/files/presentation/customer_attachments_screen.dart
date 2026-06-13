import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

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
    required this.canViewAttachments,
    required this.allowedUploadCategories,
  });

  final Customer customer;
  final FilesApi filesApi;
  final PermissionService permissionService;
  final bool canViewAttachments;
  final Set<String> allowedUploadCategories;

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
  final Map<int, String> _downloadUrls = <int, String>{};
  Timer? _autoRefreshTimer;
  int _autoRefreshTicks = 0;

  @override
  void initState() {
    super.initState();
    final allowed = _availableCategories;
    if (allowed.isNotEmpty) {
      _selectedCategory = allowed.first;
    }
    if (widget.canViewAttachments) {
      _loadFiles();
      return;
    }
    _loading = false;
    _error = 'No tienes permiso para ver adjuntos de clientes.';
  }

  List<String> get _availableCategories => _categories
      .where((category) => widget.allowedUploadCategories.contains(category))
      .toList(growable: false);

  bool get _hasPendingUploads => _items.any((item) => item.status == 'UPLOADING');

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }

  void _startAutoRefreshIfNeeded() {
    if (!_hasPendingUploads) {
      _stopAutoRefresh();
      return;
    }

    if (_autoRefreshTimer != null) {
      return;
    }

    _autoRefreshTicks = 0;
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        _stopAutoRefresh();
        return;
      }

      _autoRefreshTicks += 1;
      if (_autoRefreshTicks > 8) {
        _stopAutoRefresh();
        return;
      }

      _loadFiles(silent: true);
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    _autoRefreshTicks = 0;
  }

  Future<void> _loadFiles({bool silent = false}) async {
    setState(() {
      if (!silent) {
        _loading = true;
        _error = null;
      }
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
      _startAutoRefreshIfNeeded();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
      _stopAutoRefresh();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No fue posible cargar adjuntos.';
        _loading = false;
      });
      _stopAutoRefresh();
    }
  }

  Future<void> _uploadFrom(ImageSource source) async {
    if (!widget.canViewAttachments) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes permiso para ver adjuntos.')),
      );
      return;
    }

    if (!widget.allowedUploadCategories.contains(_selectedCategory)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes permiso para subir esta categoria.')),
      );
      return;
    }

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
      setState(() => _uploading = false);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      setState(() => _uploading = false);
      await _loadFiles(silent: true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo subir el adjunto.')),
      );
      setState(() => _uploading = false);
      await _loadFiles(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = _availableCategories;
    final canUploadCurrentCategory = widget.canViewAttachments &&
        availableCategories.isNotEmpty &&
        availableCategories.contains(_selectedCategory);

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
                if (_uploading || _hasPendingUploads)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4D6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFD98A)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _uploading
                                ? 'Subiendo archivo...'
                                : 'Hay adjuntos pendientes de confirmacion. Actualizando automaticamente.',
                          ),
                        ),
                      ],
                    ),
                  ),
                DropdownButtonFormField<String>(
                  value: availableCategories.contains(_selectedCategory)
                      ? _selectedCategory
                      : null,
                  items: availableCategories
                      .map(
                        (String category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _uploading || availableCategories.isEmpty
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
                        onPressed: _uploading || !canUploadCurrentCategory
                            ? null
                            : () => _uploadFrom(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camara'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _uploading || !canUploadCurrentCategory
                            ? null
                            : () => _uploadFrom(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeria'),
                      ),
                    ),
                  ],
                ),
                if (!widget.canViewAttachments) ...[
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sin acceso: files.profile.view',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ] else if (availableCategories.isEmpty) ...[
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Solo lectura: sin permisos de carga para categorias de cliente.',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  bool _isImageAttachment(AttachmentItem item) {
    return item.status == 'ACTIVE' && item.mimeType.toLowerCase().startsWith('image/');
  }

  bool _isPdfAttachment(AttachmentItem item) {
    return item.status == 'ACTIVE' && item.mimeType.toLowerCase().contains('pdf');
  }

  bool _isPreviewableAttachment(AttachmentItem item) {
    return _isImageAttachment(item) || _isPdfAttachment(item) || item.status == 'ACTIVE';
  }

  IconData _attachmentIcon(AttachmentItem item) {
    if (_isImageAttachment(item)) return Icons.image_outlined;
    if (_isPdfAttachment(item)) return Icons.picture_as_pdf_outlined;
    return Icons.description_outlined;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return const Color(0xFF1F9D6A);
      case 'UPLOADING':
        return const Color(0xFFB7791F);
      case 'REJECTED':
        return const Color(0xFFCC3333);
      case 'DELETED':
        return const Color(0xFF666666);
      default:
        return const Color(0xFF46607A);
    }
  }

  Future<String?> _resolveDownloadUrl(int attachmentId) async {
    final cached = _downloadUrls[attachmentId];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final url = await widget.filesApi.getDownloadUrl(attachmentId: attachmentId);
      _downloadUrls[attachmentId] = url;
      return url;
    } on ApiException catch (error) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return null;
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la previsualizacion.')),
      );
      return null;
    }
  }

  Future<void> _openPreview(AttachmentItem item) async {
    if (item.status != 'ACTIVE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo se pueden previsualizar adjuntos activos.')),
      );
      return;
    }

    final url = await _resolveDownloadUrl(item.id);
    if (!mounted || url == null || url.isEmpty) {
      return;
    }

    if (_isPdfAttachment(item)) {
      await _openDocumentUrl(
        url: url,
        preferInApp: true,
        fallbackMessage: 'No se pudo abrir el PDF en vista integrada.',
      );
      return;
    }

    if (!_isImageAttachment(item)) {
      await _showDocumentPreviewSheet(item: item, url: url);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Vista previa - ${item.category}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No se pudo cargar la imagen. Intenta nuevamente.'),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDocumentPreviewSheet({
    required AttachmentItem item,
    required String url,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_attachmentIcon(item)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Documento: ${item.category}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tipo: ${item.mimeType} | ${(item.sizeBytes / 1024).toStringAsFixed(1)} KB',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _openDocumentUrl(
                    url: url,
                    preferInApp: true,
                    fallbackMessage: 'No se pudo abrir la vista previa del documento.',
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir documento'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await Clipboard.setData(ClipboardData(text: url));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL de descarga copiada al portapapeles.')),
                  );
                },
                icon: const Icon(Icons.link_outlined),
                label: const Text('Copiar enlace'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDocumentUrl({
    required String url,
    required bool preferInApp,
    required String fallbackMessage,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL de documento invalida.')),
      );
      return;
    }

    final firstMode = preferInApp ? LaunchMode.inAppBrowserView : LaunchMode.externalApplication;
    final secondMode = preferInApp ? LaunchMode.externalApplication : LaunchMode.inAppBrowserView;

    final openedFirst = await launchUrl(uri, mode: firstMode);
    if (openedFirst) return;

    final openedSecond = await launchUrl(uri, mode: secondMode);
    if (openedSecond) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(fallbackMessage)),
    );
  }

  Future<void> _copyDownloadUrl(AttachmentItem item) async {
    final url = await _resolveDownloadUrl(item.id);
    if (!mounted || url == null || url.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL de descarga copiada al portapapeles.')),
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
        final canPreviewImage = _isImageAttachment(item);
        final canPreviewAny = _isPreviewableAttachment(item);
        final isActive = item.status == 'ACTIVE';
        final createdAt = item.createdAt;
        final createdAtLabel = createdAt == null
            ? '-'
            : '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

        return ListTile(
          leading: CircleAvatar(
            child: Icon(_attachmentIcon(item)),
          ),
          title: Text(item.category),
          subtitle: Text(
            'Estado: ${item.status} | ${item.mimeType} | ${(item.sizeBytes / 1024).toStringAsFixed(1)} KB | $createdAtLabel',
          ),
          trailing: Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: Text(item.status),
                backgroundColor: _statusColor(item.status).withOpacity(0.12),
                labelStyle: TextStyle(
                  color: _statusColor(item.status),
                  fontWeight: FontWeight.w700,
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: isActive ? 'Vista previa' : 'Pendiente de confirmacion',
                onPressed: canPreviewAny ? () => _openPreview(item) : null,
                icon: Icon(canPreviewImage ? Icons.visibility_outlined : Icons.open_in_new),
              ),
              if (item.status == 'ACTIVE')
                IconButton(
                  tooltip: 'Copiar URL de descarga',
                  onPressed: () => _copyDownloadUrl(item),
                  icon: const Icon(Icons.link_outlined),
                ),
            ],
          ),
        );
      },
    );
  }
}
