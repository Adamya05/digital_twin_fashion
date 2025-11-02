import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/model_provider.dart';

/// Widget for selecting model quality settings
class ModelQualitySelector extends ConsumerWidget {
  final ValueChanged<ModelQuality>? onQualityChanged;
  final ModelQuality? initialQuality;

  const ModelQualitySelector({
    Key? key,
    this.onQualityChanged,
    this.initialQuality,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentQuality = ref.watch(modelQualitySettingsProvider);
    final quality = initialQuality ?? currentQuality;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model Quality',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Higher quality provides better visual fidelity but requires more resources',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: ModelQuality.values.map((quality) {
                return RadioListTile<ModelQuality>(
                  title: Text(quality.displayName),
                  subtitle: Text(_getQualityDescription(quality)),
                  value: quality,
                  groupValue: quality,
                  onChanged: (newQuality) {
                    if (newQuality != null) {
                      ref.read(modelQualitySettingsProvider.notifier).setQuality(newQuality);
                      onQualityChanged?.call(newQuality);
                    }
                  },
                  secondary: _getQualityIcon(quality),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getQualityDescription(ModelQuality quality) {
    switch (quality) {
      case ModelQuality.low:
        return 'Fast loading, smaller file size';
      case ModelQuality.medium:
        return 'Balanced quality and performance';
      case ModelQuality.high:
        return 'Better detail, moderate loading time';
      case ModelQuality.ultra:
        return 'Maximum quality, slower loading';
    }
  }

  Widget _getQualityIcon(ModelQuality quality) {
    switch (quality) {
      case ModelQuality.low:
        return const Icon(Icons.speed, color: Colors.green);
      case ModelQuality.medium:
        return const Icon(Icons.balance, color: Colors.blue);
      case ModelQuality.high:
        return const Icon(Icons.high_quality, color: Colors.orange);
      case ModelQuality.ultra:
        return const Icon(Icons.star, color: Colors.purple);
    }
  }
}

/// Widget for displaying cache statistics
class CacheStatisticsWidget extends ConsumerWidget {
  const CacheStatisticsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheStats = ref.watch(cacheStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cache Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              'Cached Models',
              '${cacheStats.cachedModels}',
              Icons.layers,
            ),
            _buildStatRow(
              context,
              'Cache Size',
              cacheStats.formattedCacheSize,
              Icons.folder,
            ),
            _buildStatRow(
              context,
              'Max Cache Size',
              cacheStats.formattedMaxCacheSize,
              Icons.settings,
            ),
            const SizedBox(height: 16),
            _buildProgressBar(context, cacheStats.cacheUtilization),
            const SizedBox(height: 8),
            Text(
              'Cache utilization: ${(cacheStats.cacheUtilization * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, double utilization) {
    return LinearProgressIndicator(
      value: utilization,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      valueColor: AlwaysStoppedAnimation<Color>(
        utilization < 0.8 
            ? Theme.of(context).colorScheme.primary
            : utilization < 0.95 
                ? Colors.orange 
                : Colors.red,
      ),
    );
  }
}

/// Widget for displaying model loading progress
class ModelLoadingProgress extends ConsumerWidget {
  final String modelUrl;

  const ModelLoadingProgress({
    Key? key,
    required this.modelUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadState = ref.watch(modelLoadingStateProvider).getLoadState(modelUrl);
    final isLoading = loadState == ModelLoadState.loading;

    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading 3D Model...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we prepare your avatar',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying recent model interactions
class ModelInteractionHistory extends ConsumerWidget {
  final String modelUrl;

  const ModelInteractionHistory({
    Key? key,
    required this.modelUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactions = ref.watch(modelInteractionsProvider);
    final lastInteraction = interactions.getLastInteraction(modelUrl);

    if (lastInteraction == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final difference = now.difference(lastInteraction);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Interaction',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatTimeAgo(difference),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (difference < const Duration(minutes: 5))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(Duration difference) {
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

/// Widget for managing auto-rotation settings
class AutoRotationControls extends ConsumerWidget {
  final String modelUrl;
  final bool initialValue;

  const AutoRotationControls({
    Key? key,
    required this.modelUrl,
    this.initialValue = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoRotateEnabled = ref.watch(autoRotateSettingsProvider)[modelUrl] ?? initialValue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.rotate_right,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto Rotation',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Automatically rotate the 3D model',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: autoRotateEnabled,
              onChanged: (enabled) {
                ref.read(autoRotateSettingsProvider.notifier).setAutoRotate(modelUrl, enabled);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for screenshot management
class ScreenshotManager extends ConsumerWidget {
  const ScreenshotManager({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastScreenshot = ref.watch(lastScreenshotProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Screenshots',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (lastScreenshot != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Last screenshot saved',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lastScreenshot,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              Icon(
                Icons.camera_alt_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'No screenshots yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}