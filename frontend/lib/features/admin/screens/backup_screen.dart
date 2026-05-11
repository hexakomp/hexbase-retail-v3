import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/admin_provider.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupsAsync = ref.watch(backupsProvider);

    return AppScaffold(
      title: 'Backups',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            await ref.read(backupRepositoryProvider).create();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Backup job queued. It will appear shortly.'),
              ),
            );
            ref.invalidate(backupsProvider);
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
        icon: const Icon(Icons.backup),
        label: const Text('New Backup'),
      ),
      body: backupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (backups) => RefreshIndicator(
          onRefresh: () => ref.refresh(backupsProvider.future),
          child: backups.isEmpty
              ? const Center(child: Text('No backups found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: backups.length,
                  itemBuilder: (ctx, i) {
                    final b = backups[i];
                    final sizeKb = (b.size / 1024).toStringAsFixed(1);
                    final created = DateTime.fromMillisecondsSinceEpoch(
                      b.created * 1000,
                    );
                    final dateStr =
                        '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')} '
                        '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE3F2FD),
                          child: Icon(Icons.folder_zip, color: Colors.blue),
                        ),
                        title: Text(b.name),
                        subtitle: Text('$dateStr  •  $sizeKb KB'),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          tooltip: 'Download',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Download: ${b.name}')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
