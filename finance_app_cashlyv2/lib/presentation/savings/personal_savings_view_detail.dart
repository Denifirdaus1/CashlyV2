import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../core/input_formatters/money_input_formatter.dart';
import '../../core/money.dart';
import '../../domain/enums.dart';
import '../../domain/models/personal_goal_summary.dart';
import '../../domain/models/saving_personal_entry.dart';

class PersonalGoalDetailPage extends ConsumerWidget {
  final String goalId;
  final String name;

  const PersonalGoalDetailPage({
    super.key,
    required this.goalId,
    required this.name,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(personalGoalEntriesProvider(goalId));
    final allGoals = ref.watch(personalGoalsProvider);
    final summary = allGoals.maybeWhen(
      data: (list) => list.firstWhere(
        (g) => g.goalId == goalId,
        orElse: () => PersonalGoalSummary(
          goalId: goalId,
          name: name,
          targetAmount: Money.zero,
          currentAmount: Money.zero,
        ),
      ),
      orElse: () => null,
    );
    final effectiveName = summary?.name ?? name;

    return Scaffold(
      appBar: AppBar(
        title: Text(effectiveName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditGoalSheet(context, ref, summary),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus tujuan?'),
                  content: const Text('Tindakan ini akan menghapus tujuan dan transaksinya.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(personalSavingRepositoryProvider).deleteGoal(goalId);
                ref.invalidate(personalGoalsProvider);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFEFF7F6),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(personalGoalEntriesProvider(goalId));
            ref.invalidate(personalGoalsProvider);
            await ref.read(personalGoalEntriesProvider(goalId).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
            children: [
              if (summary != null) _GoalHeader(summary: summary),
              const SizedBox(height: 8),
              entries.when(
                data: (items) => items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Belum ada transaksi tabungan.')),
                      )
                    : Column(
                        children:
                            items.map((e) => _EntryTile(entry: e)).toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(err.toString(),
                      style: const TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntrySheet(context, ref, summary),
        icon: const Icon(Icons.add),
        label: const Text('Transaksi'),
      ),
    );
  }

  Future<void> _showAddEntrySheet(
    BuildContext context,
    WidgetRef ref,
    PersonalGoalSummary? summary,
  ) async {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    var selectedType = SavingEntryType.deposit;
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tambah Transaksi'),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) selectedDate = picked;
                      },
                      child: Text(DateFormat.yMMMd().format(selectedDate)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<SavingEntryType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Jenis'),
                  items: SavingEntryType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t == SavingEntryType.deposit ? 'Setor' : 'Tarik'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => selectedType = val ?? selectedType,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Nominal'),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Harus diisi';
                    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
                    return digits.isEmpty ? 'Nominal tidak valid' : null;
                  },
                ),
                const SizedBox(height: 12),
                _PresetRow(
                  onAdd: (inc) {
                    final current = Money.fromFormatted(amountCtrl.text);
                    final updated = Money(current.cents + inc);
                    amountCtrl.text =
                        NumberFormat.decimalPattern('id_ID').format(updated.cents ~/ 100);
                  },
                  onSet: (val) {
                    amountCtrl.text =
                        NumberFormat.decimalPattern('id_ID').format(val ~/ 100);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final amount = Money.fromFormatted(amountCtrl.text);
                      final current = summary?.currentAmount.cents ?? 0;
                      if (selectedType == SavingEntryType.withdraw &&
                          amount.cents > current) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Nominal tarik melebihi saldo tujuan'),
                          ),
                        );
                        return;
                      }

                      try {
                        await ref.read(personalSavingRepositoryProvider).addEntry(
                              goalId: goalId,
                              transactionDate: selectedDate,
                              amount: amount,
                              type: selectedType,
                              note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                            );
                        ref.invalidate(personalGoalEntriesProvider(goalId));
                        ref.invalidate(personalGoalsProvider);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Transaksi tabungan tersimpan')),
                          );
                        }
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Gagal simpan: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditGoalSheet(
    BuildContext context,
    WidgetRef ref,
    PersonalGoalSummary? summary,
  ) async {
    final formKey = GlobalKey<FormState>();
    final currentName = summary?.name ?? name;
    final nameCtrl = TextEditingController(text: currentName);
    final descCtrl = TextEditingController();
    final targetCtrl = TextEditingController(
      text: summary != null
          ? NumberFormat.decimalPattern('id_ID')
              .format(summary.targetAmount.cents ~/ 100)
          : '',
    );
    DateTime? deadline;
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Tujuan',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) deadline = picked;
                      },
                      child: Text(
                          deadline != null ? DateFormat.yMMMd().format(deadline!) : 'Deadline?'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama tujuan'),
                  validator: (val) => val == null || val.isEmpty ? 'Harus diisi' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Target nominal'),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Harus diisi';
                    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.isEmpty) return 'Nominal tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      try {
                        await ref.read(personalSavingRepositoryProvider).updateGoal(
                              goalId: goalId,
                              name: nameCtrl.text,
                              description:
                                  descCtrl.text.isEmpty ? null : descCtrl.text,
                              targetAmount: Money.fromFormatted(targetCtrl.text),
                              deadline: deadline,
                            );
                        ref.invalidate(personalGoalsProvider);
                        ref.invalidate(personalGoalEntriesProvider(goalId));
                        if (context.mounted) Navigator.of(context).pop();
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Gagal simpan: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GoalHeader extends StatelessWidget {
  final PersonalGoalSummary summary;
  const _GoalHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    final progress = summary.progress;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF68CEC3),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${summary.currentAmount.format()} / ${summary.targetAmount.format()}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final SavingPersonalEntry entry;
  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDeposit = entry.type == SavingEntryType.deposit;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDeposit ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            isDeposit ? Icons.upload : Icons.download,
            color: isDeposit ? Colors.green : Colors.red,
          ),
        ),
        title: Text(entry.amount.format(),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          DateFormat.yMMMd().format(entry.transactionDate) +
              (entry.note != null && entry.note!.isNotEmpty
                  ? ' • ${entry.note}'
                  : ''),
        ),
        trailing: Text(
          isDeposit ? 'Setor' : 'Tarik',
          style: TextStyle(
            color: isDeposit ? Colors.green : Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  final void Function(int cents) onAdd;
  final void Function(int cents) onSet;

  const _PresetRow({required this.onAdd, required this.onSet});

  @override
  Widget build(BuildContext context) {
    final presets = [500000, 1000000, 5000000, 10000000];
    return Wrap(
      spacing: 8,
      children: presets
          .map(
            (c) => OutlinedButton(
              onPressed: () => onAdd(c),
              onLongPress: () => onSet(c),
              child: Text('Rp ${NumberFormat.decimalPattern('id_ID').format(c ~/ 100)}'),
            ),
          )
          .toList(),
    );
  }
}
