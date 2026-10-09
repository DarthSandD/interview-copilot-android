// Unit tests for the pure logic — no microphone, no native code, no disk.
//
// These are the tests that would have caught the footer overflow and the
// transcript-growth problem, and they run in milliseconds.

import 'package:flutter_test/flutter_test.dart';

import 'package:interview_copilot/core/result.dart';
import 'package:interview_copilot/data/model_integrity.dart';
import 'package:interview_copilot/domain/models.dart';

void main() {
  group('TranscriptLine', () {
    test('counts words across messy whitespace', () {
      final line = TranscriptLine(
        speaker: Speaker.them,
        text: '  explain   how\nRAG\tworks ',
        at: _epoch,
      );
      expect(line.wordCount, 4);
    });

    test('round-trips through JSON', () {
      final line = TranscriptLine(
        speaker: Speaker.you,
        text: 'hello there',
        at: _epoch,
      );
      final restored = TranscriptLine.tryFromJson(line.toJson());
      expect(restored, isNotNull);
      expect(restored!.speaker, Speaker.you);
      expect(restored.text, 'hello there');
      expect(restored.at, _epoch);
    });

    test('rejects malformed JSON instead of throwing', () {
      expect(TranscriptLine.tryFromJson({'speaker': 'them'}), isNull);
      expect(
        TranscriptLine.tryFromJson({'text': 'x', 'at': 'not-a-date'}),
        isNull,
      );
      expect(
        TranscriptLine.tryFromJson({'text': 42, 'at': '2026-01-01T00:00:00Z'}),
        isNull,
      );
    });
  });

  group('Speaker', () {
    test('maps stored names, defaulting unknown values to them', () {
      expect(Speaker.fromName('you'), Speaker.you);
      expect(Speaker.fromName('sys'), Speaker.system);
      expect(Speaker.fromName('them'), Speaker.them);
      expect(Speaker.fromName('garbage'), Speaker.them);
    });
  });

  group('CaptureStatus', () {
    test('marks only the in-flight states as busy', () {
      expect(CaptureStatus.idle.isBusy, isFalse);
      expect(CaptureStatus.preparing.isBusy, isTrue);
      expect(CaptureStatus.downloadingModel.isBusy, isTrue);
      expect(CaptureStatus.loadingModel.isBusy, isTrue);
      expect(CaptureStatus.listening.isBusy, isFalse);
      expect(CaptureStatus.error.isBusy, isFalse);
    });
  });

  group('Result', () {
    test('fold routes to the right branch', () {
      const ok = Ok<int>(3);
      const err = Err<int>('boom');
      expect(ok.fold((v) => 'v$v', (m) => 'e$m'), 'v3');
      expect(err.fold((v) => 'v$v', (m) => 'e$m'), 'eboom');
      expect(ok.valueOrNull, 3);
      expect(err.valueOrNull, isNull);
      expect(err.errorOrNull, 'boom');
    });
  });

  group('ModelCatalog', () {
    test('pins a full 64-char sha256 and a real size', () {
      final spec = ModelCatalog.baseEn;
      expect(spec.sha256.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(spec.sha256), isTrue);
      expect(spec.sizeBytes, greaterThan(0));
      expect(spec.url.scheme, 'https');
      expect(spec.fileName, endsWith('.bin'));
    });
  });
}

final DateTime _epoch = DateTime.utc(2026, 1, 1);
