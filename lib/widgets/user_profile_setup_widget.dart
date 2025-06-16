import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health_life/screens/home_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import '../providers/user_provider.dart';

class UserProfileSetup extends StatefulWidget {
  final bool isDialog;
  final User? userToEdit;

  const UserProfileSetup({Key? key, this.isDialog = false, this.userToEdit})
      : super(key: key);

  @override
  State<UserProfileSetup> createState() => _UserProfileSetupState();
}

class _UserProfileSetupState extends State<UserProfileSetup> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  File? _pickedImageFile; // Holds the actual file selected
  String? _userPhotoPath; // Holds the path string to save in the database
  String? _selectedGender;

  // Form keys
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with userToEdit data if available
    if (widget.userToEdit != null) {
      _nameController.text = widget.userToEdit!.name;
      _ageController.text = widget.userToEdit!.age.toString();
      _selectedGender = widget.userToEdit!.gender;
      _weightController.text = widget.userToEdit!.weight?.toString() ?? '';
      _heightController.text = widget.userToEdit!.height?.toString() ?? '';
      _userPhotoPath = widget.userToEdit!.photoPath;
      if (_userPhotoPath != null && _userPhotoPath!.isNotEmpty) {
        _pickedImageFile =
            File(_userPhotoPath!); // Create File object if path exists
      }
    } else {
      _selectedGender = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locals = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final locals = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            locals.userProfileSetup,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStepIndicator(0, locals.stepOneOfThree)),
              Expanded(child: _buildStepIndicator(1, locals.stepTwoOfThree)),
              Expanded(child: _buildStepIndicator(2, locals.stepThreeOfThree)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final theme = Theme.of(context);
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
          ),
          child: Icon(
            isCompleted ? Icons.check : Icons.circle,
            color: isCompleted || isActive
                ? Colors.white
                : theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStep1() {
    final locals = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _step1Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locals.basicInformation,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceSelection,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    backgroundImage: _pickedImageFile != null
                        ? FileImage(_pickedImageFile!)
                        : null,
                    child: _pickedImageFile == null
                        ? Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Center(
                child: TextButton.icon(
                  onPressed: _showImageSourceSelection,
                  label: Text(locals.uploadPhoto),
                  icon: Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: locals.name,
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return locals.pleaseEnterName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: locals.age,
                  prefixIcon: const Icon(Icons.cake),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return locals.pleaseEnterAge;
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 1 || age > 120) {
                    return 'Please enter a valid age (1-120)'; // More descriptive
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: locals.gender,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'male',
                    child: Text(locals.male),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text(locals.female),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(locals.other),
                  ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return locals.pleaseSelectGender;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // New method for picking and saving image ....
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      //   Get the application's document directory for persistent storage
      final appDir = await getApplicationDocumentsDirectory();
      //   Create a specific sub-directory for user photos
      final photosDir = Directory('${appDir.path}/user_photos');
      // Ensure the directory exists
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      //   Generate a unique file name
      final String fileName =
          '${DateTime.now().microsecondsSinceEpoch}_${const Uuid().v4()}${p.extension(image.path)}';
      final String newPath = p.join(photosDir.path, fileName);
      try {
        final File newImageFile = await File(image.path).copy(newPath);
        setState(() {
          _pickedImageFile = newImageFile;
          _userPhotoPath = newImageFile.path;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving image : ${e.toString()}'),
            ),
          );
        }
      }
    }
  }

  Future<void> _showImageSourceSelection() async {
    final locals = AppLocalizations.of(context);
    await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text(locals!.photoLibrary),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: Text(locals.camera),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                // if(_pickedImageFile != null)
                //   ListTile(
                //     leading: const Icon(Icons.delete,color: Colors.red,),
                //     title: Text(locals.removePhoto,style: const TextStyle(color: Colors.red),),
                //     onTap: (){
                //       setState(() {
                //         _pickedImageFile = null;
                //         _userPhotoPath = null;
                //       });
                //       Navigator.pop(context);
                //     },
                //   ),
              ],
            ),
          );
        });
  }

  Widget _buildStep2() {
    final locals = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _step2Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locals.healthInformation,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: locals.enterWeight,
                  prefixIcon: const Icon(Icons.fitness_center),
                  suffixText: locals.kg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  // Weight is optional, so only validate if value is NOT empty
                  if (value != null && value.trim().isNotEmpty) {
                    final weight =
                        double.tryParse(value); // Use double.tryParse
                    if (weight == null || weight < 1 || weight > 500) {
                      // More realistic weight range
                      return 'Please enter a valid weight (1-500 kg)';
                    }
                  }
                  return null; // Return null if empty (optional) or valid
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _heightController,
                decoration: InputDecoration(
                  labelText: locals.enterHeight,
                  prefixIcon: const Icon(Icons.height),
                  suffixText: locals.cm,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  // Height is optional, so only validate if value is NOT empty
                  if (value != null && value.trim().isNotEmpty) {
                    final height =
                        double.tryParse(value); // Use double.tryParse
                    if (height == null || height < 50 || height > 250) {
                      // More realistic height range
                      return 'Please enter a valid height (50-250 cm)';
                    }
                  }
                  return null; // Return null if empty (optional) or valid
                },
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please enter correct weight and height for better Health Care!',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep3() {
    final locals = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locals.preferences,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Profile Setup Complete!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your profile has been set up successfully. You can now start tracking your health data and managing your well-being!',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What you can track with HealthWave:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                        Icons.monitor_heart, locals.bloodPressure),
                    _buildFeatureItem(Icons.bloodtype, locals.bloodSugar),
                    _buildFeatureItem(
                        Icons.directions_run, locals.dailyActivity),
                    _buildFeatureItem(
                        Icons.medical_services, locals.medications),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final locals = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                child: Text(
                  locals.previous,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep == 2 ? _finishSetup : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              child: Text(
                _currentStep == 2 ? locals.finish : locals.next,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    // Validate Step 1 before proceeding
    if (_currentStep == 0) {
      if (_step1Key.currentState == null ||
          !_step1Key.currentState!.validate()) {
        return;
      }
    }
    // Validate Step 2 before proceeding
    // Note: The validators in _buildStep2 are now updated to handle optional fields correctly.
    if (_currentStep == 1) {
      if (_step2Key.currentState == null ||
          !_step2Key.currentState!.validate()) {
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishSetup() async {
    final locals = AppLocalizations.of(context)!;
    bool validationPassed = true;
    // Re-validate Step 1 form one last time before saving
    if (_step1Key.currentState != null && !_step1Key.currentState!.validate()) {
      validationPassed = false;
      // Optionally show a more specific error for Step 1
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locals.pleaseCorrectErrorsInStepOne),
            // You'll need to add this string to your app_en.arb
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    // Re-validate Step 2 form (optional fields are now correctly handled by their validators)
    if (_step2Key.currentState == null || !_step2Key.currentState!.validate()) {
      validationPassed = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locals.pleaseCorrectErrorsInStepTwo),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (!validationPassed) {
      // if (mounted) {
      //   Navigator.of(context).pushReplacement(
      //     MaterialPageRoute(
      //       builder: (_) => const HomeScreen(),
      //     ),
      //   );
      // }
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Safely parse values.
    // .trim() is added for robustness against leading/trailing spaces.
    final int? ageParsed = int.tryParse(_ageController.text.trim());
    final double? weightParsed = double.tryParse(_weightController.text.trim());
    final double? heightParsed = double.tryParse(_heightController.text.trim());

    // Debugging print statements (remove in production)
    // print('Age Controller Text: "${_ageController.text.trim()}"');
    // print('Age Parsed: $ageParsed');
    // print('Weight Controller Text: "${_weightController.text.trim()}"');
    // print('Weight Parsed: $weightParsed');
    // print('Height Controller Text: "${_heightController.text.trim()}"');
    // print('Height Parsed: $heightParsed');

    final user = User(
      id: widget.userToEdit?.id ?? const Uuid().v4(),
      // Use const Uuid().v4()
      name: _nameController.text.trim(),
      age: ageParsed ?? 0,
      // Fallback to 0 if age parsing fails (though validator should prevent it)
      gender: _selectedGender ?? 'other',
      // Should always be non-null due to DropdownButtonFormField
      weight: weightParsed,
      // Correctly null if text is empty or invalid
      height: heightParsed,
      // Correctly null if text is empty or invalid
      photoPath: _userPhotoPath,
      // Pass the saved photo path
      createdAt: widget.userToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.userToEdit == null) {
        await userProvider.createUser(user);
      } else {
        await userProvider.updateUser(user);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locals.profileCreatedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        // Only navigate home if setup is successful or intended to be completed
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      }
    }
  }
}
