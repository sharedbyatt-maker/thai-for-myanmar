class PhraseIssue {
  const PhraseIssue({
    required this.id,
    required this.phraseId,
    required this.thai,
    required this.myanmar,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String phraseId;
  final String thai;
  final String myanmar;
  final String description;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'phraseId': phraseId,
    'thai': thai,
    'myanmar': myanmar,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };

  static PhraseIssue? tryParse(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['id'];
    final phraseId = value['phraseId'];
    final thai = value['thai'];
    final myanmar = value['myanmar'];
    final description = value['description'];
    final createdAt = DateTime.tryParse(value['createdAt']?.toString() ?? '');
    if (id is! String ||
        phraseId is! String ||
        thai is! String ||
        myanmar is! String ||
        description is! String ||
        id.isEmpty ||
        phraseId.isEmpty ||
        description.trim().isEmpty ||
        createdAt == null) {
      return null;
    }
    return PhraseIssue(
      id: id,
      phraseId: phraseId,
      thai: thai,
      myanmar: myanmar,
      description: description,
      createdAt: createdAt,
    );
  }

  String get shareText =>
      'Thai for Myanmar — စကားစုအမှားထောက်ပြချက်\n'
      'Phrase ID: $phraseId\n'
      'Thai: $thai\n'
      'Myanmar: $myanmar\n'
      'အကြောင်းအရာ: $description\n'
      'နေ့စွဲ: ${createdAt.toIso8601String()}';
}
