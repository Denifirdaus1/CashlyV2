import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../cashflow/cashflow_view.dart';
import '../savings/savings_view.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(homeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(mode == HomeMode.cashflow ? 'Keuangan' : 'Tabungan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<HomeMode>(
              segments: const [
                ButtonSegment(
                  value: HomeMode.cashflow,
                  label: Text('Keuangan'),
                  icon: Icon(Icons.account_balance_wallet),
                ),
                ButtonSegment(
                  value: HomeMode.savings,
                  label: Text('Tabungan'),
                  icon: Icon(Icons.savings),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (value) {
                ref.read(homeModeProvider.notifier).setMode(value.first);
              },
            ),
          ),
          Expanded(
            child:
                mode == HomeMode.cashflow ? const CashflowView() : const SavingsView(),
          ),
        ],
      ),
    );
  }
}
