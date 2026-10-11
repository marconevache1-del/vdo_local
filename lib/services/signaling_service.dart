import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Scambia i messaggi di segnalazione (offer/answer/candidate) fra i due
/// dispositivi tramite un WebSocket sulla rete locale.
class SignalingService {
  HttpServer? _server;
  WebSocketChannel? _socket;
  String? _token;

  /// Chiamata per ogni messaggio JSON ricevuto.
  Function(Map<String, dynamic> message)? onMessage;

  /// Trasmettitore: un ricevitore si è collegato.
  VoidCallback? onPeerConnected;

  /// La connessione WebSocket si è chiusa.
  VoidCallback? onClosed;

  // --- Modalità trasmettitore ---

  /// Avvia il server e restituisce l'URI da mettere nel QR (con token segreto).
  Future<String?> startLocalServer() async {
    final localIp = await _getLocalIp();
    if (localIp == null) return null;

    _token = _randomToken();

    final wsHandler = webSocketHandler((WebSocketChannel webSocket, _) {
      _socket?.sink.close();
      _socket = webSocket;
      onPeerConnected?.call();
      webSocket.stream.listen(
        (message) => _dispatch(message),
        onDone: () {
          if (_socket == webSocket) onClosed?.call();
        },
      );
    });

    FutureOr<Response> handler(Request request) {
      if (request.url.queryParameters['t'] != _token) {
        return Response.forbidden('token non valido');
      }
      return wsHandler(request);
    }

    // Su tutte le interfacce: funziona anche con l'hotspot attivo.
    // Porta 8080 se libera, altrimenti una a caso.
    try {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
    } on SocketException {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 0);
    }
    return 'ws://$localIp:${_server!.port}/?t=$_token';
  }

  // --- Modalità ricevitore ---

  /// Si connette al server letto dal QR. Completa quando il socket è aperto.
  Future<void> connectTo(String uri) async {
    final channel = WebSocketChannel.connect(Uri.parse(uri));
    _socket = channel;
    channel.stream.listen(
      (message) => _dispatch(message),
      onError: (e) => debugPrint('Errore WebSocket: $e'),
      onDone: () => onClosed?.call(),
    );
    await channel.ready;
  }

  // --- Utilità ---

  void _dispatch(dynamic message) {
    try {
      onMessage?.call(jsonDecode(message as String) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Messaggio di segnalazione non valido: $e');
    }
  }

  void send(Map<String, dynamic> message) {
    _socket?.sink.add(jsonEncode(message));
  }

  void stop() {
    onClosed = null;
    onPeerConnected = null;
    _socket?.sink.close();
    _server?.close(force: true);
  }

  String _randomToken() {
    final rnd = Random.secure();
    return List.generate(16, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// IP locale, con priorità agli indirizzi tipici di un hotspot.
  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLoopback: false);
      final addrs = [for (final i in interfaces) ...i.addresses.map((a) => a.address)];

      for (final a in addrs) {
        if (a.startsWith('192.168.43.') || a.startsWith('172.20.10.')) return a;
      }
      for (final a in addrs) {
        if (a.startsWith('192.168.') || a.startsWith('10.') || a.startsWith('172.')) {
          return a;
        }
      }
    } catch (e) {
      debugPrint('Errore nella ricerca dell\'IP: $e');
    }
    // Android a volte nasconde l'interfaccia con l'hotspot attivo:
    // 192.168.43.1 è l'IP che assegna a se stesso.
    return '192.168.43.1';
  }
}
