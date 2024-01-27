class CatchupCategory {
  final int? id;
  final String name;
  final int spendLimit;

  CatchupCategory({this.id, required this.name, required this.spendLimit});

  // Convert a Map to a Category object
  CatchupCategory.fromMap(Map<String, dynamic> item)
      : id = item["id"] as int?,
        name = item["name"] as String,
        spendLimit = item["spend_limit"] as int;

  // Convert a Category object to a Map
  Map<String, Object?> toMap() {
    return {"id": id, "name": name, "spend_limit": spendLimit};
  }
}
