import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:windmark/features/home/home_page.dart';
import 'package:windmark/features/liuyao/liuyao_page.dart';
import 'package:windmark/features/meihua/meihua_page.dart';
import 'package:windmark/features/profile/profile_page.dart';
import 'package:windmark/features/shell/app_tab.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(appTabProvider);
    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const [
          HomePage(),
          MeihuaPage(),
          LiuyaoPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (index) {
          ref.read(appTabProvider.notifier).select(AppTab.values[index]);
        },
        destinations: [
          for (final destination in AppTab.values)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
