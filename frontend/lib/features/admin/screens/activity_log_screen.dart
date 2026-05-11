import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/admin_provider.dart';

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  final List<ActivityLogEntry> _entries = [];
  int? _filterUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (reset) {
      _page = 1;
      _hasMore = true;
      _entries.clear();
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(activityLogRepositoryProvider);
      final result = await repo.list(page: _page, userId: _filterUserId);
      final data = result['data'] as List? ?? [];
      final meta = result['meta'] as Map? ?? {};
      final lastPage = meta['last_page'] ?? 1;
      setState(() {
        _entries.addAll(data.map((j) => ActivityLogEntry.fromJson(j)));
        _hasMore = _page < lastPage;
        _page++;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Color _eventColor(String event) {
    switch (event) {
      case 'created':
        return Colors.green;
      case 'updated':
        return Colors.blue;
      case 'deleted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Activity Log',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Filter by user ID',
                      prefixIcon: Icon(Icons.person_search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (v) {
                      _filterUserId = int.tryParse(v);
                      _load(reset: true);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _load(reset: true),
                ),
              ],
            ),
          ),
          Expanded(
            child: _entries.isEmpty && !_loading
                ? const Center(child: Text('No activity entries.'))
                : NotificationListener<ScrollNotification>(
                    onNotification: (s) {
                      if (s.metrics.pixels >= s.metrics.maxScrollExtent - 100 &&
                          _hasMore) {
                        _load();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _entries.length + (_loading ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i == _entries.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final e = _entries[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _eventColor(
                                e.event,
                              ).withOpacity(0.15),
                              child: Text(
                                e.event[0].toUpperCase(),
                                style: TextStyle(
                                  color: _eventColor(e.event),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              '${e.event.toUpperCase()} — ${e.subjectType.split('\\').last}',
                            ),
                            subtitle: Text(
                              'ID: ${e.subjectId ?? '-'}  •  User: ${e.causerId ?? '-'}\n${e.createdAt}',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
