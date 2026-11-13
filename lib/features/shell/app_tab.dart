import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTab {
  home,
  meihua,
  liuyao,
  profile,
}

extension AppTabView on AppTab {
  String get label => switch (this) {
    AppTab.home => '首页',
    AppTab.meihua => '梅花',
    AppTab.liuyao => '六爻',
    AppTab.profile => '我的',
  };

  IconData get icon => switch (this) {
    AppTab.home => Icons.home_outlined,
    AppTab.meihua => Icons.filter_vintage_outlined,
    AppTab.liuyao => Icons.toll_outlined,
    AppTab.profile => Icons.person_outline,
  };

  IconData get selectedIcon => switch (this) {
    AppTab.home => Icons.home,
    AppTab.meihua => Icons.filter_vintage,
    AppTab.liuyao => Icons.toll,
    AppTab.profile => Icons.person,
  };
}

class AppTabController extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.home;

  void select(AppTab tab) => state = tab;
}

final appTabProvider = NotifierProvider<AppTabController, AppTab>(
  AppTabController.new,
);
