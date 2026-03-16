class TestProfileForPassControlDot {
  final int? ratingPlanControlDotId;
  final String? ratingPlanControlDotTitle;
  final int? ratingPlanSectionId;
  final String? ratingPlanSectionTitle;
  final int? ratingPlanDisciplineId;
  final String? ratingPlanDisciplineTitle;
  final String? ratingPlanDisciplineLanguage;

  const TestProfileForPassControlDot({
    this.ratingPlanControlDotId,
    this.ratingPlanControlDotTitle,
    this.ratingPlanSectionId,
    this.ratingPlanSectionTitle,
    this.ratingPlanDisciplineId,
    this.ratingPlanDisciplineTitle,
    this.ratingPlanDisciplineLanguage,
  });

  factory TestProfileForPassControlDot.fromJson(Map<String, dynamic> json) {
    return TestProfileForPassControlDot(
      ratingPlanControlDotId: json['RatingPlanControlDotId'] as int?,
      ratingPlanControlDotTitle: json['RatingPlanControlDotTitle']?.toString(),
      ratingPlanSectionId: json['RatingPlanSectionId'] as int?,
      ratingPlanSectionTitle: json['RatingPlanSectionTitle']?.toString(),
      ratingPlanDisciplineId: json['RatingPlanDisciplineId'] as int?,
      ratingPlanDisciplineTitle: json['RatingPlanDisciplineTitle']?.toString(),
      ratingPlanDisciplineLanguage: json['RatingPlanDisciplineLanguage']
          ?.toString(),
    );
  }
}
