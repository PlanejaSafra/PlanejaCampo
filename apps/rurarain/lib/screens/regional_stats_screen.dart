import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/regional_stats.dart';
import '../services/chuva_service.dart';
import '../services/rainfall_stats_service.dart';
import '../widgets/balanco_hidrico_chart.dart';

/// Screen showing regional rainfall statistics and comparison with user's data.
class RegionalStatsScreen extends StatefulWidget {
  final String propertyId;
  final double? latitude;
  final double? longitude;

  const RegionalStatsScreen({
    super.key,
    required this.propertyId,
    this.latitude,
    this.longitude,
  });

  @override
  State<RegionalStatsScreen> createState() => _RegionalStatsScreenState();
}

class _RegionalStatsScreenState extends State<RegionalStatsScreen> {
  final _statsService = RainfallStatsService();
  final _chuvaService = ChuvaService();

  RegionalStats? _regionalStats;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorDetail;
  double? _userTotalMm;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Check consent
    if (!_statsService.hasUserConsent) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    // Check location
    if (widget.latitude == null || widget.longitude == null) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Fetch regional stats
      final stats = await _statsService.fetchRegionalStats(
        latitude: widget.latitude!,
        longitude: widget.longitude!,
      );

      // Calculate user's total for current month
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      final userTotal = _chuvaService.totalDoMes(
        currentMonth,
        propertyId: widget.propertyId,
      );

      setState(() {
        _regionalStats = stats;
        _userTotalMm = userTotal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorDetail = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AgroLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.regionalStatsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: l10n.refreshTooltip,
          ),
        ],
      ),
      body: _buildBody(theme, l10n),
      bottomNavigationBar: const AgroBannerWidget(),
    );
  }

  Widget _buildBody(ThemeData theme, AgroLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      // Determine error message based on state
      String errorMsg;
      if (!_statsService.hasUserConsent) {
        errorMsg = l10n.regionalRequireConsent;
      } else if (widget.latitude == null || widget.longitude == null) {
        errorMsg = l10n.configurePropertyFirst;
      } else if (_errorDetail != null) {
        errorMsg = l10n.regionalLoadError(_errorDetail!);
      } else {
        errorMsg = l10n.regionalStatsTitle;
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                errorMsg,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (!_statsService.hasUserConsent)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AgroPrivacyScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: Text(l10n.goToSettingsButton),
                )
              else
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.tryAgainButton),
                ),
            ],
          ),
        ),
      );
    }

    if (_regionalStats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.regionalNoData,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.regionalNoDataDesc,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.checkAgainButton),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          _buildInfoCard(theme, l10n),
          const SizedBox(height: 16),
          // Comparison card
          _buildComparisonCard(theme, l10n),
          const SizedBox(height: 16),
          // Regional Water Balance Chart
          if (widget.latitude != null && widget.longitude != null)
            BalancoHidricoChart(
              propertyId: widget.propertyId,
              latitude: widget.latitude!,
              longitude: widget.longitude!,
            ),
          const SizedBox(height: 16),
          // Details card
          _buildDetailsCard(theme, l10n),
          const SizedBox(height: 16),
          // Privacy note
          _buildPrivacyNote(theme, l10n),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, AgroLocalizations l10n) {
    final stats = _regionalStats!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.regionalYourRegion,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.map,
              label: l10n.regionalCoverageArea,
              value: stats.getAreaDescription(),
              theme: theme,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.people,
              label: l10n.regionalContributors,
              value: '${stats.contributorCount}',
              theme: theme,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.verified,
              label: l10n.regionalConfidenceLevel,
              value: stats.getConfidenceLevel(),
              theme: theme,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.update,
              label: l10n.regionalLastUpdate,
              value: _formatDate(stats.lastUpdated, l10n),
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCard(ThemeData theme, AgroLocalizations l10n) {
    final stats = _regionalStats!;
    final userMm = _userTotalMm ?? 0;
    final regionalMm = stats.averageMm;
    final difference = userMm - regionalMm;
    final percentDiff = regionalMm > 0 ? (difference / regionalMm) * 100 : 0;

    final isAboveAverage = difference > 0;
    final color = isAboveAverage
        ? Colors.blue
        : difference < -10
            ? Colors.orange
            : Colors.grey;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.regionalComparison,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    label: l10n.regionalYourProperty,
                    value: '${NumberFormat('#0.0', 'pt_BR').format(userMm)} mm',
                    color: theme.colorScheme.primary,
                    theme: theme,
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: theme.colorScheme.outline,
                ),
                Expanded(
                  child: _buildStatColumn(
                    label: l10n.regionalAverage,
                    value:
                        '${NumberFormat('#0.0', 'pt_BR').format(regionalMm)} mm',
                    color: theme.colorScheme.secondary,
                    theme: theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color),
              ),
              child: Row(
                children: [
                  Icon(
                    isAboveAverage ? Icons.trending_up : Icons.trending_down,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAboveAverage
                          ? l10n.regionalAboveAverage(
                              percentDiff.abs().toStringAsFixed(1))
                          : l10n.regionalBelowAverage(
                              percentDiff.abs().toStringAsFixed(1)),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailsCard(ThemeData theme, AgroLocalizations l10n) {
    final stats = _regionalStats!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.regionalDetails,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              label: l10n.regionalAccumulatedTotal,
              value:
                  '${NumberFormat('#0.0', 'pt_BR').format(stats.totalMm)} mm',
              theme: theme,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              label: l10n.regionalGeoHash,
              value: stats.geoHash,
              theme: theme,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              label: l10n.regionalPrecision,
              value: l10n.regionalCharacters(stats.geoHashPrecision),
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyNote(ThemeData theme, AgroLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.regionalPrivacyNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, AgroLocalizations l10n) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return l10n.timeAgoMinutes(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.timeAgoHours(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.timeAgoDays(difference.inDays);
    } else {
      return DateFormat.yMMMd(locale).format(date);
    }
  }
}
