class CatchupTransaction {
  final int? id;
  final int amount;
  final DateTime date;
  final int categoryId;
  final String description;
  final String? originalTransactionId;

  CatchupTransaction(
      {this.id,
      required this.amount,
      required this.date,
      required this.categoryId,
      required this.description,
      this.originalTransactionId});

  // Convert a Map to a Category object
  CatchupTransaction.fromMap(Map<String, dynamic> item)
      : id = item["id"] as int?,
        amount = item["amount"] as int,
        date = DateTime.fromMillisecondsSinceEpoch(
            item["transaction_date"] * 1000),
        categoryId = item["category_id"] as int,
        description = item["description"] as String,
        originalTransactionId = item["original_transaction_id"] as String?;

  // Convert a Category object to a Map
  Map<String, Object?> toMap() {
    return {
      "id": id,
      "amount": amount,
      "transaction_date": date.millisecondsSinceEpoch ~/ 1000,
      "category_id": categoryId,
      "description": description,
      "original_transaction_id": originalTransactionId
    };
  }
}
