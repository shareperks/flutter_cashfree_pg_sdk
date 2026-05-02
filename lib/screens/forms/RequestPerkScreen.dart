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
import 'package:soui/theme.dart';

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

  static const _perkTypes = <String, String>{
    'discount_code': 'Discount code',
    'cashback': 'Cashback',
    'giftcard': 'Gift card',
  };

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
      if (context.canPop())
        context.replaceNamed(RouteNames.EMAIL_SUCCESS_SCREEN);
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

    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: const Text('Request a Perk'),
        toolbarHeight: 40,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Perk type', style: labelStyle),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: _perkTypes.entries
                        .map(
                          (e) => ButtonSegment<String>(
                            value: e.key,
                            label: Text(
                              e.value,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                    selected: {_perkType},
                    onSelectionChanged: (next) {
                      setState(() => _perkType = next.first);
                    },
                    emptySelectionAllowed: false,
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Company name', style: labelStyle),
                  const SizedBox(height: 8),
                  DropdownFlutter<String>.searchRequest(
                    closedHeaderPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                    ),
                    decoration: CustomDropdownDecoration(
                      expandedBorder: Border.all(
                        width: 1,
                        color: AppColors.neutral200,
                      ),
                      listItemStyle: const TextStyle(fontSize: 13),
                      expandedShadow: <BoxShadow>[],
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
                  const SizedBox(height: 20),
                  Text('Details', style: labelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _detailsController,
                    minLines: 5,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText:
                          'Describe what you are looking for (brand, amount, etc.)',
                      alignLabelWithHint: true,
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: SizedBox(
            width: double.infinity,
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
