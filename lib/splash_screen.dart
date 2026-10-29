import 'dart:async';

import 'package:flutter/material.dart';
import 'package:visitorsdata/screens/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _gold = Color(0xFFC9A227);
  static const _dark = Color(0xFF2B2004);
  static const _brown = Color.fromARGB(255, 85, 64, 9);
  static const _olive = Color.fromARGB(255, 111, 93, 45);

  late final AnimationController _c;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _ring;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _tagFade;
  late final Animation<double> _progress;
  Timer? _timer;

  Animation<double> _iv(double a, double b, Curve curve) => CurvedAnimation(
        parent: _c,
        curve: Interval(a, b, curve: curve),
      );

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _logoScale = Tween(begin: 0.5, end: 1.0)
        .animate(_iv(0.0, 0.35, Curves.easeOutBack));
    _logoFade = _iv(0.0, 0.25, Curves.easeOut);
    _ring = _iv(0.15, 0.7, Curves.easeOut);
    _titleFade = _iv(0.3, 0.55, Curves.easeOut);
    _titleSlide = Tween(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(_iv(0.3, 0.55, Curves.easeOutCubic));
    _tagFade = _iv(0.5, 0.75, Curves.easeOut);
    _progress = _iv(0.2, 1.0, Curves.easeInOut);

    _c.forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _timer = Timer(const Duration(milliseconds: 400), _goHome);
      }
    });
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  Widget _blob(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _gold.withValues(alpha: opacity),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_dark, _brown, _olive],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // soft decorative circles
            Positioned(top: -80, right: -60, child: _blob(260, 0.07)),
            Positioned(bottom: -100, left: -80, child: _blob(320, 0.06)),
            Positioned(top: 140, left: -40, child: _blob(120, 0.05)),

            // fills the whole screen so the Column can centre its children
            Positioned.fill(
              child: SafeArea(
                child: SizedBox.expand(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(flex: 3),

                          // ---- logo with expanding ring ----
                          SizedBox(
                            width: 190,
                            height: 190,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Opacity(
                                  opacity:
                                      (1 - _ring.value).clamp(0.0, 1.0) * 0.6,
                                  child: Container(
                                    width: 110 + 80 * _ring.value,
                                    height: 110 + 80 * _ring.value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border:
                                          Border.all(color: _gold, width: 2),
                                    ),
                                  ),
                                ),
                                Opacity(
                                  opacity: _logoFade.value,
                                  child: Transform.scale(
                                    scale: _logoScale.value,
                                    child: Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                _gold.withValues(alpha: 0.45),
                                            blurRadius: 40,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                      // Replace with Image.asset(...) for your real logo
                                      child: const Icon(
                                        Icons.apartment_rounded,
                                        size: 58,
                                        color: _brown,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ---- company name ----
                          FadeTransition(
                            opacity: _titleFade,
                            child: SlideTransition(
                              position: _titleSlide,
                              child: const Column(
                                children: [
                                  // left padding = letterSpacing, so the text
                                  // looks exactly centred
                                  Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Text(
                                      'VISITOR',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 38,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 10,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: Text(
                                      ' MANAGEMENT SYSTEM',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _gold,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // ---- divider + tagline ----
                          FadeTransition(
                            opacity: _tagFade,
                            child: Column(
                              children: [
                                Container(
                                  width: 48,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: _gold,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // const Padding(
                                //   padding: EdgeInsets.only(left: 1.5),
                                //   child: Text(
                                //     'Visitor Management System',
                                //     textAlign: TextAlign.center,
                                //     style: TextStyle(
                                //       color: Colors.white70,
                                //       fontSize: 15,
                                //       letterSpacing: 1.5,
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ),

                          const Spacer(flex: 3),

                          // ---- loading bar ----
                          SizedBox(
                            width: 160,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _progress.value,
                                minHeight: 3,
                                backgroundColor: Colors.white12,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(_gold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Opacity(
                            opacity: _tagFade.value,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 2),
                              child: Text(
                                'Secure  •  Smart  •  Seamless',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}