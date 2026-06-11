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

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  Timer? _autoAcceptTimer;
  int _secondsLeft = 5;

  @override
  void initState() {
    super.initState();
    _checkAutoAccept();
  }

  void _checkAutoAccept() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authNotifierProvider).user;
      if (user?.autoAcceptCalls == true) {
        _startAutoAcceptTimer();
      }
    });
  }

  void _startAutoAcceptTimer() {
    _autoAcceptTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          timer.cancel();
          ref.read(callNotifierProvider.notifier).answerCall();
        }
      });
    });
  }

  @override
  void dispose() {
    _autoAcceptTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final callState = ref.watch(callNotifierProvider);
    final user = ref.watch(authNotifierProvider).user;
    final autoAccept = user?.autoAcceptCalls == true;

    // If call status changes away from ringing, pop this screen
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
      backgroundColor: Colors.black, // Dark overlay for incoming call screen
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Caller Profile Area
              Column(
                children: [
                  const SizedBox(height: 40),
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.person,
                      size: 64,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    callState.remoteUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    callState.isVideo ? 'Incoming Video Call...' : 'Incoming Voice Call...',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (autoAccept)
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Text(
                        'Auto-accepting in $_secondsLeft seconds...',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              
              // Acceptance & Rejection Actions
              if (!autoAccept)
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Reject Button
                    Column(
                      children: [
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(72, 72),
                          ),
                          icon: const Icon(Icons.call_end, color: Colors.white, size: 32),
                          onPressed: () {
                            ref.read(callNotifierProvider.notifier).rejectCall();
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Decline',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        )
                      ],
                    ),
                    
                    // Accept Button
                    Column(
                      children: [
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(72, 72),
                          ),
                          icon: const Icon(Icons.call, color: Colors.white, size: 32),
                          onPressed: () {
                            ref.read(callNotifierProvider.notifier).answerCall();
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Accept',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        )
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
