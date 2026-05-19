import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sa_apply/models/application_model.dart';
import 'package:sa_apply/providers/application_provider.dart';
import 'package:sa_apply/core/constants/app_routes.dart';

// Reuse static data from form
const List<String> kDetailAcademicLevels = [
  'First Year',
  'Second Year',
  'Third Year'
];

const Map<String, List<String>> kDetailModulesByLevel = {
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

class ApplicationDetailScreen extends StatefulWidget {
  final ApplicationModel application;
  const ApplicationDetailScreen({super.key, required this.application});

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  // Edit controllers
  String? _editModule1Level;
  String? _editModule1Name;
  bool _editAddSecondModule = false;
  String? _editModule2Level;
  String? _editModule2Name;

  final _formKey = GlobalKey<FormState>();

  void _initEditState(ApplicationModel app) {
    _editModule1Level = app.module1Level;
    _editModule1Name = app.module1Name;
    _editAddSecondModule = app.module2Name != null;
    _editModule2Level = app.module2Level;
    _editModule2Name = app.module2Name;
  }

  List<String> _modulesFor(String? level) {
    if (level == null) return [];
    return kDetailModulesByLevel[level] ?? [];
  }

  Future<void> _handleSave(ApplicationModel app) async {
    if (!_formKey.currentState!.validate()) return;

    if (_editAddSecondModule) {
      if (_editModule2Level == null || _editModule2Name == null) {
        _showSnack('Please complete the second module or remove it.',
            isError: true);
        return;
      }
      if (_editModule2Level == _editModule1Level &&
          _editModule2Name == _editModule1Name) {
        _showSnack('Module 2 cannot be the same as Module 1.', isError: true);
        return;
      }
    }

    setState(() => _isSaving = true);

    final updates = {
      'module_1_level': _editModule1Level,
      'module_1_name': _editModule1Name,
      'module_2_level': _editAddSecondModule ? _editModule2Level : null,
      'module_2_name': _editAddSecondModule ? _editModule2Name : null,
    };

    final success = await context
        .read<ApplicationProvider>()
        .updateApplication(app.id, updates);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (success) _isEditing = false;
    });

    if (success) {
      _showSnack('Application updated successfully.');
    } else {
      _showSnack('Failed to update application.', isError: true);
    }
  }

  Future<void> _handleDelete(ApplicationModel app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.delete_outline_rounded,
          size: 40,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Delete Application'),
        content: const Text(
          'Are you sure you want to delete this application? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    final success =
        await context.read<ApplicationProvider>().deleteApplication(app.id);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.studentHome);
    } else {
      setState(() => _isDeleting = false);
      _showSnack('Failed to delete application.', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPending = app.status == 'pending';

    // Init edit state once
    if (_editModule1Level == null) _initEditState(app);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        actions: [
          if (isPending && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit application',
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (isPending && _isEditing)
            TextButton(
              onPressed: () => setState(() {
                _isEditing = false;
                _initEditState(app); // reset changes
              }),
              child: const Text('Cancel'),
            ),
        ],
      ),
      body: _isDeleting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Deleting application...'),
                ],
              ),
            )
          : _isEditing
              ? _buildEditForm(app, theme, colorScheme)
              : _buildDetailView(app, theme, colorScheme, isPending),
    );
  }

  // ── Detail View ───────────────────────────────────────────────────────────────
  Widget _buildDetailView(
    ApplicationModel app,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isPending,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Status banner
        _StatusBanner(status: app.status),
        const SizedBox(height: 24),

        // Personal info
        _DetailSection(
          title: 'Personal Information',
          icon: Icons.person_outline_rounded,
          children: [
            _DetailRow(label: 'Student Number', value: app.studentNumber),
            _DetailRow(
              label: 'Year of Study',
              value: _yearLabel(app.yearOfStudy),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Module 1
        _DetailSection(
          title: 'Primary Module',
          icon: Icons.book_outlined,
          children: [
            _DetailRow(label: 'Academic Level', value: app.module1Level),
            _DetailRow(label: 'Module', value: app.module1Name),
          ],
        ),
        const SizedBox(height: 16),

        // Module 2
        if (app.module2Name != null) ...[
          _DetailSection(
            title: 'Secondary Module',
            icon: Icons.add_box_outlined,
            children: [
              _DetailRow(
                  label: 'Academic Level', value: app.module2Level ?? '-'),
              _DetailRow(label: 'Module', value: app.module2Name ?? '-'),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Document
        _DetailSection(
          title: 'Supporting Documentation',
          icon: Icons.upload_file_outlined,
          children: [
            _DetailRow(
              label: 'Document',
              value:
                  app.documentUrl != null ? 'Document attached' : 'No document',
              valueColor: app.documentUrl != null ? Colors.green : null,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Submitted date
        _DetailSection(
          title: 'Submission Info',
          icon: Icons.calendar_today_outlined,
          children: [
            _DetailRow(
                label: 'Date Submitted', value: _formatDate(app.createdAt)),
            _DetailRow(
                label: 'Application ID',
                value: app.id.substring(0, 8).toUpperCase()),
          ],
        ),
        const SizedBox(height: 32),

        // Delete button — only if pending
        if (isPending)
          OutlinedButton.icon(
            onPressed: () => _handleDelete(app),
            icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
            label: Text(
              'Delete Application',
              style: TextStyle(color: colorScheme.error),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: BorderSide(color: colorScheme.error),
            ),
          ),

        if (!isPending)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    color: colorScheme.onSurfaceVariant, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This application has been ${app.status} and can no longer be edited or deleted.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Edit Form ─────────────────────────────────────────────────────────────────
  Widget _buildEditForm(
      ApplicationModel app, ThemeData theme, ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded,
                    color: colorScheme.onTertiaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can update your module selections below. '
                    'Personal information cannot be changed.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Read-only personal info
          _DetailSection(
            title: 'Personal Information',
            icon: Icons.person_outline_rounded,
            children: [
              _DetailRow(label: 'Student Number', value: app.studentNumber),
              _DetailRow(
                  label: 'Year of Study', value: _yearLabel(app.yearOfStudy)),
            ],
          ),
          const SizedBox(height: 24),

          // Edit Module 1
          Text('Primary Module',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _editModule1Level,
            decoration: const InputDecoration(
              labelText: 'Academic level',
              prefixIcon: Icon(Icons.layers_outlined),
            ),
            items: kDetailAcademicLevels
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (val) => setState(() {
              _editModule1Level = val;
              _editModule1Name = null;
            }),
            validator: (val) =>
                val == null ? 'Please select an academic level' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _editModule1Name,
            decoration: const InputDecoration(
              labelText: 'Module',
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
            items: _modulesFor(_editModule1Level)
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: _editModule1Level == null
                ? null
                : (val) => setState(() => _editModule1Name = val),
            validator: (val) => val == null ? 'Please select a module' : null,
            hint: Text(
              _editModule1Level == null
                  ? 'Select a level first'
                  : 'Select a module',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),

          // Edit Module 2
          Text('Secondary Module',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: const Text('Include a second module'),
              value: _editAddSecondModule,
              onChanged: (val) => setState(() {
                _editAddSecondModule = val;
                if (!val) {
                  _editModule2Level = null;
                  _editModule2Name = null;
                }
              }),
            ),
          ),
          if (_editAddSecondModule) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _editModule2Level,
              decoration: const InputDecoration(
                labelText: 'Academic level (Module 2)',
                prefixIcon: Icon(Icons.layers_outlined),
              ),
              items: kDetailAcademicLevels
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (val) => setState(() {
                _editModule2Level = val;
                _editModule2Name = null;
              }),
              validator: (val) => _editAddSecondModule && val == null
                  ? 'Please select an academic level'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _editModule2Name,
              decoration: const InputDecoration(
                labelText: 'Module (Module 2)',
                prefixIcon: Icon(Icons.menu_book_outlined),
              ),
              items: _modulesFor(_editModule2Level)
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: _editModule2Level == null
                  ? null
                  : (val) => setState(() => _editModule2Name = val),
              validator: (val) => _editAddSecondModule && val == null
                  ? 'Please select a module'
                  : null,
              hint: Text(
                _editModule2Level == null
                    ? 'Select a level first'
                    : 'Select a module',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: _isSaving ? null : () => _handleSave(app),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _yearLabel(int year) {
    const labels = {1: '1st Year', 2: '2nd Year', 3: '3rd Year'};
    return labels[year] ?? '$year';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ─── Status Banner ─────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color bgColor;
    Color fgColor;
    IconData icon;
    String label;
    String description;

    switch (status) {
      case 'approved':
        bgColor = Colors.green.shade50;
        fgColor = Colors.green.shade700;
        icon = Icons.check_circle_rounded;
        label = 'Approved';
        description = 'Congratulations! Your application has been approved.';
        break;
      case 'rejected':
        bgColor = colorScheme.errorContainer;
        fgColor = colorScheme.onErrorContainer;
        icon = Icons.cancel_rounded;
        label = 'Rejected';
        description = 'Unfortunately your application was not successful.';
        break;
      default:
        bgColor = Colors.orange.shade50;
        fgColor = Colors.orange.shade700;
        icon = Icons.hourglass_top_rounded;
        label = 'Pending Review';
        description =
            'Your application is awaiting review by an administrator.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fgColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(color: fgColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Section ────────────────────────────────────────────────────────────
class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ─── Detail Row ────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
