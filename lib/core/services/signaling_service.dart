import 'dart:async';
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';

class SignalingService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  
  // Call status, remote stream, etc.
  // Call status, remote stream, etc.
  Function(MediaStream)? onRemoteStream;
  Function(String)? onCallStatusChanged;
  Function()? onPartnerWantsHangup;

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
      final currentData = snapshot.data() as Map<String, dynamic>?;
      if (currentData == null) return;
      final status = currentData['status'] as String?;

      if (onCallStatusChanged != null && status != null) {
        onCallStatusChanged!(status);
      }

      if (status == 'ended' || status == 'rejected') {
        cleanUpCall();
        return;
      }
      
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final isCaller = myUid == currentData['callerId'];
      final otherWantsHangup = isCaller ? currentData['receiverHangup'] == true : currentData['callerHangup'] == true;
      if (otherWantsHangup && onPartnerWantsHangup != null) {
        onPartnerWantsHangup!();
      }

      if (status == 'connected') {
        final remoteDesc = await peerConnection?.getRemoteDescription();
        if (remoteDesc == null && currentData['sdpAnswer'] != null) {
          final sdpAnswer = RTCSessionDescription(
            currentData['sdpAnswer']['sdp'],
            currentData['sdpAnswer']['type'],
          );
          await peerConnection?.setRemoteDescription(sdpAnswer);
          
          // Now it's safe to listen for Receiver ICE Candidates
          if (_candidatesSubscription == null) {
            _candidatesSubscription = callDoc.collection('receiverCandidates').snapshots().listen((snapshot) {
              for (final change in snapshot.docChanges) {
                if (change.type == DocumentChangeType.added) {
                  final candidateData = change.doc.data() as Map<String, dynamic>;
                  peerConnection?.addCandidate(
                    RTCIceCandidate(
                      candidateData['candidate'],
                      candidateData['sdpMid'],
                      candidateData['sdpMLineIndex'],
                    ),
                  );
                }
              }
            });
          }
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
      final snapData = snap.data() as Map<String, dynamic>?;
      if (snapData == null) return;

      final status = snapData['status'] as String?;
      if (onCallStatusChanged != null && status != null) {
        onCallStatusChanged!(status);
      }
      if (status == 'ended' || status == 'rejected') {
        cleanUpCall();
      } else {
        final myUid = FirebaseAuth.instance.currentUser?.uid;
        final isCaller = myUid == snapData['callerId'];
        final otherWantsHangup = isCaller ? snapData['receiverHangup'] == true : snapData['callerHangup'] == true;
        if (otherWantsHangup && onPartnerWantsHangup != null) {
          onPartnerWantsHangup!();
        }
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
      final docRef = _db.collection(AppConstants.callsCollection).doc(callId);
      final doc = await docRef.get();
      if (!doc.exists) {
        cleanUpCall();
        return;
      }
      
      final data = doc.data()!;
      if (isRejected || data['status'] != 'connected') {
         await docRef.update({'status': isRejected ? 'rejected' : 'ended'});
         cleanUpCall();
         return;
      }

      // Check mutual disconnect
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final callerId = data['callerId'];
      
      final isCaller = myUid == callerId;
      final otherWantsHangup = isCaller ? data['receiverHangup'] == true : data['callerHangup'] == true;
      
      if (otherWantsHangup) {
         // Both agreed
         await docRef.update({'status': 'ended'});
         cleanUpCall();
      } else {
         // I am the first to request hangup
         if (isCaller) {
             await docRef.update({'callerHangup': true});
         } else {
             await docRef.update({'receiverHangup': true});
         }
         // Do not cleanUpCall yet, wait for other user.
         // We can update local state to show "Waiting for other to end..." if we want,
         // but for now, we just stay in the call.
      }
    } catch (e) {
      dev.log("Error ending call: $e");
      cleanUpCall(); // Fallback
    }
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
