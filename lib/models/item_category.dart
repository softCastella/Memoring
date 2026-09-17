enum ItemCategory {
  todo,
  study,
  routine;

  String get storageName => name;

  String get label => switch (this) {
    ItemCategory.todo => '할 일',
    ItemCategory.study => '업무·공부',
    ItemCategory.routine => '루틴',
  };

  static ItemCategory fromStorage(String value) {
    return ItemCategory.values.firstWhere(
      (item) => item.storageName == value,
      orElse: () => ItemCategory.todo,
    );
  }
}
