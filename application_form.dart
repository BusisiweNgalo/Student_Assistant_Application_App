/**
*Student Number: 218009030, 220049798, 220033640, 222057332, 221002961.
*Student Name: TA RASEGO, LONWABO SIFUMBA, BN NGALO, TC LAAT, 221002961.
*Question: 
*/



import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sa_apply/providers/application_provider.dart';
import 'package:sa_apply/providers/auth_provider.dart';
import 'package:sa_apply/models/application_model.dart';

// ─── Static Data ───────────────────────────────────────────────────────────────
const List<String> kYearsOfStudy = ['1st Year', '2nd Year', '3rd Year'];

const List<String> kAcademicLevels = [
  'First Year',
  'Second Year',
  'Third Year'
];

const Map<String, List<String>> kModulesByLevel = {
  'First Year': [
    'Introduction to Programming',
    'Computer Fundamentals',
    'Mathematics for Computing',
    'Information Systems 1',
    'Web Development Basics',
  ],
  'Second Year': [
    'Data Structures & Algorithms',
    'Object-Oriented Programming',
    'Database Management',
    'Operating Systems',
    'Software Engineering',
  ],
  'Third Year': [
    'Artificial Intelligence',
    'Network Security',
    'Mobile Application Development',
    'Cloud Computing',
    'Capstone Project',
  ],
};

