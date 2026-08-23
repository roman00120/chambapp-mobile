import 'dart:async';

import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _asset = 'assets/video/chambapp-splash.mp4';
  static const _fadeDuration = Duration(milliseconds: 260);

  late final VideoPlayerController _videoController;
  final _introFinished = Completer<void>();
  Timer? _fallbackTimer;
  Timer? _transitionTimer;
  bool _videoReady = false;
  bool _fadeOut = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset(_asset)
      ..addListener(_handleVideoProgress);
    _fallbackTimer = Timer(const Duration(seconds: 7), _finishIntro);
    unawaited(_initializeVideo());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(authControllerProvider.notifier)
          .restoreSession(waitFor: _introFinished.future);
    });
  }

  Future<void> _initializeVideo() async {
    try {
      await _videoController.initialize();
      await _videoController.setLooping(false);
      if (!mounted || _introFinished.isCompleted) return;
      setState(() => _videoReady = true);
      await _videoController.play();
    } catch (_) {
      if (mounted) {
        setState(() => _videoReady = false);
      }
      _transitionTimer = Timer(const Duration(milliseconds: 900), _finishIntro);
    }
  }

  void _handleVideoProgress() {
    if (_videoController.value.isCompleted) {
      _finishIntro();
    }
  }

  void _finishIntro() {
    if (_finishing || _introFinished.isCompleted) return;
    _finishing = true;
    _fallbackTimer?.cancel();
    if (mounted) {
      setState(() => _fadeOut = true);
    }
    _transitionTimer = Timer(_fadeDuration, () {
      if (!_introFinished.isCompleted) {
        _introFinished.complete();
      }
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _transitionTimer?.cancel();
    _videoController
      ..removeListener(_handleVideoProgress)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = ref.watch(
      authControllerProvider.select((state) => state.message),
    );
    if (message != null) {
      return Scaffold(
        body: SafeArea(
          child: ErrorState(
            title: 'No pudimos conectarnos',
            message: message,
            onRetry: () =>
                ref.read(authControllerProvider.notifier).restoreSession(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Semantics(
        label: 'Presentación de Chambapp',
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(
              color: Colors.white,
              child: Center(
                child: Image(
                  image: AssetImage('assets/branding/chambapp-logo.png'),
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (_videoReady)
              AnimatedOpacity(
                opacity: _fadeOut ? 0 : 1,
                duration: _fadeDuration,
                curve: Curves.easeOut,
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
