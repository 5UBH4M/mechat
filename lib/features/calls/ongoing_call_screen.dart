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

class _OngoingCallScreenState extends ConsumerState<OngoingCallScreen> with WidgetsBindingObserver {
  final SimplePip _pip = SimplePip();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // For Android 12+ auto enter
    _pip.setAutoPipMode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      _pip.enterPipMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final callState = ref.watch(callNotifierProvider);
    final notifier = ref.watch(callNotifierProvider.notifier);
    final user = ref.watch(authNotifierProvider).user;
    final disableMute = user?.disableMute ?? false;
    final disableCameraOff = user?.disableCameraOff ?? false;

    // Automatically navigate home if the call is closed
    ref.listen<CallState>(callNotifierProvider, (previous, next) {
      if (previous?.status != next.status) {
        if (next.status == 'idle' || next.status == 'ended' || next.status == 'rejected') {
          context.go('/home');
        }
      }
      
      if (previous?.partnerWantsHangup != true && next.partnerWantsHangup == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Call Disconnect'),
            content: const Text('Your partner wants to end the call. Accept or reject?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  notifier.rejectHangupRequest();
                },
                child: const Text('Reject', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  notifier.endCall();
                },
                child: const Text('Accept', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
        );
      }

      if (previous?.partnerHangupRejected != true && next.partnerHangupRejected == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your partner rejected the call end request. You can retry later.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    return PipWidget(
      pipChild: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: ref.watch(callNotifierProvider).isVideo 
            ? _buildVideoCallStream(ref.watch(callNotifierProvider), ref.watch(callNotifierProvider.notifier))
            : Icon(Icons.call, color: Colors.green, size: 50),
        ),
      ),
      child: Builder(
        builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                // 1. Core Background View (Video Streams or Voice Pulsing Wave)
                if (callState.isVideo)
                  _buildVideoCallStream(callState, notifier)
                else
                  _buildVoiceCallStream(callState, theme),


                  // 2. Call Info Overlay Header (Name, Call Status, Timer)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Text(
                    callState.remoteUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    callState.status == 'connected'
                        ? DateFormatter.formatCallTimer(callState.duration)
                        : callState.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Floating Bottom Toolbar
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Mic Toggle
                    if (!disableMute)
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: callState.isMicMuted ? Colors.white : Colors.white24,
                          foregroundColor: callState.isMicMuted ? Colors.black : Colors.white,
                          minimumSize: const Size(56, 56),
                        ),
                        icon: Icon(callState.isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded),
                        onPressed: notifier.toggleMute,
                      ),
                    
                    // Speaker Mode Toggle (Voice Call) or Camera Toggle (Video Call)
                    if (callState.isVideo)
                      if (!disableCameraOff)
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: callState.isCameraEnabled ? Colors.white24 : Colors.white,
                            foregroundColor: callState.isCameraEnabled ? Colors.white : Colors.black,
                            minimumSize: const Size(56, 56),
                          ),
                          icon: Icon(callState.isCameraEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded),
                          onPressed: notifier.toggleCamera,
                        )
                      else
                        const SizedBox()
                    else
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: callState.isSpeakerOn ? Colors.white : Colors.white24,
                          foregroundColor: callState.isSpeakerOn ? Colors.black : Colors.white,
                          minimumSize: const Size(56, 56),
                        ),
                        icon: Icon(callState.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded),
                        onPressed: notifier.toggleSpeaker,
                      ),
                    
                    // Camera Flip (Video Call only)
                    if (callState.isVideo)
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(56, 56),
                        ),
                        icon: const Icon(Icons.flip_camera_ios_rounded),
                        onPressed: notifier.switchCamera,
                      ),
                      
                    // PIP Button
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(56, 56),
                      ),
                      icon: const Icon(Icons.picture_in_picture_alt_rounded),
                      onPressed: () {
                        _pip.enterPipMode();
                      },
                    ),

                    // End / Hangup Button
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(64, 64),
                      ),
                      icon: const Icon(Icons.call_end_rounded),
                      onPressed: () {
                        notifier.endCall();
                        if (callState.status == 'connected') {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Requested call end. Waiting for partner...')));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildVideoCallStream(CallState state, CallNotifier notifier) {
    final hasRemote = state.status == 'connected' && notifier.remoteRenderer.srcObject != null;
    return Stack(
      children: [
        // Background View: Remote Stream
        if (hasRemote)
          RTCVideoView(
            notifier.remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        else
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Waiting for remote stream...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        
        // Picture in Picture View: Local Camera Preview
        if (state.isCameraEnabled && notifier.localRenderer.srcObject != null)
          Positioned(
            right: 20,
            top: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 110,
                height: 150,
                color: Colors.black87,
                child: RTCVideoView(
                  notifier.localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVoiceCallStream(CallState state, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 64,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: const Icon(
              Icons.person,
              size: 72,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 48),
          const Text(
            'Ongoing voice call...',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
