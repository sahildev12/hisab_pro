class PasteRecentEntry {
  const PasteRecentEntry({
    required this.id,
    required this.text,
    required this.title,
    required this.savedAt,
  });

  final String id;
  final String text;
  final String title;
  final DateTime savedAt;

  String get preview {
    final firstLine = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    if (firstLine.isNotEmpty) return firstLine;
    if (title.isNotEmpty) return title;
    return 'Pasted calculation';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'title': title,
        'savedAt': savedAt.toIso8601String(),
      };

  factory PasteRecentEntry.fromJson(Map<String, dynamic> json) {
    return PasteRecentEntry(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      title: json['title'] as String? ?? '',
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
