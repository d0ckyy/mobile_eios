import 'package:eios/data/models/test_profile.dart';

class TestSessionResult {
  final int sessionId;
  final TestProfile? testProfile;
  final String? sessionStartDateTime;
  final String? sessionFinishDateTime;
  final double? result;
  final bool isReportAvalible;

  const TestSessionResult({
    required this.sessionId,
    this.testProfile,
    this.sessionStartDateTime,
    this.sessionFinishDateTime,
    this.result,
    required this.isReportAvalible,
  });

  factory TestSessionResult.fromJson(Map<String, dynamic> json) {
    return TestSessionResult(
      sessionId: json['SessionId'] as int? ?? 0,
      testProfile: json['TestProfile'] != null
          ? TestProfile.fromJson(json['TestProfile'] as Map<String, dynamic>)
          : null,
      sessionStartDateTime: json['SessionStartDateTime']?.toString(),
      sessionFinishDateTime: json['SessionFinishDateTime']?.toString(),
      result: (json['Result'] as num?)?.toDouble(),
      isReportAvalible: json['IsReportAvalible'] as bool? ?? false,
    );
  }
}
