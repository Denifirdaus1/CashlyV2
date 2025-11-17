import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../core/money.dart';
import '../../domain/enums.dart';
import '../../domain/models/group_member_summary.dart';
import '../../domain/models/group_summary.dart';
import '../../domain/models/saving_group_entry.dart';

class GroupDetailPage extends ConsumerWidget {
  final String groupId;
  final String name;

  const GroupDetailPage({
    super.key,
    required this.groupId,
    required this.name,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberSummaries = ref.watch(groupMemberSummariesProvider(groupId));
    final entries = ref.watch(groupEntriesProvider(groupId));
    final summary = ref.watch(groupSummariesProvider).maybeWhen(
          data: (list) => list.firstWhere(
            (g) => g.groupId == groupId,
            orElse: () => GroupSummary(
              groupId: groupId,
              name: name,
              targetTotal: Money.zero,
              totalContributed: Money.zero,
              memberCount: 0,
            ),
          ),
          orElse: () => null,
        );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ringkasan'),
              Tab(text: 'Anggota'),
              Tab(text: 'Transaksi'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SummaryTab(summary: summary),
            _MemberTab(
              members: memberSummaries,
              onAddMember: () => _showAddMember(context, ref),
            ),
            _TransactionsTab(
              entries: entries,
              members: memberSummaries,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddEntry(context, ref),
          icon: const Icon(Icons.savings),
          label: const Text('Transaksi'),
        ),
      ),
    );
  }

  Future<void> _showAddMember(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();

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
                const Text('Tambah Anggota', style: TextStyle(fontWeight: FontWeight.w600)),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (val) => val == null || val.isEmpty ? 'Harus diisi' : null,
                ),
                TextFormField(
                  controller: targetCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Target nominal (opsional)'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final targetRaw = targetCtrl.text.trim();
                      try {
                        await ref.read(groupSavingRepositoryProvider).addMember(
                              groupId: groupId,
                              displayName: nameCtrl.text,
                              targetAmount: targetRaw.isEmpty
                                  ? null
                                  : Money.fromDouble(
                                      double.parse(targetRaw.replaceAll(',', '')),
                                    ),
                            );
                        ref.invalidate(groupMemberSummariesProvider(groupId));
                        ref.invalidate(groupSummariesProvider);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Anggota ditambahkan')),
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

  Future<void> _showAddEntry(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    var selectedType = SavingEntryType.deposit;
    String? selectedMemberId;
    final members = await ref.read(groupMemberSummariesProvider(groupId).future);

    if (!context.mounted) return;

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
                    const Text('Catat Transaksi'),
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
                DropdownButtonFormField<String>(
                  initialValue: selectedMemberId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Pilih anggota'),
                  items: members
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.memberId,
                          child: Text(m.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => selectedMemberId = val,
                  validator: (val) => val == null ? 'Pilih anggota' : null,
                ),
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
                TextFormField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Nominal'),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Harus diisi';
                    return double.tryParse(val.replaceAll(',', '')) == null
                        ? 'Nominal tidak valid'
                        : null;
                  },
                ),
                TextFormField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      if (selectedMemberId == null) return;
                      final amount =
                          double.parse(amountCtrl.text.replaceAll(',', ''));
                      final member = members.firstWhere(
                        (m) => m.memberId == selectedMemberId,
                        orElse: () => members.first,
                      );
                      if (selectedType == SavingEntryType.withdraw &&
                          Money.fromDouble(amount).cents >
                              member.totalContributed.cents) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                                'Tarik melebihi saldo anggota ${member.displayName}'),
                          ),
                        );
                        return;
                      }

                      try {
                        await ref.read(groupSavingRepositoryProvider).addEntry(
                              groupId: groupId,
                              memberId: selectedMemberId!,
                              transactionDate: selectedDate,
                              amount: Money.fromDouble(amount),
                              type: selectedType,
                              note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                            );
                        ref.invalidate(groupEntriesProvider(groupId));
                        ref.invalidate(groupMemberSummariesProvider(groupId));
                        ref.invalidate(groupSummariesProvider);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Transaksi kelompok tersimpan')),
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

class _SummaryTab extends StatelessWidget {
  final GroupSummary? summary;
  const _SummaryTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary!.name,
                    style:
                        const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: summary!.progress),
                const SizedBox(height: 8),
                Text(
                  '${summary!.totalContributed.format()} / ${summary!.targetTotal.format()}',
                ),
                const SizedBox(height: 8),
                Text('Jumlah anggota: ${summary!.memberCount}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberTab extends StatelessWidget {
  final AsyncValue<List<GroupMemberSummary>> members;
  final VoidCallback onAddMember;
  const _MemberTab({
    required this.members,
    required this.onAddMember,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onAddMember,
              icon: const Icon(Icons.person_add),
              label: const Text('Tambah anggota'),
            ),
          ),
        ),
        Expanded(
          child: members.when(
            data: (items) => items.isEmpty
                ? const Center(child: Text('Belum ada anggota.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    itemBuilder: (ctx, index) =>
                        _MemberTile(summary: items[index]),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text(err.toString(), style: const TextStyle(color: Colors.red))),
          ),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final GroupMemberSummary summary;
  const _MemberTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(summary.displayName),
        subtitle: Text(
          'Terkumpul: ${summary.totalContributed.format()}'
          '${summary.targetAmount != null ? ' / ${summary.targetAmount!.format()}' : ''}',
        ),
      ),
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  final AsyncValue<List<SavingGroupEntry>> entries;
  final AsyncValue<List<GroupMemberSummary>> members;

  const _TransactionsTab({
    required this.entries,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return entries.when(
      data: (items) {
        final memberMap = members.asData?.value.fold<Map<String, String>>(
              {},
              (acc, m) {
                acc[m.memberId] = m.displayName;
                return acc;
              },
            ) ??
            {};

        if (items.isEmpty) {
          return const Center(child: Text('Belum ada transaksi.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (ctx, index) =>
              _EntryTile(entry: items[index], memberMap: memberMap),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text(err.toString(), style: const TextStyle(color: Colors.red))),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final SavingGroupEntry entry;
  final Map<String, String> memberMap;

  const _EntryTile({required this.entry, required this.memberMap});

  @override
  Widget build(BuildContext context) {
    final isDeposit = entry.type == SavingEntryType.deposit;
    final memberName = memberMap[entry.memberId] ?? 'Anggota';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDeposit ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            isDeposit ? Icons.upload : Icons.download,
            color: isDeposit ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          entry.amount.format(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$memberName - ${DateFormat.yMMMd().format(entry.transactionDate)}'
          '${entry.note != null && entry.note!.isNotEmpty ? ' - ${entry.note}' : ''}',
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
