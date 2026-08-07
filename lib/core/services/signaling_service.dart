import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
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

  Function(MediaStream)? onRemoteStream;
  Function(String)? onCallStatusChanged;
  Function()? onPartnerWantsHangup;
  Function()? onPartnerHangupRejected;

  StreamSubscription<DocumentSnapshot>? _callSubscription;
  StreamSubscription<QuerySnapshot>? _candidatesSubscription;
  final List<RTCIceCandidate> _pendingCallerCandidates = [];


  Future<MediaStream> getLocalStream(bool videoEnabled) async {

    await Permission.microphone.request();
    if (videoEnabled) {
      await Permission.camera.request();
    }

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': videoEnabled
          ? {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            }
          : false,
    };

    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    return localStream!;
  }


  Future<String> initCall({
    required String callerId,
    required String callerName,
    required String receiverId,
    required bool isVideo,
  }) async {
    final callDoc = _db.collection(AppConstants.callsCollection).doc();
    final callId = callDoc.id;

    peerConnection = await createPeerConnection(
      await AppConstants.getIceServers(),
    );
    _registerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      _pendingCallerCandidates.add(candidate);
    };

    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    await callDoc.set({
      'id': callId,
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'type': isVideo ? 'video' : 'voice',
      'status': 'dialing',
      'sdpOffer': {'type': offer.type, 'sdp': offer.sdp},
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (final candidate in _pendingCallerCandidates) {
      await callDoc.collection('callerCandidates').add(candidate.toMap());
    }
    _pendingCallerCandidates.clear();

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      callDoc.collection('callerCandidates').add(candidate.toMap());
    };

    _callSubscription = callDoc.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      final currentData = snapshot.data();
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
      final otherWantsHangup = isCaller
          ? currentData['receiverHangup'] == true
          : currentData['callerHangup'] == true;
      if (otherWantsHangup && onPartnerWantsHangup != null) {
        onPartnerWantsHangup!();
      } else if (!otherWantsHangup && currentData['rejectedHangup'] == true) {

        if (onPartnerHangupRejected != null) {
          onPartnerHangupRejected!();
        }

        callDoc.update({'rejectedHangup': FieldValue.delete()});
      }

      if (status == 'connected') {
        final remoteDesc = await peerConnection?.getRemoteDescription();
        if (remoteDesc == null && currentData['sdpAnswer'] != null) {
          final sdpAnswer = RTCSessionDescription(
            currentData['sdpAnswer']['sdp'],
            currentData['sdpAnswer']['type'],
          );
          await peerConnection?.setRemoteDescription(sdpAnswer);


          _candidatesSubscription ??= callDoc
              .collection('receiverCandidates')
              .snapshots()
              .listen((snapshot) {
                for (final change in snapshot.docChanges) {
                  if (change.type == DocumentChangeType.added) {
                    final candidateData =
                        change.doc.data() as Map<String, dynamic>;
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
    });

    return callId;
  }


  Future<void> joinCall(String callId) async {
    final callDoc = _db.collection(AppConstants.callsCollection).doc(callId);
    final snapshot = await callDoc.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final sdpOfferData = data['sdpOffer'];

    peerConnection = await createPeerConnection(
      await AppConstants.getIceServers(),
    );
    _registerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      callDoc.collection('receiverCandidates').add(candidate.toMap());
    };

    final offer = RTCSessionDescription(
      sdpOfferData['sdp'],
      sdpOfferData['type'],
    );
    await peerConnection?.setRemoteDescription(offer);

    final answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    await callDoc.update({
      'status': 'connected',
      'startedAt': FieldValue.serverTimestamp(),
      'sdpAnswer': {'type': answer.type, 'sdp': answer.sdp},
    });


    _callSubscription = callDoc.snapshots().listen((snap) {
      if (!snap.exists) return;
      final snapData = snap.data();
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
        final otherWantsHangup = isCaller
            ? snapData['receiverHangup'] == true
            : snapData['callerHangup'] == true;
        if (otherWantsHangup && onPartnerWantsHangup != null) {
          onPartnerWantsHangup!();
        } else if (!otherWantsHangup && snapData['rejectedHangup'] == true) {
          if (onPartnerHangupRejected != null) {
            onPartnerHangupRejected!();
          }
          callDoc.update({'rejectedHangup': FieldValue.delete()});
        }
      }
    });

    _candidatesSubscription = callDoc
        .collection('callerCandidates')
        .snapshots()
        .listen((snap) {
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


  void _registerConnectionListeners() {
    peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        if (onRemoteStream != null) {
          onRemoteStream!(remoteStream!);
        }
      }
    };

    peerConnection?.onIceConnectionState = (RTCIceConnectionState iceState) {
      if (iceState == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          iceState == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        cleanUpCall();
      }
    };
  }


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
        await docRef.update({
          'status': isRejected ? 'rejected' : 'ended',
          'endedAt': FieldValue.serverTimestamp(),
        });
        cleanUpCall();
        return;
      }


      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final callerId = data['callerId'];

      final isCaller = myUid == callerId;
      final otherWantsHangup = isCaller
          ? data['receiverHangup'] == true
          : data['callerHangup'] == true;

      if (otherWantsHangup) {

        await docRef.update({
          'status': 'ended',
          'endedAt': FieldValue.serverTimestamp(),
        });
        cleanUpCall();
      } else {

        if (isCaller) {
          await docRef.update({'callerHangup': true});
        } else {
          await docRef.update({'receiverHangup': true});
        }


      }
    } catch (e) {
      if (kDebugMode) {
        dev.log("Error ending call: $e");
      }
      cleanUpCall();
    }
  }


  Future<void> rejectHangup(String callId) async {
    try {
      final docRef = _db.collection(AppConstants.callsCollection).doc(callId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final isCaller = myUid == data['callerId'];


      if (isCaller) {
        await docRef.update({'receiverHangup': false, 'rejectedHangup': true});
      } else {
        await docRef.update({'callerHangup': false, 'rejectedHangup': true});
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log("Error rejecting hangup: $e");
      }
    }
  }


  void cleanUpCall() {
    _callSubscription?.cancel();
    _callSubscription = null;
    _candidatesSubscription?.cancel();
    _candidatesSubscription = null;
    _pendingCallerCandidates.clear();

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


  }
}
