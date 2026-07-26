import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/services/holding/holding.service.dart';
import 'package:soui/elements/SpScafold.dart';
import 'package:url_launcher/url_launcher.dart';

const String _kCdslCasUrl = 'https://www.cdslindia.com/cas/logincas.aspx';

/// Indian income-tax PAN: 5 letters, 4 digits, 1 letter (e.g. ABCDE1234F).
final RegExp _kPanPattern = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

class UploadHoldingStatementScreen extends StatefulWidget {
  const UploadHoldingStatementScreen({super.key});

  @override
  State<UploadHoldingStatementScreen> createState() =>
      _UploadHoldingStatementScreenState();
}

class _UploadHoldingStatementScreenState
    extends State<UploadHoldingStatementScreen> {
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _pdfPasswordController = TextEditingController();

  PlatformFile? _pickedFile;
  String? _panError;
  String? _passwordError;
  String? _fileError;

  bool _submitting = false;

  /// True while UI shows spinner; kept in sync with [_pickGate] lifecycle.
  bool _pickingFile = false;

  /// Synchronous mutex so two [pickFiles] native calls cannot overlap (iOS:
  /// `multiple_request`).
  bool _pickGate = false;

  final String _brokerCode = 'cdsl';
  final String _depository = 'CDSL';

  @override
  void dispose() {
    _panController.dispose();
    _pdfPasswordController.dispose();
    super.dispose();
  }

  Future<FilePickerResult?> _openFilePicker() {
    return FilePicker.pickFiles(
      type: FileType.any,
      withData: false,
      compressionQuality: 0,
    );
  }

  Future<void> _pickPdf() async {
    if (_pickGate) return;
    _pickGate = true;

    if (mounted) {
      setState(() {
        _pickingFile = true;
        _panError = null;
        _passwordError = null;
        _fileError = null;
      });
    }

    try {
      // Let navigator / transitions finish so native isn't invoked twice quickly.
      await Future<void>.delayed(const Duration(milliseconds: 380));
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;

      FilePickerResult? result;
      try {
        result = await _openFilePicker();
      } on PlatformException catch (e) {
        if (e.code != 'multiple_request') rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;
        result = await _openFilePicker();
      }

      if (result == null || result.files.isEmpty) return;

      final f = result.files.single;
      final name = f.name.toLowerCase().trim();

      if (!mounted) return;
      setState(() {
        if (!name.endsWith('.pdf')) {
          _pickedFile = null;
          _fileError = 'Only PDF files are allowed.';
          return;
        }
        if (name.isEmpty) {
          _pickedFile = null;
          _fileError = 'Invalid file.';
          return;
        }
        _pickedFile = f;
        _fileError = null;
      });
    } on PlatformException catch (e) {
      if (e.code == 'multiple_request') {
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick file: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not pick file: $e')));
    } finally {
      _pickGate = false;
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  void _clearPickedFile() {
    setState(() {
      _pickedFile = null;
      _fileError = null;
    });
  }

  bool _validate() {
    setState(() {
      _panError = null;
      _passwordError = null;
      _fileError = null;
    });

    final pan = _panController.text.trim().toUpperCase();
    if (pan.isEmpty) {
      setState(() => _panError = 'PAN is required');
      return false;
    }
    if (!_kPanPattern.hasMatch(pan)) {
      setState(() => _panError = 'Enter a valid PAN (e.g. ABCDE1234F)');
      return false;
    }

    // Password is optional; many PDFs are not password protected.

    if (_pickedFile == null) {
      setState(() => _fileError = 'Please select a PDF statement');
      return false;
    }
    final name = _pickedFile!.name.toLowerCase();
    if (!name.endsWith('.pdf')) {
      setState(() => _fileError = 'Only PDF files are allowed');
      return false;
    }
    if (_pickedFile!.path == null || _pickedFile!.path!.trim().isEmpty) {
      setState(() => _fileError = 'Could not read file path. Please reselect.');
      return false;
    }

    return true;
  }

  Future<void> _onUploadPressed() async {
    if (!_validate()) return;
    setState(() {
      _submitting = true;
    });
    try {
      final filePath = _pickedFile!.path!;
      final password = _pdfPasswordController.text.trim();

      final job = await HoldingService.importHoldings(
        filePath: filePath,
        brokerCode: _brokerCode,
        depository: _depository,
        password: password,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import queued successfully. (${job.status})')),
      );
      Navigator.of(context).maybePop();
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        toolbarHeight: 40,
        leading: AppBackButton(),
        title: const Text("Upload Statement"),
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Upload your CDSL consolidated holdings statement',
                style: TextStyle(
                  color: SharePerksColors.textPrimaryLight,
                  fontSize: 12,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select a PDF file to import holdings and check eligibility.',
                style: TextStyle(
                  color: SharePerksColors.textSecondaryLight,
                  fontSize: 10,
                  fontFamily: SharePerksFonts.inter,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              _InputField(
                label: 'PAN number',
                hint: 'ABCDE1234F',
                controller: _panController,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                maxLength: 10,
                errorText: _panError,
                onChanged: (_) {
                  if (_panError != null) setState(() => _panError = null);
                },
              ),
              _InputField(
                label: 'PDF password',
                hint: 'Optional (only if your PDF is password protected)',
                controller: _pdfPasswordController,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                errorText: _passwordError,
                onChanged: (_) {
                  if (_passwordError != null) {
                    setState(() => _passwordError = null);
                  }
                },
              ),
              const SizedBox(height: 28),
              StatementPdfPicker(
                pickedFile: _pickedFile,
                errorText: _fileError,
                picking: _pickingFile,
                onChoose: _pickPdf,
                onClear: _pickedFile != null && !_pickingFile
                    ? _clearPickedFile
                    : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting ? null : _onUploadPressed,
                child: _submitting
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const Text('Upload & Import Holdings'),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SharePerksColors.borderLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      HugeIconsSolid.informationCircle,
                      color: SharePerksColors.textSecondaryLight,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tip: Download the “Consolidated Account Statement (CAS)” from CDSL and upload it here.',
                        style: TextStyle(
                          color: SharePerksColors.textSecondaryLight,
                          fontSize: 12,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SharePerksColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          HugeIconsSolid.download04,
                          color: SharePerksColors.textSecondaryLight,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'How to download the PDF',
                          style: TextStyle(
                            color: SharePerksColors.textPrimaryLight,
                            fontSize: 13,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '1. Open the CDSL CAS / Declare Bonafide login page.\n'
                      '2. Enter your PAN, BO ID, and date of birth (all fields are required).\n'
                      '3. Complete login and download your consolidated account statement as a PDF.',
                      style: TextStyle(
                        color: SharePerksColors.textSecondaryLight,
                        fontSize: 12,
                        fontFamily: SharePerksFonts.inter,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse(_kCdslCasUrl);
                        if (!await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        )) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open the CDSL page.'),
                              ),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              HugeIconsSolid.link02,
                              size: 18,
                              color: SharePerksColors.textPrimaryLight,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Open CDSL CAS page',
                              style: TextStyle(
                                color: SharePerksColors.textPrimaryLight,
                                fontSize: 12,
                                fontFamily: SharePerksFonts.inter,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dotted PDF drop zone with [file_picker] integration.
class StatementPdfPicker extends StatelessWidget {
  const StatementPdfPicker({
    super.key,
    required this.pickedFile,
    required this.onChoose,
    this.onClear,
    this.errorText,
    this.picking = false,
  });

  final PlatformFile? pickedFile;
  final VoidCallback onChoose;
  final VoidCallback? onClear;
  final String? errorText;
  final bool picking;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DottedBorder(
          options: RectDottedBorderOptions(
            dashPattern: const [7, 5],
            strokeWidth: 1.4,
            color: errorText != null
                ? SharePerksColors.error.withValues(alpha: 0.6)
                : SharePerksColors.borderLight,
            padding: const EdgeInsets.all(14),
            strokeCap: StrokeCap.round,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: SharePerksColors.borderLight.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    HugeIconsSolid.fileUpload,
                    color: SharePerksColors.textSecondaryLight,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  pickedFile == null ? 'Select statement PDF' : 'Selected file',
                  style: TextStyle(
                    color: SharePerksColors.textPrimaryLight,
                    fontSize: 14,
                    fontFamily: SharePerksFonts.inter,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                if (pickedFile != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          pickedFile!.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: SharePerksColors.textSecondaryLight,
                            fontSize: 12,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (onClear != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: onClear,
                          icon: Icon(Icons.close_rounded),
                          tooltip: 'Remove file',
                          color: SharePerksColors.textSecondaryLight,
                          iconSize: 20,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                ] else
                  Text(
                    'Tap below to choose a file',
                    style: TextStyle(
                      color: SharePerksColors.textSecondaryLight,
                      fontSize: 12,
                      fontFamily: SharePerksFonts.inter,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: picking ? null : onChoose,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: SharePerksColors.textPrimaryLight,
                      side: BorderSide(color: SharePerksColors.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: picking
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: SharePerksColors.textPrimaryLight,
                            ),
                          )
                        : Text(
                            pickedFile == null ? 'Choose PDF' : 'Change PDF',
                            style: TextStyle(
                              fontFamily: SharePerksFonts.inter,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Supported format: PDF',
                  style: TextStyle(
                    color: SharePerksColors.textSecondaryLight,
                    fontSize: 11,
                    fontFamily: SharePerksFonts.inter,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TextStyle(
              color: SharePerksColors.error,
              fontSize: 11,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.obscureText = false,
    this.errorText,
    this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final bool obscureText;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          label,
          style: TextStyle(
            color: SharePerksColors.textPrimaryLight,
            fontSize: 10,
            fontFamily: SharePerksFonts.inter,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          maxLength: maxLength,
          autocorrect: false,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12),
            errorText: hasError ? errorText : null,
          ),
        ),
      ],
    );
  }
}
