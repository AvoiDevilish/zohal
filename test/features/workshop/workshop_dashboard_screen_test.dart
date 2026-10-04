import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/costing/production_cost.dart';
import 'package:zohal_android_test/core/costing/production_cost_store.dart';
import 'package:zohal_android_test/core/workshop/production_batch.dart';
import 'package:zohal_android_test/core/workshop/production_batch_store.dart';
import 'package:zohal_android_test/features/workshop/presentation/screens/workshop_dashboard_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('loads production metrics from stores', (tester) async {
    final batches = ProductionBatchStore.instance;
    final costs = ProductionCostStore.instance;
    final now = DateTime.now();

    await batches.add(ProductionBatch(
      id: 'active-1',
      productVariantId: 'variant-1',
      productName: 'محصول فعال',
      units: 10,
      unitWeightGrams: 100,
      recipeId: 'recipe-1',
      recipeVersion: 1,
      createdAt: now,
      status: ProductionBatchStatus.inProduction,
    ));

    await batches.add(ProductionBatch(
      id: 'done-1',
      productVariantId: 'variant-1',
      productName: 'محصول تکمیل شده',
      units: 20,
      unitWeightGrams: 100,
      recipeId: 'recipe-1',
      recipeVersion: 1,
      createdAt: now,
      status: ProductionBatchStatus.completed,
    ));

    await costs.add(ProductionCost(
      productionId: 'done-1',
      materialCost: 120,
      packagingCost: 20,
      consumableCost: 10,
      totalCost: 150,
      outputQuantity: 20,
      createdAt: now,
    ));

    await tester.pumpWidget(MaterialApp(
      home: WorkshopDashboardScreen(batchStore: batches, costStore: costs),
    ));
    await tester.pumpAndSettle();

    expect(find.text('تولید فعال'), findsOneWidget);
    expect(find.text('تکمیل شده امروز'), findsOneWidget);
    expect(find.text('150.00'), findsOneWidget);
    expect(find.text('7.50'), findsOneWidget);
    expect(find.text('محصول فعال'), findsOneWidget);
    expect(find.text('محصول تکمیل شده'), findsOneWidget);
  });

  testWidgets('shows empty production state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WorkshopDashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('هنوز تولیدی ثبت نشده است.'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(4));
  });
}
