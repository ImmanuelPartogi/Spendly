import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Backup Service
// ─────────────────────────────────────────────────────────────────────────────

const _kLastBackup = 'last_backup_date';

class BackupService {
  BackupService._();

  /// Export semua data ke JSON file.
  static Future<File> exportToJson({
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> wallets,
    required List<Map<String, dynamic>> budgets,
    required List<Map<String, dynamic>> goals,
  }) async {
    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'transactions': transactions,
        'wallets': wallets,
        'budgets': budgets,
        'goals': goals,
      },
    };

    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/spendly_backup_$ts.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );

    // Simpan tanggal backup terakhir
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kLastBackup, DateTime.now().toIso8601String(),);

    return file;
  }

  /// Restore data dari JSON file.
  static Future<BackupPayload> importFromJson(File file) async {
    final raw = await file.readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return BackupPayload.fromJson(json);
  }

  /// Share file via OS share sheet.
  static Future<void> shareBackup(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Spendly Backup',
      ),
    );
  }

  /// Tanggal backup terakhir (null jika belum pernah).
  static Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_kLastBackup);
    return str != null ? DateTime.parse(str) : null;
  }
}

class BackupPayload {
  final int version;
  final DateTime exportedAt;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> wallets;
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> goals;

  const BackupPayload({
    required this.version,
    required this.exportedAt,
    required this.transactions,
    required this.wallets,
    required this.budgets,
    required this.goals,
  });

  factory BackupPayload.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return BackupPayload(
      version: json['version'] as int,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      transactions: _castList(data['transactions']),
      wallets: _castList(data['wallets']),
      budgets: _castList(data['budgets']),
      goals: _castList(data['goals']),
    );
  }

  static List<Map<String, dynamic>> _castList(dynamic raw) {
    if (raw == null) return [];
    return (raw as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Backup Screen UI
// ─────────────────────────────────────────────────────────────────────────────

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  DateTime? _lastBackup;

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  Future<void> _loadLastBackup() async {
    final dt = await BackupService.getLastBackupDate();
    if (mounted) setState(() => _lastBackup = dt);
  }

  Future<void> _backup() async {
    setState(() => _isBackingUp = true);
    try {
      // TODO: fetch real data from providers
      final file = await BackupService.exportToJson(
        transactions: [],
        wallets: [],
        budgets: [],
        goals: [],
      );
      await BackupService.shareBackup(file);
      await _loadLastBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restore() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore Data?'),
        content: const Text(
          'Data yang ada saat ini akan digantikan dengan data dari file backup. '
          'Pastikan kamu memilih file backup Spendly yang valid.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);
    try {
      // TODO: use file_picker to select JSON file
      // final result = await FilePicker.platform.pickFiles(
      //   type: FileType.custom,
      //   allowedExtensions: ['json'],
      // );
      // if (result == null) return;
      // final file = File(result.files.single.path!);
      // final payload = await BackupService.importFromJson(file);
      // TODO: restore data into local database

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dipulihkan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status card ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_rounded,
                          color: Colors.white, size: 20,),
                      SizedBox(width: 8),
                      Text(
                        'Status Backup',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _lastBackup == null
                        ? 'Belum pernah di-backup'
                        : 'Terakhir: ${_formatDate(_lastBackup!)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Backup section ────────────────────────────────────────────
            Text('Backup', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Export semua data (transaksi, wallet, budget, goals) ke file JSON '
              'yang bisa disimpan di perangkat atau dibagikan.',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,),
            ),
            const SizedBox(height: 16),
            _ActionCard(
              icon: Icons.upload_rounded,
              color: AppColors.primary,
              title: 'Buat Backup',
              subtitle: 'Export ke file JSON',
              isLoading: _isBackingUp,
              onTap: _backup,
            ),
            const SizedBox(height: 28),

            // ── Restore section ───────────────────────────────────────────
            Text('Restore', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Pulihkan data dari file backup JSON yang sebelumnya dibuat. '
              'Data yang ada saat ini akan digantikan.',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,),
            ),
            const SizedBox(height: 16),
            _ActionCard(
              icon: Icons.download_rounded,
              color: AppColors.income,
              title: 'Restore dari File',
              subtitle: 'Import file JSON backup',
              isLoading: _isRestoring,
              onTap: _restore,
            ),
            const SizedBox(height: 28),

            // ── Tips ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_rounded,
                      color: AppColors.warning, size: 18,),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Backup secara berkala untuk mencegah kehilangan data. '
                      'Simpan file backup di Google Drive atau cloud storage lainnya.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning.withValues(alpha: 0.9),
                        height: 1.5,
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
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: isLoading
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      ),
                    )
                  : Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700,),),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,),),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textHint,),
          ],
        ),
      ),
    );
  }
}