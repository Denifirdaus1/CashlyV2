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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black54,
              indicator: BoxDecoration(
                color: Color(0xFF68CEC3),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              indicatorPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              labelPadding: EdgeInsets.symmetric(horizontal: 16),
              tabs: [
                Tab(text: 'Pribadi'),
                Tab(text: 'Kelompok'),
              ],
            ),
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
