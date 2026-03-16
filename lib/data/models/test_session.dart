class TestSession {
  final int id;
  final int profileId;
  final List<int> sessionQuestionsId;

  const TestSession({
    required this.id,
    required this.profileId,
    required this.sessionQuestionsId,
  });

  factory TestSession.fromJson(Map<String, dynamic> json) {
    return TestSession(
      id: json['Id'] as int? ?? 0,
      profileId: json['ProfileId'] as int? ?? 0,
      sessionQuestionsId: (json['SessionQuestionsId'] as List? ?? const [])
          .map((item) => item as int)
          .toList(),
    );
  }
}
