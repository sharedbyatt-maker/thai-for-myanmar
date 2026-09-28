class PhraseCategory {
  const PhraseCategory({
    required this.id,
    required this.my,
    required this.th,
    required this.en,
    required this.kind,
    required this.icon,
  });

  final String id;
  final String my;
  final String th;
  final String en;
  final String kind;
  final String icon;

  factory PhraseCategory.fromJson(Map<String, dynamic> json) {
    return PhraseCategory(
      id: json['id'] as String,
      my: json['my'] as String,
      th: json['th'] as String,
      en: json['en'] as String,
      kind: json['kind'] as String,
      icon: json['icon'] as String,
    );
  }
}

class Phrase {
  const Phrase({
    required this.id,
    required this.categoryId,
    required this.thai,
    required this.myanmar,
    required this.pronunciation,
    required this.english,
    required this.keywords,
    required this.tags,
    this.thaiMale,
    this.thaiFemale,
    this.note,
  });

  final String id;
  final String categoryId;
  final String thai;
  final String? thaiMale;
  final String? thaiFemale;
  final String myanmar;
  final String pronunciation;
  final String english;
  final List<String> keywords;
  final List<String> tags;
  final String? note;

  factory Phrase.fromJson(Map<String, dynamic> json) {
    return Phrase(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      thai: json['thai'] as String,
      thaiMale: json['thaiMale'] as String?,
      thaiFemale: json['thaiFemale'] as String?,
      myanmar: json['my'] as String,
      pronunciation: json['pronunciation'] as String,
      english: json['en'] as String,
      keywords: List<String>.from(json['keywords'] as List<dynamic>),
      tags: List<String>.from(json['tags'] as List<dynamic>),
      note: json['note'] as String?,
    );
  }

  String thaiFor(String politeStyle) {
    if (politeStyle == 'female' && thaiFemale != null) return thaiFemale!;
    if (politeStyle == 'male' && thaiMale != null) return thaiMale!;
    return thai;
  }

  String get searchableText => <String>[
    thai,
    if (thaiMale != null) thaiMale!,
    if (thaiFemale != null) thaiFemale!,
    myanmar,
    pronunciation,
    english,
    ...keywords,
    ...tags,
  ].join(' ');
}
