import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/join_request_model.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  final String? initialCode;
  final bool autoScan;

  const JoinGroupScreen({super.key, this.initialCode, this.autoScan = false});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  JoinResult? _joinResult;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _codeController.text = widget.initialCode!.toUpperCase().trim();
    }
    if (widget.autoScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openQrScannerSheet();
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _openQrScannerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QrScannerModal(
        onCodeScanned: (scannedCode) {
          Navigator.of(ctx).pop();
          _codeController.text = scannedCode.toUpperCase().trim();
          _submitJoin();
        },
      ),
    );
  }

  Future<void> _submitJoin() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 6-character Group Code or link'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _joinResult = null;
    });

    final currentUser = await ref.read(currentUserProvider.future);
    final userId = currentUser?.uid ?? 'guest_user';
    final userName = currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'Kitty Member';

    final result = await ref.read(groupRepositoryProvider).redeemOneTimeInvite(
          rawInput: code,
          userId: userId,
          userName: userName,
          photoUrl: currentUser?.photoUrl,
        );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _joinResult = result;
    });

    if (result.status == JoinResultStatus.joined && result.group != null) {
      ref.read(selectedGroupIdProvider.notifier).state = result.group!.groupId;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/group/${result.group!.groupId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Kitty Circle'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            tooltip: 'Scan QR Code',
            onPressed: _openQrScannerSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                // Hero Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Text('🎀', style: TextStyle(fontSize: 40)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Join a Kitty Group',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter the Group Code or scan the QR Code shared by your host to join!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Join Result View if Pending
                if (_joinResult != null && _joinResult!.status == JoinResultStatus.pendingApproval) ...[
                  _buildPendingApprovalCard(_joinResult!),
                  const SizedBox(height: 24),
                ] else ...[
                  // Group Code Input
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 9,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'K7P9-X4M2',
                      hintStyle: TextStyle(
                        fontSize: 24,
                        letterSpacing: 4,
                        color: Colors.grey.shade300,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 28),
                        tooltip: 'Scan QR Code',
                        onPressed: _openQrScannerSheet,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Primary Scan QR Button
                  ElevatedButton.icon(
                    onPressed: _openQrScannerSheet,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                    label: const Text(
                      'Scan QR Code 🔳',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Join with Code Button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _submitJoin,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                          )
                        : const Icon(Icons.key_rounded, size: 20),
                    label: const Text('Join with Code'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Alternative Paste option button
                  TextButton.icon(
                    onPressed: () async {
                      final clipboardData = await Clipboard.getData('text/plain');
                      if (!context.mounted) return;
                      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
                        final text = clipboardData.text!;
                        final code = _extractInviteCode(text);
                        if (code.isNotEmpty) {
                          _codeController.text = code.toUpperCase();
                          _submitJoin();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No valid Group Code found in clipboard')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Paste Code from Clipboard'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],

                if (_joinResult != null && _joinResult!.status != JoinResultStatus.pendingApproval) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _joinResult!.status == JoinResultStatus.alreadyMember
                          ? Colors.blue.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _joinResult!.status == JoinResultStatus.alreadyMember
                              ? Icons.info_outline
                              : Icons.error_outline,
                          color: _joinResult!.status == JoinResultStatus.alreadyMember
                              ? Colors.blue
                              : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _joinResult!.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: _joinResult!.status == JoinResultStatus.alreadyMember
                                  ? Colors.blue.shade900
                                  : Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingApprovalCard(JoinResult result) {
    final group = result.group;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_top_rounded, size: 48, color: Colors.amber),
          const SizedBox(height: 12),
          Text(
            group?.name ?? 'Kitty Circle',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          if (group != null)
            Text(
              '👥 ${group.memberCount} Members',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          const SizedBox(height: 16),
          const Text(
            'Request Sent to Host! ⏳',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'The host needs to approve your request before you can access group features.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/groups'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back to My Groups'),
          ),
        ],
      ),
    );
  }
}

class _QrScannerModal extends StatefulWidget {
  final ValueChanged<String> onCodeScanned;

  const _QrScannerModal({required this.onCodeScanned});

  @override
  State<_QrScannerModal> createState() => _QrScannerModalState();
}

class _QrScannerModalState extends State<_QrScannerModal> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _isScanned = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isScanned) return;
    for (final barcode in capture.barcodes) {
      final String? rawValue = barcode.rawValue ?? barcode.displayValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        final code = _extractInviteCode(rawValue);
        if (code.isNotEmpty) {
          _isScanned = true;
          HapticFeedback.mediumImpact();
          widget.onCodeScanned(code);
          break;
        }
      }
    }
  }


  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      try {
        final BarcodeCapture? capture = await _scannerController.analyzeImage(file.path);
        if (capture != null && capture.barcodes.isNotEmpty) {
          _handleBarcode(capture);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No QR code detected in selected image')),
            );
          }
        }
      } catch (e) {
        debugPrint('Error analyzing gallery image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF14141E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                  onPressed: () {
                    _scannerController.toggleTorch();
                    setState(() => _isTorchOn = !_isTorchOn);
                  },
                ),
                const Text(
                  'Scan Kitty Circle QR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _handleBarcode,
                        errorBuilder: (context, error, child) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 48),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Camera permission required',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Please enable camera access in app settings',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Positioned(
                            top: _animController.value * 240,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Point camera at Kitty Circle QR Code',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.white12, padding: const EdgeInsets.all(16)),
                    ),
                    const SizedBox(height: 6),
                    const Text('Gallery Photo', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => _scannerController.switchCamera(),
                      icon: const Icon(Icons.cameraswitch_outlined, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.white12, padding: const EdgeInsets.all(16)),
                    ),
                    const SizedBox(height: 6),
                    const Text('Flip Camera', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _extractInviteCode(String rawInput) {
  final text = rawInput.trim();
  // 1. Hyphenated token (e.g., K7P9-X4M2)
  final hyphenMatch = RegExp(r'([A-Za-z0-9]{4}\-[A-Za-z0-9]{4})').firstMatch(text);
  if (hyphenMatch != null) {
    return hyphenMatch.group(1)!;
  }
  // 2. Query param code (e.g., https://.../join?code=K7P9-X4M2 or code=KTY7P2)
  final paramMatch = RegExp(r'[?&]code=([A-Za-z0-9\-]{6,9})').firstMatch(text);
  if (paramMatch != null) {
    return paramMatch.group(1)!;
  }
  // 3. Simple 6-character group code (e.g., KTY7P2)
  final sixCharMatch = RegExp(r'\b([A-Za-z0-9]{6})\b').firstMatch(text);
  if (sixCharMatch != null) {
    return sixCharMatch.group(1)!;
  }
  return text;
}

