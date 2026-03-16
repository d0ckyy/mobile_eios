class SessionQuestionAnswer {
  final int id;
  final String? htmlText;
  final bool selected;
  final int? order;

  const SessionQuestionAnswer({
    required this.id,
    this.htmlText,
    required this.selected,
    this.order,
  });

  factory SessionQuestionAnswer.fromJson(Map<String, dynamic> json) {
    return SessionQuestionAnswer(
      id: json['Id'] as int? ?? 0,
      htmlText: json['HtmlText']?.toString(),
      selected: json['Selected'] as bool? ?? false,
      order: json['Order'] as int?,
    );
  }
}
