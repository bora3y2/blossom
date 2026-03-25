import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_session.dart';
import '../../core/image_utils.dart';
import '../../core/theme.dart';
import '../../models/location_models.dart';
import '../../models/profile_models.dart';
import '../../repositories/location_repository.dart';
import '../../repositories/profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _didLoad = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  ProfileModel? _profile;

  late TextEditingController _nameController;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Location state
  List<CountryModel> _countries = [];
  List<StateModel> _states = [];
  int? _selectedCountryId;
  int? _selectedStateId;
  bool _loadingStates = false;

  ProfileRepository _repository(BuildContext context) {
    return ProfileRepository(AppSessionScope.of(context));
  }

  LocationRepository _locationRepo(BuildContext context) {
    return LocationRepository(AppSessionScope.of(context));
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profileRepo = _repository(context);
      final locationRepo = _locationRepo(context);
      final results = await Future.wait([
        profileRepo.fetchMyProfile(),
        locationRepo.fetchCountries(),
      ]);
      final profile = results[0] as ProfileModel;
      final countries = results[1] as List<CountryModel>;

      List<StateModel> states = [];
      if (profile.countryId != null) {
        try {
          states = await locationRepo.fetchStates(profile.countryId!);
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameController.text = profile.displayName ?? '';
        _countries = countries;
        _states = states;
        _selectedCountryId = profile.countryId;
        _selectedStateId = profile.stateId;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _onCountryChanged(int? countryId) async {
    setState(() {
      _selectedCountryId = countryId;
      _selectedStateId = null;
      _states = [];
      _loadingStates = countryId != null;
    });
    if (countryId == null) return;
    final repo = _locationRepo(context);
    try {
      final states = await repo.fetchStates(countryId);
      if (!mounted) return;
      setState(() {
        _states = states;
        _loadingStates = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStates = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = _repository(context);

      if (_selectedImage != null) {
        await repo.updateAvatar(_selectedImage!);
      }

      final newName = _nameController.text.trim();
      final nameChanged = newName.isNotEmpty && newName != _profile?.displayName;
      final countryChanged = _selectedCountryId != _profile?.countryId;
      final stateChanged = _selectedStateId != _profile?.stateId;

      if (nameChanged || countryChanged || stateChanged) {
        await repo.updateMyProfile(
          displayName: nameChanged ? newName : null,
          countryId: countryChanged ? _selectedCountryId : null,
          stateId: stateChanged ? _selectedStateId : null,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _profile == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(title: const Text('Edit Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadProfile();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            Center(
              child: GestureDetector(
                onTap: _isSaving ? null : _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          width: 4,
                        ),
                      ),
                      child: ClipOval(
                        child: _selectedImage != null
                            ? FutureBuilder<Uint8List>(
                                future: _selectedImage!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              )
                            : CachedNetworkImage(
                                imageUrl: resolveAvatarImageUrl(
                                  _profile?.avatarPath,
                                ),
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Country dropdown
            DropdownButtonFormField<int>(
              initialValue: _selectedCountryId,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select country'),
              items: _countries.map((c) {
                return DropdownMenuItem<int>(
                  value: c.id,
                  child: Text(c.name),
                );
              }).toList(),
              onChanged: _isSaving
                  ? null
                  : (value) => _onCountryChanged(value),
            ),
            if (_selectedCountryId != null) ...[
              const SizedBox(height: 16),
              _loadingStates
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      // key forces rebuild when country changes so selection resets
                      key: ValueKey('state_$_selectedCountryId'),
                      initialValue: _selectedStateId,
                      decoration: const InputDecoration(
                        labelText: 'State / City',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select state'),
                      items: _states.map((s) {
                        return DropdownMenuItem<int>(
                          value: s.id,
                          child: Text(s.name),
                        );
                      }).toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) => setState(() => _selectedStateId = value),
                    ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
