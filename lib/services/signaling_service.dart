import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SignalingService {
  HttpServer? _server;
  WebSocketChannel? _socket;
  
  // Questa è una "callback". Quando arriva un messaggio via radio, 
  // lo passiamo a chi sta usando questo servizio (es. il WebRTC Service)
  Function(dynamic message)? onMessage;

  // --- 1. MODALITÀ TRASMETTITORE ---
  // Avvia il server e restituisce l'URI da mettere nel QR Code
  Future<String?> startLocalServer() async {
    String? localIp = await _getLocalIp();
    if (localIp == null) return null; // Nessuna connessione WiFi trovata

    // Creiamo il ricevitore del walkie-talkie
    var handler = webSocketHandler((webSocket, protocol) {
      _socket = webSocket;
      
      // Rimaniamo in ascolto di eventuali messaggi in entrata
      _socket!.stream.listen((message) {
        if (onMessage != null) {
          onMessage!(jsonDecode(message));
        }
      });
    });

    // InternetAddress.anyIPv4 forza il server ad ascoltare su TUTTE le interfacce,
    // garantendo che riceva i messaggi anche se cambia l'IP dell'hotspot.
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
    
    // Restituiamo la stringa finale (es. ws://192.168.1.10:8080)
    return 'ws://$localIp:8080'; 
  }

  // --- 2. MODALITÀ RICEVITORE ---
  // Si connette al server usando l'URI letto dallo scanner
  void connectTo(String uri) {
    try {
      _socket = WebSocketChannel.connect(Uri.parse(uri));
      _socket!.stream.listen(
        (message) {
          if (onMessage != null) onMessage!(jsonDecode(message));
        },
        onError: (error) {
          print(">>> ERRORE WEBSOCKET: $error");
        },
        onDone: () {
          print(">>> WEBSOCKET CHIUSO DAL SERVER");
        }
      );
    } catch (e) {
      print(">>> ECCEZIONE CRITICA WEBSOCKET: $e");
    }
  }

  // --- 3. FUNZIONI DI UTILITÀ ---
  // Invia un messaggio all'altro telefono
  void send(dynamic message) {
    if (_socket != null) {
      _socket!.sink.add(jsonEncode(message));
    }
  }

  // Chiude tutte le connessioni quando usciamo dalla schermata
  void stop() {
    _socket?.sink.close();
    _server?.close();
  }

  // Ricerca automatica dell'indirizzo IP locale ottimizzata per Hotspot
  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLoopback: false);
          
      // 1. PRIORITÀ HOTSPOT: Cerchiamo prima gli IP tipici degli Hotspot (Android e iOS)
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.address.startsWith('192.168.43.') || addr.address.startsWith('172.20.10.')) {
             return addr.address;
          }
        }
      }
      
      // 2. RETE STANDARD: Se non trova hotspot, prende un IP locale generico (es. Wi-Fi di casa)
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.address.startsWith('192.168.') || addr.address.startsWith('10.') || addr.address.startsWith('172.')) {
             return addr.address;
          }
        }
      }
    } catch (e) {
      print(">>> Errore nella ricerca dell'IP: $e");
    }
    
    // 3. IL TRUCCO DI FALLBACK: Se Android nasconde l'interfaccia (succede spesso con l'hotspot attivo),
    // forziamo l'IP di default che Android assegna SEMPRE a se stesso come router.
    return '192.168.43.1'; 
  }
}