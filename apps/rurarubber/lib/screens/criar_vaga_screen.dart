import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/job_post.dart';

class CriarVagaScreen extends StatefulWidget {
  const CriarVagaScreen({super.key});

  @override
  State<CriarVagaScreen> createState() => _CriarVagaScreenState();
}

class _CriarVagaScreenState extends State<CriarVagaScreen> {
  final _formKey = GlobalKey<FormState>();
  JobType _selectedType = JobType.offeringWork;
  bool _isPublishing = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _percentageController = TextEditingController();
  final _treesController = TextEditingController();
  final _validityController = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = AuthService.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _municipalityController.dispose();
    _descriptionController.dispose();
    _percentageController.dispose();
    _treesController.dispose();
    _validityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final isOffering = _selectedType == JobType.offeringWork;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.criarVagaTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type selector
            Text(
              l10n.criarVagaTypeLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    type: JobType.offeringWork,
                    icon: Icons.work,
                    title: l10n.criarVagaTypeOffering,
                    subtitle: l10n.criarVagaTypeOfferingDesc,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeCard(
                    type: JobType.seekingWork,
                    icon: Icons.person_search,
                    title: l10n.criarVagaTypeSeeking,
                    subtitle: l10n.criarVagaTypeSeekingDesc,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.criarVagaNameLabel,
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.criarVagaNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: l10n.criarVagaPhoneLabel,
                prefixIcon: const Icon(Icons.phone),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.criarVagaPhoneRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Municipality
            TextFormField(
              controller: _municipalityController,
              decoration: InputDecoration(
                labelText: l10n.criarVagaMunicipalityLabel,
                hintText: l10n.criarVagaMunicipalityHint,
                prefixIcon: const Icon(Icons.location_city),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Job Details section (only for offering work)
            if (isOffering) ...[
              Text(
                l10n.criarVagaJobDetails,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              // Percentage offered
              TextFormField(
                controller: _percentageController,
                decoration: InputDecoration(
                  labelText: l10n.criarVagaPercentageLabel,
                  hintText: l10n.criarVagaPercentageHint,
                  prefixIcon: const Icon(Icons.percent),
                  border: const OutlineInputBorder(),
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Trees count
              TextFormField(
                controller: _treesController,
                decoration: InputDecoration(
                  labelText: l10n.criarVagaTreesLabel,
                  hintText: l10n.criarVagaTreesHint,
                  prefixIcon: const Icon(Icons.park),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.criarVagaDescriptionLabel,
                hintText: l10n.criarVagaDescriptionHint,
                prefixIcon: const Icon(Icons.description),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.criarVagaDescriptionRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Validity
            TextFormField(
              controller: _validityController,
              decoration: InputDecoration(
                labelText: l10n.criarVagaValidityLabel,
                hintText: l10n.criarVagaValidityHint,
                prefixIcon: const Icon(Icons.calendar_today),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.criarVagaValidityInvalid;
                }
                final days = int.tryParse(value);
                if (days == null || days < 1 || days > 90) {
                  return l10n.criarVagaValidityInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Publish button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isPublishing ? null : _publishJob,
                icon: _isPublishing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish),
                label: Text(
                  _isPublishing
                      ? l10n.criarVagaPublishing
                      : l10n.criarVagaPublishButton,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required JobType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publishJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPublishing = true);

    final l10n = BorrachaLocalizations.of(context)!;

    try {
      final user = AuthService.currentUser;
      final validityDays = int.parse(_validityController.text);
      final now = DateTime.now();

      final jobData = {
        'userId': user?.uid ?? 'anonymous',
        'userName': _nameController.text,
        'type': _selectedType == JobType.offeringWork
            ? 'offeringWork'
            : 'seekingWork',
        'regions': ['Rio Preto'], // TODO: Get from user profile
        'description': _descriptionController.text,
        'contactPhone': _phoneController.text,
        'municipality': _municipalityController.text,
        'createdAt': Timestamp.fromDate(now),
        'validUntil': Timestamp.fromDate(now.add(Duration(days: validityDays))),
      };

      // Add optional fields for offering work
      if (_selectedType == JobType.offeringWork) {
        final percentage = double.tryParse(_percentageController.text);
        if (percentage != null) {
          jobData['offeredPercentage'] = percentage;
        }
        final trees = int.tryParse(_treesController.text);
        if (trees != null) {
          jobData['treesCount'] = trees;
        }
      }

      await FirebaseFirestore.instance.collection('job_posts').add(jobData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.criarVagaSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.criarVagaError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }
}
