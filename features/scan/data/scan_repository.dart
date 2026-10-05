import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../scan_kind.dart';
import 'scan_analysis_repository.dart';

class ScanRepository {
  ScanRepository(this._api);

  final ApiClient _api;

  /// Gemini on the backend may retry busy models for up to 45 s, plus the upload.
  static const timeout = Duration(seconds: 90);

  /// Uploads the photo; the backend analyses it, saves the scan to History and returns the result.
  /// Throws a ServerException with the backend's message for a photo that isn't seeds / a crop.
  Future<ScanAnalysis> analyze(ScanKind kind, String imagePath, String language) async {
    final data = await _api.postMultipart(
      '/scans/',
      filePath: imagePath,
      contentType: _imageType(imagePath),
      timeout: timeout,
      fields: {'type': kind.apiType, 'analyze': 'true', 'language': language},
    ) as Map<String, dynamic>;
    final analysis = (data['analysis'] as Map).cast<String, dynamic>();
    return kind == ScanKind.seed ? SeedAnalysis.fromJson(analysis) : DiseaseAnalysis.fromJson(analysis);
  }

  static String _imageType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}

final scanRepositoryProvider = Provider<ScanRepository>((ref) => ScanRepository(ref.watch(apiClientProvider)));
