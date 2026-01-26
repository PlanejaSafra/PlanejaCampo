import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/job_post.dart';
import '../widgets/rubber_drawer.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _userRegion = "Rio Preto";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.jobsTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.work),
              text: l10n.jobsTabOffering,
            ),
            Tab(
              icon: const Icon(Icons.person_search),
              text: l10n.jobsTabSeeking,
            ),
          ],
        ),
      ),
      drawer: buildRubberDrawer(context: context, l10n: l10n),
      body: Column(
        children: [
          // Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.mercadoFilterLabel}: $_userRegion',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Vagas (produtores oferecendo trabalho)
                _buildJobsList(JobType.offeringWork),
                // Disponíveis (sangradores procurando trabalho)
                _buildJobsList(JobType.seekingWork),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/criar-vaga');
        },
        label: Text(l10n.jobsCreateButton),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildJobsList(JobType jobType) {
    final typeString =
        jobType == JobType.offeringWork ? 'offeringWork' : 'seekingWork';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('job_posts')
          .where('validUntil',
              isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .where('type', isEqualTo: typeString)
          .orderBy('validUntil', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildJobsListFallback(jobType);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(jobType);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final job = JobPost.fromFirestore(docs[index]);
            return _buildJobCard(job);
          },
        );
      },
    );
  }

  // Fallback for when index doesn't exist
  Widget _buildJobsListFallback(JobType jobType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('job_posts')
          .where('validUntil',
              isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('validUntil', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final l10n = BorrachaLocalizations.of(context)!;
          return Center(child: Text('${l10n.errorLabel}: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['type'] ?? 'seekingWork';
          return type ==
              (jobType == JobType.offeringWork ? 'offeringWork' : 'seekingWork');
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState(jobType);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final job = JobPost.fromFirestore(filteredDocs[index]);
            return _buildJobCard(job);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(JobType jobType) {
    final l10n = BorrachaLocalizations.of(context)!;
    final isOffering = jobType == JobType.offeringWork;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOffering ? Icons.work_off : Icons.person_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isOffering ? l10n.jobsNoOffering : l10n.jobsNoSeeking,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/criar-vaga'),
            icon: const Icon(Icons.add),
            label: Text(l10n.jobsCreateButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobPost job) {
    final l10n = BorrachaLocalizations.of(context)!;
    final isOffering = job.type == JobType.offeringWork;

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Expiration warning
                    if (job.isExpiringSoon)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber,
                                size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              l10n.mercadoExpiringDays(job.daysRemaining),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                    // Job type badge
                    Chip(
                      label: Text(
                          isOffering ? l10n.jobsRoleProducer : l10n.jobsRoleTapper),
                      backgroundColor:
                          isOffering ? Colors.blue[100] : Colors.green[100],
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Municipality
            if (job.municipality != null && job.municipality!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.location_city, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    job.municipality!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Job details (for offering work)
            if (isOffering) ...[
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (job.offeredPercentage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.percent, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '${job.offeredPercentage!.toStringAsFixed(0)}% ${l10n.jobsPercentageLabel}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  if (job.treesCount != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.park, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${job.treesCount} ${l10n.mercadoTreesLabel}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            const Divider(),

            // Description
            Text(
              job.description,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Valid until
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${l10n.mercadoOfferValidUntil}: ${DateFormat('dd/MM/yyyy').format(job.validUntil)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                label: Text(l10n.jobsContactButton),
                icon: const Icon(Icons.chat),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _launchWhatsApp(job),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(JobPost job) async {
    final l10n = BorrachaLocalizations.of(context)!;
    final phone = job.contactPhone.replaceAll(RegExp(r'[^\d]'), '');

    String text;
    if (job.type == JobType.offeringWork) {
      text = l10n.jobsWhatsappMessageOffering(job.userName, _userRegion);
    } else {
      text = l10n.jobsWhatsappMessageSeeking(job.userName, _userRegion);
    }

    final url =
        Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(text)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
