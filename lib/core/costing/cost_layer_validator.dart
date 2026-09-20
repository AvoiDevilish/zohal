import 'cost_layer.dart';

class CostLayerValidator {
  const CostLayerValidator();

  void validate(CostLayer layer) {
    if (layer.id.trim().isEmpty) {
      throw ArgumentError('Cost layer id cannot be empty.');
    }

    if (layer.materialId.trim().isEmpty) {
      throw ArgumentError('Cost layer material id cannot be empty.');
    }

    if (layer.materialName.trim().isEmpty) {
      throw ArgumentError('Cost layer material name cannot be empty.');
    }

    if (layer.quantity <= 0) {
      throw ArgumentError('Cost layer quantity must be greater than zero.');
    }

    if (layer.remainingQuantity < 0) {
      throw ArgumentError('Cost layer remaining quantity cannot be negative.');
    }

    if (layer.remainingQuantity > layer.quantity) {
      throw ArgumentError(
        'Remaining quantity cannot exceed original quantity.',
      );
    }

    if (layer.unit.trim().isEmpty) {
      throw ArgumentError('Cost layer unit cannot be empty.');
    }

    if (layer.unitCost < 0) {
      throw ArgumentError('Cost layer unit cost cannot be negative.');
    }
  }
}
