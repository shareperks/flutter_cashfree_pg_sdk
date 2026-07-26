import 'package:dio/dio.dart';
import 'package:dropdown_flutter/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/routes.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/perk_request_payload.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'package:shareperks/repository/services/listing/broker.service.dart';
import 'package:shareperks/repository/services/listing/submit.service.dart';
import 'package:soui/elements/SpScafold.dart';

class RequestPerkScreen extends StatefulWidget {
  const RequestPerkScreen({super.key});

  @override
  State<RequestPerkScreen> createState() => _RequestPerkScreenState();
}

class _RequestPerkScreenState extends State<RequestPerkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();

  String _perkType = 'discount_code';
  String? _selectedCompany;
  bool _submitting = false;

  static const _perkTypes = <_PerkTypeOption>[
    _PerkTypeOption(
      key: 'discount_code',
      label: 'Discount',
      icon: HugeIconsSolid.couponPercent,
    ),
    _PerkTypeOption(
      key: 'cashback',
      label: 'Cashback',
      icon: HugeIconsSolid.cashback,
    ),
    _PerkTypeOption(
      key: 'giftcard',
      label: 'Gift card',
      icon: HugeIconsSolid.giftCard,
    ),
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<List<String>> _searchCompanies(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      final res = await BrokerService.searchBrokers(search: q);
      return (res.data ?? [])
          .map((e) => e.nameOfCompany)
          .whereType<String>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final company = _selectedCompany?.trim();
    if (company == null || company.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Select a company from the list',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final user = context.read<UserProvider>().user;
    if (user?.id == null ||
        user?.name == null ||
        user?.email == null ||
        user?.mobile == null) {
      Fluttertoast.showToast(
        msg: 'Please log in to submit a request',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await SubmitService.submitPerkRequest(
        PerkRequestPayload(
          userId: user!.id!,
          userName: user.name!,
          userEmail: user.email!,
          userMobile: user.mobile!,
          userImage: user.image,
          company: company,
          perkType: _perkType,
          text: _detailsController.text.trim(),
        ),
      );
      if (!mounted) return;
      if (context.canPop()) {
        context.replaceNamed(RouteNames.EMAIL_SUCCESS_SCREEN);
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      Fluttertoast.showToast(
        msg: msg ?? e.message ?? 'Something went wrong',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString(),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 13,
      fontFamily: SharePerksFonts.albertSans,
      fontWeight: FontWeight.w600,
      color: SharePerksColors.textPrimaryLight,
    );
    final hintStyle = TextStyle(
      fontSize: 12,
      fontFamily: SharePerksFonts.inter,
      fontWeight: FontWeight.w400,
      color: SharePerksColors.textSecondaryLight,
      height: 1.35,
    );

    return SpScafold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: AppBackButton(),
        title: const Text('Request a Perk'),
        toolbarHeight: 40,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _RequestIntroCard(),
                const SizedBox(height: 16),
                Text('Perk type', style: labelStyle),
                const SizedBox(height: 4),
                Text('What kind of perk are you looking for?', style: hintStyle),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < _perkTypes.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _PerkTypeChip(
                          option: _perkTypes[i],
                          selected: _perkType == _perkTypes[i].key,
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            setState(() => _perkType = _perkTypes[i].key);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                Text('Company', style: labelStyle),
                const SizedBox(height: 4),
                Text('Search and pick the brand or company', style: hintStyle),
                const SizedBox(height: 10),
                Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: SharePerksColors.inputFillLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 1,
                        color: SharePerksColors.inputBorderLight,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: DropdownFlutter<String>.searchRequest(
                      closedHeaderPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: CustomDropdownDecoration(
                        closedFillColor: Colors.transparent,
                        expandedFillColor: SharePerksColors.inputFillLight,
                        // Overlay keeps a matching outer border (incl. L/R).
                        expandedBorder: Border.all(
                          width: 1,
                          color: SharePerksColors.inputBorderLight,
                        ),
                        expandedBorderRadius: BorderRadius.circular(12),
                        listItemStyle: TextStyle(
                          fontSize: 13,
                          fontFamily: SharePerksFonts.inter,
                          color: SharePerksColors.textPrimaryLight,
                        ),
                        hintStyle: TextStyle(
                          fontSize: 13,
                          fontFamily: SharePerksFonts.inter,
                          color: SharePerksColors.textSecondaryLight,
                        ),
                        headerStyle: TextStyle(
                          fontSize: 13,
                          fontFamily: SharePerksFonts.inter,
                          fontWeight: FontWeight.w500,
                          color: SharePerksColors.textPrimaryLight,
                        ),
                        expandedShadow: SharePerksShadows.md,
                        searchFieldDecoration: SearchFieldDecoration(
                          fillColor: SharePerksColors.surfaceLight,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          hintStyle: TextStyle(
                            fontSize: 13,
                            fontFamily: SharePerksFonts.inter,
                            color: SharePerksColors.textSecondaryLight,
                          ),
                          textStyle: TextStyle(
                            fontSize: 13,
                            fontFamily: SharePerksFonts.inter,
                            color: SharePerksColors.textPrimaryLight,
                          ),
                          prefixIcon: Icon(
                            HugeIconsSolid.search01,
                            size: 18,
                            color: SharePerksColors.textSecondaryLight,
                          ),
                          // No inner outline — outer container/overlay border only.
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                      futureRequest: _searchCompanies,
                      hintText: 'Search company',
                      searchHintText: 'Type to search',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Select a company from the list';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() => _selectedCompany = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Details', style: labelStyle),
                const SizedBox(height: 4),
                Text(
                  'Brand, amount, or anything else we should know',
                  style: hintStyle,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _detailsController,
                  minLines: 4,
                  maxLines: 6,
                  textInputAction: TextInputAction.done,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: SharePerksFonts.inter,
                    color: SharePerksColors.textPrimaryLight,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Amazon ₹500 gift card, or 10% off on Swiggy',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      fontFamily: SharePerksFonts.inter,
                      color: SharePerksColors.textSecondaryLight,
                    ),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: SharePerksColors.inputFillLight,
                    contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: SharePerksColors.inputBorderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: SharePerksColors.inputBorderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: SharePerksColors.primary,
                        width: 1.2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: SharePerksColors.error),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please add a short description';
                    }
                    if (v.trim().length < 8) {
                      return 'Please add a bit more detail (8+ characters)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit request'),
            ),
          ),
        ),
      ),
    );
  }
}

