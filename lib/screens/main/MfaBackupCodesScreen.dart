import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/elements/SpScafold.dart';

class MfaBackupCodesScreen extends StatefulWidget {
  final List<String> backupCodes;

  const MfaBackupCodesScreen({super.key, required this.backupCodes});

  @override
  State<MfaBackupCodesScreen> createState() => _MfaBackupCodesScreenState();
}

class _MfaBackupCodesScreenState extends State<MfaBackupCodesScreen> {
  bool _saved = false;

  Future<void> _copyAll() async {
    final text = widget.backupCodes.join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    Fluttertoast.showToast(
      msg: 'Backup codes copied',
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  Future<void> _copyOne(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    Fluttertoast.showToast(
      msg: 'Copied',
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  void _done() {
    context.goNamed(RouteNames.SETTINGS_SCREEN);
  }

  @override
  Widget build(BuildContext context) {
    final codes = widget.backupCodes;

    return PopScope(
      canPop: _saved,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saved) {
          Fluttertoast.showToast(
            msg: 'Please confirm you saved your backup codes.',
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
      },
      child: SpScafold(
        appBar: AppBar(
          leading: _saved
              ? const AppBackButton()
              : IconButton(
                  onPressed: () {
                    Fluttertoast.showToast(
                      msg: 'Please confirm you saved your backup codes.',
                      backgroundColor: Colors.orange,
                      textColor: Colors.white,
                    );
                  },
                  icon: const Icon(
                    HugeIconsSolid.arrowLeft02,
                    color: Colors.white,
                  ),
                ),
          toolbarHeight: 40,
          title: const Text('Backup codes'),
          actions: [
            Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
            const SizedBox(width: 20),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save these codes',
                      style: TextStyle(
                        color: SharePerksColors.textPrimaryLight,
                        fontSize: 22,
                        fontFamily: SharePerksFonts.albertSans,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Each code can be used once if you lose access to your authenticator app.',
                      style: TextStyle(
                        color: SharePerksColors.textSecondaryLight,
                        fontSize: 13,
                        height: 1.4,
                        fontFamily: SharePerksFonts.inter,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),
                        borderRadius:
                            BorderRadius.circular(SharePerksRadii.md),
                        border: Border.all(color: const Color(0xFFFFD9A8)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFB45309),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'These codes are shown only once. Store them somewhere safe before continuing.',
                              style: TextStyle(
                                color: const Color(0xFF92400E),
                                fontSize: 12,
                                height: 1.35,
                                fontFamily: SharePerksFonts.inter,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '${codes.length} codes',
                          style: TextStyle(
                            color: SharePerksColors.textSecondaryLight,
                            fontSize: 12,
                            fontFamily: SharePerksFonts.inter,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _copyAll,
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy all'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6400E0),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SharePerksColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(SharePerksRadii.lg),
                        border: Border.all(color: SharePerksColors.borderLight),
                      ),
                      child: codes.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No backup codes returned.',
                                style: TextStyle(
                                  color: SharePerksColors.textSecondaryLight,
                                  fontFamily: SharePerksFonts.inter,
                                ),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final twoCol = constraints.maxWidth > 320;
                                if (!twoCol) {
                                  return Column(
                                    children: [
                                      for (var i = 0; i < codes.length; i++)
                                        _BackupCodeTile(
                                          index: i + 1,
                                          code: codes[i],
                                          onCopy: () => _copyOne(codes[i]),
                                        ),
                                    ],
                                  );
                                }
                                final mid = (codes.length / 2).ceil();
                                final left = codes.take(mid).toList();
                                final right = codes.skip(mid).toList();
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          for (var i = 0; i < left.length; i++)
                                            _BackupCodeTile(
                                              index: i + 1,
                                              code: left[i],
                                              onCopy: () =>
                                                  _copyOne(left[i]),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          for (var i = 0;
                                              i < right.length;
                                              i++)
                                            _BackupCodeTile(
                                              index: mid + i + 1,
                                              code: right[i],
                                              onCopy: () =>
                                                  _copyOne(right[i]),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: SharePerksColors.borderLight),
                  ),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _saved = !_saved),
                      borderRadius:
                          BorderRadius.circular(SharePerksRadii.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _saved,
                                onChanged: (v) =>
                                    setState(() => _saved = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "I've saved my backup codes somewhere safe",
                                style: TextStyle(
                                  color: const Color(0xFF333333),
                                  fontSize: 13,
                                  fontFamily: SharePerksFonts.inter,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saved ? _done : null,
                        child: const Text('Continue to Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupCodeTile extends StatelessWidget {
  const _BackupCodeTile({
    required this.index,
    required this.code,
    required this.onCopy,
  });

  final int index;
  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SharePerksRadii.md),
        border: Border.all(color: SharePerksColors.borderLight),
      ),
      child: Row(
        children: [
          Text(
            '$index'.padLeft(2, '0'),
            style: TextStyle(
              color: SharePerksColors.textSecondaryLight,
              fontSize: 11,
              fontFamily: SharePerksFonts.inter,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              code,
              style: TextStyle(
                color: SharePerksColors.textPrimaryLight,
                fontSize: 14,
                fontFamily: SharePerksFonts.inter,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.copy_rounded,
                size: 16,
                color: Color(0xFF6400E0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
