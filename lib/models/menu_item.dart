class MenuItemModel {
  final int id;
  final String iconName;
  final String menuName;
  final String menuUrl;
  final int ordering;

  MenuItemModel({
    required this.id,
    required this.iconName,
    required this.menuName,
    required this.menuUrl,
    required this.ordering,
  });

  // Tương thích ngược với mã nguồn cũ
  String get title => menuName;
  String get iconPath => iconName;
  String get route => menuUrl;

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] ?? 0,
      iconName: json['icon_name'] ?? json['iconPath'] ?? '',
      menuName: json['menu_name'] ?? json['title'] ?? '',
      menuUrl: json['menu_url'] ?? json['route'] ?? '',
      ordering: json['ordering'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'icon_name': iconName,
      'menu_name': menuName,
      'menu_url': menuUrl,
      'ordering': ordering,
    };
  }

  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    return MenuItemModel(
      id: map['id'] ?? 0,
      iconName: map['icon_name'] ?? map['iconPath'] ?? '',
      menuName: map['menu_name'] ?? map['title'] ?? '',
      menuUrl: map['menu_url'] ?? map['route'] ?? '',
      ordering: map['ordering'] ?? 0,
    );
  }
}
