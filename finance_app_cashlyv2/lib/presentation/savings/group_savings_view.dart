import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../core/input_formatters/money_input_formatter.dart';
import '../../core/money.dart';
import '../../domain/models/group_summary.dart';
import 'group_savings_view_detail.dart';

class GroupSavingsView extends ConsumerWidget {
  const GroupSavingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupSummariesProvider);

    return Stack(
      children: [
        Container(
          color: const Color(0xFFEFF7F6),
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupSummariesProvider);
              await ref.read(groupSummariesProvider.future);
            },
            child: groups.when(
              data: (items) => items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 48),
                        Center(child: Text('Belum ada kelompok tabungan.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                      itemCount: items.length,
                      itemBuilder: (ctx, index) =>
                          _GroupTile(summary: items[index]),
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
            onPressed: () => _showAddGroupSheet(context, ref),
            icon: const Icon(Icons.group_add),
            label: const Text('Kelompok'),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddGroupSheet(BuildContext context, WidgetRef ref) async {
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
                    const Text('Buat Kelompok',
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
                      child: Text(deadline != null
                          ? DateFormat.yMMMd().format(deadline!)
                          : 'Deadline?'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tujuan menabung'),
                  validator: (val) => val == null || val.isEmpty ? 'Harus diisi' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Deskripsi (opsional)'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration:
                      const InputDecoration(labelText: 'Target total nominal'),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Harus diisi';
                    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.isEmpty) return 'Nominal tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _PresetRow(
                  onAdd: (inc) {
                    final current = Money.fromFormatted(targetCtrl.text);
                    final updated = Money(current.cents + inc);
                    targetCtrl.text =
                        NumberFormat.decimalPattern('id_ID').format(updated.cents ~/ 100);
                  },
                  onSet: (val) {
                    targetCtrl.text =
                        NumberFormat.decimalPattern('id_ID').format(val ~/ 100);
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
                        await ref.read(groupSavingRepositoryProvider).createGroup(
                              name: nameCtrl.text,
                              description:
                                  descCtrl.text.isEmpty ? null : descCtrl.text,
                              targetTotal: target,
                              deadline: deadline,
                            );
                        ref.invalidate(groupSummariesProvider);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Kelompok dibuat')),
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

class _GroupTile extends StatelessWidget {
  final GroupSummary summary;
  const _GroupTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GroupDetailPage(
              groupId: summary.groupId,
              name: summary.name,
              avatarUrl: summary.avatarUrl,
            ),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFF68CEC3).withValues(alpha: 0.15),
                backgroundImage: summary.avatarUrl != null
                    ? NetworkImage(summary.avatarUrl!)
                    : null,
                child: summary.avatarUrl == null
                    ? const Icon(Icons.groups, color: Color(0xFF68CEC3))
                    : null,
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
                        value: summary.progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF68CEC3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${summary.totalContributed.format()} / ${summary.targetTotal.format()}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text('Anggota: ${summary.memberCount}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
