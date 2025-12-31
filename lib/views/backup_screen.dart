import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/backup_service.dart';
import '../widgets/dialogs/confirmation_dialog.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  List<FileSystemEntity> _backupFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    setState(() => _isLoading = true);
    final files = await _backupService.getBackupFiles();
    if (mounted) {
      setState(() {
        _backupFiles = files;
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);

    try {
      final file = await _backupService.exportToJson();
      
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup created: ${file.path.split('/').last}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: () => _shareBackup(file.path),
          ),
        ),
      );

      _loadBackupFiles();
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      if (!mounted) return;

      // Confirm before importing
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => ConfirmationDialog(
          title: 'Import Backup',
          message: 'This will replace all current data (except settings) with the backup data. Are you sure?',
          confirmText: 'Import',
          isDestructive: true,
        ),
      );

      if (confirmed != true) return;

      setState(() => _isLoading = true);

      final success = await _backupService.importFromJson(filePath);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup imported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareBackup(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: 'POS App Backup');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBackup(String filePath) async {
    final fileName = filePath.split('/').last;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Backup',
        message: 'Are you sure you want to delete "$fileName"?',
        confirmText: 'Delete',
        isDestructive: true,
      ),
    );

    if (confirmed != true) return;

    final success = await _backupService.deleteBackupFile(filePath);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup deleted'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBackupFiles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete backup'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreBackup(String filePath) async {
    final fileName = filePath.split('/').last;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Restore Backup',
        message: 'This will replace all current data (except settings) with "$fileName". Are you sure?',
        confirmText: 'Restore',
        isDestructive: true,
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final success = await _backupService.importFromJson(filePath);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackupFiles,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading && _backupFiles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _createBackup,
                          icon: const Icon(Icons.backup),
                          label: const Text('Create Backup'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _importBackup,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Import Backup'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(),
                
                // Backup files list
                Expanded(
                  child: _backupFiles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.backup,
                                size: 64,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No backups found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create your first backup to get started',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _backupFiles.length,
                          itemBuilder: (context, index) {
                            final file = _backupFiles[index];
                            return _BackupFileCard(
                              file: file,
                              backupService: _backupService,
                              onRestore: () => _restoreBackup(file.path),
                              onShare: () => _shareBackup(file.path),
                              onDelete: () => _deleteBackup(file.path),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _BackupFileCard extends StatelessWidget {
  final FileSystemEntity file;
  final BackupService backupService;
  final VoidCallback onRestore;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _BackupFileCard({
    required this.file,
    required this.backupService,
    required this.onRestore,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = file.path.split('/').last;
    final stat = file.statSync();
    final modifiedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(stat.modified);
    final sizeKB = (stat.size / 1024).toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.folder_zip,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(modifiedDate),
            Text('Size: $sizeKB KB'),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'restore':
                onRestore();
                break;
              case 'share':
                onShare();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore),
                  SizedBox(width: 12),
                  Text('Restore'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 12),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 12),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
