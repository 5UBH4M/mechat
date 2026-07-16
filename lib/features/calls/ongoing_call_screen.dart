import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/date_formatter.dart';
import '../auth/auth_notifier.dart';

import 'package:simple_pip_mode/simple_pip.dart';
import 'package:simple_pip_mode/pip_widget.dart';
import 'call_notifier.dart';

class OngoingCallScreen extends ConsumerStatefulWidget {
  const OngoingCallScreen({super.key});

  @override
  ConsumerState<OngoingCallScreen> createState() => _OngoingCallScreenState();
}

class _OngoingCallScreenState extends ConsumerState<OngoingCallScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final SimplePip _pip = SimplePip();
  bool _controlsVisible = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pip.setAutoPipMode();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.value = 1.0; // Start visible
  }

  @override
  void dispose() {
    _fadeController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _pip.enterPipMode();
    }
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    if (_controlsVisible) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callNotifierProvider);
    final notifier = ref.read(callNotifierProvider.notifier);
    final user = ref.watch(authNotifierProvider).user;
    final disableMute = user?.disableMute ?? false;
    final disableCameraOff = user?.disableCameraOff ?? false;

    // Automatically navigate home if the call is closed
    ref.listen<CallState>(callNotifierProvider, (previous, next) {
      if (previous?.status != next.status) {
        if (next.status == 'idle' ||
            next.status == 'ended' ||
            next.status == 'rejected') {
          context.go('/home');
        }
      }

      if (previous?.partnerWantsHangup != true &&
          next.partnerWantsHangup == true) {
        _showHangupDialog(notifier);
      }

      if (previous?.partnerHangupRejected != true &&
          next.partnerHangupRejected == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Your partner rejected the call end request.',
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return PipWidget(
      pipChild: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: callState.isVideo
              ? _buildVideoCallStream(callState, notifier)
              : const Icon(Icons.call, color: Colors.green, size: 50),
        ),
      ),
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: GestureDetector(
              onTap: callState.isVideo ? _toggleControls : null,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: callState.isVideo
                    ? const BoxDecoration(color: Colors.black)
                    : const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0A1628),
                            Color(0xFF132A47),
                            Color(0xFF1A3A5C),
                          ],
                        ),
                      ),
                child: SafeArea(
                  child: Stack(
                    children: [
                      // Core content
                      if (callState.isVideo)
                        _buildVideoCallStream(callState, notifier)
                      else
                        _buildVoiceCallView(callState),

                      // Top bar with caller info
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildTopBar(callState),
                      ),

                      // Bottom controls
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildBottomControls(
                          callState,
                          notifier,
                          disableMute,
                          disableCameraOff,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(CallState callState) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            Text(
              callState.remoteUserName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: callState.status == 'connected'
                    ? const Color(0xFF00E676).withOpacity(0.15)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                callState.status == 'connected'
                    ? DateFormatter.formatCallTimer(callState.duration)
                    : callState.status.toUpperCase(),
                style: TextStyle(
                  color: callState.status == 'connected'
                      ? const Color(0xFF00E676)
                      : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: callState.status == 'connected' ? 1.0 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(
    CallState callState,
    CallNotifier notifier,
    bool disableMute,
    bool disableCameraOff,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 30, 16, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute Mic
            if (!disableMute)
              _buildControlButton(
                icon: callState.isMicMuted
                    ? Icons.mic_off_rounded
                    : Icons.mic_rounded,
                label: callState.isMicMuted ? 'Unmute' : 'Mute',
                isActive: callState.isMicMuted,
                onTap: notifier.toggleMute,
              ),

            // Speaker (Voice) or Camera Toggle (Video)
            if (callState.isVideo)
              if (!disableCameraOff)
                _buildControlButton(
                  icon: callState.isCameraEnabled
                      ? Icons.videocam_rounded
                      : Icons.videocam_off_rounded,
                  label: callState.isCameraEnabled ? 'Cam Off' : 'Cam On',
                  isActive: !callState.isCameraEnabled,
                  onTap: notifier.toggleCamera,
                )
              else
                const SizedBox(width: 56)
            else
              _buildControlButton(
                icon: callState.isSpeakerOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_down_rounded,
                label: callState.isSpeakerOn ? 'Speaker' : 'Earpiece',
                isActive: callState.isSpeakerOn,
                onTap: notifier.toggleSpeaker,
              ),

            // Camera Flip (Video only)
            if (callState.isVideo)
              _buildControlButton(
                icon: Icons.flip_camera_ios_rounded,
                label: 'Flip',
                onTap: notifier.switchCamera,
              ),

            // PIP
            _buildControlButton(
              icon: Icons.picture_in_picture_alt_rounded,
              label: 'PIP',
              onTap: () => _pip.enterPipMode(),
            ),

            // End Call
            _buildEndCallButton(notifier, callState),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndCallButton(CallNotifier notifier, CallState callState) {
    return GestureDetector(
      onTap: () {
        notifier.endCall();
        if (callState.status == 'connected') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Requested call end. Waiting for partner...'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B5C),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF3B5C).withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'End',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCallStream(CallState state, CallNotifier notifier) {
    final hasRemote =
        state.status == 'connected' &&
        notifier.remoteRenderer.srcObject != null;
    return Stack(
      children: [
        // Remote stream (full screen)
        if (hasRemote)
          RTCVideoView(
            notifier.remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        else
          Container(
            color: const Color(0xFF0D0D2B),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Connecting...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Local camera preview (PiP corner)
        if (state.isCameraEnabled && notifier.localRenderer.srcObject != null)
          Positioned(
            right: 16,
            top: 100,
            child: GestureDetector(
              child: Container(
                width: 110,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: RTCVideoView(
                    notifier.localRenderer,
                    mirror: true,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVoiceCallView(CallState callState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large avatar with gradient border
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4FC3F7),
                  Color(0xFF2196F3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4FC3F7).withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),
          // Audio waveform indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + index * 50),
                width: 4,
                height: callState.status == 'connected'
                    ? 12.0 + (index % 3) * 8.0
                    : 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC3F7).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            callState.status == 'connected'
                ? 'Call in progress'
                : 'Connecting...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _showHangupDialog(CallNotifier notifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'End Call?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your partner wants to end the call.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.rejectHangupRequest();
            },
            child: const Text(
              'Continue',
              style: TextStyle(color: Color(0xFF4FC3F7)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B5C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.endCall();
            },
            child: const Text('End Call'),
          ),
        ],
      ),
    );
  }
}
