import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/i18n/translations.dart';
import '../../core/theme.dart';
import '../../core/widgets/toast.dart';
import 'assistant_controller.dart';
import 'assistant_launcher.dart';
import 'widgets/assistant_input_bar.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/robot_face.dart';
import 'widgets/robot_hero.dart';

/// How long after the shell appears the panel opens by itself (null = never; tests).
final assistantAutoOpenDelayProvider = Provider<Duration?>(
  (ref) => const Duration(seconds: 1),
);

/// Remembers the auto-open for this app launch (spec: once per launch, not per page).
class _AutoOpened extends Notifier<bool> {
  @override
  bool build() => false;

  void mark() => state = true;
}

final _autoOpenedProvider = NotifierProvider<_AutoOpened, bool>(
  _AutoOpened.new,
);

/// Port of FloatingAgent: the floating robot button and the chat panel.
class FloatingAssistant extends ConsumerStatefulWidget {
  const FloatingAssistant({super.key, required this.location});

  /// The current route. A change closes the panel and resets its language (as on the website).
  final String location;

  @override
  ConsumerState<FloatingAssistant> createState() => _FloatingAssistantState();
}

class _FloatingAssistantState extends ConsumerState<FloatingAssistant>
    with SingleTickerProviderStateMixin {
  final _started = DateTime.now();
  Timer? _tick;
  Timer? _autoOpen;
  String? _fullscreen;
  final _scroll = ScrollController();
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  AssistantController get _ctl =>
      ref.read(assistantControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && ref.read(assistantControllerProvider).open) {
        setState(() {});
      }
    });
    final delay = ref.read(assistantAutoOpenDelayProvider);
    if (delay != null && !ref.read(_autoOpenedProvider)) {
      _autoOpen = Timer(delay, () {
        if (!mounted || ref.read(_autoOpenedProvider)) return;
        ref.read(_autoOpenedProvider.notifier).mark();
        _ctl.open();
      });
    }
    // The dashboard tip's mic button (the website's `open-robot` event).
    ref.listenManual(assistantLauncherProvider, (_, _) => _ctl.open());
    // Keep the newest message in view, also when a reply replaces "Thinking..." (same count).
    ref.listenManual(
      assistantControllerProvider.select((s) => s.messages),
      (_, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });
      },
    );
  }

  @override
  void didUpdateWidget(FloatingAssistant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ctl.close();
        _ctl.resetLanguage();
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _autoOpen?.cancel();
    _scroll.dispose();
    _float.dispose();
    super.dispose();
  }

  String get _elapsed {
    final s = DateTime.now().difference(_started).inSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantControllerProvider);
    // The body shrinks when the keyboard opens; size the panel from what's left so its
    // header (and close button) never slides under the top bar.
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
      children: [
        if (state.open)
          Positioned.fill(
            child: GestureDetector(
              key: const Key('assistantBarrier'),
              behavior: HitTestBehavior.opaque,
              onTap: _ctl.close,
            ),
          ),
        PositionedDirectional(
          end: 16,
          bottom: 16,
          child: state.open ? _panel(context, state, constraints.maxHeight - 32) : _launcher(),
        ),
      ],
      ),
    );
  }

  Widget _launcher() {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -8 * Curves.easeInOut.transform(_float.value)),
        child: child,
      ),
      child: GestureDetector(
        key: const Key('assistantLauncher'),
        onTap: _ctl.open,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.forest,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: const RobotFace(size: 40),
        ),
      ),
    );
  }

  Widget _panel(BuildContext context, AssistantState state, double maxHeight) {
    final texts = _ctl.texts;
    final size = MediaQuery.sizeOf(context);
    return LayoutBuilder(
      builder: (context, _) {
        final width = (size.width * 0.9).clamp(0.0, 420.0);
        final height = (size.height * 0.75).clamp(0.0, 600.0).clamp(0.0, maxHeight.clamp(0.0, double.infinity));
        return Container(
          key: const Key('assistantPanel'),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 50,
                offset: Offset(0, 20),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                Column(
                  children: [
                    _header(state, texts),
                    _robotRow(state, texts),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: ListView.separated(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          itemCount: state.messages.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 16),
                          itemBuilder: (_, i) => ChatBubble(
                            message: state.messages[i],
                            texts: texts,
                            onOpenImage: (path) =>
                                setState(() => _fullscreen = path),
                          ),
                        ),
                      ),
                    ),
                    AssistantInputBar(
                      texts: texts,
                      onOpenImage: (path) => setState(() => _fullscreen = path),
                    ),
                  ],
                ),
                if (_fullscreen != null) _fullscreenImage(_fullscreen!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(AssistantState state, Translations texts) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          texts.t('assistant.liveChat'),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: Text(
                      _elapsed,
                      style: TextStyle(
                        color: AppColors.earth.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            key: const Key('assistantLang'),
            borderRadius: BorderRadius.circular(999),
            onTap: _ctl.toggleLanguage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.globe,
                    size: 14,
                    color: AppColors.earth,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    texts.t('assistant.langButton'),
                    style: const TextStyle(
                      color: AppColors.earth,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const Key('assistantClose'),
            tooltip: texts.t('assistant.close'),
            onPressed: _ctl.close,
            icon: const Icon(LucideIcons.x, size: 20, color: AppColors.earth),
          ),
        ],
      ),
    );
  }

  Widget _robotRow(AssistantState state, Translations texts) {
    final recording = state.mode == InputMode.recording;
    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Row(
          children: [
            RobotHero(
              recording: recording,
              onTap: () async {
                final ok = await _ctl.toggleRecording();
                if (!ok && mounted) {
                  showToast(
                    context,
                    texts.t('assistant.micDenied'),
                    type: ToastType.error,
                  );
                }
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                texts.t(
                  recording ? 'assistant.listening' : 'assistant.recordVoice',
                ),
                textDirection: texts.isRtl
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: recording
                      ? AppColors.gold
                      : Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fullscreenImage(String path) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _fullscreen = null),
        child: Container(
          color: Colors.black.withValues(alpha: 0.9),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Center(child: Image.file(File(path), fit: BoxFit.contain)),
              PositionedDirectional(
                top: 8,
                end: 8,
                child: IconButton(
                  onPressed: () => setState(() => _fullscreen = null),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                  ),
                  icon: const Icon(LucideIcons.x, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
