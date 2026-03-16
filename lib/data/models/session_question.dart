import 'package:eios/data/models/session_question_answer.dart';

class SessionQuestion {
  final int id;
  final int? questionType;
  final String? questionTypeName;
  final String? htmlText;
  final String? scaleExplanation;
  final int? maxStars;
  final int? selectedStars;
  final String? shortAnswer;
  final int? secondsLeft;
  final List<SessionQuestionAnswer> sessionQuestionAnswers;

  const SessionQuestion({
    required this.id,
    this.questionType,
    this.questionTypeName,
    this.htmlText,
    this.scaleExplanation,
    this.maxStars,
    this.selectedStars,
    this.shortAnswer,
    this.secondsLeft,
    required this.sessionQuestionAnswers,
  });

  factory SessionQuestion.fromJson(Map<String, dynamic> json) {
    return SessionQuestion(
      id: json['Id'] as int? ?? 0,
      questionType: json['QuestionType'] as int?,
      questionTypeName: json['QuestionTypeName']?.toString(),
      htmlText: json['HtmlText']?.toString(),
      scaleExplanation: json['ScaleExplanation']?.toString(),
      maxStars: json['MaxStars'] as int?,
      selectedStars: json['SelectedStars'] as int?,
      shortAnswer: json['ShortAnswer']?.toString(),
      secondsLeft: json['SecondsLeft'] as int?,
      sessionQuestionAnswers:
          (json['SessionQuestionAnswers'] as List? ?? const [])
              .map(
                (item) => SessionQuestionAnswer.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }
}
