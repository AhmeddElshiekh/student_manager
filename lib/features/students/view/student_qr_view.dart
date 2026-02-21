import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nizam/models/student_model.dart';
import 'package:nizam/models/payment_record_model.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nizam/features/settings/view_model/settings_cubit.dart';

class QRScannerView extends StatefulWidget {
  const QRScannerView({super.key});

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessingQR = false;
  String _scanResult = 'امسح رمز QR الخاص بالطالب';
  Color _resultColor = Colors.blueGrey;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _resetScanStateAndRestartCamera() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _scanResult = 'امسح رمز QR الخاص بالطالب';
          _resultColor = Colors.blueGrey;
          _isProcessingQR = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          cameraController.start();
        });
      }
    });
  }

  Future<void> _processScanResult(String studentId) async {
    if (_isProcessingQR) return;

    setState(() {
      _isProcessingQR = true;
      _scanResult = 'جاري معالجة الرمز...';
      _resultColor = Colors.blue;
    });

    final studentsBox = Hive.box<StudentModel>('students');
    final student = studentsBox.values.firstWhereOrNull((s) => s.id == studentId);

    if (student == null) {
      setState(() {
        _scanResult = 'الطالب غير موجود!';
        _resultColor = Colors.red;
      });
      _resetScanStateAndRestartCamera();
      return;
    }

    await cameraController.stop();

    if (student.isPaid) {
      await _showCancellationConfirmationModal(context, student);
    } else {
      await _showPaymentConfirmationModal(context, student);
    }

    _resetScanStateAndRestartCamera();
  }

  Future<void> _showPaymentConfirmationModal(BuildContext context, StudentModel student) async {
    final theme = Theme.of(context);
    final lastPayment = student.paymentHistory.lastOrNull;
    final isPostponed = lastPayment?.paymentMethod == 'مؤجل';

    final String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModalHandle(),
                Text(
                  'تأكيد حالة الدفع',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildStudentInfoTile(student),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDetailChip(Icons.class_, student.studentClass, Colors.orange),
                    _buildDetailChip(Icons.group, _formatGroupDateTime(student.group), Colors.purple),
                    _buildDetailChip(
                      isPostponed ? Icons.watch_later : Icons.cancel,
                      isPostponed ? 'الحالة الحالية: مؤجل' : 'الحالة الحالية: غير مدفوع',
                      isPostponed ? Colors.blueGrey : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildModalButton(
                  context: modalContext,
                  label: 'تأكيد الدفع',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  onPressed: () => Navigator.pop(modalContext, 'paid'),
                ),
                const SizedBox(height: 8),
                _buildModalButton(
                  context: modalContext,
                  label: 'إلغاء',
                  icon: Icons.close,
                  isOutlined: true,
                  onPressed: () => Navigator.pop(modalContext, 'cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == 'paid') {
      final paymentDurationHours = context.read<SettingsCubit>().state.paymentDurationHours;
      final expiryDate = DateTime.now().add(Duration(hours: paymentDurationHours));
      student.paymentHistory.add(PaymentRecord(
        date: DateTime.now(),
        isPaid: true,
        paymentExpiresAt: expiryDate,
        paymentMethod: 'مسح QR Code',
      ));
      await student.save();

      setState(() {
        _scanResult = 'تم تسجيل دفع الطالب ${student.name} بنجاح!\nينتهي في: ${DateFormat('yyyy-MM-dd hh:mm a', 'ar').format(expiryDate)}.';
        _resultColor = Colors.green;
      });
    } else {
      setState(() {
        _scanResult = 'تم إلغاء العملية للطالب ${student.name}.';
        _resultColor = Colors.grey;
      });
    }
  }

  Future<void> _showCancellationConfirmationModal(BuildContext context, StudentModel student) async {
    final theme = Theme.of(context);

    final String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        final lastPayment = student.paymentHistory.lastOrNull;
        final expiryDateText = lastPayment?.paymentExpiresAt != null
            ? DateFormat('yyyy-MM-dd hh:mm a', 'ar').format(lastPayment!.paymentExpiresAt!)
            : 'غير محدد';
        return Padding(
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModalHandle(),
                Text(
                  'إلغاء اشتراك الطالب',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildStudentInfoTile(student, subtitle: 'اشتراك سارٍ حتى $expiryDateText'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDetailChip(Icons.class_, student.studentClass, Colors.orange),
                    _buildDetailChip(Icons.group, _formatGroupDateTime(student.group), Colors.purple),
                    _buildDetailChip(Icons.check_circle, 'الحالة الحالية: مدفوع', Colors.green),
                  ],
                ),
                const SizedBox(height: 24),
                _buildModalButton(
                  context: modalContext,
                  label: 'إلغاء الاشتراك',
                  icon: Icons.cancel,
                  color: Colors.red,
                  onPressed: () => Navigator.pop(modalContext, 'cancel_subscription'),
                ),
                const SizedBox(height: 8),
                _buildModalButton(
                  context: modalContext,
                  label: 'مؤجل',
                  icon: Icons.watch_later,
                  color: Colors.blueGrey,
                  onPressed: () => Navigator.pop(modalContext, 'postponed'),
                ),
                const SizedBox(height: 8),
                _buildModalButton(
                  context: modalContext,
                  label: 'إلغاء',
                  icon: Icons.close,
                  isOutlined: true,
                  onPressed: () => Navigator.pop(modalContext, 'cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == 'cancel_subscription') {
      final lastPayment = student.paymentHistory.lastOrNull;
      if (lastPayment != null) {
        lastPayment.paymentExpiresAt = DateTime.now();
        lastPayment.isPaid = false;
        lastPayment.cancellationReason = 'تم الإلغاء من خلال ماسح QR Code';
        await student.save();
        setState(() {
          _scanResult = 'تم إلغاء اشتراك الطالب ${student.name} بنجاح.';
          _resultColor = Colors.green;
        });
      }
    } else if (result == 'postponed') {
      final lastPayment = student.paymentHistory.lastWhereOrNull((record) => record.isPaid);
      if (lastPayment != null) {
        lastPayment.isPaid = false;
        lastPayment.paymentExpiresAt = DateTime.now();
        lastPayment.cancellationReason = 'تم تغيير الحالة إلى مؤجل من خلال ماسح QR';
      }
      student.paymentHistory.add(PaymentRecord(
        date: DateTime.now(),
        isPaid: false,
        paymentExpiresAt: null,
        paymentMethod: 'مؤجل',
      ));
      await student.save();
      setState(() {
        _scanResult = 'تم تأجيل اشتراك الطالب ${student.name} بنجاح.';
        _resultColor = Colors.orange;
      });
    } else {
      setState(() {
        _scanResult = 'تم إلغاء العملية للطالب ${student.name}.';
        _resultColor = Colors.grey;
      });
    }
  }

  Widget _buildModalHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStudentInfoTile(StudentModel student, {String? subtitle}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.primaryColor.withAlpha(51),
        child: Icon(Icons.person, color: theme.primaryColor),
      ),
      title: Text(student.name, style: theme.textTheme.titleMedium),
      subtitle: Text(subtitle ?? student.studentNumber),
    );
  }

  Widget _buildModalButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    Color? color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    final style = isOutlined
        ? OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: color ?? Colors.blueGrey),
    )
        : ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    final button = isOutlined
        ? OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: style,
    )
        : ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: style,
    );

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }

  String _formatGroupDateTime(String group) {
    try {
      final DateTime dt = DateTime.parse(group);
      return DateFormat('EEEE h:mm a', 'ar').format(dt);
    } catch (_) {
      return group;
    }
  }

  Widget _buildDetailChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      backgroundColor: color.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ماسح QR Code للدفع', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, _) {
                return Icon(
                  state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: state == TorchState.on ? Colors.yellow : Colors.grey,
                );
              },
            ),
            onPressed: cameraController.toggleTorch,
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, _) {
                return Icon(state == CameraFacing.front ? Icons.camera_front : Icons.camera_rear);
              },
            ),
            onPressed: cameraController.switchCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    if (!_isProcessingQR) {
                      final code = capture.barcodes.firstOrNull?.rawValue;
                      if (code != null && code.isNotEmpty) {
                        _processScanResult(code);
                      }
                    }
                  },
                ),
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black.withAlpha(179),
                    child: Text(
                      _scanResult,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _resultColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
