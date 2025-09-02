// lib/screens/data_analysis_screen.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../db/app_db.dart' as db;
import '../widgets/modern_widgets.dart';

class DataAnalysisScreen extends StatefulWidget {
  const DataAnalysisScreen({
    super.key,
    required this.projectId,
    required this.database,
  });

  final int projectId;
  final db.AppDb database;

  @override
  State<DataAnalysisScreen> createState() => _DataAnalysisScreenState();
}

class _DataAnalysisScreenState extends State<DataAnalysisScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  db.Project? _project;
  List<db.Point> _points = [];
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _anomalies = [];
  
  // Filtering options
  DateTimeRange? _dateFilter;
  double _minMagnitude = 0;
  double _maxMagnitude = 100000;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load project details using the correct method
      final projects = await (widget.database.select(widget.database.projects)
          ..where((p) => p.id.equals(widget.projectId))).get();
      
      if (projects.isEmpty) {
        throw Exception('Project not found');
      }
      _project = projects.first;

      // Load points using the correct method
      _points = await widget.database.listPoints(widget.projectId);
      
      if (_points.isNotEmpty) {
        _calculateStatistics();
        _detectAnomalies();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _calculateStatistics() {
    if (_points.isEmpty) return;

    // Use the correct field names from your Point model
    final magnitudes = _points.map((p) => p.totalField).toList();
    final altitudes = _points.map((p) => p.altitude).toList();
    final accuracies = _points.where((p) => p.accuracyM != null).map((p) => p.accuracyM!).toList();

    // Magnetic field statistics
    magnitudes.sort();
    final mean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final variance = magnitudes.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / magnitudes.length;
    final standardDeviation = math.sqrt(variance);
    
    _statistics = {
      'total_measurements': _points.length,
      'magnitude_min': magnitudes.first,
      'magnitude_max': magnitudes.last,
      'magnitude_mean': mean,
      'magnitude_std': standardDeviation,
      'magnitude_median': magnitudes.length % 2 == 0 
          ? (magnitudes[magnitudes.length ~/ 2 - 1] + magnitudes[magnitudes.length ~/ 2]) / 2
          : magnitudes[magnitudes.length ~/ 2],
      'altitude_mean': altitudes.isNotEmpty ? altitudes.reduce((a, b) => a + b) / altitudes.length : 0.0,
      'gps_accuracy_mean': accuracies.isNotEmpty ? accuracies.reduce((a, b) => a + b) / accuracies.length : null,
      'duration_hours': _points.isNotEmpty ? _points.last.ts.difference(_points.first.ts).inHours : 0,
      'survey_area_km2': _calculateSurveyArea(),
    };
  }

  double _calculateSurveyArea() {
    if (_points.length < 3) return 0.0;
    
    final lats = _points.map((p) => p.lat).toList();
    final lngs = _points.map((p) => p.lon).toList();
    
    lats.sort();
    lngs.sort();
    
    // Simple rectangular area calculation (in km²)
    final latRange = lats.last - lats.first;
    final lngRange = lngs.last - lngs.first;
    
    // Convert degrees to km (approximate)
    final latKm = latRange * 111.32;
    final lngKm = lngRange * 111.32 * math.cos(lats[lats.length ~/ 2] * math.pi / 180);
    
    return latKm * lngKm;
  }

  void _detectAnomalies() {
    if (_points.length < 10) return;

    _anomalies.clear();
    final mean = _statistics['magnitude_mean'] as double;
    final std = _statistics['magnitude_std'] as double;
    final threshold = std * 2; // 2 standard deviations

    for (int i = 0; i < _points.length; i++) {
      final point = _points[i];
      final deviation = (point.totalField - mean).abs();
      
      if (deviation > threshold) {
        _anomalies.add({
          'index': i,
          'point': point,
          'deviation': deviation,
          'severity': deviation > std * 3 ? 'High' : 'Medium',
        });
      }
    }

    // Sort by deviation (highest first)
    _anomalies.sort((a, b) => (b['deviation'] as double).compareTo(a['deviation'] as double));
    
    // Keep only top 20 anomalies
    if (_anomalies.length > 20) {
      _anomalies = _anomalies.take(20).toList();
    }
  }

  void _applyFilters() {
    // Implementation would filter _points based on current filter settings
    setState(() {});
  }

  void _exportData() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildExportSheet(),
    );
  }

  Widget _buildExportSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Export Analysis Data',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Export as CSV'),
            subtitle: const Text('Raw measurement data'),
            onTap: () {
              Navigator.pop(context);
              _showExportMessage('CSV');
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.insert_chart),
            title: const Text('Export Statistics'),
            subtitle: const Text('Analysis summary and statistics'),
            onTap: () {
              Navigator.pop(context);
              _showExportMessage('Statistics');
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.warning),
            title: const Text('Export Anomalies'),
            subtitle: const Text('Detected anomalous readings'),
            onTap: () {
              Navigator.pop(context);
              _showExportMessage('Anomalies');
            },
          ),
          
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showExportMessage(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type export functionality coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_project?.name ?? 'Data Analysis'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Overview'),
            Tab(icon: Icon(Icons.show_chart), text: 'Trends'),
            Tab(icon: Icon(Icons.warning), text: 'Anomalies'),
            Tab(icon: Icon(Icons.map), text: 'Spatial'),
          ],
        ),
      ),
      
      body: Column(
        children: [
          // Filter panel
          if (_showFilters) _buildFilterPanel(),
          
          // Main content
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return const ModernLoadingIndicator(message: 'Analyzing survey data...');
                }
                
                if (_hasError) {
                  return ModernErrorState(
                    message: _errorMessage,
                    onRetry: _loadData,
                  );
                }
                
                if (_points.isEmpty) {
                  return ModernEmptyState(
                    message: 'No survey data available for analysis.\nStart collecting measurements to see analysis.',
                    icon: Icons.analytics,
                    actionText: 'Start Survey',
                    onAction: () => Navigator.pop(context),
                  );
                }
                
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildTrendsTab(),
                    _buildAnomaliesTab(),
                    _buildSpatialTab(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Data Filters',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _dateFilter = null;
                    _minMagnitude = 0;
                    _maxMagnitude = 100000;
                  });
                  _applyFilters();
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: Text(_dateFilter != null ? 'Date Range Set' : 'Date Range'),
                onPressed: () async {
                  if (_points.isEmpty) return;
                  
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: _points.first.ts,
                    lastDate: _points.last.ts,
                    initialDateRange: _dateFilter,
                  );
                  if (picked != null) {
                    setState(() => _dateFilter = picked);
                    _applyFilters();
                  }
                },
              ),
              
              ActionChip(
                avatar: const Icon(Icons.tune, size: 18),
                label: const Text('Magnitude Range'),
                onPressed: () => _showMagnitudeFilter(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMagnitudeFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Magnitude Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filter by magnetic field magnitude (nT)'),
            const SizedBox(height: 16),
            RangeSlider(
              values: RangeValues(_minMagnitude, _maxMagnitude),
              min: (_statistics['magnitude_min'] as double?)?.toDouble() ?? 0,
              max: (_statistics['magnitude_max'] as double?)?.toDouble() ?? 100000,
              divisions: 100,
              labels: RangeLabels(
                _minMagnitude.toStringAsFixed(1),
                _maxMagnitude.toStringAsFixed(1),
              ),
              onChanged: (values) {
                setState(() {
                  _minMagnitude = values.start;
                  _maxMagnitude = values.end;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _applyFilters();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              StatCard(
                title: 'Total Points',
                value: '${_statistics['total_measurements'] ?? 0}',
                icon: Icons.analytics,
                color: Colors.blue,
                subtitle: 'Data points collected',
              ),
              
              StatCard(
                title: 'Survey Duration',
                value: '${_statistics['duration_hours'] ?? 0}h',
                icon: Icons.access_time,
                color: Colors.green,
                subtitle: 'Collection time',
              ),
              
              StatCard(
                title: 'Survey Area',
                value: '${((_statistics['survey_area_km2'] as double?) ?? 0).toStringAsFixed(2)} km²',
                icon: Icons.map,
                color: Colors.orange,
                subtitle: 'Coverage area',
              ),
              
              StatCard(
                title: 'Anomalies Found',
                value: '${_anomalies.length}',
                icon: Icons.warning,
                color: Colors.red,
                subtitle: 'Unusual readings',
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Magnetic field statistics
          DataCard(
            title: 'Magnetic Field Statistics',
            child: Column(
              children: [
                _buildStatRow('Minimum', '${((_statistics['magnitude_min'] as double?) ?? 0).toStringAsFixed(2)} nT'),
                _buildStatRow('Maximum', '${((_statistics['magnitude_max'] as double?) ?? 0).toStringAsFixed(2)} nT'),
                _buildStatRow('Mean', '${((_statistics['magnitude_mean'] as double?) ?? 0).toStringAsFixed(2)} nT'),
                _buildStatRow('Median', '${((_statistics['magnitude_median'] as double?) ?? 0).toStringAsFixed(2)} nT'),
                _buildStatRow('Std. Deviation', '${((_statistics['magnitude_std'] as double?) ?? 0).toStringAsFixed(2)} nT'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Additional statistics
          DataCard(
            title: 'Survey Conditions',
            child: Column(
              children: [
                _buildStatRow('Avg. Altitude', '${((_statistics['altitude_mean'] as double?) ?? 0).toStringAsFixed(1)} m'),
                if (_statistics['gps_accuracy_mean'] != null)
                  _buildStatRow('Avg. GPS Accuracy', '${((_statistics['gps_accuracy_mean'] as double?) ?? 0).toStringAsFixed(1)} m'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DataCard(
            title: 'Magnetic Field Over Time',
            child: Container(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Time Series Chart',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'Chart visualization coming soon',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          DataCard(
            title: 'Field Components',
            child: Container(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'X, Y, Z Components',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'Component analysis coming soon',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomaliesTab() {
    if (_anomalies.isEmpty) {
      return const ModernEmptyState(
        message: 'No significant anomalies detected in the survey data.',
        icon: Icons.check_circle_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _anomalies.length,
      itemBuilder: (context, index) {
        final anomaly = _anomalies[index];
        final point = anomaly['point'] as db.Point;
        final severity = anomaly['severity'] as String;
        final deviation = anomaly['deviation'] as double;

        final severityColor = severity == 'High' ? Colors.red : Colors.orange;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: severityColor.withOpacity(0.1),
              child: Icon(
                severity == 'High' ? Icons.priority_high : Icons.warning,
                color: severityColor,
              ),
            ),
            title: Text('${point.totalField.toStringAsFixed(2)} nT'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deviation: ${deviation.toStringAsFixed(2)} nT'),
                Text('Location: ${point.lat.toStringAsFixed(6)}, ${point.lon.toStringAsFixed(6)}'),
                Text('Time: ${_formatDateTime(point.ts)}'),
              ],
            ),
            trailing: Chip(
              label: Text(
                severity,
                style: TextStyle(
                  color: severityColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: severityColor.withOpacity(0.1),
            ),
            onTap: () {
              _showAnomalyDetails(anomaly);
            },
          ),
        );
      },
    );
  }

  Widget _buildSpatialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DataCard(
            title: 'Measurement Locations',
            action: IconButton(
              icon: const Icon(Icons.map),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Interactive map coming soon!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Interactive Survey Map',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_points.length} measurement points',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    Text(
                      'Map visualization coming soon',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Coordinate bounds
          DataCard(
            title: 'Survey Bounds',
            child: Column(
              children: [
                _buildCoordinateInfo(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateInfo() {
    if (_points.isEmpty) return const Text('No data available');

    final lats = _points.map((p) => p.lat).toList();
    final lngs = _points.map((p) => p.lon).toList();
    
    lats.sort();
    lngs.sort();

    return Column(
      children: [
        _buildStatRow('North Bound', '${lats.last.toStringAsFixed(6)}°'),
        _buildStatRow('South Bound', '${lats.first.toStringAsFixed(6)}°'),
        _buildStatRow('East Bound', '${lngs.last.toStringAsFixed(6)}°'),
        _buildStatRow('West Bound', '${lngs.first.toStringAsFixed(6)}°'),
        const Divider(),
        _buildStatRow('Lat Range', '${(lats.last - lats.first).toStringAsFixed(6)}°'),
        _buildStatRow('Lng Range', '${(lngs.last - lngs.first).toStringAsFixed(6)}°'),
      ],
    );
  }

  void _showAnomalyDetails(Map<String, dynamic> anomaly) {
    final point = anomaly['point'] as db.Point;
    final deviation = anomaly['deviation'] as double;
    final severity = anomaly['severity'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anomaly Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Total Field', '${point.totalField.toStringAsFixed(3)} nT'),
            _buildDetailRow('Deviation', '${deviation.toStringAsFixed(3)} nT'),
            _buildDetailRow('Severity', severity),
            _buildDetailRow('X Component', '${point.magneticX.toStringAsFixed(3)} nT'),
            _buildDetailRow('Y Component', '${point.magneticY.toStringAsFixed(3)} nT'),
            _buildDetailRow('Z Component', '${point.magneticZ.toStringAsFixed(3)} nT'),
            _buildDetailRow('Latitude', '${point.lat.toStringAsFixed(6)}°'),
            _buildDetailRow('Longitude', '${point.lon.toStringAsFixed(6)}°'),
            _buildDetailRow('Altitude', '${point.altitude.toStringAsFixed(1)} m'),
            _buildDetailRow('Timestamp', _formatDateTime(point.ts)),
            if (point.accuracyM != null)
              _buildDetailRow('GPS Accuracy', '${point.accuracyM!.toStringAsFixed(1)} m'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Anomaly marked for review'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Mark Reviewed'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}