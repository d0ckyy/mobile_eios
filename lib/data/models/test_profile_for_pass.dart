import 'package:eios/data/models/test_profile.dart';
import 'package:eios/data/models/test_profile_for_pass_control_dot.dart';

class TestProfileForPass {
  final int? type;
  final int? durationInMinutes;
  final int? questionsCount;
  final int? attemptsCount;
  final int? attemptsUsedCount;
  final double? result;
  final bool canStartSession;
  final TestProfileForPassControlDot? controlDot;
  final TestProfile? testProfile;
  final String? avalibleDatetimeStart;
  final String? avalibleDatetimeEnd;
  final int? activeSessionId;

  const TestProfileForPass({
    this.type,
    this.durationInMinutes,
    this.questionsCount,
    this.attemptsCount,
    this.attemptsUsedCount,
    this.result,
    required this.canStartSession,
    this.controlDot,
    this.testProfile,
    this.avalibleDatetimeStart,
    this.avalibleDatetimeEnd,
    this.activeSessionId,
  });

  factory TestProfileForPass.fromJson(Map<String, dynamic> json) {
    return TestProfileForPass(
      type: json['Type'] as int?,
      durationInMinutes: json['DurationInMinutes'] as int?,
      questionsCount: json['QuestionsCount'] as int?,
      attemptsCount: json['AttemptsCount'] as int?,
      attemptsUsedCount: json['AttemptsUsedCount'] as int?,
      result: (json['Result'] as num?)?.toDouble(),
      canStartSession: json['CanStartSession'] as bool? ?? false,
      controlDot: json['ControlDot'] != null
          ? TestProfileForPassControlDot.fromJson(
              json['ControlDot'] as Map<String, dynamic>,
            )
          : null,
      testProfile: json['TestProfile'] != null
          ? TestProfile.fromJson(json['TestProfile'] as Map<String, dynamic>)
          : null,
      avalibleDatetimeStart: json['AvalibleDatetimeStart']?.toString(),
      avalibleDatetimeEnd: json['AvalibleDatetimeEnd']?.toString(),
      activeSessionId: json['ActiveSessionId'] as int?,
    );
  }
}
