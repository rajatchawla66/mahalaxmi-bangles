class Cutmail {
  final String? id;
  final String? categoryId;
  final String categoryName;
  final String itemId;
  final String itemNameSnapshot;
  final String? itemNumberSnapshot;
  final String? imageUrlSnapshot;
  final String? checkedByLabourId;
  final String? checkedByName;
  final String status;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const Cutmail({
    this.id,
    this.categoryId,
    required this.categoryName,
    required this.itemId,
    required this.itemNameSnapshot,
    this.itemNumberSnapshot,
    this.imageUrlSnapshot,
    this.checkedByLabourId,
    this.checkedByName,
    this.status = 'pending',
    this.note,
    this.createdAt,
    this.updatedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  Cutmail copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    String? itemId,
    String? itemNameSnapshot,
    String? itemNumberSnapshot,
    String? imageUrlSnapshot,
    String? checkedByLabourId,
    String? checkedByName,
    String? status,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return Cutmail(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      itemId: itemId ?? this.itemId,
      itemNameSnapshot: itemNameSnapshot ?? this.itemNameSnapshot,
      itemNumberSnapshot: itemNumberSnapshot ?? this.itemNumberSnapshot,
      imageUrlSnapshot: imageUrlSnapshot ?? this.imageUrlSnapshot,
      checkedByLabourId: checkedByLabourId ?? this.checkedByLabourId,
      checkedByName: checkedByName ?? this.checkedByName,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      'category_name': categoryName,
      'item_id': itemId,
      'item_name_snapshot': itemNameSnapshot,
      if (itemNumberSnapshot != null) 'item_number_snapshot': itemNumberSnapshot,
      if (imageUrlSnapshot != null) 'image_url_snapshot': imageUrlSnapshot,
      if (checkedByLabourId != null) 'checked_by_labour_id': checkedByLabourId,
      if (checkedByName != null) 'checked_by_name': checkedByName,
      'status': status,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
    };
  }

  factory Cutmail.fromJson(Map<String, dynamic> json) {
    return Cutmail(
      id: json['id'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String? ?? '',
      itemId: json['item_id'] as String? ?? '',
      itemNameSnapshot: json['item_name_snapshot'] as String? ?? '',
      itemNumberSnapshot: json['item_number_snapshot'] as String?,
      imageUrlSnapshot: json['image_url_snapshot'] as String?,
      checkedByLabourId: json['checked_by_labour_id'] as String?,
      checkedByName: json['checked_by_name'] as String?,
      status: json['status'] as String? ?? 'pending',
      note: json['note'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'] as String) : null,
      reviewedBy: json['reviewed_by'] as String?,
    );
  }
}
