import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/phrase.dart';

class PhraseRepository {
  PhraseRepository({required this.categories, required this.phrases});

  final List<PhraseCategory> categories;
  final List<Phrase> phrases;

  static Future<PhraseRepository> load(AssetBundle bundle) async {
    final categoryJson = jsonDecode(
      await bundle.loadString('assets/data/phrase_categories.json'),
    ) as List<dynamic>;
    final phraseJson = jsonDecode(
      await bundle.loadString('assets/data/phrases.json'),
    ) as List<dynamic>;
    return PhraseRepository(
      categories: categoryJson
          .map((row) => PhraseCategory.fromJson(row as Map<String, dynamic>))
          .toList(growable: false),
      phrases: phraseJson
          .map((row) => Phrase.fromJson(row as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  PhraseCategory? categoryFor(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  List<Phrase> inCategory(String categoryId) => phrases
      .where((phrase) => phrase.categoryId == categoryId)
      .toList(growable: false);

  List<Phrase> search(String query, {String? categoryId}) {
    final needle = normalize(query);
    final source = categoryId == null
        ? phrases
        : phrases.where((phrase) => phrase.categoryId == categoryId);
    if (needle.isEmpty) return source.toList(growable: false);

    final matches = source.where((phrase) {
      return normalize(phrase.searchableText).contains(needle);
    }).toList();
    matches.sort((a, b) {
      final aText = normalize(a.searchableText);
      final bText = normalize(b.searchableText);
      final aStarts = aText.startsWith(needle);
      final bStarts = bText.startsWith(needle);
      if (aStarts != bStarts) return aStarts ? -1 : 1;
      return a.id.compareTo(b.id);
    });
    return matches;
  }

  static String normalize(String input) =>
      input.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}
