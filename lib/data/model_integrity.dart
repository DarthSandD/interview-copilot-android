import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../core/logger.dart';
import '../core/result.dart';

/// A speech model this app is willing to execute.
///
/// [sha256] is the digest published by the upstream repository. The native
/// whisper.cpp parser is fed this file directly, so an unverified or
/// tampered download is a real attack surface — never load a model whose
/// digest has not been checked.
class ModelSpec {
  final String name;
  final String fileName;
  final Uri url;
  final int sizeBytes;
  final String sha256;

  const ModelSpec({
    required this.name,
    required this.fileName,
    required this.url,
    required this.sizeBytes,
    required this.sha256,
  });
}

/// The pinned model catalogue.
///
/// Digests come from the Hugging Face LFS metadata for
/// `ggerganov/whisper.cpp`; sizes are the exact byte counts. If upstream
/// re-publishes a model the digest changes and the app refuses to load it
/// until this list is updated deliberately.
///
/// (A `final` class rather than `abstract final` because the entries are
/// constructed here — const Uri/ModelSpec require runtime initialisation of
/// the parsed URI, which const evaluation forbids.)
final class ModelCatalog {
  static final ModelSpec baseEn = ModelSpec(
    name: 'base.en',
    fileName: 'ggml-base.en.bin',
    url: Uri.parse(
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin',
    ),
    sizeBytes: 147964211,
    sha256: 'a03779c86df3323075f5e796cb2ce5029f00ec8869eee3fdfb897afe36c6d002',
  );

  ModelCatalog._();
}

/// Verifies model files on disk before they are handed to native code.
abstract final class ModelIntegrity {
  /// Streaming digest so a 142 MB file is never held in memory.
  static Future<String> sha256OfFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  /// Returns [Ok] with the verified file, or [Err] with a reason.
  ///
  /// Checks size first (cheap) then digest (authoritative).
  static Future<Result<File>> verify(File file, ModelSpec spec) async {
    if (!await file.exists()) {
      return const Err('model file missing');
    }

    final length = await file.length();
    if (length != spec.sizeBytes) {
      Log.w('model.size_mismatch', {
        'expected': spec.sizeBytes,
        'actual': length,
      });
      return Err(
        'model file is $length bytes, expected ${spec.sizeBytes} — '
        'the download was incomplete or corrupted',
      );
    }

    final actual = await sha256OfFile(file);
    if (actual != spec.sha256) {
      Log.w('model.digest_mismatch', {
        'expected': spec.sha256.substring(0, 12),
        'actual': actual.substring(0, 12),
      });
      return const Err(
        'model file failed its integrity check and was rejected',
      );
    }

    Log.i('model.verified', {'name': spec.name});
    return Ok(file);
  }
}
