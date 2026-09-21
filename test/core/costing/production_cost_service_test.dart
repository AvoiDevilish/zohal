import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/costing/cost_consumption_service.dart';
import 'package:zohal_android_test/core/costing/cost_allocation_store.dart';
import 'package:zohal_android_test/core/costing/cost_layer.dart';
import 'package:zohal_android_test/core/costing/cost_layer_store.dart';
import 'package:zohal_android_test/core/costing/production_cost_service.dart';
import 'package:zohal_android_test/core/workshop/production_calculator.dart';
import 'package:zohal_android_test/core/workshop/production_requirement.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CostLayerStore layerStore;
  late CostAllocationStore allocationStore;
  late ProductionCostService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    layerStore = CostLayerStore.instance;
    allocationStore = CostAllocationStore.instance;

    await layerStore.clear();
    await allocationStore.clear();

    service = ProductionCostService(
      costConsumptionService: CostConsumptionService(
        costLayerStore: layerStore,
        allocationStore: allocationStore,
      ),
    );
  });

  test('calculates production cost from consumed materials', () async {
    await layerStore.add(
      CostLayer(
        id: 'date-layer',
        materialId: 'date',
        materialName: 'خرمای خشت',
        quantity: 10000,
        remainingQuantity: 10000,
        unit: 'g',
        unitCost: 10,
        createdAt: DateTime(2026, 1, 1),
        purchaseId: 'purchase-date',
      ),
    );

    await layerStore.add(
      CostLayer(
        id: 'package-layer',
        materialId: 'box',
        materialName: 'ظرف',
        quantity: 100,
        remainingQuantity: 100,
        unit: 'unit',
        unitCost: 500,
        createdAt: DateTime(2026, 1, 1),
        purchaseId: 'purchase-box',
      ),
    );

    final calculation = ProductionCalculation(
      units: 10,
      unitWeightGrams: 100,
      totalWeightGrams: 1000,
      requirements: [
        const ProductionRequirement(
          materialId: 'date',
          materialName: 'خرمای خشت',
          quantity: 1000,
          unit: 'g',
        ),
        const ProductionRequirement(
          materialId: 'box',
          materialName: 'ظرف',
          quantity: 10,
          unit: 'unit',
          type: ProductionRequirementType.packaging,
        ),
      ],
    );

    final result = await service.calculate(
      productionId: 'production-test',
      calculation: calculation,
    );

    expect(result.materialCost, 10000);
    expect(result.packagingCost, 5000);
    expect(result.totalCost, 15000);
    expect(result.outputQuantity, 10);
    expect(result.unitCost, 1500);
  });
}
