
import 'package:flutter/material.dart';
import '../../auth/view/auth_wrapper.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.0, 0.7, curve: Curves.easeIn)),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)),
    );

    _animationController.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 1000),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthWrapper(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isNarrow = size.width < 360;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor,
              theme.colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withAlpha(230),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withAlpha(51),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: size.width * 0.35,
                            height: size.width * 0.35,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.school,
                                size: size.width * 0.3,
                                color: theme.primaryColor,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // App Name
                      FittedBox(
                        child: Text(
                          'مدير الطلاب',
                          style: (isNarrow
                                  ? theme.textTheme.displayMedium
                                  : theme.textTheme.displayLarge)
                              ?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: theme.shadowColor.withAlpha(102),
                                blurRadius: 8,
                                offset: const Offset(3, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        child: Text(
                          'إدارة طلابك بذكاء',
                          style: (isNarrow
                                  ? theme.textTheme.titleMedium
                                  : theme.textTheme.titleLarge)
                              ?.copyWith(
                            color: theme.colorScheme.onPrimary.withAlpha(230),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      isNarrow
                          ? Column(
                              children: [
                                _buildStyledImage('assets/images/qr.webp', context, size),
                                const SizedBox(height: 15),
                                _buildStyledImage('assets/images/data-storage-77.png', context, size),
                                const SizedBox(height: 15),
                                _buildStyledImage('assets/images/undraw_personal-goals_f9bb.png', context, size),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStyledImage('assets/images/qr.webp', context, size),
                                const SizedBox(width: 20),
                                _buildStyledImage('assets/images/data-storage-77.png', context, size),
                                const SizedBox(width: 20),
                                _buildStyledImage('assets/images/undraw_personal-goals_f9bb.png', context, size),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledImage(String imageUrl, BuildContext context, Size size) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withAlpha(204),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset(
          imageUrl,
          width: size.width * 0.25,
          height: size.width * 0.25,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size.width * 0.25,
              height: size.width * 0.25,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withAlpha(128),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.broken_image, color: theme.primaryColor),
            );
          },
        ),
      ),
    );
  }
}
