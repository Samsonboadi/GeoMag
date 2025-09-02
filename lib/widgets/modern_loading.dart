// lib/widgets/modern_loading.dart - FIXES FOR OVERFLOW ISSUES
import 'package:flutter/material.dart';

// Fix for the overflow at line 687 mentioned in your logs
class ModernLoadingWidget extends StatefulWidget {
  const ModernLoadingWidget({super.key});

  @override
  State<ModernLoadingWidget> createState() => _ModernLoadingWidgetState();
}

class _ModernLoadingWidgetState extends State<ModernLoadingWidget> 
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 200,
          maxHeight: 200,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // CRITICAL: Use min size
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animation.value * 2 * 3.14159,
                  child: Icon(
                    Icons.refresh,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// FIXED VERSION OF YOUR OVERFLOWING STATS CARDS
class SafeModernStatsCard extends StatelessWidget {
  const SafeModernStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
    this.width,
    this.height,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: width ?? 135.7, // Match your constraint from logs
      height: height ?? 106.1, // Match your constraint from logs
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12), // Reduced from 21 to fit
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate available height for content
                final availableHeight = constraints.maxHeight - 24; // Account for padding
                final hasSubtitle = subtitle != null;
                final hasIcon = icon != null;
                
                // Determine layout based on available space
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row - always fits on one line
                    Row(
                      children: [
                        if (hasIcon) ...[
                          Icon(
                            icon,
                            size: 16, // Smaller icon to save space
                            color: color ?? theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Main value - flexible sizing
                    Flexible(
                      fit: FlexFit.loose,
                      child: Text(
                        value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color ?? theme.colorScheme.onSurface,
                          fontSize: availableHeight < 60 ? 14 : 16, // Adaptive font size
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Subtitle - only show if space allows
                    if (hasSubtitle && availableHeight > 50) ...[
                      const SizedBox(height: 4),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10, // Smaller to fit
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// SCROLLABLE VERSION FOR REALLY CONSTRAINED SPACES
class ScrollableStatsCard extends StatelessWidget {
  const ScrollableStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 80,
            maxHeight: 106.1,
          ),
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 16,
                        color: color ?? theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color ?? theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// UTILITY CLASS FOR HANDLING OVERFLOW PREVENTION
class OverflowPrevention {
  // Replace Column widgets that cause overflow
  static Widget safeColumn({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    double? height,
  }) {
    if (height != null && height < 200) {
      // Use scrollable column for constrained heights
      return SizedBox(
        height: height,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      );
    }
    
    // Use flexible column for normal cases
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.map((child) => Flexible(child: child)).toList(),
    );
  }
  
  // Replace Row widgets that cause overflow
  static Widget safeRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.min,
  }) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.map((child) => Flexible(child: child)).toList(),
    );
  }
}

// ADAPTIVE STATS GRID THAT WON'T OVERFLOW
class AdaptiveStatsGrid extends StatelessWidget {
  const AdaptiveStatsGrid({
    super.key,
    required this.stats,
    this.crossAxisCount,
    this.childAspectRatio,
    this.maxHeight,
  });

  final List<Widget> stats;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate optimal grid parameters
    final optimalColumns = crossAxisCount ?? 
        (screenWidth < 600 ? 2 : (screenWidth < 900 ? 3 : 4));
    final optimalRatio = childAspectRatio ?? 
        (screenHeight < 600 ? 1.8 : 1.3);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? screenHeight * 0.4,
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        crossAxisCount: optimalColumns,
        childAspectRatio: optimalRatio,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: stats,
      ),
    );
  }
}