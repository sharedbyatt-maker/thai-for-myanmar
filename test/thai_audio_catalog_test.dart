import 'package:flutter_test/flutter_test.dart';
import 'package:thai_for_myanmar/models/phrase.dart';
import 'package:thai_for_myanmar/services/thai_audio_catalog.dart';

void main() {
  group('ThaiAudioCatalog', () {
    const phrase = Phrase(
      id: 'greet_hello',
      categoryId: 'greetings',
      thai: 'สวัสดีครับ / สวัสดีค่ะ',
      thaiMale: 'สวัสดีครับ',
      thaiFemale: 'สวัสดีค่ะ',
      myanmar: 'မင်္ဂလာပါ။',
      pronunciation: 'စဝတ်ဒီ',
      english: 'Hello.',
      keywords: [],
      tags: [],
    );

    test('maps selected male and female forms independently', () {
      final catalog = ThaiAudioCatalog.fromJson({
        'schemaVersion': 1,
        'entries': [
          {
            'phraseId': phrase.id,
            'form': 'male',
            'thai': phrase.thaiMale,
            'asset': 'audio/thai/greet_hello_male.mp3',
          },
          {
            'phraseId': phrase.id,
            'form': 'female',
            'thai': phrase.thaiFemale,
            'asset': 'audio/thai/greet_hello_female.mp3',
          },
        ],
      });

      expect(
        catalog.match(phrase, 'male')?.assetPath,
        'audio/thai/greet_hello_male.mp3',
      );
      expect(
        catalog.match(phrase, 'female')?.assetPath,
        'audio/thai/greet_hello_female.mp3',
      );
    });

    test('accepts a shared neutral phrase only for matching text', () {
      const neutral = Phrase(
        id: 'water',
        categoryId: 'restaurant',
        thai: 'น้ำเปล่า',
        myanmar: 'ရေသန့်',
        pronunciation: 'နမ်ပလ่าว',
        english: 'Plain water.',
        keywords: [],
        tags: [],
      );
      final catalog = ThaiAudioCatalog.fromJson({
        'schemaVersion': 1,
        'entries': [
          {
            'phraseId': neutral.id,
            'form': 'shared',
            'thai': neutral.thai,
            'asset': 'audio/thai/water_shared.mp3',
          },
        ],
      });

      expect(catalog.match(neutral, 'female')?.form, ThaiAudioForm.shared);
      expect(catalog.match(neutral, 'male')?.form, ThaiAudioForm.shared);
    });

    test('rejects a stale mapping when the displayed phrase changed', () {
      final catalog = ThaiAudioCatalog.fromJson({
        'schemaVersion': 1,
        'entries': [
          {
            'phraseId': phrase.id,
            'form': 'male',
            'thai': 'สวัสดีครับครับ',
            'asset': 'audio/thai/greet_hello_old.mp3',
          },
        ],
      });

      expect(catalog.match(phrase, 'male'), isNull);
    });

    test('rejects duplicate, remote, and traversal mappings', () {
      final duplicate = {
        'schemaVersion': 1,
        'entries': [
          {
            'phraseId': phrase.id,
            'form': 'male',
            'thai': phrase.thaiMale,
            'asset': 'audio/thai/hello.mp3',
          },
          {
            'phraseId': phrase.id,
            'form': 'male',
            'thai': phrase.thaiMale,
            'asset': 'audio/thai/hello-copy.mp3',
          },
        ],
      };
      final remote = {
        'schemaVersion': 1,
        'entries': [
          {
            'phraseId': phrase.id,
            'form': 'male',
            'thai': phrase.thaiMale,
            'asset': 'https://example.test/hello.mp3',
          },
        ],
      };
      final traversal = {
        'schemaVersion': 1,
        'entries': [
          {
            'phraseId': phrase.id,
            'form': 'male',
            'thai': phrase.thaiMale,
            'asset': 'audio/thai/../../private.mp3',
          },
        ],
      };

      expect(() => ThaiAudioCatalog.fromJson(duplicate), throwsFormatException);
      expect(() => ThaiAudioCatalog.fromJson(remote), throwsFormatException);
      expect(() => ThaiAudioCatalog.fromJson(traversal), throwsFormatException);
    });
  });
}
