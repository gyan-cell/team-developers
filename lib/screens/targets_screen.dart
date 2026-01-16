import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/target.dart';
import '../services/api_service.dart';
import '../providers/scan_provider.dart';
import '../widgets/animations.dart';

class TargetsScreen extends StatefulWidget {
  const TargetsScreen({super.key});

  @override
  State<TargetsScreen> createState() => _TargetsScreenState();
}

class _TargetsScreenState extends State<TargetsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();

  List<Target> _targets = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  late AnimationController _animController;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadTargets();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadTargets() async {
    setState(() => _isLoading = true);
    // Simulate loading existing targets
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _targets = [
        Target(
          id: '1',
          name: 'Example API',
          url: 'https://api.example.com',
          lastScanned: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Target(
          id: '2',
          name: 'Dashboard App',
          url: 'https://dashboard.myapp.io',
          lastScanned: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Target(
          id: '3',
          name: 'Auth Service',
          url: 'https://auth.service.net',
          lastScanned: null,
        ),
      ];
      _isLoading = false;
    });
    _animController.reset();
    _animController.forward();
    _refreshKey++;
  }

  Future<void> _submitTarget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final url = _urlController.text.trim();

    try {
      // Send to API
      final response = await ApiService.startScan(url);

      // Save scan result to provider
      final scanResult = ScanResult.fromScanResponse(response, url);
      if (mounted) {
        context.read<ScanProvider>().addScan(scanResult);
      }

      // Extract domain name from URL for display
      final name = _extractDomainName(url);

      final newTarget = Target(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        url: url,
        lastScanned: DateTime.now(),
      );

      setState(() {
        _targets.insert(0, newTarget);
        _isSubmitting = false;
      });

      _urlController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan started! ID: ${scanResult.scanId}'),
            backgroundColor: AppTheme.severityLow,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.severityHigh,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a URL';
    }
    final urlPattern = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    if (!urlPattern.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  String _extractDomainName(String url) {
    try {
      String cleanUrl = url.trim();
      if (!cleanUrl.startsWith('http')) {
        cleanUrl = 'https://$cleanUrl';
      }
      final uri = Uri.parse(cleanUrl);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (_) {
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Targets'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTargets),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentCyan),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlideUp(
                    key: ValueKey('form-$_refreshKey'),
                    delay: Duration.zero,
                    child: _buildAddTargetForm(),
                  ),
                  const SizedBox(height: 24),
                  SlideUp(
                    key: ValueKey('list-$_refreshKey'),
                    delay: const Duration(milliseconds: 100),
                    child: _buildTargetsList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAddTargetForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.accentCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add New Target',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _urlController,
                validator: _validateUrl,
                keyboardType: TextInputType.url,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Target URL',
                  hintText: 'https://example.com',
                  prefixIcon: const Icon(Icons.link),
                  filled: true,
                  fillColor: AppTheme.bgPrimary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppTheme.accentCyan,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.severityHigh),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTarget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentCyan,
                    foregroundColor: AppTheme.bgPrimary,
                    disabledBackgroundColor: AppTheme.accentCyan.withAlpha(100),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.bgPrimary,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 8),
                            Text(
                              'Add Target',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Existing Targets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '${_targets.length} targets',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_targets.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.track_changes,
                      size: 48,
                      color: AppTheme.textSecondary.withAlpha(100),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No targets yet',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _targets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final target = _targets[index];
              return _buildTargetCard(target);
            },
          ),
      ],
    );
  }

  Widget _buildTargetCard(Target target) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.accentPurple.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.language,
            color: AppTheme.accentPurple,
            size: 24,
          ),
        ),
        title: Text(
          target.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              target.url,
              style: const TextStyle(color: AppTheme.accentCyan, fontSize: 13),
            ),
            if (target.lastScanned != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last scanned: ${_formatDate(target.lastScanned!)}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
          onSelected: (value) {
            if (value == 'scan') {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Starting scan...')));
            } else if (value == 'delete') {
              setState(() => _targets.remove(target));
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'scan', child: Text('Start Scan')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
