import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:shareperks/components/BackButton.dart';
import 'package:shareperks/constants/assets.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:shareperks/repository/models/profile_model.dart';
import 'package:shareperks/repository/providers/user.provider.dart';
import 'package:shareperks/repository/services/auth/user_model.dart';
import 'package:shareperks/repository/services/files/files.service.dart';
import 'package:shareperks/repository/services/profile/profile.service.dart';
import 'package:shareperks/utils/image_url.dart';
import 'package:soui/elements/ImageBuilder.dart';
import 'package:soui/elements/SpScafold.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDob;

  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;

  /// Synchronous mutex so two native picker calls cannot overlap (iOS:
  /// `multiple_request`).
  bool _pickGate = false;

  String? _imageUrl;

  /// Local file path of an image the user just picked, shown as a preview
  /// while the upload + PATCH is in flight. Cleared once the server URL
  /// arrives.
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Pre-fill from cached UserProvider so the form renders instantly.
    final cached = context.read<UserProvider>().user;
    if (cached != null) {
      _applyUser(cached);
    }
    // Then refresh from the server in the background.
    try {
      final profile = await ProfileService.getProfile();
      if (!mounted) return;
      _applyProfile(profile);
      _syncProvider(profile);
    } catch (_) {
      // Soft-fail: keep cached values; user can still edit + save.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _applyUser(UserModel u) {
    final parts = _splitName(u.name);
    _firstNameController.text = parts.$1;
    _lastNameController.text = parts.$2;
    _mobileController.text = _stripCountryCode(u.mobile ?? '');
    _emailController.text = u.email ?? '';
    final dob = _parseDob(u.dob);
    if (dob != null) {
      _selectedDob = dob;
      _dobController.text = _formatDob(dob);
    }
    _imageUrl = u.image;
  }

  void _applyProfile(Profile p) {
    final parts = _splitName(p.name);
    _firstNameController.text = parts.$1;
    _lastNameController.text = parts.$2;
    _mobileController.text = _stripCountryCode(p.mobile ?? '');
    _emailController.text = p.email ?? '';
    final dob = _parseDob(p.dob);
    if (dob != null) {
      _selectedDob = dob;
      _dobController.text = _formatDob(dob);
    } else {
      _dobController.text = '';
      _selectedDob = null;
    }
    setState(() {
      _imageUrl = p.image;
    });
  }

  void _syncProvider(Profile p) {
    final provider = context.read<UserProvider>();
    final current = provider.user;
    if (current == null) return;
    current
      ..name = p.name ?? current.name
      ..email = p.email ?? current.email
      ..mobile = p.mobile ?? current.mobile
      ..dob = p.dob ?? current.dob
      ..image = p.image ?? current.image;
    provider.setUser(current);
  }

  /// Splits `"Sourav Das"` -> `("Sourav", "Das")`. Empty parts allowed.
  (String, String) _splitName(String? full) {
    final s = (full ?? '').trim();
    if (s.isEmpty) return ('', '');
    final i = s.indexOf(' ');
    if (i < 0) return (s, '');
    return (s.substring(0, i), s.substring(i + 1).trim());
  }

  String _stripCountryCode(String mobile) {
    var m = mobile.trim();
    if (m.startsWith('+91')) m = m.substring(3);
    if (m.startsWith('91') && m.length > 10) m = m.substring(2);
    if (m.startsWith('0') && m.length == 11) m = m.substring(1);
    return m;
  }

  String _formatDob(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  DateTime? _parseDob(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _pickDob(BuildContext context) async {
    final now = DateTime.now();
    final initial = _selectedDob ?? DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );

    if (picked == null) return;
    setState(() {
      _selectedDob = picked;
      _dobController.text = _formatDob(picked);
    });
  }

  Future<FilePickerResult?> _openImagePicker() {
    return FilePicker.pickFiles(
      type: FileType.image,
      withData: false,
      compressionQuality: 0,
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_pickGate || _uploadingAvatar || _saving) return;
    _pickGate = true;

    try {
      // Let native transitions settle so the picker isn't double-invoked.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;

      FilePickerResult? result;
      try {
        result = await _openImagePicker();
      } on PlatformException catch (e) {
        if (e.code != 'multiple_request') rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        result = await _openImagePicker();
      }

      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      final path = picked.path;
      if (path == null || path.isEmpty) {
        _toast('Could not read the selected image.', error: true);
        return;
      }

      if (!mounted) return;
      setState(() {
        _localImagePath = path;
        _uploadingAvatar = true;
      });

      // Upload bytes -> get { url, key } -> PATCH /profile with the URL.
      // The server's Zod validator requires a full https URL on `image`.
      // `UploadedFile.key` is still surfaced for callers that may want the
      // bare bucket-relative path later (e.g. signed download flows).
      final uploaded = await FileUploadService.uploadFile(path);
      final updated = await ProfileService.updateProfile(
        ProfileUpdate(image: uploaded.key),
      );
      if (!mounted) return;
      _applyProfile(updated);
      _syncProvider(updated);
      setState(() {
        _localImagePath = null;
      });
      _toast('Profile photo updated.', error: false);
    } on PlatformException catch (e) {
      if (e.code == 'multiple_request') return;
      if (!mounted) return;
      setState(() => _localImagePath = null);
      _toast('Could not pick image: ${e.message ?? e.code}', error: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _localImagePath = null);
      _toast(_extractError(e), error: true);
    } finally {
      _pickGate = false;
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  bool _validate() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    if (first.isEmpty) {
      _toast('Please enter your first name.', error: true);
      return false;
    }
    if ('$first $last'.trim().length < 2) {
      _toast('Name must be at least 2 characters.', error: true);
      return false;
    }
    if (email.isEmpty || !email.contains('@')) {
      _toast('Please enter a valid email.', error: true);
      return false;
    }
    // Mobile is the auth identity (OTP login) and is not user-editable from
    // this screen, so we don't validate or PATCH it here.
    return true;
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_validate()) return;

    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final fullName = last.isEmpty ? first : '$first $last';

    final patch = ProfileUpdate(
      name: fullName,
      email: _emailController.text.trim(),
      dob: _selectedDob != null ? _formatDob(_selectedDob!) : null,
    );

    setState(() => _saving = true);
    try {
      final updated = await ProfileService.updateProfile(patch);
      if (!mounted) return;
      _applyProfile(updated);
      _syncProvider(updated);
      _toast('Profile updated.', error: false);
      // Pop back to the previous screen on success.
      if (context.canPop()) context.pop();
    } catch (e) {
      if (!mounted) return;
      _toast(_extractError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _extractError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (e.response?.statusCode == 409) return 'Already in use.';
      if (e.response?.statusCode == 400) return 'Please check your details.';
    }
    return 'Could not update profile. Please try again.';
  }

  void _toast(String msg, {required bool error}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: error ? Colors.red : Colors.green,
      textColor: Colors.white,
    );
  }

  Widget _buildAvatar() {
    const size = 100.0;
    final hasLocal = _localImagePath != null;
    final hasRemote = (_imageUrl ?? '').isNotEmpty;

    final Widget image;
    if (hasLocal) {
      image = ClipOval(
        child: Image.file(
          File(_localImagePath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (hasRemote) {
      image = ImageBuilder(
        imageUrl: imageUrl(_imageUrl!),
        width: size,
        height: size,
        borderRadius: size,
      );
    } else {
      image = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, size: 48, color: Color(0xFFB0B0B0)),
      );
    }

    return GestureDetector(
      onTap: (_uploadingAvatar || _saving) ? null : _pickAndUploadAvatar,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Positioned.fill(child: image),
            if (_uploadingAvatar)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0x66000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: SharePerksColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  HugeIconsSolid.camera02,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpScafold(
      appBar: AppBar(
        leading: AppBackButton(),
        title: Text("Profile Details"),
        toolbarHeight: 40,
        actions: [
          Image.asset(Assets.ASSETS_ICONS_APP_BRAND_PNG, height: 17),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(
                  vertical: 25,
                  horizontal: 16,
                ),
                decoration: ShapeDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.43),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 28.80,
                      offset: Offset(0, 3.46),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Center(child: _buildAvatar()),
                    SizedBox(height: 20),
                    Row(
                      spacing: 10,
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: 'First Name',
                            child: TextField(
                              controller: _firstNameController,
                              textCapitalization: TextCapitalization.words,
                              enabled: !_saving,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _LabeledField(
                            label: 'Last Name',
                            child: TextField(
                              controller: _lastNameController,
                              textCapitalization: TextCapitalization.words,
                              enabled: !_saving,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Mobile is the OTP-login identity and intentionally not
                    // editable from this screen.
                    _LabeledField(
                      label: 'Email ID',
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_saving,
                      ),
                    ),
                    _LabeledField(
                      label: 'Date of Birth',
                      child: TextField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: _saving ? null : () => _pickDob(context),
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            onPressed: _saving ? null : () => _pickDob(context),
                            icon: Icon(
                              HugeIconsSolid.calendar02,
                              color: SharePerksColors.borderDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Center(
                      child: OutlinedButton(
                        onPressed: (_loading || _saving) ? null : _submit,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Update Profile Details"),
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 3,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF898989),
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
        child,
      ],
    );
  }
}
