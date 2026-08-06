import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workbyte_app/widgets/pinned_tab_bar_delegate.dart';

/// The profile screens stack a collapsing header, a pinned [TabBar] and a
/// [TabBarView] inside one [NestedScrollView], and hang pull-to-refresh off the
/// scroll view inside a tab. Nested scrollables are where that arrangement
/// usually breaks, so these tests exercise the real shape of it.
void main() {
  /// Mirrors a profile tab: refresh indicator wrapping the tab's own scroll
  /// view, which is what the reviews tab actually builds.
  Widget tab(
    String name, {
    Future<void> Function()? onRefresh,
    int items = 40,
    bool storeOffset = true,
    bool alwaysScrollable = true,
  }) {
    final list = ListView.builder(
      key: storeOffset ? PageStorageKey<String>(name) : null,
      physics: alwaysScrollable ? const AlwaysScrollableScrollPhysics() : null,
      itemCount: items,
      itemBuilder: (_, i) => SizedBox(height: 60, child: Text('$name-$i')),
    );
    return onRefresh == null
        ? list
        : RefreshIndicator(onRefresh: onRefresh, child: list);
  }

  Widget harness(List<Widget> tabs) => MaterialApp(
    home: DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            const SliverToBoxAdapter(child: SizedBox(height: 200)),
            SliverPersistentHeader(
              pinned: true,
              delegate: PinnedTabBarDelegate(
                TabBar(
                  tabs: List.generate(tabs.length, (i) => Tab(text: 'tab$i')),
                ),
              ),
            ),
          ],
          body: TabBarView(children: tabs),
        ),
      ),
    ),
  );

  testWidgets('pull-to-refresh fires from a tab inside the nested view', (
    tester,
  ) async {
    var refreshed = 0;
    await tester.pumpWidget(
      harness([tab('a', onRefresh: () async => refreshed++)]),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.text('a-1'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(refreshed, 1);
  });

  testWidgets('the pinned tab bar survives the header collapsing', (
    tester,
  ) async {
    await tester.pumpWidget(harness([tab('a'), tab('b')]));
    await tester.pumpAndSettle();

    await tester.drag(find.text('a-1'), const Offset(0, -400));
    await tester.pumpAndSettle();

    // Header scrolled off, tab bar still pinned near the top of the viewport.
    final tabBar = tester.getRect(find.byType(TabBar));
    expect(tabBar.top, lessThan(60));
    expect(tabBar.top, greaterThanOrEqualTo(0));
    expect(find.text('tab1'), findsOneWidget);
  });

  testWidgets('each tab keeps its own scroll offset across switches', (
    tester,
  ) async {
    await tester.pumpWidget(harness([tab('a'), tab('b')]));
    await tester.pumpAndSettle();

    await tester.drag(find.text('a-1'), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('a-0'), findsNothing, reason: 'tab a should be scrolled');

    await tester.tap(find.text('tab1'));
    await tester.pumpAndSettle();
    expect(find.text('b-0'), findsOneWidget, reason: 'tab b starts at the top');

    await tester.tap(find.text('tab0'));
    await tester.pumpAndSettle();
    expect(
      find.text('a-0'),
      findsNothing,
      reason: 'tab a must not be reset to the top by the visit to tab b',
    );
  });

  testWidgets('without a PageStorageKey a tab loses its offset', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness([tab('a', storeOffset: false), tab('b', storeOffset: false)]),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.text('a-1'), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('a-0'), findsNothing);

    await tester.tap(find.text('tab1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('tab0'));
    await tester.pumpAndSettle();

    // Documents why the profile tabs carry PageStorageKeys: without one the
    // tab is rebuilt from scratch and jumps back to the top.
    expect(find.text('a-0'), findsOneWidget);
  });

  testWidgets('a tab shorter than the viewport can still collapse the header', (
    tester,
  ) async {
    // One item, default physics: the inner list has nothing to scroll, so this
    // is where a body could plausibly trap the header.
    await tester.pumpWidget(
      harness([tab('a', items: 1, alwaysScrollable: false)]),
    );
    await tester.pumpAndSettle();

    final before = tester.getRect(find.byType(TabBar)).top;
    await tester.drag(find.byType(TabBarView), const Offset(0, -200));
    await tester.pumpAndSettle();
    final after = tester.getRect(find.byType(TabBar)).top;

    expect(after, lessThan(before), reason: 'header should have collapsed');
  });
}
