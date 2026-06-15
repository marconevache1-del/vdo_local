import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  
  // Passiamo il nostro walkie-talkie a questa centralina
  final SignalingService signaling;

  // Questa callback serve al Ricevitore: scatterà quando il video arriva dal tubo
  Function(MediaStream stream)? onRemoteStream;

  WebRTCService(this.signaling) {
    // 1. Diciamo al walkie-talkie: "Se ricevi un messaggio, passalo a me"
    signaling.onMessage = (message) {
      _handleMessage(message);
    };
  }

  // 2. Inizializziamo il tubo (Peer Connection)
  Future<void> initConnection() async {
    // Una configurazione vuota degli 'iceServers' forza WebRTC a non usare
    // server cloud (STUN/TURN), ma a cercare solo connessioni sulla rete locale.
    Map<String, dynamic> configuration = {
      'iceServers': []
    };

    _peerConnection = await createPeerConnection(configuration);

    // Quando WebRTC trova una via d'uscita sulla rete (ICE Candidate), la spedisce via walkie-talkie
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      signaling.send({
        'type': 'candidate',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    // Quando dal tubo esce un flusso video (evento 'onTrack')
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty && onRemoteStream != null) {
        onRemoteStream!(event.streams[0]);
      }
    };
  }

  // 3. (Solo per Trasmettitore) Prende la fotocamera e la pompa nel tubo
  Future<void> addLocalStream(MediaStream stream) async {
    stream.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, stream);
    });
  }

  // 4. (Solo per Trasmettitore) Avvia la trattativa creando un'Offerta (SDP)
  Future<void> createOffer() async {
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    
    // Invia la scheda tecnica via walkie-talkie
    signaling.send({
      'type': 'offer',
      'sdp': offer.sdp,
    });
  }

  // 5. (Solo per Ricevitore) Risponde all'Offerta creando un'Answer (SDP)
  Future<void> _createAnswer() async {
    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    
    signaling.send({
      'type': 'answer',
      'sdp': answer.sdp,
    });
  }

  // 6. Il cervello che smista i messaggi in arrivo dal Signaling Service
  Future<void> _handleMessage(Map<String, dynamic> message) async {
    String type = message['type'];

    if (type == 'offer') {
      // Se ricevo un'offerta, la registro e rispondo in automatico
      print(">>> STO PROCESSANDO L'OFFERTA E CREANDO LA RISPOSTA...");
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(message['sdp'], type),
      );
      await _createAnswer(); 
      
    } else if (type == 'answer') {
      // Se ricevo una risposta, la registro
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(message['sdp'], type),
      );
      
    } else if (type == 'candidate') {
      // Se ricevo un percorso di rete, lo aggiungo al navigatore
      await _peerConnection!.addCandidate(
        RTCIceCandidate(
          message['candidate'],
          message['sdpMid'],
          message['sdpMLineIndex'],
        ),
      );
    }
  }

  // Chiude i rubinetti quando si esce dalla schermata
  void dispose() {
    _peerConnection?.close();
  }
}