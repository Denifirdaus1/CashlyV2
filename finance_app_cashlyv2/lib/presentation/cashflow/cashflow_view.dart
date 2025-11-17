import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../core/money.dart';
import '../../domain/enums.dart';
import '../../domain/models/cash_rollup.dart';
import '../../domain/models/cash_transaction.dart';

class CashflowView extends ConsumerWidget {
  const CashflowView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rollup = ref.watch(cashRollupProvider);
    final transactions = ref.watch(cashTransactionsProvider);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(cashRollupProvider);
            ref.invalidate(cashTransactionsProvider);
            await ref.read(cashRollupProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            children: [
              rollup.when(
                data: (data) => _CashSummary(rollup: data),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => _ErrorText(message: err.toString()),
              ),
              const SizedBox(height: 8),
              const Text('Transaksi Terbaru',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 4),
              transactions.when(
                data: (items) => items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Belum ada transaksi.')),
                      )
                    : Column(
                        children: items
                            .map((t) => _TransactionTile(transaction: t))
                            .toList(),
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => _ErrorText(message: err.toString()),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddTransactionSheet(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Transaksi'),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddTransactionSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    var selectedType = CashTransactionType.expense;

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
                    const Text('Tambah Transaksi',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                        }
                      },
                      child: Text(DateFormat.yMMMd().format(selectedDate)),
                    ),
                  ],
                ),
                DropdownButtonFormField<CashTransactionType>(
                  initialValue: selectedType,
                  items: CashTransactionType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            t == CashTransactionType.income ? 'Pemasukan' : 'Pengeluaran',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => selectedType = val ?? selectedType,
                  decoration: const InputDecoration(labelText: 'Jenis'),
                ),
                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Nominal'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harus diisi';
                    }
                    final parsed = double.tryParse(value.replaceAll(',', ''));
                    if (parsed == null) return 'Nominal tidak valid';
                    if (parsed < 0) return 'Tidak boleh negatif';
                    return null;
                  },
                ),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final amount = double.parse(
                        amountController.text.replaceAll(',', ''),
                      );
                      await ref.read(cashRepositoryProvider).addTransaction(
                            transactionDate: selectedDate,
                            amount: Money.fromDouble(amount),
                            type: selectedType,
                            note: noteController.text.isEmpty
                                ? null
                                : noteController.text,
                          );
                      ref.invalidate(cashRollupProvider);
                      ref.invalidate(cashTransactionsProvider);
                      if (context.mounted) Navigator.of(context).pop();
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

class _CashSummary extends StatelessWidget {
  final CashRollup rollup;
  const _CashSummary({required this.rollup});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Income Hari Ini',
                value: rollup.today.totalIncome.format(),
                color: Colors.green.shade100,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                title: 'Expense Hari Ini',
                value: rollup.today.totalExpense.format(),
                color: Colors.red.shade100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Income Bulan Ini',
                value: rollup.month.totalIncome.format(),
                color: Colors.green.shade50,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                title: 'Expense Bulan Ini',
                value: rollup.month.totalExpense.format(),
                color: Colors.red.shade50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SummaryCard(
          title: 'Saldo',
          value: rollup.month.balance.format(),
          color: Colors.blue.shade50,
          highlighted: true,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final bool highlighted;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: highlighted ? Colors.blue.shade800 : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final CashTransaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == CashTransactionType.income;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction.amount.format(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${DateFormat.yMMMd().format(transaction.transactionDate)}'
          '${transaction.note != null && transaction.note!.isNotEmpty ? ' \u2022 ${transaction.note}' : ''}',
        ),
        trailing: Text(
          isIncome ? 'Income' : 'Expense',
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;
  const _ErrorText({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}
