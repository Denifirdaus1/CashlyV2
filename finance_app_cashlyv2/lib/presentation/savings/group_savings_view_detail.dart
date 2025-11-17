import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../core/input_formatters/money_input_formatter.dart';
import '../../core/money.dart';
import '../../domain/enums.dart';
import '../../domain/models/group_member_summary.dart';
import '../../domain/models/group_summary.dart';
import '../../domain/models/saving_group_entry.dart';
import '../../infrastructure/supabase/supabase_storage_service.dart';

class GroupDetailPage extends ConsumerWidget {
  final String groupId;
  final String name;
  final String? avatarUrl;

  const GroupDetailPage({
    super.key,
    required this.groupId,
    required this.name,
    this.avatarUrl,
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
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF68CEC3).withValues(alpha: 0.15),
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.groups, color: Color(0xFF68CEC3))
                    : null,
              ),
              const SizedBox(width: 10),
              Text(name),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ringkasan'),
              Tab(text: 'Anggota'),
              Tab(text: 'Transaksi'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditGroup(context, ref, summary),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _SummaryTab(summary: summary),
            _MemberTab(
              members: memberSummaries,
              entries: entries,
              groupId: groupId,
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
    final picker = ImagePicker();
    File? pickedImage;
    final storage = SupabaseStorageService(ref.read(supabaseClientProvider));

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
                GestureDetector(
                  onTap: () async {
                    final file = await picker.pickImage(source: ImageSource.gallery);
                    if (file != null) {
                      pickedImage = File(file.path);
                    }
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        pickedImage != null ? FileImage(pickedImage!) : null,
                    child: pickedImage == null
                        ? const Icon(Icons.camera_alt)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Tambah Anggota', style: TextStyle(fontWeight: FontWeight.w600)),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (val) => val == null || val.isEmpty ? 'Harus diisi' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: const InputDecoration(
                      labelText: 'Target nominal (opsional)'),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final targetRaw = targetCtrl.text.trim();
                      try {
                        String? avatar;
                        if (pickedImage != null) {
                          avatar = await storage.uploadAvatar(pickedImage!);
                        }
                        await ref.read(groupSavingRepositoryProvider).addMember(
                              groupId: groupId,
                              displayName: nameCtrl.text,
                              targetAmount: targetRaw.isEmpty
                                  ? null
                                  : Money.fromFormatted(targetRaw),
                              avatarUrl: avatar,
                            );
                        ref.invalidate(groupMemberSummariesProvider(groupId));
                        ref.invalidate(groupSummariesProvider);
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
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
                      final amount = Money.fromFormatted(amountCtrl.text);
                      final member = members.firstWhere(
                        (m) => m.memberId == selectedMemberId,
                        orElse: () => members.first,
                      );
                      if (selectedType == SavingEntryType.withdraw &&
                          amount.cents > member.totalContributed.cents) {
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
                              amount: amount,
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

  Future<void> _showEditGroup(
    BuildContext context,
    WidgetRef ref,
    GroupSummary? summary,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: name);
    final descCtrl = TextEditingController();
    final targetCtrl = TextEditingController(
      text: summary != null
          ? NumberFormat.decimalPattern('id_ID')
              .format(summary.targetTotal.cents ~/ 100)
          : '',
    );
    File? pickedImage;
    final picker = ImagePicker();
    final storage = SupabaseStorageService(ref.read(supabaseClientProvider));
    String? avatar = avatarUrl;

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
                GestureDetector(
                  onTap: () async {
                    final file = await picker.pickImage(source: ImageSource.gallery);
                    if (file != null) pickedImage = File(file.path);
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: pickedImage != null
                        ? FileImage(pickedImage!)
                        : (avatar != null ? NetworkImage(avatar) : null),
                    child: pickedImage == null && avatar == null
                        ? const Icon(Icons.camera_alt)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tujuan menabung'),
                  validator: (val) => val == null || val.isEmpty ? 'Harus diisi' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Target total nominal'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      try {
                        String? uploadedAvatar = avatar;
                        if (pickedImage != null) {
                          uploadedAvatar =
                              await storage.uploadAvatar(pickedImage!);
                        }
                        await ref.read(groupSavingRepositoryProvider).updateGroup(
                              groupId: groupId,
                              name: nameCtrl.text,
                              description:
                                  descCtrl.text.isNotEmpty ? descCtrl.text : null,
                              targetTotal: targetCtrl.text.isEmpty
                                  ? null
                                  : Money.fromFormatted(targetCtrl.text),
                              avatarUrl: uploadedAvatar,
                            );
                        ref.invalidate(groupSummariesProvider);
                        ref.invalidate(groupMemberSummariesProvider(groupId));
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

class _SummaryTab extends StatelessWidget {
  final GroupSummary? summary;
  const _SummaryTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) return const Center(child: CircularProgressIndicator());
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

class _MemberTab extends ConsumerWidget {
  final AsyncValue<List<GroupMemberSummary>> members;
  final AsyncValue<List<SavingGroupEntry>> entries;
  final String groupId;
  final VoidCallback onAddMember;

  const _MemberTab({
    required this.members,
    required this.entries,
    required this.groupId,
    required this.onAddMember,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    itemBuilder: (ctx, index) {
                      final member = items[index];
                      return _MemberTile(
                        summary: member,
                        onTap: () => _showMemberTransactions(
                          context,
                          member,
                          entries.asData?.value ?? [],
                        ),
                        onEdit: () => _showEditMemberSheet(
                          context,
                          ref,
                          member,
                        ),
                        onDelete: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ref
                                .read(groupSavingRepositoryProvider)
                                .deleteMember(member.memberId);
                            ref.invalidate(groupMemberSummariesProvider(groupId));
                            ref.invalidate(groupEntriesProvider(groupId));
                            ref.invalidate(groupSummariesProvider);
                            messenger.showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Anggota ${member.displayName} dihapus')),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Gagal hapus: $e')),
                            );
                          }
                        },
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text(err.toString(), style: const TextStyle(color: Colors.red))),
          ),
        ),
      ],
    );
  }

  void _showMemberTransactions(
    BuildContext context,
    GroupMemberSummary member,
    List<SavingGroupEntry> allEntries,
  ) {
    final memberEntries =
        allEntries.where((e) => e.memberId == member.memberId).toList();
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        if (memberEntries.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Belum ada transaksi untuk anggota ini.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: memberEntries.length,
          itemBuilder: (ctx, index) {
            final entry = memberEntries[index];
            final isDeposit = entry.type == SavingEntryType.deposit;
            return ListTile(
              leading: Icon(
                isDeposit ? Icons.upload : Icons.download,
                color: isDeposit ? Colors.green : Colors.red,
              ),
              title: Text(entry.amount.format()),
              subtitle: Text(
                DateFormat.yMMMd().format(entry.transactionDate) +
                    (entry.note != null && entry.note!.isNotEmpty
                        ? ' • ${entry.note}'
                        : ''),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditMemberSheet(
    BuildContext context,
    WidgetRef ref,
    GroupMemberSummary member,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: member.displayName);
    final targetCtrl = TextEditingController(
      text: member.targetAmount != null
          ? NumberFormat.decimalPattern('id_ID')
              .format(member.targetAmount!.cents ~/ 100)
          : '',
    );
    String? avatarUrl = member.avatarUrl;
    File? pickedImage;
    final picker = ImagePicker();
    final storage = SupabaseStorageService(ref.read(supabaseClientProvider));
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
                GestureDetector(
                  onTap: () async {
                    final file = await picker.pickImage(source: ImageSource.gallery);
                    if (file != null) {
                      pickedImage = File(file.path);
                    }
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: pickedImage != null
                        ? FileImage(pickedImage!)
                        : (avatarUrl != null ? NetworkImage(avatarUrl) : null),
                    child: avatarUrl == null && pickedImage == null
                        ? const Icon(Icons.camera_alt)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (val) => val == null || val.isEmpty ? 'Harus diisi' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration:
                      const InputDecoration(labelText: 'Target nominal (opsional)'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      try {
                        String? uploadedAvatar = avatarUrl;
                        if (pickedImage != null) {
                          uploadedAvatar =
                              await storage.uploadAvatar(pickedImage!);
                        }
                        await ref.read(groupSavingRepositoryProvider).updateMember(
                              memberId: member.memberId,
                              displayName: nameCtrl.text,
                              targetAmount: targetCtrl.text.trim().isEmpty
                                  ? null
                                  : Money.fromFormatted(targetCtrl.text),
                              avatarUrl: uploadedAvatar,
                            );
                        ref.invalidate(groupMemberSummariesProvider(groupId));
                        ref.invalidate(groupSummariesProvider);
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

class _MemberTile extends StatelessWidget {
  final GroupMemberSummary summary;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemberTile({
    required this.summary,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: summary.avatarUrl != null
            ? CircleAvatar(backgroundImage: NetworkImage(summary.avatarUrl!))
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(summary.displayName),
        subtitle: Text(
          'Terkumpul: ${summary.totalContributed.format()}'
          '${summary.targetAmount != null ? ' / ${summary.targetAmount!.format()}' : ''}',
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: onDelete,
            ),
          ],
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
          backgroundColor:
              isDeposit ? Colors.green.shade100 : Colors.red.shade100,
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
          '$memberName • ${DateFormat.yMMMd().format(entry.transactionDate)}'
          '${entry.note != null && entry.note!.isNotEmpty ? ' • ${entry.note}' : ''}',
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
