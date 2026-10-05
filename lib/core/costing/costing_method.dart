enum CostingMethod { fifo, fefo, weightedAverage }

extension CostingMethodX on CostingMethod {
  String get key {
    switch (this) {
      case CostingMethod.fifo:
        return 'fifo';
      case CostingMethod.fefo:
        return 'fefo';
      case CostingMethod.weightedAverage:
        return 'weightedAverage';
    }
  }

  String get title {
    switch (this) {
      case CostingMethod.fifo:
        return 'اولین خرید، اولین مصرف';
      case CostingMethod.fefo:
        return 'اولین انقضا، اولین مصرف';
      case CostingMethod.weightedAverage:
        return 'میانگین موزون';
    }
  }

  static CostingMethod fromKey(String key) {
    return CostingMethod.values.firstWhere(
      (method) => method.key == key,
      orElse: () => CostingMethod.fifo,
    );
  }
}
