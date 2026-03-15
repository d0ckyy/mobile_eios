import 'package:eios/data/models/accepted_attendance.dart';
import 'package:eios/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'bloc/attendance_bloc.dart';
import 'bloc/attendance_event.dart';
import 'bloc/attendance_state.dart';

class AttendanceCodeScreen extends StatelessWidget {
  final bool isActive;

  const AttendanceCodeScreen({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AttendanceBloc(),
      child: _AttendanceView(isActive: isActive),
    );
  }
}

class _AttendanceView extends StatefulWidget {
  final bool isActive;

  const _AttendanceView({required this.isActive});

  @override
  State<_AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<_AttendanceView>
    with WidgetsBindingObserver {
  final TextEditingController _codeController = TextEditingController();

  MobileScannerController? _scannerController;
  bool _isCameraInitialized = false;
  String? _lastScannedCode;

  bool get _isActive => widget.isActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_isActive) _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _codeController.dispose();
    _disposeCamera();
    super.dispose();
  }

  @override
  void didUpdateWidget(_AttendanceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isActive && !oldWidget.isActive) {
      _initializeCamera();
    } else if (!_isActive && oldWidget.isActive) {
      _disposeCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isActive) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _initializeCamera();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _disposeCamera();
        break;
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted || _isCameraInitialized) return;
    await _disposeCamera();
    if (!mounted) return;

    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        autoStart: true,
      );
      _isCameraInitialized = true;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _isCameraInitialized = false;
    }
  }

  Future<void> _disposeCamera() async {
    _isCameraInitialized = false;
    if (_scannerController == null) return;

    try {
      await _scannerController!.stop();
    } catch (_) {}
    try {
      await _scannerController!.dispose();
    } catch (_) {}

    _scannerController = null;
    if (mounted) setState(() {});
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (!_isActive || !mounted) return;

    final state = context.read<AttendanceBloc>().state;
    if (state.isLoading || state.isScannerLocked) return;

    final code = barcodes.barcodes.firstOrNull?.displayValue;
    if (code != null && code.isNotEmpty && code != _lastScannedCode) {
      _lastScannedCode = code;
      context.read<AttendanceBloc>().add(AttendanceCodeSubmitted(code));
    }
  }

  void _showSuccessDialog(AcceptedAttendance attendance) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 30),
            SizedBox(width: 10),
            Text('Успешно!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (attendance.disciplineTitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Дисциплина: ${attendance.disciplineTitle}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (attendance.date != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('Дата: ${attendance.date}'),
              ),
            if (attendance.teacher != null)
              Text('Преподаватель: ${attendance.teacher!.fio ?? "Не указан"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ BUILD ═══════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Отметка посещаемости')),
      body: BlocListener<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          // ── Успех → диалог ──
          if (state.status == AttendanceStatus.success &&
              state.successResult != null) {
            _showSuccessDialog(state.successResult!);
            _codeController.clear();
            _lastScannedCode = null;
            context.read<AttendanceBloc>().add(AttendanceResultHandled());
          }

          // ── Ошибка → снекбар ──
          if (state.status == AttendanceStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.magenta,
                duration: const Duration(seconds: 2),
              ),
            );
            _lastScannedCode = null;
            context.read<AttendanceBloc>().add(AttendanceResultHandled());
          }
        },
        child: BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: appPanelDecoration(),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: _buildScannerView(),
                            ),
                          ),
                          if (state.isLoading)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.42),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Positioned(
                            top: 18,
                            left: 18,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.deepBlue.withValues(
                                  alpha: 0.88,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                !state.isLoading &&
                                        _isActive &&
                                        _isCameraInitialized
                                    ? 'Наведите камеру на QR-код'
                                    : 'Сканер посещаемости',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: appPanelDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Ручной ввод',
                              style: TextStyle(
                                color: AppColors.deepBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Если камера недоступна, введите код вручную.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _codeController,
                            enabled: !state.isLoading,
                            decoration: const InputDecoration(
                              hintText: 'Введите код',
                              prefixIcon: Icon(Icons.qr_code_2_rounded),
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              letterSpacing: 2,
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                            onSubmitted: (_) {
                              if (!state.isLoading) {
                                context.read<AttendanceBloc>().add(
                                  AttendanceCodeSubmitted(_codeController.text),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: state.isLoading
                                  ? null
                                  : () {
                                      context.read<AttendanceBloc>().add(
                                        AttendanceCodeSubmitted(
                                          _codeController.text,
                                        ),
                                      );
                                    },
                              child: state.isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Отправить'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    if (!_isActive || !_isCameraInitialized || _scannerController == null) {
      return Container(
        color: AppColors.ink,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.white54, size: 64),
              SizedBox(height: 16),
              Text('Камера неактивна', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    return MobileScanner(
      controller: _scannerController!,
      onDetect: _handleBarcode,
      errorBuilder: (context, error) {
        return Container(
          color: AppColors.ink,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.magenta,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Ошибка камеры: ${error.errorCode.name}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _disposeCamera();
                    await Future.delayed(const Duration(milliseconds: 500));
                    if (mounted) await _initializeCamera();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Повторить'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
