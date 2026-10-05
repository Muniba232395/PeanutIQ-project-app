import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/translations.dart';
import '../../../core/theme.dart';
import '../device/photo_picker.dart';
import '../scan_kind.dart';

/// The website's dashed upload box. Drag-and-drop becomes Camera / Gallery buttons.
class UploadCard extends ConsumerWidget {
  const UploadCard({super.key, required this.kind, required this.onPick});

  final ScanKind kind;
  final ValueChanged<PhotoSource> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(trProvider);
    final accent = kind == ScanKind.seed ? AppColors.forest : AppColors.terracotta;
    final dash = kind == ScanKind.seed ? AppColors.earth : AppColors.terracotta.withValues(alpha: 0.5);
    final p = kind.prefix;
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(color: dash),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.sand,
                shape: BoxShape.circle,
                border: Border.all(color: accent),
              ),
              child: Icon(LucideIcons.cloudUpload, size: 36, color: accent),
            ),
            const SizedBox(height: 24),
            Text(t.t('$p.uploadTitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
            const SizedBox(height: 8),
            // The website's seed text talks about drag and drop; the app has its own.
            Text(t.t(p == 'seed' ? 'seed.app.uploadDesc' : '$p.uploadDesc'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.charcoal.withValues(alpha: 0.7))),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _PickButton(
                    icon: LucideIcons.camera, label: t.t('$p.captureCamera'), onTap: () => onPick(PhotoSource.camera)),
                _PickButton(
                    icon: LucideIcons.image, label: t.t('$p.selectGallery'), onTap: () => onPick(PhotoSource.gallery)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)));
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}
