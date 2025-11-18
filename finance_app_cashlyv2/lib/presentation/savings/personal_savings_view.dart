import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../core/input_formatters/money_input_formatter.dart';
import '../../core/money.dart';
import '../../domain/models/personal_goal_summary.dart';
import 'personal_savings_view_detail.dart';

class PersonalSavingsView extends ConsumerWidget {
  const PersonalSavingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(personalGoalsProvider);

    return Stack(
      children: [
        Container(
          color: const Color(0xFFEFF7F6),
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(personalGoalsProvider);
              await ref.read(personalGoalsProvider.future);
            },
            child: goals.when(
              data: (items) => items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 48),
                        Center(child: Text('Belum ada tujuan tabungan.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                      itemCount: items.length,
                      itemBuilder: (ctx, index) =>
                          _GoalTile(summary: items[index]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(err.toString(), style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddGoalSheet(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Tujuan'),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddGoalSheet(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    DateTime? deadline;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final messenger = ScaffoldMessenger.of(ctx);
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
                    const Text('Buat Tujuan', style: TextStyle(fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          deadline = picked;
                        }
                      },
                      child: Text(deadline != null
                          ? DateFormat.yMMMd().format(deadline!)
                          : 'Deadline?'),
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
                const SizedBox(height: 12),
                _PresetRow(
                  onAdd: (increment) {
                    final current = Money.fromFormatted(targetCtrl.text);
                    final updated = Money(current.cents + increment);
                    targetCtrl.text =
                        NumberFormat.decimalPattern('id_ID').format(updated.cents ~/ 100);
                  },
                  onSet: (value) {
                    targetCtrl.text =
                        NumberFormat.decimalPattern('id_ID').format(value ~/ 100);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final target = Money.fromFormatted(targetCtrl.text);
                      try {
                        await ref
                            .read(personalSavingRepositoryProvider)
                            .createGoal(
                              name: nameCtrl.text,
                              description:
                                  descCtrl.text.isEmpty ? null : descCtrl.text,
                              targetAmount: target,
                              deadline: deadline,
                            );
                        ref.invalidate(personalGoalsProvider);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Tujuan tabungan dibuat'),
                            ),
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
}

class _GoalTile extends StatelessWidget {
  final PersonalGoalSummary summary;
  const _GoalTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    final progress = summary.progress;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PersonalGoalDetailPage(
              goalId: summary.goalId,
              name: summary.name,
            ),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF68CEC3).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.savings, color: Color(0xFF68CEC3)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 6),
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
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
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
    final presets = [500000, 1000000, 5000000, 10000000]; // cents
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
