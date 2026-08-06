import 'package:flutter/material.dart';

/// Keeps a [TabBar] stuck below the fixed action row while the profile header
/// above it scrolls away, so tabs stay reachable without scrolling back up.
class PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const PinnedTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(PinnedTabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}
