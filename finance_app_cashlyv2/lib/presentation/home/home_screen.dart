import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme.dart';
import '../cashflow/cashflow_view.dart';
import '../savings/savings_view.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(homeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(mode == HomeMode.cashflow ? 'Keuangan' : 'Tabungan'),
          ],
        ),
      ),
      body: Container(
        color: AppColors.primary.withValues(alpha: 0.04),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      spreadRadius: -4,
                color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: SegmentedButton<HomeMode>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.primary,
                      selectedForegroundColor: Colors.white,
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
              ),
            ),
            Expanded(
              child:
                  mode == HomeMode.cashflow ? const CashflowView() : const SavingsView(),
            ),
          ],
        ),
      ),
    );
  }
}
