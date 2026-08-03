import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/services/backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final BackupService _backupService = BackupService();
  bool _isLoadingSizes = true;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _includeMedia = true;

  int _dbSize = 0;
  int _mediaSize = 0;
  DateTime? _lastBackupDate;

  String _statusStage = '';
  double _statusProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoadingSizes = true);
    try {
      final sizes = await _backupService.getBackupSizes();
      final lastBackup = await _backupService.getLastBackupDate();
      if (mounted) {
        setState(() {
          _dbSize = sizes['database'] ?? 0;
          _mediaSize = sizes['media'] ?? 0;
          _lastBackupDate = lastBackup;
          _isLoadingSizes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSizes = false);
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handleBackup() async {
    setState(() {
      _isBackingUp = true;
      _statusStage = 'Initializing...';
      _statusProgress = 0.0;
    });

    try {
      final path = await _backupService.createBackup(
        ownerUid: FirebaseAuth.instance.currentUser?.uid ?? '',
        includeMedia: _includeMedia,
        onProgress: (stage, progress) {
          if (mounted) {
            setState(() {
              _statusStage = stage;
              _statusProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup created successfully at: $path')),
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  Future<void> _handleRestore() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (!mounted) return;

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;

      if (!path.toLowerCase().endsWith('.zip')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a valid .zip backup file')),
          );
        }
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Backup'),
          content: const Text(
            'Are you sure you want to restore from this backup? '
            'All current messages and media will be replaced. This action cannot be undone.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        setState(() {
          _isRestoring = true;
          _statusStage = 'Initializing...';
          _statusProgress = 0.0;
        });

        try {
          await _backupService.restoreBackup(
            path,
            currentUid: FirebaseAuth.instance.currentUser?.uid ?? '',
            onProgress: (stage, progress) {
              if (mounted) {
                setState(() {
                  _statusStage = stage;
                  _statusProgress = progress;
                });
              }
            },
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup restored successfully')),
            );
          }
          await _loadData();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Restore failed: $e')),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isRestoring = false;
            });
          }
        }
      }
    }
  }

  Widget _buildProgressOverlay(String title) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 24),
                LinearProgressIndicator(value: _statusProgress),
                const SizedBox(height: 16),
                Text(_statusStage),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24.0),
            children: [

              Icon(Icons.cloud_sync_outlined, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Safeguard your chats and media by creating a local backup.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),


              Text('Create Backup', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoadingSizes)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Database size:'),
                            Text(_formatBytes(_dbSize)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Media size:'),
                            Text(_formatBytes(_mediaSize)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Include media files'),
                          value: _includeMedia,
                          onChanged: (val) => setState(() => _includeMedia = val),
                        ),
                        const Divider(),
                        if (_lastBackupDate != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                            child: Text(
                              'Last backup: ${DateFormat.yMMMd().add_jm().format(_lastBackupDate!)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isBackingUp || _isRestoring ? null : _handleBackup,
                            icon: const Icon(Icons.cloud_download_outlined),
                            label: const Text('Create Backup'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),


              Text('Restore Backup', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Warning: Restoring a backup will replace all your current messages and media.',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isBackingUp || _isRestoring ? null : _handleRestore,
                          icon: const Icon(Icons.restore),
                          label: const Text('Restore from Backup'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_isBackingUp) _buildProgressOverlay('Creating Backup...'),
          if (_isRestoring) _buildProgressOverlay('Restoring Backup...'),
        ],
      ),
    );
  }
}
