class CatchupTransaction {
  final int? id;
  final int amount;
  final DateTime date;
  final int categoryId;

  CatchupTransaction(
      {this.id,
      required this.amount,
      required this.date,
      required this.categoryId});

  // Convert a Map to a Category object
  CatchupTransaction.fromMap(Map<String, dynamic> item)
      : id = item["id"] as int?,
        amount = item["amount"] as int,
        date = DateTime.fromMillisecondsSinceEpoch(
            item["transaction_date"] * 1000),
        categoryId = item["category_id"] as int;

  // Convert a Category object to a Map
  Map<String, Object?> toMap() {
    return {
      "id": id,
      "amount": amount,
      "transaction_date": (date.microsecondsSinceEpoch / 1000).round(),
      "category_id": categoryId
    };
  }
}
