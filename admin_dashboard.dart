/**
*Student Number: 218009030, 220049798, 220033640, 222057332, 221002961.
*Student Name: TA RASEGO, LONWABO SIFUMBA, BN NGALO, TC LAAT, TC RADEBE.
*Question: 
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sa_apply/providers/auth_provider.dart';
import 'package:sa_apply/models/application_model.dart';
import 'package:sa_apply/core/constants/app_routes.dart';
import 'package:sa_apply/services/application_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<ApplicationModel> _allApplications = [];
  List<ApplicationModel> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _statusFilter = 'all';
  final _searchController = TextEditingController();
  final ApplicationService _service = ApplicationService();

  @override
  void initState() {
    super.initState();
    _fetchAll();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final apps = await _service.getAllApplications();
      setState(() {
        _allApplications = apps;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load applications.';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _allApplications.where((app) {
        final matchesStatus =
            _statusFilter == 'all' || app.status == _statusFilter;
        final matchesSearch = query.isEmpty ||
            app.studentNumber.toLowerCase().contains(query) ||
            app.module1Name.toLowerCase().contains(query) ||
            (app.module2Name?.toLowerCase().contains(query) ?? false);
        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  Future<void> _updateStatus(ApplicationModel app, String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          status == 'approved'
              ? Icons.check_circle_outline_rounded
              : Icons.cancel_outlined,
          size: 40,
          color: status == 'approved'
              ? Colors.green
              : Theme.of(context).colorScheme.error,
        ),
        title:
            Text('${status == 'approved' ? 'Approve' : 'Reject'} Application'),
        content: Text(
          'Are you sure you want to ${status == 'approved' ? 'approve' : 'reject'} '
          'the application from student ${app.studentNumber}?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: status == 'approved'
                  ? Colors.green
                  : Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(status == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.updateStatus(app.id, status);
      setState(() {
        final index = _allApplications.indexWhere((a) => a.id == app.id);
        if (index != -1) _allApplications[index] = app.copyWith(status: status);
      });
      _applyFilter();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Application ${status == 'approved' ? 'approved' : 'rejected'}.'),
            behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Failed to update status.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _deleteApplication(ApplicationModel app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline_rounded,
            size: 40, color: Theme.of(context).colorScheme.error),
        title: const Text('Delete Application'),
        content: Text(
            'Remove the application from student ${app.studentNumber}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.adminDeleteApplication(app.id);
      setState(() => _allApplications.removeWhere((a) => a.id == app.id));
      _applyFilter();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Application deleted.'),
            behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Failed to delete.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = context.watch<AuthProvider>();

    final total = _allApplications.length;
    final pending = _allApplications.where((a) => a.status == 'pending').length;
    final approved =
        _allApplications.where((a) => a.status == 'approved').length;
    final rejected =
        _allApplications.where((a) => a.status == 'rejected').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: _fetchAll),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              await authProvider.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: colorScheme.error),
                      const SizedBox(height: 12),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                          onPressed: _fetchAll, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAll,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stats
                              Row(
                                children: [
                                  _StatCard(
                                      label: 'Total',
                                      count: total,
                                      color: colorScheme.primary),
                                  const SizedBox(width: 12),
                                  _StatCard(
                                      label: 'Pending',
                                      count: pending,
                                      color: Colors.orange),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _StatCard(
                                      label: 'Approved',
                                      count: approved,
                                      color: Colors.green),
                                  const SizedBox(width: 12),
                                  _StatCard(
                                      label: 'Rejected',
                                      count: rejected,
                                      color: colorScheme.error),
                                ],
                              ),
                              const SizedBox(height: 24),

                              
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText:
                                      'Search by student number or module...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded),
                                          onPressed: () {
                                            _searchController.clear();
                                            _applyFilter();
                                          })
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),

                            
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _FilterChip(
                                        label: 'All',
                                        selected: _statusFilter == 'all',
                                        onTap: () => setState(() {
                                              _statusFilter = 'all';
                                              _applyFilter();
                                            })),
                                    const SizedBox(width: 8),
                                    _FilterChip(
                                        label: 'Pending',
                                        selected: _statusFilter == 'pending',
                                        color: Colors.orange,
                                        onTap: () => setState(() {
                                              _statusFilter = 'pending';
                                              _applyFilter();
                                            })),
                                    const SizedBox(width: 8),
                                    _FilterChip(
                                        label: 'Approved',
                                        selected: _statusFilter == 'approved',
                                        color: Colors.green,
                                        onTap: () => setState(() {
                                              _statusFilter = 'approved';
                                              _applyFilter();
                                            })),
                                    const SizedBox(width: 8),
                                    _FilterChip(
                                        label: 'Rejected',
                                        selected: _statusFilter == 'rejected',
                                        color: colorScheme.error,
                                        onTap: () => setState(() {
                                              _statusFilter = 'rejected';
                                              _applyFilter();
                                            })),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                  '${_filtered.length} application${_filtered.length == 1 ? '' : 's'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      if (_filtered.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 64,
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.4)),
                                const SizedBox(height: 16),
                                Text('No applications found',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            color:
                                                colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final app = _filtered[index];
                                return _AdminApplicationCard(
                                  application: app,
                                  onApprove: () =>
                                      _updateStatus(app, 'approved'),
                                  onReject: () =>
                                      _updateStatus(app, 'rejected'),
                                  onDelete: () => _deleteApplication(app),
                                );
                              },
                              childCount: _filtered.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatCard(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$count',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor : chipColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? chipColor : chipColor.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : chipColor,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }
}

class _AdminApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;
  const _AdminApplicationCard(
      {required this.application,
      required this.onApprove,
      required this.onReject,
      required this.onDelete});

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Theme.of(context).colorScheme.error;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_empty_rounded;
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = application.status;
    final statusColor = _statusColor(context, status);
    final isPending = status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Student: ${application.studentNumber}',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text('Year ${application.yearOfStudy}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status), size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(status[0].toUpperCase() + status.substring(1),
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.book_outlined,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        '${application.module1Name} (${application.module1Level})',
                        style: theme.textTheme.bodyMedium)),
              ],
            ),
            if (application.module2Name != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.book_outlined,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          '${application.module2Name} (${application.module2Level})',
                          style: theme.textTheme.bodyMedium)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_file_rounded,
                    size: 14,
                    color: application.documentUrl != null
                        ? Colors.green
                        : colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                    application.documentUrl != null
                        ? 'Document attached'
                        : 'No document',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: application.documentUrl != null
                            ? Colors.green
                            : colorScheme.onSurfaceVariant)),
                const Spacer(),
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(_formatDate(application.createdAt),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: Icon(Icons.close_rounded,
                          color: colorScheme.error, size: 18),
                      label: Text('Reject',
                          style: TextStyle(color: colorScheme.error)),
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: colorScheme.error.withOpacity(0.5))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve'),
                      style:
                          FilledButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded,
                  size: 16, color: colorScheme.error),
              label: Text('Remove',
                  style: TextStyle(color: colorScheme.error, fontSize: 12)),
              style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            ),
          ],
        ),
      ),
    );
  }
}
