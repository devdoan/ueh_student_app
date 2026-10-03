class MenuItemModel {
  final int id;
  final String title;
  final String route;
  final String iconPath;

  MenuItemModel({
    required this.id,
    required this.title,
    required this.route,
    required this.iconPath,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'],
      title: json['title'],
      route: json['route'],
      iconPath: json['iconPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'route': route,
      'iconPath': iconPath,
    };
  }

  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    return MenuItemModel(
      id: map['id'],
      title: map['title'],
      route: map['route'],
      iconPath: map['iconPath'],
    );
  }
}
