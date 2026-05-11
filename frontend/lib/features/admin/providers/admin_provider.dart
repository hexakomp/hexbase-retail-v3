import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

// ─── Company Settings ───────────────────────────────────────────────────────

class CompanySettingsRepository {
  final ApiClient _client;
  CompanySettingsRepository(this._client);

  Future<Map<String, dynamic>> get() async {
    final res = await _client.dio.get('/api/v1/admin/company');
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<void> update(Map<String, dynamic> payload) async {
    await _client.dio.put('/api/v1/admin/company', data: payload);
  }
}

// ─── Bank Accounts ──────────────────────────────────────────────────────────

class BankAccount {
  final int id;
  final String name;
  final String accountNumber;
  final String ifsc;
  final String bankName;
  final bool isActive;

  const BankAccount({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.ifsc,
    required this.bankName,
    required this.isActive,
  });

  factory BankAccount.fromJson(Map<String, dynamic> j) => BankAccount(
    id: j['id'],
    name: j['name'] ?? '',
    accountNumber: j['account_number'] ?? '',
    ifsc: j['ifsc'] ?? '',
    bankName: j['bank_name'] ?? '',
    isActive: j['is_active'] == true,
  );
}

class BankAccountRepository {
  final ApiClient _client;
  BankAccountRepository(this._client);

  Future<List<BankAccount>> list() async {
    final res = await _client.dio.get('/api/v1/admin/bank-accounts');
    return (res.data['data'] as List)
        .map((j) => BankAccount.fromJson(j))
        .toList();
  }

  Future<void> create(Map<String, dynamic> data) async =>
      await _client.dio.post('/api/v1/admin/bank-accounts', data: data);

  Future<void> update(int id, Map<String, dynamic> data) async =>
      await _client.dio.put('/api/v1/admin/bank-accounts/$id', data: data);

  Future<void> delete(int id) async =>
      await _client.dio.delete('/api/v1/admin/bank-accounts/$id');

  Future<void> toggleActive(int id) async =>
      await _client.dio.patch('/admin/bank-accounts/$id/toggle-active');
}

// ─── Users ──────────────────────────────────────────────────────────────────

class AdminUser {
  final int id;
  final String name;
  final String email;
  final List<String> roles;
  final bool isActive;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    required this.isActive,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
    id: j['id'],
    name: j['name'] ?? '',
    email: j['email'] ?? '',
    roles: (j['roles'] as List? ?? []).map((r) => r.toString()).toList(),
    isActive: j['is_active'] == true,
  );
}

class AdminUsersRepository {
  final ApiClient _client;
  AdminUsersRepository(this._client);

  Future<List<AdminUser>> list() async {
    final res = await _client.dio.get('/api/v1/admin/users');
    return (res.data['data'] as List)
        .map((j) => AdminUser.fromJson(j))
        .toList();
  }

  Future<void> create(Map<String, dynamic> data) async =>
      await _client.dio.post('/api/v1/admin/users', data: data);

  Future<void> update(int id, Map<String, dynamic> data) async =>
      await _client.dio.put('/api/v1/admin/users/$id', data: data);

  Future<void> deactivate(int id) async =>
      await _client.dio.patch('/admin/users/$id/deactivate');
}

// ─── Numbering Sequences ────────────────────────────────────────────────────

class NumberingSequence {
  final int id;
  final String type;
  final String prefix;
  final int nextNumber;
  final int padding;

  const NumberingSequence({
    required this.id,
    required this.type,
    required this.prefix,
    required this.nextNumber,
    required this.padding,
  });

  factory NumberingSequence.fromJson(Map<String, dynamic> j) =>
      NumberingSequence(
        id: j['id'],
        type: j['type'] ?? '',
        prefix: j['prefix'] ?? '',
        nextNumber: j['next_number'] ?? 1,
        padding: j['padding'] ?? 4,
      );
}

class NumberingSequenceRepository {
  final ApiClient _client;
  NumberingSequenceRepository(this._client);

