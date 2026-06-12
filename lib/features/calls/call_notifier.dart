import 'dart:async';
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/constants/app_constants.dart';

import '../../core/services/service_providers.dart';
import '../auth/auth_notifier.dart';

class CallState {
  final String? callId;
  final String status; // 'idle', 'dialing', 'ringing', 'connected', 'ended', 'rejected', 'missed'
  final bool isVideo;
  final bool isMicMuted;
  final bool isCameraEnabled;
  final bool isSpeakerOn;
  final int duration; // In seconds
  final String remoteUserName;
  final String remoteUserAvatar;
  final String callerId;
  final String receiverId;
  final bool partnerWantsHangup;

  const CallState({
    this.callId,
    required this.status,
    required this.isVideo,
    required this.isMicMuted,
    required this.isCameraEnabled,
    required this.isSpeakerOn,
    required this.duration,
    required this.remoteUserName,
    required this.remoteUserAvatar,
    required this.callerId,
    required this.receiverId,
    required this.partnerWantsHangup,
  });

  factory CallState.idle() => const CallState(
        status: 'idle',
        isVideo: false,
        isMicMuted: false,
        isCameraEnabled: true,
        isSpeakerOn: false,
        duration: 0,
        remoteUserName: '',
        remoteUserAvatar: '',
        callerId: '',
        receiverId: '',
        partnerWantsHangup: false,
      );

  CallState copyWith({
    String? callId,
    String? status,
    bool? isVideo,
    bool? isMicMuted,
    bool? isCameraEnabled,
    bool? isSpeakerOn,
    int? duration,
    String? remoteUserName,
    String? remoteUserAvatar,
    String? callerId,
    String? receiverId,
    bool? partnerWantsHangup,
  }) {
    return CallState(
      callId: callId ?? this.callId,
      status: status ?? this.status,
      isVideo: isVideo ?? this.isVideo,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      duration: duration ?? this.duration,
      remoteUserName: remoteUserName ?? this.remoteUserName,
      remoteUserAvatar: remoteUserAvatar ?? this.remoteUserAvatar,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      partnerWantsHangup: partnerWantsHangup ?? this.partnerWantsHangup,
    );
  }
}

class CallNotifier extends StateNotifier<CallState> {
  final Ref _ref;
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  StreamSubscription? _incomingCallSub;
  Timer? _callTimer;

  CallNotifier(this._ref) : super(CallState.idle()) {
    _initRenderers();
    _listenForIncomingCalls();
  }

  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  // Monitor incoming call documents
  void _listenForIncomingCalls() {
    _ref.listen(authNotifierProvider, (previous, next) {
      final user = next.user;
      if (user == null) {
        _incomingCallSub?.cancel();
        return;
      }

      _incomingCallSub?.cancel();
      _incomingCallSub = FirebaseFirestore.instance
          .collection(AppConstants.callsCollection)
          .where('receiverId', isEqualTo: user.uid)
          .where('status', whereIn: ['dialing', 'ringing'])
          .snapshots()
          .listen((snapshot) {
            if (snapshot.docs.isNotEmpty && state.status == 'idle') {
              final doc = snapshot.docs.first;
              final data = doc.data();
              
              // Set the ringing status locally
              state = CallState(
                callId: doc.id,
                status: 'ringing',
                isVideo: data['type'] == 'video',
                isMicMuted: false,
                isCameraEnabled: true,
                isSpeakerOn: data['type'] == 'video',
                duration: 0,
                remoteUserName: data['callerName'] ?? 'Unknown Caller',
                remoteUserAvatar: '', // Resolve from user details later
                callerId: data['callerId'],
                receiverId: data['receiverId'],
                partnerWantsHangup: false,
              );

              // Setup local/remote signaling callbacks
              _setupSignalingCallbacks();

              // Show notification if app is in background
              final lifecycleState = WidgetsBinding.instance.lifecycleState;
              if (lifecycleState != AppLifecycleState.resumed) {
                _ref.read(notificationServiceProvider).showCustomNotification(
                  id: doc.id.hashCode,
                  title: 'Incoming Call',
                  body: '${data['callerName'] ?? 'Someone'} is calling you',
                );
              }
            }
          });
    }, fireImmediately: true);
  }

