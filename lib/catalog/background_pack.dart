class BackgroundAsset {
  const BackgroundAsset({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.base64Data,
    required this.sortIndex,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final String base64Data;
  final int sortIndex;

  BackgroundAsset copyWith({
    String? id,
    String? fileName,
    String? mimeType,
    String? base64Data,
    int? sortIndex,
  }) {
    return BackgroundAsset(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      base64Data: base64Data ?? this.base64Data,
      sortIndex: sortIndex ?? this.sortIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'mimeType': mimeType,
    'base64Data': base64Data,
    'sortIndex': sortIndex,
  };

  factory BackgroundAsset.fromJson(Map<String, dynamic> json) {
    return BackgroundAsset(
      id: json['id'] as String,
      fileName: json['fileName'] as String? ?? 'image',
      mimeType: json['mimeType'] as String? ?? 'image/jpeg',
      base64Data: json['base64Data'] as String? ?? '',
      sortIndex: json['sortIndex'] as int? ?? 0,
    );
  }
}

class BackgroundPack {
  const BackgroundPack({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.isFree,
    required this.isPublished,
    required this.images,
    required this.updatedAt,
    this.storeProductId,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final bool isFree;
  final bool isPublished;
  /// 앱스토어 상품 ID. 금액 숫자 필드가 아니다.
  final String? storeProductId;
  final List<BackgroundAsset> images;
  final DateTime updatedAt;

  int get imageCount => images.length;

  BackgroundPack copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    bool? isFree,
    bool? isPublished,
    String? storeProductId,
    List<BackgroundAsset>? images,
    DateTime? updatedAt,
    bool clearStoreProductId = false,
  }) {
    return BackgroundPack(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      isFree: isFree ?? this.isFree,
      isPublished: isPublished ?? this.isPublished,
      storeProductId: clearStoreProductId
          ? null
          : storeProductId ?? this.storeProductId,
      images: images ?? this.images,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'isFree': isFree,
    'isPublished': isPublished,
    'storeProductId': storeProductId,
    'images': images.map((item) => item.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory BackgroundPack.fromJson(Map<String, dynamic> json) {
    final raw = json['images'];
    return BackgroundPack(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '꽃',
      isFree: json['isFree'] as bool? ?? true,
      isPublished: json['isPublished'] as bool? ?? false,
      storeProductId: json['storeProductId'] as String?,
      images: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) =>
                      BackgroundAsset.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
