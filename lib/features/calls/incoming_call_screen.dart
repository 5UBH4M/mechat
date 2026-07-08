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
  @override
  void initState() {
    super.initState();
    _checkAutoAccept();
  }

  void _checkAutoAccept() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authNotifierProvider).user;
      if (user?.autoAcceptCalls == true) {
        // Immediately answer the call
        ref.read(callNotifierProvider.notifier).answerCall();
      }
    });
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
      backgroundColor: theme
          .scaffoldBackgroundColor, // Use theme background instead of black
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
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    callState.remoteUserName,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    callState.isVideo
                        ? 'Incoming Video Call...'
                        : 'Incoming Voice Call...',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (autoAccept)
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Text(
                        'Auto-accepting call...',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
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
                          icon: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () {
                            ref
                                .read(callNotifierProvider.notifier)
                                .rejectCall();
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Decline',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 14,
                          ),
                        ),
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
                          icon: Icon(
                            callState.isVideo ? Icons.videocam : Icons.call,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () {
                            ref
                                .read(callNotifierProvider.notifier)
                                .answerCall();
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Accept',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              if (autoAccept)
                const SizedBox(
                  height: 100,
                ), // Placeholder to keep spacing when buttons are hidden
            ],
          ),
        ),
      ),
    );
  }
}
