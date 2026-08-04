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
    // Configurazione 100% offline per rete locale (nessun server esterno)
    Map<String, dynamic> configuration = {
      'iceServers': []
    };

    _peerConnection = await createPeerConnection(configuration);

    // Sensore di stato della connessione P2P
    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      print(">>> STATO CONNESSIONE P2P: $state");
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      print(">>> 🚀 STO INVIANDO UN MIO PERCORSO DI RETE (ICE)!"); // <-- AGGIUNGI QUESTO
      signaling.send({
        'type': 'candidate',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    // Quando dal tubo esce finalmente il flusso video
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      print(">>> 🎬 TRACCIA VIDEO RICEVUTA DAL TUBO!");
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

  // 4. (Solo per Ricevitore) Avvia la trattativa creando un'Offerta (SDP)
  Future<void> createOffer() async {
    try {
      // 1. STANDARD MODERNO: Aggiungiamo un ricetrasmettitore in sola ricezione (RecvOnly)
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      // 2. Creiamo l'offerta senza i vecchi vincoli
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      
      // 3. Registriamo l'offerta localmente (QUESTO E' IL COMANDO CHE AVVIA LA RICERCA DEI PERCORSI ICE)
      await _peerConnection!.setLocalDescription(offer);
      
      // 4. Inviamo l'offerta via walkie-talkie
      signaling.send({
        'type': 'offer',
        'sdp': offer.sdp,
      });
      print(">>> OFFERTA CREATA E INVIATA CON SUCCESSO");

    } catch (e) {
      // Se qualcosa si rompe qui, ora lo vedremo chiaramente!
      print(">>> ❌ ERRORE CRITICO DURANTE LA CREAZIONE DELL'OFFERTA: $e");
    }
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
      print(">>> BOOM! RISPOSTA RICEVUTA DAL TELEFONO!"); // <-- Aggiungi questo
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(message['sdp'], type),
      );
      
    } else if (type == 'candidate') {
      // Se ricevo un percorso di rete, lo aggiungo al navigatore
      print(">>> 📍 RICEVUTO PERCORSO DI RETE DALL'ALTRO TELEFONO!"); // <-- AGGIUNGI QUESTO
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