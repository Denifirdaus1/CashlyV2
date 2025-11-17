import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
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
        RefreshIndicator(
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
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama kelompok'),
                  validator: (val) => val == null || val.isEmpty ? 'Harus diisi' : null,
                ),
                TextFormField(
                  controller: descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Deskripsi (opsional)'),
                ),
                TextFormField(
                  controller: targetCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Target total nominal'),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Harus diisi';
                    final parsed = double.tryParse(val.replaceAll(',', ''));
                    if (parsed == null) return 'Nominal tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final target = double.parse(targetCtrl.text.replaceAll(',', ''));
                      try {
                        await ref.read(groupSavingRepositoryProvider).createGroup(
                              name: nameCtrl.text,
                              description:
                                  descCtrl.text.isEmpty ? null : descCtrl.text,
                              targetTotal: Money.fromDouble(target),
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
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GroupDetailPage(
              groupId: summary.groupId,
              name: summary.name,
            ),
          ));
        },
        title: Text(summary.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            LinearProgressIndicator(value: summary.progress),
            const SizedBox(height: 6),
            Text(
              '${summary.totalContributed.format()} / ${summary.targetTotal.format()}',
              style: const TextStyle(fontSize: 12),
            ),
            Text('Anggota: ${summary.memberCount}', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
