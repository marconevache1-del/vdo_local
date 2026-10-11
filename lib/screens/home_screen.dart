import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/metal_button.dart';
import 'camera_screen.dart';
import 'viewer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.3,
            colors: [Color(0xFF2A0A10), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [AppColors.steel, Colors.white, AppColors.steel],
                      ).createShader(r),
                      child: const Text('VDO LOCAL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: Colors.white)),
                    ),
                    const SizedBox(height: 8),
                    Text('Streaming video locale a bassa latenza',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.steel.withValues(alpha: 0.7),
                            letterSpacing: 1)),
                    const SizedBox(height: 56),
                    MetalButton(
                      icon: Icons.videocam_rounded,
                      label: 'TRASMETTI',
                      subtitle: 'Usa questo dispositivo come camera',
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CameraScreen())),
                    ),
                    const SizedBox(height: 24),
                    MetalButton(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'RICEVI',
                      subtitle: 'Scansiona il QR e guarda il video',
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ViewerScreen())),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