  void _setupSignalingCallbacks() {
    final signaling = _ref.read(signalingServiceProvider);
    
    signaling.onCallStatusChanged = (status) {
      state = state.copyWith(status: status);
      
      if (status == 'connected') {
        _startTimer();
      }

      if (status == 'ended' || status == 'rejected' || status == 'idle') {
        _stopTimer();
        state = CallState.idle();
      }
    };

    signaling.onRemoteStream = (stream) {
      remoteRenderer.srcObject = stream;
    };

    signaling.onPartnerWantsHangup = () {
      state = state.copyWith(partnerWantsHangup: true);
    };
  }

  // Start outgoing call
  Future<void> makeCall({
    required String receiverId,
    required String receiverName,
    required bool isVideo,
  }) async {
    final sender = _ref.read(authNotifierProvider).user;
    if (sender == null) return;

    state = CallState(
      status: 'dialing',
      isVideo: isVideo,
      isMicMuted: false,
      isCameraEnabled: true,
      isSpeakerOn: isVideo,
      duration: 0,
      remoteUserName: receiverName,
      remoteUserAvatar: '',
      callerId: sender.uid,
      receiverId: receiverId,
      partnerWantsHangup: false,
    );

    _setupSignalingCallbacks();

    final signaling = _ref.read(signalingServiceProvider);
    
    try {
      // Setup local audio/video stream
      final stream = await signaling.getLocalStream(isVideo);
      localRenderer.srcObject = stream;

      // Initialize Firestore WebRTC call
      final callId = await signaling.initCall(
        callerId: sender.uid,
        callerName: sender.displayName,
        receiverId: receiverId,
        isVideo: isVideo,
      );

      state = state.copyWith(callId: callId);
    } catch (e) {
      dev.log("Error launching call: $e");
      signaling.cleanUpCall();
      state = CallState.idle();
    }
  }

  // Answer call
  Future<void> answerCall() async {
    final callId = state.callId;
    if (callId == null) return;

    final signaling = _ref.read(signalingServiceProvider);

    try {
      final stream = await signaling.getLocalStream(state.isVideo);
      localRenderer.srcObject = stream;
      
      await signaling.joinCall(callId);
    } catch (e) {
      dev.log("Error accepting call: $e");
      signaling.cleanUpCall();
      state = CallState.idle();
    }
  }

  // Reject call
  Future<void> rejectCall() async {
    final callId = state.callId;
    if (callId == null) return;
    
    final signaling = _ref.read(signalingServiceProvider);
    await signaling.endCall(callId, isRejected: true);
  }

  // End active call
  Future<void> endCall() async {
    final callId = state.callId;
    if (callId == null) {
      state = CallState.idle();
      return;
    }
    
    final signaling = _ref.read(signalingServiceProvider);
    await signaling.endCall(callId);
  }

  // Actions
  void toggleMute() {
    final newValue = !state.isMicMuted;
    _ref.read(signalingServiceProvider).setMicrophoneMute(newValue);
    state = state.copyWith(isMicMuted: newValue);
  }

  void toggleCamera() {
    final newValue = !state.isCameraEnabled;
    _ref.read(signalingServiceProvider).setCameraEnabled(newValue);
    state = state.copyWith(isCameraEnabled: newValue);
  }

  void switchCamera() {
    _ref.read(signalingServiceProvider).switchCamera();
  }

  void toggleSpeaker() {
    final newValue = !state.isSpeakerOn;
    _ref.read(signalingServiceProvider).setSpeakerphoneOn(newValue);
    state = state.copyWith(isSpeakerOn: newValue);
  }

  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(duration: state.duration + 1);
    });
  }

  void _stopTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    _stopTimer();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }
}

final callNotifierProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  return CallNotifier(ref);
});
