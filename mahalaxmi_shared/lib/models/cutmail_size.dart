class CutmailSize {
  final String? id;
  final String? cutmailId;
  final String size;
  final int availableQty;
  final bool isAvailable;
  final String? note;
  final DateTime? createdAt;

  const CutmailSize({
    this.id,
    this.cutmailId,
    required this.size,
    this.availableQty = 0,
    this.isAvailable = true,
    this.note,
    this.createdAt,
  });

  CutmailSize copyWith({
    String? id,
    String? cutmailId,
    String? size,
    int? availableQty,
    bool? isAvailable,
    String? note,
    DateTime? createdAt,
  }) {
    return CutmailSize(
      id: id ?? this.id,
      cutmailId: cutmailId ?? this.cutmailId,
      size: size ?? this.size,
      availableQty: availableQty ?? this.availableQty,
      isAvailable: isAvailable ?? this.isAvailable,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (cutmailId != null) 'cutmail_id': cutmailId,
      'size': size,
      'available_qty': availableQty,
      'is_available': isAvailable,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  factory CutmailSize.fromJson(Map<String, dynamic> json) {
    return CutmailSize(
      id: json['id'] as String?,
      cutmailId: json['cutmail_id'] as String?,
      size: json['size'] as String? ?? '',
      availableQty: json['available_qty'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
      note: json['note'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}
