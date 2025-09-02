// lib/screens/data_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../db/app_db.dart' as db;
import '../widgets/modern_loading.dart';
import '../widgets/modern_feedback.dart';

class DataAnalysisScreen extends StatefulWidget {
  final int projectId;
  final db.AppDb database;

  const DataAnalysisScreen({
    super.key,
    required this.projectId,
    required this.database,
  });

  @override
  State<DataAnalysisScreen> createState() => _DataAnalysisScreenState();
}

class _DataAnalysisScreenState extends State<DataAnalysisScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  List<db.Point> _points = [];
  bool _loading = true;
  String? _error;

  // Analysis results
  double _minField = 0;
  double _maxField = 0;
  double _avgField = 0;
  double _stdDev = 0;
  int _totalPoints = 0;
  double _surveyDistance = 0;
  Duration _surveyDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      
      final points = await widget.database.listPoints(widget.projectId);
      
      if (points.isNotEmpty) {
        _calculateStatistics(points);
      }
      
      setState(() {
        _points = points;
        _loading = false;
      });
      
      _slideController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      
      if (mounted) {
        ModernFeedback.showError(context, 'Failed to load analysis data');
      }
    }
  }

  void _calculateStatistics(List<db.Point> points) {
    if (points.isEmpty) return;

    final fields = points.map((p) => p.totalField).toList();
    _minField = fields.reduce(math.min);
    _maxField = fields.reduce(math.max);
    _avgField = fields.reduce((a, b) => a + b) / fields.length;
    
    // Standard deviation
    final variance = fields.map((f) => math.pow(f - _avgField, 2)).reduce((a, b) => a + b) / fields.length;
    _stdDev = math.sqrt(variance);

    _totalPoints = points.length;
    
    // Calculate survey distance and duration
    if (points.length > 1) {
      double totalDistance = 0;
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final distance = _calculateDistance(
          prev.lat, prev.lon,
          curr.lat, curr.lon,
        );
        totalDistance += distance;
      }
      _surveyDistance = totalDistance;
      
      final start = points.first.ts;
      final end = points.last.ts;
      _surveyDuration = end.difference(start);
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: const Text(
                'Data Analysis',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              expandedHeight: 200,
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadData,
                  tooltip: 'Refresh Analysis',
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _exportAnalysisReport(),
                  tooltip: 'Export Report',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: const Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: 50,
                        child: Icon(
                          Icons.analytics,
                          size: 140,
                          color: Colors.white12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Statistics'),
                  Tab(text: 'Visualization'),
                ],
              ),
            ),
          ];
        },
        body: _loading
            ? const ModernLoadingIndicator(message: 'Analyzing survey data...')
            : _error != null
                ? ModernErrorState(
                    title: 'Analysis Error',
                    message: _error!,
                    onRetry: _loadData,
                  )
                : _points.isEmpty
                    ? ModernEmptyState(
                        title: 'No Data Yet',
                        subtitle: 'Start recording survey points to see analysis',
                        icon: Icons.analytics,
                        action: FilledButton.icon(
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Survey'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      )
                    : SlideTransition(
                        position: _slideAnimation,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(),
                            _buildStatisticsTab(),
                            _buildVisualizationTab(),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              ModernStatsCard(
                title: 'Total Points',
                value: _totalPoints.toString(),
                subtitle: 'measurements recorded',
                icon: Icons.location_on,
                color: theme.colorScheme.primary,
              ),
              ModernStatsCard(
                title: 'Field Range',
                value: '${(_maxField - _minField).toStringAsFixed(1)}',
                subtitle: 'µT variation',
                icon: Icons.tune,
                color: Colors.orange,
              ),
              ModernStatsCard(
                title: 'Distance',
                value: _surveyDistance > 1000 
                  ? '${(_surveyDistance / 1000).toStringAsFixed(1)} km'
                  : '${_surveyDistance.toStringAsFixed(0)} m',
                subtitle: 'survey path length',
                icon: Icons.straighten,
                color: Colors.green,
              ),
              ModernStatsCard(
                title: 'Duration',
                value: _formatDuration(_surveyDuration),
                subtitle: 'active recording time',
                icon: Icons.access_time,
                color: Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Field strength overview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.primaryContainer.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insights,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Field Strength Analysis',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _FieldStrengthBar(
                  label: 'Minimum',
                  value: _minField,
                  progress: 0.0,
                  color: Colors.blue,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _FieldStrengthBar(
                  label: 'Average',
                  value: _avgField,
                  progress: (_maxField - _minField) > 0 ? (_avgField - _minField) / (_maxField - _minField) : 0.5,
                  color: Colors.green,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _FieldStrengthBar(
                  label: 'Maximum',
                  value: _maxField,
                  progress: 1.0,
                  color: Colors.red,
                  theme: theme,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quality metrics
          _QualityMetricsCard(
            points: _points,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Statistical measures
          _StatCard(
            title: 'Descriptive Statistics',
            icon: Icons.calculate,
            theme: theme,
            children: [
              _StatRow('Mean', '${_avgField.toStringAsFixed(2)} µT', theme),
              _StatRow('Standard Deviation', '${_stdDev.toStringAsFixed(2)} µT', theme),
              _StatRow('Minimum', '${_minField.toStringAsFixed(2)} µT', theme),
              _StatRow('Maximum', '${_maxField.toStringAsFixed(2)} µT', theme),
              _StatRow('Range', '${(_maxField - _minField).toStringAsFixed(2)} µT', theme),
              _StatRow('Coefficient of Variation', _avgField > 0 ? '${((_stdDev / _avgField) * 100).toStringAsFixed(1)}%' : 'N/A', theme),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Spatial statistics
          _StatCard(
            title: 'Spatial Metrics',
            icon: Icons.map,
            theme: theme,
            children: [
              _StatRow('Total Points', '$_totalPoints', theme),
              _StatRow('Survey Distance', _surveyDistance > 1000 
                ? '${(_surveyDistance / 1000).toStringAsFixed(2)} km'
                : '${_surveyDistance.toStringAsFixed(0)} m', theme),
              _StatRow('Point Density', _surveyDistance > 0 
                ? '${(_totalPoints / (_surveyDistance / 1000)).toStringAsFixed(1)} pts/km'
                : 'N/A', theme),
              _StatRow('Average Spacing', _totalPoints > 1 
                ? '${(_surveyDistance / (_totalPoints - 1)).toStringAsFixed(1)} m'
                : 'N/A', theme),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Temporal statistics
          _StatCard(
            title: 'Temporal Metrics',
            icon: Icons.schedule,
            theme: theme,
            children: [
              _StatRow('Survey Duration', _formatDuration(_surveyDuration), theme),
              _StatRow('Recording Rate', _surveyDuration.inSeconds > 0 
                ? '${(_totalPoints / (_surveyDuration.inSeconds / 60)).toStringAsFixed(1)} pts/min'
                : 'N/A', theme),
              _StatRow('Start Time', _points.isNotEmpty 
                ? _formatDateTime(_points.first.ts)
                : 'N/A', theme),
              _StatRow('End Time', _points.isNotEmpty 
                ? _formatDateTime(_points.last.ts)
                : 'N/A', theme),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Export analysis button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.file_download),
              label: const Text('Export Analysis Report'),
              onPressed: _exportAnalysisReport,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizationTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Field strength histogram
          _VisualizationCard(
            title: 'Field Strength Distribution',
            icon: Icons.bar_chart,
            theme: theme,
            child: _FieldHistogram(points: _points, theme: theme),
          ),
          
          const SizedBox(height: 20),
          
          // Time series
          _VisualizationCard(
            title: 'Field vs Time',
            icon: Icons.timeline,
            theme: theme,
            child: _TimeSeriesChart(points: _points, theme: theme),
          ),
          
          const SizedBox(height: 20),
          
          // Component analysis
          _VisualizationCard(
            title: 'Magnetic Components',
            icon: Icons.analytics,
            theme: theme,
            child: _ComponentAnalysis(points: _points, theme: theme),
          ),
          
          const SizedBox(height: 20),
          
          // Spatial heatmap placeholder
          _VisualizationCard(
            title: 'Spatial Distribution',
            icon: Icons.scatter_plot,
            theme: theme,
            child: _SpatialView(points: _points, theme: theme),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAnalysisReport() async {
    try {
      final report = _generateAnalysisReport();
      
      await Clipboard.setData(ClipboardData(text: report));
      ModernFeedback.showSuccess(context, 'Analysis report copied to clipboard');
      
    } catch (e) {
      ModernFeedback.showError(context, 'Failed to export report: $e');
    }
  }

  String _generateAnalysisReport() {
    final buffer = StringBuffer();
    buffer.writeln('# GeoMag Survey Analysis Report');
    buffer.writeln('Project ID: ${widget.projectId}');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();
    buffer.writeln('## Summary');
    buffer.writeln('- Total Points: $_totalPoints');
    buffer.writeln('- Survey Distance: ${_surveyDistance > 1000 ? "${(_surveyDistance / 1000).toStringAsFixed(2)} km" : "${_surveyDistance.toStringAsFixed(0)} m"}');
    buffer.writeln('- Duration: ${_formatDuration(_surveyDuration)}');
    buffer.writeln();
    buffer.writeln('## Field Statistics');
    buffer.writeln('- Mean: ${_avgField.toStringAsFixed(2)} µT');
    buffer.writeln('- Standard Deviation: ${_stdDev.toStringAsFixed(2)} µT');
    buffer.writeln('- Minimum: ${_minField.toStringAsFixed(2)} µT');
    buffer.writeln('- Maximum: ${_maxField.toStringAsFixed(2)} µT');
    buffer.writeln('- Range: ${(_maxField - _minField).toStringAsFixed(2)} µT');
    if (_avgField > 0) {
      buffer.writeln('- CV: ${((_stdDev / _avgField) * 100).toStringAsFixed(1)}%');
    }
    
    return buffer.toString();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _FieldStrengthBar extends StatelessWidget {
  final String label;
  final double value;
  final double progress;
  final Color color;
  final ThemeData theme;

  const _FieldStrengthBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)} µT',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QualityMetricsCard extends StatelessWidget {
  final List<db.Point> points;
  final ThemeData theme;

  const _QualityMetricsCard({
    required this.points,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final highAccuracy = points.where((p) => p.accuracyM != null && p.accuracyM! <= 5).length;
    final mediumAccuracy = points.where((p) => p.accuracyM != null && p.accuracyM! > 5 && p.accuracyM! <= 10).length;
    final lowAccuracy = points.where((p) => p.accuracyM != null && p.accuracyM! > 10).length;
    final noAccuracy = points.where((p) => p.accuracyM == null).length;
    final total = points.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.high_quality,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Data Quality',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (total > 0) ...[
            _QualityBar(
              label: 'High Accuracy (≤5m)',
              count: highAccuracy,
              total: total,
              color: Colors.green,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _QualityBar(
              label: 'Medium Accuracy (5-10m)',
              count: mediumAccuracy,
              total: total,
              color: Colors.orange,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _QualityBar(
              label: 'Low Accuracy (>10m)',
              count: lowAccuracy,
              total: total,
              color: Colors.red,
              theme: theme,
            ),
            if (noAccuracy > 0) ...[
              const SizedBox(height: 12),
              _QualityBar(
                label: 'No Accuracy Data',
                count: noAccuracy,
                total: total,
                color: Colors.grey,
                theme: theme,
              ),
            ],
          ] else
            Text(
              'No data available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _QualityBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final ThemeData theme;

  const _QualityBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) : 0.0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count (${(percentage * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final ThemeData theme;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.children,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _StatRow(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualizationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final ThemeData theme;

  const _VisualizationCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }
}

// Visualization widgets
class _FieldHistogram extends StatelessWidget {
  final List<db.Point> points;
  final ThemeData theme;

  const _FieldHistogram({required this.points, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          'No data to display',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final fields = points.map((p) => p.totalField).toList();
    final minField = fields.reduce(math.min);
    final maxField = fields.reduce(math.max);
    
    // Create 10 bins
    const binCount = 10;
    final binWidth = (maxField - minField) / binCount;
    final bins = List.filled(binCount, 0);
    
    for (final field in fields) {
      final binIndex = binWidth > 0 
          ? ((field - minField) / binWidth).floor().clamp(0, binCount - 1)
          : 0;
      bins[binIndex]++;
    }
    
    final maxBinValue = bins.isNotEmpty ? bins.reduce(math.max) : 1;
    
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bins.asMap().entries.map((entry) {
              final height = maxBinValue > 0 ? (entry.value / maxBinValue) : 0.0;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: height * 150,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.value}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${minField.toStringAsFixed(0)} µT',
              style: theme.textTheme.labelSmall,
            ),
            Text(
              '${maxField.toStringAsFixed(0)} µT',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeSeriesChart extends StatelessWidget {
  final List<db.Point> points;
  final ThemeData theme;

  const _TimeSeriesChart({required this.points, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          'No data to display',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final minField = points.map((p) => p.totalField).reduce(math.min);
    final maxField = points.map((p) => p.totalField).reduce(math.max);
    
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _TimeSeriesPainter(
        points: points,
        minField: minField,
        maxField: maxField,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _TimeSeriesPainter extends CustomPainter {
  final List<db.Point> points;
  final double minField;
  final double maxField;
  final Color color;

  _TimeSeriesPainter({
    required this.points,
    required this.minField,
    required this.maxField,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final fieldRange = maxField - minField;
    
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final normalizedField = fieldRange > 0 ? (points[i].totalField - minField) / fieldRange : 0.5;
      final y = size.height - (normalizedField * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Add gradient fill
    final gradientPath = Path.from(path);
    gradientPath.lineTo(size.width, size.height);
    gradientPath.lineTo(0, size.height);
    gradientPath.close();
    
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(gradientPath, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ComponentAnalysis extends StatelessWidget {
  final List<db.Point> points;
  final ThemeData theme;

  const _ComponentAnalysis({required this.points, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          'No component data to display',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final xValues = points.map((p) => p.magneticX).toList();
    final yValues = points.map((p) => p.magneticY).toList();
    final zValues = points.map((p) => p.magneticZ).toList();

    final xAvg = xValues.reduce((a, b) => a + b) / xValues.length;
    final yAvg = yValues.reduce((a, b) => a + b) / yValues.length;
    final zAvg = zValues.reduce((a, b) => a + b) / zValues.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ComponentBar(
                label: 'X-Component',
                value: xAvg,
                color: Colors.red,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ComponentBar(
                label: 'Y-Component',
                value: yAvg,
                color: Colors.green,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ComponentBar(
                label: 'Z-Component',
                value: zAvg,
                color: Colors.blue,
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.onPrimaryContainer,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Average magnetic field components across all measurements',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComponentBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final ThemeData theme;

  const _ComponentBar({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(1)}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'µT',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpatialView extends StatelessWidget {
  final List<db.Point> points;
  final ThemeData theme;

  const _SpatialView({required this.points, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          'No spatial data to display',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Spatial Heatmap',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${points.length} measurement points',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'View on Map',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
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
}