  Future<List<NumberingSequence>> list() async {
    final res = await _client.dio.get('/api/v1/admin/numbering-sequences');
    return (res.data['data'] as List)
        .map((j) => NumberingSequence.fromJson(j))
        .toList();
  }

  Future<void> update(int id, Map<String, dynamic> data) async =>
      await _client.dio.put('/api/v1/admin/numbering-sequences/$id', data: data);
}

// ─── Activity Log ───────────────────────────────────────────────────────────

class ActivityLogEntry {
  final int id;
  final String event;
  final String subjectType;
  final int? subjectId;
  final int? causerId;
  final String? properties;
  final String createdAt;

  const ActivityLogEntry({
    required this.id,
    required this.event,
    required this.subjectType,
    this.subjectId,
    this.causerId,
    this.properties,
    required this.createdAt,
  });

  factory ActivityLogEntry.fromJson(Map<String, dynamic> j) => ActivityLogEntry(
    id: j['id'],
    event: j['event'] ?? '',
    subjectType: j['subject_type'] ?? '',
    subjectId: j['subject_id'],
    causerId: j['causer_id'],
    properties: j['properties'],
    createdAt: j['created_at'] ?? '',
  );
}

class ActivityLogRepository {
  final ApiClient _client;
  ActivityLogRepository(this._client);

  Future<Map<String, dynamic>> list({int page = 1, int? userId}) async {
    final res = await _client.dio.get(
      '/admin/activity-log',
      queryParameters: {'page': page, if (userId != null) 'user_id': userId},
    );
    return res.data;
  }
}

// ─── Backups ─────────────────────────────────────────────────────────────────

class BackupFile {
  final String id;
  final String name;
  final int size;
  final int created;

  const BackupFile({
    required this.id,
    required this.name,
    required this.size,
    required this.created,
  });

  factory BackupFile.fromJson(Map<String, dynamic> j) => BackupFile(
    id: j['id'],
    name: j['name'],
    size: j['size'] ?? 0,
    created: j['created'] ?? 0,
  );
}

class BackupRepository {
  final ApiClient _client;
  BackupRepository(this._client);

  Future<List<BackupFile>> list() async {
    final res = await _client.dio.get('/api/v1/admin/backups');
    return (res.data['data'] as List)
        .map((j) => BackupFile.fromJson(j))
        .toList();
  }

  Future<void> create() async => await _client.dio.post('/api/v1/admin/backups');

  String downloadUrl(String id) => '/admin/backups/$id/download';
}

// ─── Providers ───────────────────────────────────────────────────────────────

final companySettingsRepositoryProvider = Provider(
  (ref) => CompanySettingsRepository(ref.read(apiClientProvider)),
);

final bankAccountRepositoryProvider = Provider(
  (ref) => BankAccountRepository(ref.read(apiClientProvider)),
);

final adminUsersRepositoryProvider = Provider(
  (ref) => AdminUsersRepository(ref.read(apiClientProvider)),
);

final numberingSequenceRepositoryProvider = Provider(
  (ref) => NumberingSequenceRepository(ref.read(apiClientProvider)),
);

final activityLogRepositoryProvider = Provider(
  (ref) => ActivityLogRepository(ref.read(apiClientProvider)),
);

final backupRepositoryProvider = Provider(
  (ref) => BackupRepository(ref.read(apiClientProvider)),
);

final bankAccountsProvider = FutureProvider.autoDispose<List<BankAccount>>(
  (ref) => ref.read(bankAccountRepositoryProvider).list(),
);

final adminUsersProvider = FutureProvider.autoDispose<List<AdminUser>>(
  (ref) => ref.read(adminUsersRepositoryProvider).list(),
);

final numberingSequencesProvider =
    FutureProvider.autoDispose<List<NumberingSequence>>(
      (ref) => ref.read(numberingSequenceRepositoryProvider).list(),
    );

final backupsProvider = FutureProvider.autoDispose<List<BackupFile>>(
  (ref) => ref.read(backupRepositoryProvider).list(),
);
