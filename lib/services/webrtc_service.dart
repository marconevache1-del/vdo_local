import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool _hasRemoteDescription = false;
  final List<RTCIceCandidate> _pendingCandidates = [];

  final SignalingService signaling;

  /// Ricevitore: arriva il flusso video.
  Function(MediaStream stream)? onRemoteStream;

  /// Cambia lo stato della connessione peer-to-peer.
  Function(RTCPeerConnectionState state)? onConnectionState;

  WebRTCService(this.signaling) {
    signaling.onMessage = _handleMessage;
  }

  /// Crea la connessione. Rete locale: nessun server STUN/TURN.
  Future<void> initConnection() async {
    await _peerConnection?.close();
    _hasRemoteDescription = false;
    _pendingCandidates.clear();

    final pc = await createPeerConnection({'iceServers': []});
    _peerConnection = pc;

    pc.onConnectionState = (state) {
      debugPrint('Stato connessione P2P: $state');
      onConnectionState?.call(state);
    };

    pc.onIceCandidate = (candidate) {
      signaling.send({
        'type': 'candidate',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) onRemoteStream?.call(event.streams[0]);
    };

    final local = _localStream;
    if (local != null) {
      for (final track in local.getTracks()) {
        await pc.addTrack(track, local);
      }
    }
  }

  /// Trasmettitore: collega la camera alla connessione.
  Future<void> addLocalStream(MediaStream stream) async {
    _localStream = stream;
    for (final track in stream.getTracks()) {
      await _peerConnection?.addTrack(track, stream);
    }
  }

  /// Ricevitore: avvia la trattativa con un'offerta in sola ricezione.
  Future<void> createOffer() async {
    final pc = _peerConnection!;
    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    signaling.send({'type': 'offer', 'sdp': offer.sdp});
  }

  Future<void> _handleMessage(Map<String, dynamic> message) async {
    try {
      switch (message['type']) {
        case 'offer':
          // Un ricevitore che si ricollega: ripartiamo da una connessione pulita.
          if (_hasRemoteDescription) await initConnection();
          await _peerConnection!.setRemoteDescription(
              RTCSessionDescription(message['sdp'], 'offer'));
          await _onRemoteDescriptionSet();
          final answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);
          signaling.send({'type': 'answer', 'sdp': answer.sdp});
        case 'answer':
          await _peerConnection!.setRemoteDescription(
              RTCSessionDescription(message['sdp'], 'answer'));
          await _onRemoteDescriptionSet();
        case 'candidate':
          final candidate = RTCIceCandidate(
              message['candidate'], message['sdpMid'], message['sdpMLineIndex']);
          if (_hasRemoteDescription) {
            await _peerConnection!.addCandidate(candidate);
          } else {
            _pendingCandidates.add(candidate); // arrivato troppo presto
          }
      }
    } catch (e) {
      debugPrint('Errore nella gestione del messaggio: $e');
    }
  }

  Future<void> _onRemoteDescriptionSet() async {
    _hasRemoteDescription = true;
    for (final c in _pendingCandidates) {
      await _peerConnection!.addCandidate(c);
    }
    _pendingCandidates.clear();
  }

  Future<void> dispose() async {
    await _peerConnection?.close();
    _peerConnection = null;
    final local = _localStream;
    if (local != null) {
      for (final t in local.getTracks()) {
        await t.stop();
      }
      await local.dispose();
      _localStream = null;
    }
  }
}
