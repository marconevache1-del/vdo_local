import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/signaling_service.dart';
import '../services/webrtc_service.dart';
import '../theme.dart';
import '../widgets/rec_light.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final SignalingService _signaling = SignalingService();
  late final WebRTCService _webrtc;

  String? _qrData;
  String? _error;

  /// true quando il video sta andando al ricevitore: schermo nero + luce rossa.
  bool _streaming = false;

  @override
  void initState() {
    super.initState();
    _webrtc = WebRTCService(_signaling);
    _webrtc.onConnectionState = _onConnectionState;
    _init();
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _webrtc.initConnection();

    // Prima il server, così il QR compare anche se la camera dà problemi.
    final uri = await _signaling.startLocalServer();
    if (!mounted) return;
    setState(() => _qrData = uri);

    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': false,
        'video': {
          'facingMode': 'environment',
          'width': {'ideal': 1920},
          'height': {'ideal': 1080},
          'frameRate': {'ideal': 30},
        }
      });
      if (!mounted) return;
      setState(() => _localRenderer.srcObject = stream);
      await _webrtc.addLocalStream(stream);
    } catch (e) {
      if (mounted) setState(() => _error = 'Fotocamera non disponibile: $e');
    }
  }

  void _onConnectionState(RTCPeerConnectionState state) {
    if (!mounted) return;
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      _setStreaming(true);
    } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
        state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
        state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
      _setStreaming(false);
    }
  }

  Future<void> _setStreaming(bool value) async {
    if (_streaming == value) return;
    setState(() => _streaming = value);
    try {
      if (value) {
        await WakelockPlus.enable();
        await ScreenBrightness().setApplicationScreenBrightness(0.0);
      } else {
        await WakelockPlus.disable();
        await ScreenBrightness().resetApplicationScreenBrightness();
      }
    } catch (e) {
      debugPrint('Luminosità/wakelock: $e');
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    ScreenBrightness().resetApplicationScreenBrightness().catchError((_) {});
    _localRenderer.dispose();
    _webrtc.dispose();
    _signaling.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _streaming ? _buildStreaming() : _buildSetup(),
    );
  }

  /// Schermo quasi spento: solo la luce rossa. Pressione lunga per riattivare.
  Widget _buildStreaming() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _setStreaming(false),
      child: SizedBox.expand(
        child: Container(
          color: Colors.black,
          child: const Align(
            alignment: Alignment(0, -0.85),
            child: RecLight(size: 34),
          ),
        ),
      ),
    );
  }

  Widget _buildSetup() {
    return Stack(
      children: [
        Positioned.fill(
          child: RTCVideoView(
            _localRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        if (_error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.highlight)),
            ),
          ),
        if (_qrData != null)
          Positioned(
            bottom: 30,
            right: 30,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.steel, Colors.white, AppColors.steel],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.red, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black87, blurRadius: 14)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                        data: _qrData!,
                        version: QrVersions.auto,
                        size: 170,
                        backgroundColor: Colors.white),
                    const SizedBox(height: 8),
                    const Text('Scansiona per ricevere',
                        style: TextStyle(
                            color: AppColors.redDark,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
