import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../app_colors.dart';

class QrScanScreen extends StatefulWidget {
  final String token;
  final String email;
  final bool autoLogin;
  final Function(bool autoLogin, String email, String token) onLinked;
  final VoidCallback onLogout;

  const QrScanScreen({
    super.key,
    required this.token,
    required this.email,
    required this.autoLogin,
    required this.onLinked,
    required this.onLogout,
  });

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _processing = false;
  bool _cameraGranted = false;
  bool _cameraDenied = false;
  String _error = '';
  final _deviceIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _requestCameraPermission();
  }

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() { _cameraGranted = true; });
    } else {
      setState(() { _cameraDenied = true; });
    }
  }

  Future<void> _linkDevice(String deviceId) async {
    if (_processing || deviceId.trim().isEmpty) return;
    setState(() { _processing = true; _error = ''; });

    try {
      final response = await http.post(
        Uri.parse('https://primarily-example-thicken.ngrok-free.dev/devices/link'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'desktop_device_id': deviceId.trim()}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        widget.onLinked(widget.autoLogin, widget.email, widget.token);
      } else {
        final body = jsonDecode(response.body);
        setState(() {
          _error = body['detail'] ?? '기기 연결에 실패했습니다.';
          _processing = false;
        });
      }
    } catch (e) {
      setState(() { _error = '서버 연결에 실패했습니다.'; _processing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          'PURBY 기기 연결',
          style: TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.t1),
        ),
        iconTheme: IconThemeData(color: AppColors.t1),
        actions: [
          TextButton(
            onPressed: widget.onLogout,
            child: const Text('로그아웃', style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.accent)),
          ),
        ],
      ),
      body: kIsWeb ? _buildTextInput() : _buildMobile(),
    );
  }

  // 웹 텍스트 입력
  Widget _buildTextInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.devices_rounded, size: 56, color: AppColors.accent),
          const SizedBox(height: 24),
          Text('PURBY 기기 ID를 입력해주세요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t1),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _deviceIdCtrl,
            style: TextStyle(fontSize: 13, color: AppColors.t1, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: '기기 ID 입력',
              hintStyle: TextStyle(color: AppColors.t3, fontSize: 13),
              filled: true, fillColor: AppColors.panel,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),
          _connectButton(() => _linkDevice(_deviceIdCtrl.text)),
          _errorBox(),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => widget.onLinked(widget.autoLogin, widget.email, widget.token),
            child: Text('기기 없이 계속하기', style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.t3)),
          ),
        ],
      ),
    );
  }

  // 모바일 카메라 QR 스캔
  Widget _buildMobile() {
    if (!_cameraGranted && !_cameraDenied) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_cameraDenied) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.t3),
            const SizedBox(height: 16),
            Text('카메라 권한이 필요해요', style: TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t1)),
            const SizedBox(height: 8),
            Text('설정에서 카메라 권한을 허용해주세요', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.t3)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
              child: const Text('설정 열기', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: _processing
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : MobileScanner(
                  onDetect: (capture) {
                    final value = capture.barcodes.firstOrNull?.rawValue;
                    if (value != null) _linkDevice(value);
                  },
                ),
        ),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner_rounded, size: 24, color: AppColors.accent),
                const SizedBox(height: 8),
                Text('PURBY 기기 화면의 QR 코드를\n카메라로 스캔해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.t2, height: 1.5),
                ),
                _errorBox(),
                TextButton(
                  onPressed: () => widget.onLinked(widget.autoLogin, widget.email, widget.token),
                  child: Text('기기 없이 계속하기', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.t3)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _connectButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processing ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          elevation: 0,
        ),
        child: _processing
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('연결하기', style: TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _errorBox() {
    if (_error.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
        ),
        child: Text(_error, style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.red)),
      ),
    );
  }
}
