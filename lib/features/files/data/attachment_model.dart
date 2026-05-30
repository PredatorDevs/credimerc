class AttachmentItem {
  const AttachmentItem({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.category,
    required this.mimeType,
    required this.sizeBytes,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String ownerType;
  final int ownerId;
  final String category;
  final String mimeType;
  final int sizeBytes;
  final String status;
  final DateTime? createdAt;

  factory AttachmentItem.fromMap(Map<String, dynamic> map) {
    return AttachmentItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      ownerType: map['ownerType']?.toString() ?? map['owner_type']?.toString() ?? 'UNKNOWN',
      ownerId: (map['ownerId'] as num?)?.toInt() ?? (map['owner_id'] as num?)?.toInt() ?? 0,
      category: map['category']?.toString() ?? 'UNKNOWN',
      mimeType: map['mimeType']?.toString() ?? map['mime_type']?.toString() ?? '',
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? (map['size_bytes'] as num?)?.toInt() ?? 0,
      status: map['status']?.toString() ?? 'UNKNOWN',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? map['created_at']?.toString() ?? ''),
    );
  }
}

class UploadTicket {
  const UploadTicket({
    required this.id,
    required this.uploadUrl,
  });

  final int id;
  final String uploadUrl;

  factory UploadTicket.fromMap(Map<String, dynamic> map) {
    return UploadTicket(
      id: (map['id'] as num?)?.toInt() ?? 0,
      uploadUrl: map['uploadUrl']?.toString() ?? '',
    );
  }
}
