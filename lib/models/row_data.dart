class RowData {
  RowData({
    required this.id,
    this.name = '',
    this.amount = '',
    this.bracket = '',
  });

  final String id;
  String name;
  String amount;
  String bracket;

  RowData copyWith({
    String? id,
    String? name,
    String? amount,
    String? bracket,
  }) {
    return RowData(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      bracket: bracket ?? this.bracket,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'bracket': bracket,
      };

  factory RowData.fromJson(Map<String, dynamic> json) {
    return RowData(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      bracket: json['bracket'] as String? ?? '',
    );
  }

  static RowData empty({required String id}) => RowData(id: id);
}