class _PerkTypeOption {
  const _PerkTypeOption({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

class _RequestIntroCard extends StatelessWidget {
  const _RequestIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SharePerksColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SharePerksColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SharePerksColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              HugeIconsSolid.note01,
              size: 20,
              color: SharePerksColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tell us what you want',
                  style: TextStyle(
                    color: SharePerksColors.textPrimaryLight,
                    fontSize: 15,
                    fontFamily: SharePerksFonts.albertSans,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We’ll review your request and try to add matching perks.',
                  style: TextStyle(
                    color: SharePerksColors.textSecondaryLight,
                    fontSize: 12,
                    fontFamily: SharePerksFonts.inter,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
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

class _PerkTypeChip extends StatelessWidget {
  const _PerkTypeChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _PerkTypeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? SharePerksColors.primary
        : SharePerksColors.textSecondaryLight;
    return Material(
      color: selected
          ? SharePerksColors.primary.withValues(alpha: 0.08)
          : SharePerksColors.inputFillLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? SharePerksColors.primary.withValues(alpha: 0.45)
                  : SharePerksColors.inputBorderLight,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(option.icon, size: 22, color: fg),
              const SizedBox(height: 6),
              Text(
                option.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: SharePerksFonts.albertSans,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? SharePerksColors.textPrimaryLight
                      : SharePerksColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
