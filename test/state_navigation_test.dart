import 'package:kissanfresh/features/catalog/application/product_search_controller.dart';
import 'package:kissanfresh/features/catalog/domain/section_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kissanfresh/core/observable.dart';
import 'package:kissanfresh/core/navigation.dart';

void main() {
  test('View All preserves the real category or the entire collection', () {
    const category = 'Fruit & Salad Subscription';
    expect(searchOptionsFor({'category': category}).category, category);

    final section = SectionModel(
      id: 'subscriptions',
      name: 'Subscription Packs',
      rank: 1,
      type: 'kissan-fresh',
      categories: [category],
    );
    expect(searchOptionsFor(section).category, category);

    section.categories.add('Vegetable Subscription');
    final options = searchOptionsFor(section);
    expect(options.category, 'Subscription Packs');
    expect(options.section?.categories, [category, 'Vegetable Subscription']);
  });

  testWidgets('reactive fields update only the active branch', (tester) async {
    final useGrocery = Observable(true);
    final grocery = ObservableList(['Fruit']);
    final kitchen = ObservableList(['Salad']);
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: FieldBuilder(() {
          builds++;
          return Text((useGrocery.value ? grocery : kitchen).join(','));
        }),
      ),
    );

    expect(find.text('Fruit'), findsOneWidget);
    kitchen.add('Soup');
    await tester.pump();
    expect(builds, 1);

    useGrocery.value = false;
    await tester.pump();
    expect(find.text('Salad,Soup'), findsOneWidget);

    grocery.clear();
    await tester.pump();
    expect(builds, 2);

    kitchen.assignAll(['Meals']);
    await tester.pump();
    expect(find.text('Meals'), findsOneWidget);
  });

  testWidgets(
    'navigation preserves literal category and dismisses only the dialog',
    (tester) async {
      const category = 'Fruit & Salad Subscription';
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: AppNavigator.key,
          navigatorObservers: [AppNavigator.observer],
          home: const Scaffold(body: Text('Home')),
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: settings,
            builder: (context) =>
                Scaffold(body: Text(settings.arguments as String)),
          ),
        ),
      );
      AppNavigator.toNamed('/search', arguments: category);
      await tester.pumpAndSettle();
      expect(find.text(category), findsOneWidget);
      expect(AppNavigator.currentRoute, '/search');

      AppNavigator.dialog(const AlertDialog(content: Text('Checking payment')));
      await tester.pumpAndSettle();
      expect(AppNavigator.isDialogOpen, true);
      AppNavigator.back();
      await tester.pumpAndSettle();
      expect(AppNavigator.isDialogOpen, false);
      expect(find.text(category), findsOneWidget);
    },
  );
}
