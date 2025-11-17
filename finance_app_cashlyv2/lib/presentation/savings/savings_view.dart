import 'package:flutter/material.dart';

import 'personal_savings_view.dart';
import 'group_savings_view.dart';

class SavingsView extends StatelessWidget {
  const SavingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: const [
          TabBar(
            tabs: [
              Tab(text: 'Pribadi'),
              Tab(text: 'Kelompok'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                PersonalSavingsView(),
                GroupSavingsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
