import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import 'call_notifier.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen>
    with TickerProviderStateMixin {
  Timer? _autoAcceptTimer;
  int _autoAcceptCountdown = 5;

  // Ripple animation
  late AnimationController _rippleController;
  // Pulse animation for the avatar
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  // Slide-up animation for buttons
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Ripple rings expanding outward
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Avatar pulsing gently
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Slide-up entrance for buttons
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _slideController.forward();

    _checkAutoAccept();
  }

  void _checkAutoAccept() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authNotifierProvider).user;
      if (user?.autoAcceptCalls == true) {
        _startAutoAcceptCountdown();
      }
    });
  }

  void _startAutoAcceptCountdown() {
    _autoAcceptTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _autoAcceptCountdown--;
      });
      if (_autoAcceptCountdown <= 0) {
        timer.cancel();
        ref.read(callNotifierProvider.notifier).answerCall();
      }
    });
  }

  @override
  void dispose() {
    _autoAcceptTimer?.cancel();
    _rippleController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callNotifierProvider);
    final user = ref.watch(authNotifierProvider).user;
    final autoAccept = user?.autoAcceptCalls == true;
    final screenSize = MediaQuery.of(context).size;

    // Navigate based on call status changes
    ref.listen<CallState>(callNotifierProvider, (previous, next) {
      if (previous?.status != next.status) {
        if (next.status == 'idle') {
          context.go('/home');
        } else if (next.status == 'connected') {
          context.pushReplacement('/ongoing-call');
        }
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: callState.isVideo
                ? [
                    const Color(0xFF0D0D2B),
                    const Color(0xFF1A1A3E),
                    const Color(0xFF2D1B69),
                  ]
                : [
                    const Color(0xFF0A1628),
                    const Color(0xFF132A47),
                    const Color(0xFF1A3A5C),
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated ripple rings behind avatar
              Center(
                child: AnimatedBuilder(
                  animation: _rippleController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(screenSize.width, screenSize.width),
                      painter: _RipplePainter(
                        progress: _rippleController.value,
                        color: callState.isVideo
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFF4FC3F7),
                      ),
                    );
                  },
                ),
              ),

              // Main content
              Column(
                children: [
                  const Spacer(flex: 2),

                  // Call type label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          callState.isVideo
                              ? Icons.videocam_rounded
                              : Icons.call_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          callState.isVideo
                              ? 'VIDEO CALL'
                              : 'VOICE CALL',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Pulsing avatar
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: callState.isVideo
                              ? [
                                  const Color(0xFF6C63FF),
                                  const Color(0xFF9C27B0),
                                ]
                              : [
                                  const Color(0xFF4FC3F7),
                                  const Color(0xFF2196F3),
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (callState.isVideo
                                    ? const Color(0xFF6C63FF)
                                    : const Color(0xFF4FC3F7))
                                .withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Caller name
                  Text(
                    callState.remoteUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Status text
                  Text(
                    callState.isVideo
                        ? 'Incoming Video Call...'
                        : 'Incoming Voice Call...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  // Auto-accept countdown
                  if (autoAccept) ...[
                    const SizedBox(height: 24),
                    _buildAutoAcceptCountdown(),
                  ],

                  const Spacer(flex: 3),

                  // Action buttons with slide-up animation
                  if (!autoAccept)
                    SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: Icons.call_end_rounded,
                              label: 'Decline',
                              color: const Color(0xFFFF3B5C),
                              shadowColor:
                                  const Color(0xFFFF3B5C).withOpacity(0.4),
                              onTap: () => ref
                                  .read(callNotifierProvider.notifier)
                                  .rejectCall(),
                            ),
                            _buildActionButton(
                              icon: callState.isVideo
                                  ? Icons.videocam_rounded
                                  : Icons.call_rounded,
                              label: 'Accept',
                              color: const Color(0xFF00E676),
                              shadowColor:
                                  const Color(0xFF00E676).withOpacity(0.4),
                              onTap: () => ref
                                  .read(callNotifierProvider.notifier)
                                  .answerCall(),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 60),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoAcceptCountdown() {
    return Column(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: _autoAcceptCountdown / 5,
                  strokeWidth: 3,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00E676),
                  ),
                ),
              ),
              Text(
                '$_autoAcceptCountdown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Auto-accepting...',
          style: TextStyle(
            color: const Color(0xFF00E676).withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Draws expanding concentric ripple rings
class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.45;

    for (int i = 0; i < 3; i++) {
      final rippleProgress = (progress + i * 0.33) % 1.0;
      final radius = maxRadius * rippleProgress;
      final opacity = (1.0 - rippleProgress).clamp(0.0, 0.25);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
