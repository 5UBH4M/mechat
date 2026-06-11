import 'dart:async';
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';

class SignalingService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  
  // Call status, remote stream, etc.
  Function(MediaStream)? onRemoteStream;
  Function(String)? onCallStatusChanged;

  StreamSubscription<DocumentSnapshot>? _callSubscription;
  StreamSubscription<QuerySnapshot>? _candidatesSubscription;

  // 1. Capture local media stream
  Future<MediaStream> getLocalStream(bool videoEnabled) async {
    // Explicitly request permissions before accessing media devices
    await Permission.microphone.request();
    if (videoEnabled) {
      await Permission.camera.request();
    }

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': videoEnabled ? {
        'mandatory': {
          'minWidth': '640', 
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      } : false
    };

    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    return localStream!;
  }

  // 2. Initialize a call (Caller Side)
  Future<String> initCall({
    required String callerId,
    required String callerName,
    required String receiverId,
    required bool isVideo,
  }) async {
    final callDoc = _db.collection(AppConstants.callsCollection).doc();
    final callId = callDoc.id;

    // Create RTCPeerConnection
    peerConnection = await createPeerConnection(AppConstants.iceServers);
    _registerConnectionListeners();

    // Add local tracks
    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Handle ICE Candidates
    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      callDoc.collection('callerCandidates').add(candidate.toMap());
    };

    // Create SDP Offer
    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    // Save Call Details
    await callDoc.set({
      'id': callId,
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'type': isVideo ? 'video' : 'voice',
      'status': 'dialing',
      'sdpOffer': {
        'type': offer.type,
        'sdp': offer.sdp,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Listen for Answer
    _callSubscription = callDoc.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      final status = data['status'] as String;

      if (onCallStatusChanged != null) {
        onCallStatusChanged!(status);
      }

      if (status == 'ended' || status == 'rejected') {
        cleanUpCall();
        return;
      }

      if (status == 'connected' && peerConnection?.getRemoteDescription() == null) {
        if (data['sdpAnswer'] != null) {
          final sdpAnswer = RTCSessionDescription(
            data['sdpAnswer']['sdp'],
            data['sdpAnswer']['type'],
          );
          await peerConnection?.setRemoteDescription(sdpAnswer);
        }
      }
    });

    // Listen for Receiver ICE Candidates
    _candidatesSubscription = callDoc.collection('receiverCandidates').snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          peerConnection?.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });

    return callId;
  }

  // 3. Join an existing call (Receiver Side)
  Future<void> joinCall(String callId) async {
    final callDoc = _db.collection(AppConstants.callsCollection).doc(callId);
    final snapshot = await callDoc.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final sdpOfferData = data['sdpOffer'];

    peerConnection = await createPeerConnection(AppConstants.iceServers);
    _registerConnectionListeners();

    // Add local tracks
    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Handle ICE Candidates
    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      callDoc.collection('receiverCandidates').add(candidate.toMap());
    };

    // Set Remote Description (Offer)
    final offer = RTCSessionDescription(sdpOfferData['sdp'], sdpOfferData['type']);
    await peerConnection?.setRemoteDescription(offer);

    // Create SDP Answer
    final answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    // Update Call Status
    await callDoc.update({
      'status': 'connected',
      'sdpAnswer': {
        'type': answer.type,
        'sdp': answer.sdp,
      }
    });

    // Listen to changes (e.g. ended by caller)
    _callSubscription = callDoc.snapshots().listen((snap) {
      if (!snap.exists) return;
      final status = snap.data()?['status'] as String?;
      if (onCallStatusChanged != null && status != null) {
        onCallStatusChanged!(status);
      }
      if (status == 'ended' || status == 'rejected') {
        cleanUpCall();
      }
    });

    // Listen for Caller ICE Candidates
    _candidatesSubscription = callDoc.collection('callerCandidates').snapshots().listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final dat = change.doc.data() as Map<String, dynamic>;
          peerConnection?.addCandidate(
            RTCIceCandidate(
              dat['candidate'],
              dat['sdpMid'],
              dat['sdpMLineIndex'],
            ),
          );
        }
      }
    });
  }

  // Register Connection Listeners
  void _registerConnectionListeners() {
    peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        if (onRemoteStream != null) {
          onRemoteStream!(remoteStream!);
        }
      }
    };
  }

  // End Call
  Future<void> endCall(String callId, {bool isRejected = false}) async {
    try {
      final status = isRejected ? 'rejected' : 'ended';
      await _db.collection(AppConstants.callsCollection).doc(callId).update({
        'status': status,
      });
    } catch (e) {
      dev.log("Error ending call: $e");
    }
    cleanUpCall();
  }

  // Clean up WebRTC peer connections and media streams
  void cleanUpCall() {
    _callSubscription?.cancel();
    _candidatesSubscription?.cancel();
    
    localStream?.getTracks().forEach((track) => track.stop());
    localStream?.dispose();
    localStream = null;

    remoteStream?.getTracks().forEach((track) => track.stop());
    remoteStream?.dispose();
    remoteStream = null;

    peerConnection?.close();
    peerConnection?.dispose();
    peerConnection = null;

    if (onCallStatusChanged != null) {
      onCallStatusChanged!('idle');
    }
  }

  // Controls
  void setMicrophoneMute(bool mute) {
    localStream?.getAudioTracks().forEach((track) {
      track.enabled = !mute;
    });
  }

  void setCameraEnabled(bool enabled) {
    localStream?.getVideoTracks().forEach((track) {
      track.enabled = enabled;
    });
  }

  void switchCamera() {
    localStream?.getVideoTracks().forEach((track) {
      Helper.switchCamera(track);
    });
  }

  void setSpeakerphoneOn(bool on) {
    // Note: platform specific adjustments if using specialized WebRTC helpers,
    // e.g. Helper.selectAudioOutput or simple speaker activation.
  }
}
