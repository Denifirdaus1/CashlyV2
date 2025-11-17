import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../core/input_formatters/money_input_formatter.dart';
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
              const SizedBox(height: 4),
              const Text('Transaksi Terbaru',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
    final categoryController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    var selectedType = CashTransactionType.expense;

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
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Form(
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
                              setSheetState(() => selectedDate = picked);
                            }
                          },
                          child: Text(DateFormat.yMMMd().format(selectedDate)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Jenis: '),
                        SegmentedButton<CashTransactionType>(
                          segments: const [
                            ButtonSegment(
                              value: CashTransactionType.expense,
                              label: Text('Pengeluaran'),
                            ),
                            ButtonSegment(
                              value: CashTransactionType.income,
                              label: Text('Pemasukan'),
                            ),
                          ],
                          selected: {selectedType},
                          onSelectionChanged: (val) =>
                              setSheetState(() => selectedType = val.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                TextFormField(
                  controller: categoryController,
                  decoration:
                      const InputDecoration(labelText: 'Kategori (mis. Belanja)'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Nominal'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harus diisi';
                        }
                        final digits =
                            value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (digits.isEmpty) return 'Nominal tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    _PresetRow(
                      onAdd: (increment) {
                        final current = Money.fromFormatted(amountController.text);
                        final updated = Money(current.cents + increment);
                        amountController.text =
                            NumberFormat.decimalPattern('id_ID').format(updated.cents ~/ 100);
                      },
                      onSet: (value) {
                        amountController.text =
                            NumberFormat.decimalPattern('id_ID').format(value ~/ 100);
                      },
                    ),
                    const SizedBox(height: 8),
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
                          final amount = Money.fromFormatted(amountController.text);
                          try {
                            await ref.read(cashRepositoryProvider).addTransaction(
                                  transactionDate: selectedDate,
                                  amount: amount,
                                  type: selectedType,
                                  categoryName: categoryController.text,
                                  note: noteController.text.isEmpty
                                      ? null
                                      : noteController.text,
                                );
                            ref.invalidate(cashRollupProvider);
                            ref.invalidate(cashTransactionsProvider);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Transaksi cashflow tersimpan'),
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
              );
            },
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
                gradient: const LinearGradient(
                  colors: [Color(0xFFAFF0E8), Color(0xFF68CEC3)],
                ),
                icon: Icons.arrow_downward,
                iconColor: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                title: 'Expense Hari Ini',
                value: rollup.today.totalExpense.format(),
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.red.shade200],
                ),
                icon: Icons.arrow_upward,
                iconColor: Colors.red.shade700,
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
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8FDFB), Color(0xFF68CEC3)],
                ),
                icon: Icons.trending_up,
                iconColor: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                title: 'Expense Bulan Ini',
                value: rollup.month.totalExpense.format(),
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.red.shade200],
                ),
                icon: Icons.trending_down,
                iconColor: Colors.red.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SummaryCard(
          title: 'Saldo',
          value: rollup.month.balance.format(),
          gradient: const LinearGradient(
            colors: [Color(0xFF68CEC3), Color(0xFF4DB4A9)],
          ),
          icon: Icons.account_balance_wallet,
          iconColor: Colors.white,
          highlighted: true,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final LinearGradient gradient;
  final bool highlighted;
  final IconData icon;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.gradient,
    required this.icon,
    required this.iconColor,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: highlighted ? Colors.white : iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    )),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: highlighted ? Colors.black : Colors.black87,
                  ),
                ),
              ],
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
          backgroundColor:
              isIncome ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction.amount.format(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMMMd().format(transaction.transactionDate),
              style: const TextStyle(fontSize: 12),
            ),
            if (transaction.note != null && transaction.note!.isNotEmpty)
              Text(
                transaction.note!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isIncome ? Colors.green : Colors.red)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isIncome ? 'Income' : 'Expense',
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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

class _PresetRow extends StatelessWidget {
  final void Function(int cents) onAdd;
  final void Function(int cents) onSet;

  const _PresetRow({
    required this.onAdd,
    required this.onSet,
  });

  @override
  Widget build(BuildContext context) {
    final presets = [500000, 1000000, 5000000, 10000000]; // in cents
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
