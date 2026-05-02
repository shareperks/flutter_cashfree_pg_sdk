import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shareperks/constants/assets.dart';

class EmailSuccessStatusScreen extends StatefulWidget {
  const EmailSuccessStatusScreen({super.key});

  @override
  State<EmailSuccessStatusScreen> createState() =>
      _EmailSuccessStatusScreenState();
}

class _EmailSuccessStatusScreenState extends State<EmailSuccessStatusScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lottieController = AnimationController(
    vsync: this,
  );

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  void _onAnimationComplete() {
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          Assets.ASSETS_LOTTIE_EMAILTAILWIND_JSON,
          width: 210,
          controller: _lottieController,
          repeat: false,
          onLoaded: (composition) {
            _lottieController
              ..duration = composition.duration
              ..forward().whenComplete(_onAnimationComplete);
          },
        ),
      ),
    );
  }
}
