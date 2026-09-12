enum SettlementType {
  lene('Lene h', 'lene aaj'),
  dene('Dene h', 'dene aaj');

  const SettlementType(this.label, this.copyLabel);

  final String label;
  final String copyLabel;

  static SettlementType fromString(String? value) {
    if (value == 'dene') {
      return SettlementType.dene;
    }
    return SettlementType.lene;
  }

  String get storageValue => name;
}
