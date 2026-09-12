enum ResultType {
  lene,
  dene,
  balanced;

  String get displayLabel {
    switch (this) {
      case ResultType.lene:
        return 'Lene Aaj';
      case ResultType.dene:
        return 'Dene Aaj';
      case ResultType.balanced:
        return 'Hisab Barabar';
    }
  }

  String get copyLabel {
    switch (this) {
      case ResultType.lene:
        return 'LENE AAJ';
      case ResultType.dene:
        return 'DENE AAJ';
      case ResultType.balanced:
        return 'HISAB BARABAR';
    }
  }

  String get shortLabel {
    switch (this) {
      case ResultType.lene:
        return 'Lene';
      case ResultType.dene:
        return 'Dene';
      case ResultType.balanced:
        return 'Barabar';
    }
  }
}
