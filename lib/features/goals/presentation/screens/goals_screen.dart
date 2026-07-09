import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/goal_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Goals Screen
// ─────────────────────────────────────────────────────────────────────────────

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Target Keuangan')),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.expense,),
              const SizedBox(height: 12),
              Text('Gagal memuat goals',
                  style: Theme.of(context).textTheme.bodyLarge,),
            ],
          ),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🏆', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Belum ada goals',
                      style: TextStyle(color: AppColors.textSecondary),),
                ],
              ),
            );
          }

          final active = goals.where((g) => !g.isCompleted).toList();
          final completed = goals.where((g) => g.isCompleted).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                const _SectionTitle('Goals Aktif'),
                const SizedBox(height: 10),
                ...active.map((g) => _GoalCard(
                      goal: g,
                      onAddFunds: () => _showAddFundsDialog(context, ref, g),
                      onEdit: () => _openAddEdit(context, existing: g),
                      onDelete: () => _confirmDelete(context, ref, g),
                    ),),
              ],
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _SectionTitle('🎉 Tercapai'),
                const SizedBox(height: 10),
                ...completed.map((g) => _GoalCard(
                      goal: g,
                      onAddFunds: () {},
                      onEdit: () {},
                      onDelete: () => _confirmDelete(context, ref, g),
                    ),),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEdit(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showAddFundsDialog(
      BuildContext context, WidgetRef ref, GoalEntity goal,) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Alokasi ke "${goal.title}"'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(hintText: 'Jumlah', prefixText: 'Rp '),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text) ?? 0.0;
              if (amount > 0) {
                await ref
                    .read(allocateFundsUseCaseProvider)
                    .call(goal.id, amount);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Alokasi'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, GoalEntity goal) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Goal?'),
        content: Text('"${goal.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(deleteGoalUseCaseProvider).call(goal.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _openAddEdit(BuildContext context, {GoalEntity? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddGoalSheet(existing: existing),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalEntity goal;
  final VoidCallback onAddFunds;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onAddFunds,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: goal.isCompleted ? goal.color.withValues(alpha: 0.05) : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              goal.isCompleted ? goal.color.withValues(alpha: 0.3) : AppColors.border,
          width: goal.isCompleted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: goal.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(goal.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (goal.isCompleted)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.check_circle_rounded,
                                color: AppColors.income, size: 16,),
                          ),
                      ],
                    ),
                    Text(
                      goal.isCompleted
                          ? 'Goal tercapai! 🎉'
                          : goal.isOverdue
                              ? '⚠️ Deadline terlewati'
                              : '${goal.daysLeft} hari tersisa',
                      style: TextStyle(
                        fontSize: 12,
                        color: goal.isCompleted
                            ? AppColors.income
                            : goal.isOverdue
                                ? AppColors.expense
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus',
                        style: TextStyle(color: AppColors.expense),),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: goal.currentAmount),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => Text(
                  CurrencyFormatter.format(val),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: goal.color,
                  ),
                ),
              ),
              Text(
                CurrencyFormatter.format(goal.targetAmount),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary,),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: goal.progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: val,
                backgroundColor: goal.color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(goal.color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(goal.progress * 100).toStringAsFixed(0)}% tercapai',
                style: TextStyle(
                  fontSize: 11,
                  color: goal.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!goal.isCompleted && goal.dailySavingsNeeded > 0)
                Text(
                  'Perlu ${CurrencyFormatter.formatCompact(goal.dailySavingsNeeded)}/hari',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary,),
                ),
            ],
          ),
          if (!goal.isCompleted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddFunds,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Alokasi Dana'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: goal.color,
                  side: BorderSide(color: goal.color),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add/Edit Goal Sheet
// ─────────────────────────────────────────────────────────────────────────────

class AddGoalSheet extends ConsumerStatefulWidget {
  final GoalEntity? existing;
  const AddGoalSheet({super.key, this.existing});

  @override
  ConsumerState<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<AddGoalSheet> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  String _emoji = '🎯';
  Color _color = AppColors.primary;
  DateTime _deadline = DateTime.now().add(const Duration(days: 180));
  bool _isLoading = false;

  static const _emojis = [
    '🎯',
    '🏠',
    '📱',
    '🚗',
    '✈️',
    '🏝️',
    '🎓',
    '💍',
    '💼',
    '🛡️',
    '🏆',
    '💻',
  ];
  static const _colors = [
    AppColors.primary,
    Color(0xFF7C5CBF),
    AppColors.income,
    AppColors.expense,
    AppColors.warning,
    AppColors.accentTeal,
    AppColors.accentOrange,
    Color(0xFF0066AE),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _titleCtrl.text = e.title;
      _targetCtrl.text = e.targetAmount.toStringAsFixed(0);
      _emoji = e.emoji;
      _color = e.color;
      _deadline = e.deadline;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final targetText = _targetCtrl.text.trim();
    if (title.isEmpty || targetText.isEmpty) return;

    final target = double.tryParse(targetText);
    if (target == null || target <= 0) return;

    setState(() => _isLoading = true);

    try {
      final entity = GoalEntity(
        id: widget.existing?.id ?? '',
        title: title,
        emoji: _emoji,
        targetAmount: target,
        currentAmount: widget.existing?.currentAmount ?? 0,
        deadline: _deadline,
        color: _color,
        isCompleted: widget.existing?.isCompleted ?? false,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );

      if (widget.existing == null) {
        await ref.read(addGoalUseCaseProvider).call(entity);
      } else {
        await ref.read(updateGoalUseCaseProvider).call(entity);
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.existing == null ? 'Buat Goal Baru' : 'Edit Goal',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            // Emoji picker
            Text('Ikon', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((e) {
                final isSel = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          isSel ? _color.withValues(alpha: 0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel ? _color : AppColors.border,
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 20)),),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Color picker
            Text('Warna', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: _colors.map((c) {
                final isSel = c.toARGB32() == _color.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isSel
                          ? Border.all(color: AppColors.textPrimary, width: 3)
                          : null,
                    ),
                    child: isSel
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Nama Goal'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Nominal',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _deadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2035),
                );
                if (d != null) setState(() => _deadline = d);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded,
                        size: 18, color: AppColors.textSecondary,),
                    const SizedBox(width: 10),
                    Text(
                      'Deadline: ${_deadline.day}/${_deadline.month}/${_deadline.year}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: _color),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2,),)
                    : const Text('Simpan Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