// ─── Screen ────────────────────────────────────────────────────────────────────
class ApplicationFormScreen extends StatefulWidget {
  const ApplicationFormScreen({super.key});

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appProvider = context.read<ApplicationProvider>();
      // Only block if applications have actually been loaded
      if (appProvider.status == ApplicationStatus.loaded &&
          appProvider.hasApplication) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already have a submitted application.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    });
  }

  // Personal
  String? _selectedYearOfStudy;

  // Module 1
  String? _module1Level;
  String? _module1Name;

  // Module 2
  bool _addSecondModule = false;
  String? _module2Level;
  String? _module2Name;

  // Eligibility & document
  bool _meetsRequirements = false;
  bool _confirmedEligibility = false;
  String? _uploadedDocumentUrl;
  bool _isUploading = false;
  String? _uploadedFileName;

  bool _isSubmitting = false;

  // ── Helpers ──────────────────────────────────────────────────────────────────

  List<String> _modulesFor(String? level) {
    if (level == null) return [];
    return kModulesByLevel[level] ?? [];
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      var bytes = file.bytes;

      if (bytes == null) {
        final path = file.path;
        if (path == null) {
          _showError('Could not read the selected file.');
          return;
        }
        bytes = await File(path).readAsBytes();
      }

      await _uploadBytes(bytes, file.name);
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to pick file: ${e.toString()}');
    }
  }

  Future<void> _uploadBytes(Uint8List bytes, String fileName) async {
    setState(() => _isUploading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$userId/${timestamp}_$fileName';

      await Supabase.instance.client.storage.from('documents').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(fileName),
              upsert: true,
            ),
          );

      setState(() {
        _uploadedFileName = fileName;
        _uploadedDocumentUrl = storagePath;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (!mounted) return;
      _showError('Upload failed: ${e.toString()}');
    }
  }

  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // One application per student rule
    final appProvider = context.read<ApplicationProvider>();
    if (appProvider.hasApplication) {
      _showError(
          'You have already submitted an application. Only one application is allowed per student.');
      return;
    }

    if (!_meetsRequirements) {
      _showError('Please confirm that you meet the minimum requirements.');
      return;
    }

    if (!_confirmedEligibility) {
      _showError('Please confirm your eligibility declaration.');
      return;
    }

    if (_uploadedDocumentUrl == null) {
      _showError('Please upload your supporting documentation.');
      return;
    }

    // Validate second module fields if added
    if (_addSecondModule) {
      if (_module2Level == null || _module2Name == null) {
        _showError('Please complete the second module selection or remove it.');
        return;
      }
      if (_module2Level == _module1Level && _module2Name == _module1Name) {
        _showError('Module 2 cannot be the same as Module 1.');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    context.read<ApplicationProvider>();

    final studentNumber =
        authProvider.user?.userMetadata?['student_number'] ?? '';
    final yearOfStudy = kYearsOfStudy.indexOf(_selectedYearOfStudy!) + 1;

    final application = ApplicationModel(
      id: '',
      userId: authProvider.user!.id,
      studentNumber: studentNumber,
      yearOfStudy: yearOfStudy,
      module1Level: _module1Level!,
      module1Name: _module1Name!,
      module2Level: _addSecondModule ? _module2Level : null,
      module2Name: _addSecondModule ? _module2Name : null,
      documentUrl: _uploadedDocumentUrl,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    final success = await appProvider.submitApplication(application);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          icon: Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Application Submitted!'),
          content: const Text(
            'Your Student Assistant application has been submitted successfully. '
            'You will be notified once it has been reviewed.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to home
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    } else {
      _showError(
          appProvider.errorMessage ?? 'Submission failed. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Assistant Application'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── Info Banner ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You may apply to assist with a maximum of two modules. '
                      'A second module is optional.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Section 1: Personal Information ─────────────────────────────
            const _SectionHeader(
              icon: Icons.person_outline_rounded,
              title: 'Personal Information',
              subtitle: 'Your current academic standing',
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedYearOfStudy,
              decoration: const InputDecoration(
                labelText: 'Current year of study',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: kYearsOfStudy
                  .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedYearOfStudy = val),
              validator: (val) =>
                  val == null ? 'Please select your year of study' : null,
            ),
            const SizedBox(height: 28),

            // ── Section 2: Module 1 ──────────────────────────────────────────
            const _SectionHeader(
              icon: Icons.book_outlined,
              title: 'Primary Module',
              subtitle: 'The main module you wish to assist with',
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _module1Level,
              decoration: const InputDecoration(
                labelText: 'Academic level',
                prefixIcon: Icon(Icons.layers_outlined),
              ),
              items: kAcademicLevels
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (val) => setState(() {
                _module1Level = val;
                _module1Name = null; // reset module when level changes
              }),
              validator: (val) =>
                  val == null ? 'Please select an academic level' : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _module1Name,
              decoration: InputDecoration(
                labelText: 'Module',
                prefixIcon: const Icon(Icons.menu_book_outlined),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              items: _modulesFor(_module1Level)
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: _module1Level == null
                  ? null
                  : (val) => setState(() => _module1Name = val),
              validator: (val) => val == null ? 'Please select a module' : null,
              hint: Text(
                _module1Level == null
                    ? 'Select a level first'
                    : 'Select a module',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 28),

            // ── Section 3: Module 2 (Optional) ──────────────────────────────
            const _SectionHeader(
              icon: Icons.add_box_outlined,
              title: 'Secondary Module',
              subtitle: 'Optional — maximum of two modules per application',
            ),
            const SizedBox(height: 12),

            Card(
              child: SwitchListTile(
                title: const Text('Add a second module'),
                subtitle: const Text('Optional — leave off if not needed'),
                value: _addSecondModule,
                onChanged: (val) => setState(() {
                  _addSecondModule = val;
                  if (!val) {
                    _module2Level = null;
                    _module2Name = null;
                  }
                }),
              ),
            ),

            if (_addSecondModule) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _module2Level,
                decoration: const InputDecoration(
                  labelText: 'Academic level (Module 2)',
                  prefixIcon: Icon(Icons.layers_outlined),
                ),
                items: kAcademicLevels
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (val) => setState(() {
                  _module2Level = val;
                  _module2Name = null;
                }),
                validator: (val) => _addSecondModule && val == null
                    ? 'Please select an academic level'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _module2Name,
                decoration: InputDecoration(
                  labelText: 'Module (Module 2)',
                  prefixIcon: const Icon(Icons.menu_book_outlined),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                items: _modulesFor(_module2Level)
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: _module2Level == null
                    ? null
                    : (val) => setState(() => _module2Name = val),
                validator: (val) => _addSecondModule && val == null
                    ? 'Please select a module'
                    : null,
                hint: Text(
                  _module2Level == null
                      ? 'Select a level first'
                      : 'Select a module',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // ── Section 4: Supporting Documentation ─────────────────────────
            const _SectionHeader(
              icon: Icons.upload_file_outlined,
              title: 'Supporting Documentation',
              subtitle:
                  'Upload your academic transcript or proof of eligibility',
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_uploadedFileName != null) ...[
                      Row(
                        children: [
                          Icon(Icons.description_outlined,
                              color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _uploadedFileName!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Document attached',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _uploadedFileName = null;
                              _uploadedDocumentUrl = null;
                            }),
                          ),
                        ],
                      ),
                    ] else ...[
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No document uploaded',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PDF, DOC or image files accepted',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickAndUploadDocument,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.attach_file_rounded),
                      label: Text(_isUploading
                          ? 'Uploading...'
                          : _uploadedFileName != null
                              ? 'Replace Document'
                              : 'Upload Document'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Section 5: Eligibility Declaration ──────────────────────────
            const _SectionHeader(
              icon: Icons.verified_outlined,
              title: 'Eligibility Declaration',
              subtitle: 'You must confirm both statements before submitting',
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _meetsRequirements,
                    onChanged: (val) =>
                        setState(() => _meetsRequirements = val ?? false),
                    title: const Text('I meet the minimum requirements'),
                    subtitle: const Text(
                      'I confirm that I meet the academic requirements for the '
                      'Student Assistant position for the selected module(s).',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  CheckboxListTile(
                    value: _confirmedEligibility,
                    onChanged: (val) =>
                        setState(() => _confirmedEligibility = val ?? false),
                    title: const Text('I declare this application is truthful'),
                    subtitle: const Text(
                      'I confirm that all information provided in this application '
                      'is accurate and complete to the best of my knowledge.',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit Button ────────────────────────────────────────────────
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label:
                  Text(_isSubmitting ? 'Submitting...' : 'Submit Application'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Section Header ───────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: colorScheme.onSecondaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
