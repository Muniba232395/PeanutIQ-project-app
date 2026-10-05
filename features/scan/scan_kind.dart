/// The two scan flows share one screen; this holds what differs.
enum ScanKind {
  // The type values the website and backend use (SeedIntelligence.jsx / DiseaseIntelligence.jsx).
  seed(apiType: 'Seed Intelligence', prefix: 'seed'),
  disease(apiType: 'Disease Intelligence', prefix: 'disease');

  const ScanKind({required this.apiType, required this.prefix});

  final String apiType;

  /// Translation namespace: 'seed' or 'disease'.
  final String prefix;
}
