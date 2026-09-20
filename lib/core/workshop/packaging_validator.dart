import 'packaging_rule.dart';

class PackagingValidator {
  const PackagingValidator();

  void validate(PackagingRule rule) {
    if (rule.productVariantId.trim().isEmpty) {
      throw ArgumentError('شناسه محصول نمی‌تواند خالی باشد.');
    }

    if (rule.materialId.trim().isEmpty) {
      throw ArgumentError('شناسه قلم بسته‌بندی نمی‌تواند خالی باشد.');
    }

    if (rule.materialName.trim().isEmpty) {
      throw ArgumentError('نام قلم بسته‌بندی نمی‌تواند خالی باشد.');
    }

    if (rule.quantityPerUnit <= 0) {
      throw ArgumentError(
        'مقدار مصرف بسته‌بندی برای هر محصول باید بیشتر از صفر باشد.',
      );
    }

    if (rule.unit.trim().isEmpty) {
      throw ArgumentError('واحد بسته‌بندی نمی‌تواند خالی باشد.');
    }
  }

  void validateAll(List<PackagingRule> rules) {
    final seenMaterialIds = <String>{};

    for (final rule in rules) {
      validate(rule);

      if (!seenMaterialIds.add(rule.materialId)) {
        throw ArgumentError(
          'برای یک قلم بسته‌بندی بیش از یک Rule فعال تعریف شده است: '
          '${rule.materialId}',
        );
      }
    }
  }
}
