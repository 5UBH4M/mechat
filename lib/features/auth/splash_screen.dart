import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_notifier.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final authState = ref.read(authNotifierProvider);
      if (authState.status != AuthStatus.initial && authState.status != AuthStatus.loading) {
        _routeTo(authState.status);
      }
      // If it's still initial/loading, the listener in build() will handle it once it updates.
    });
  }

  void _routeTo(AuthStatus status) {
    switch (status) {
      case AuthStatus.authenticated:
        context.go('/home');
        break;
      case AuthStatus.profileIncomplete:
        context.go('/create-profile');
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
      case AuthStatus.codeSent:
        context.go('/login');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      } else if (next.status == AuthStatus.profileIncomplete) {
        context.go('/create-profile');
      } else if (next.status == AuthStatus.unauthenticated) {
        context.go('/login');
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'MeChat',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Secure One-to-One Messaging',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 48),
            Text(
              'developed by ~ Subham 🤍',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
