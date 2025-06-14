import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../screens/home_screen.dart';

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
  String _selectedGender = 'male';

  // Form keys
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

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
                : theme.colorScheme.surfaceVariant,
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

    return Padding(
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
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: locals.name,
                prefixIcon: const Icon(Icons.person),
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
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return locals.pleaseEnterAge;
                }
                final age = int.tryParse(value);
                if (age == null || age < 1 || age > 120) {
                  return 'Please enter a valid age';
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
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
              validator: (value) {
                if (value == null) {
                  return locals.pleaseSelectGender;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    final locals = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
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
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: locals.enterHeight,
                prefixIcon: const Icon(Icons.height),
                suffixText: locals.cm,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Weight and height are optional but help provide better health insights.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
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

  Widget _buildStep3() {
    final locals = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Profile Setup Complete!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your profile has been set up successfully. You can now start tracking your health data.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What you can track:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.favorite, locals.bloodPressure),
                  _buildFeatureItem(Icons.water_drop, locals.bloodSugar),
                  _buildFeatureItem(
                      Icons.directions_walk, locals.dailyActivity),
                  _buildFeatureItem(Icons.medication, locals.medications),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final locals = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: Text(locals.previous),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep == 2 ? _finishSetup : _nextStep,
              child: Text(_currentStep == 2 ? locals.finish : locals.next),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0 && !_step1Key.currentState!.validate()) {
      return;
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

    if (!_step1Key.currentState!.validate()) {
      setState(() {
        _currentStep = 0;
      });
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final user = User(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text),
      gender: _selectedGender,
      weight: _weightController.text.isEmpty
          ? null
          : double.tryParse(_weightController.text),
      height: _heightController.text.isEmpty
          ? null
          : double.tryParse(_heightController.text),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await userProvider.createUser(user);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(locals.profileCreatedSuccessfully)),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
