import 'package:eios/data/models/student_rating_plan.dart';
import 'package:eios/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:eios/data/models/rating_plan_section.dart';
import 'package:eios/data/models/control_dot.dart';

class RatingPlanScreen extends StatelessWidget {
  final StudentRatingPlan plan;
  final String disciplineTitle;

  const RatingPlanScreen({
    super.key,
    required this.plan,
    required this.disciplineTitle,
  });

  String _formatDate(dynamic date) {
    if (date == null) return '—';
    DateTime? parsedDate = DateTime.tryParse(date.toString());
    if (parsedDate == null) return '—';
    return "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final hasSections = plan.sections != null && plan.sections!.isNotEmpty;
    final hasZeroSession = plan.markZeroSession != null;
    final hasContent = hasSections || hasZeroSession;
    final sortedSections = hasSections
        ? (List<RatingPlanSection>.from(plan.sections!)..sort((a, b) {
            final isAFinal = a.sectionType > 10;
            final isBFinal = b.sectionType > 10;

            if (isAFinal != isBFinal) {
              return isAFinal ? 1 : -1;
            }

            return (a.order ?? 0).compareTo(b.order ?? 0);
          }))
        : const <RatingPlanSection>[];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(disciplineTitle, style: const TextStyle(fontSize: 18)),
            const Text(
              'Рейтинг-план',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
      body: !hasContent
          ? _buildEmptyState(context)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                if (hasZeroSession)
                  _buildZeroSessionHeader(plan.markZeroSession!.ball),

                if (hasSections)
                  ...sortedSections.map(
                    (section) => _buildSection(context, section),
                  ),

                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: appPanelDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Рейтинг-план пуст',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Для этой дисциплины еще не загружен рейтинг-план',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Вернуться назад'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZeroSessionHeader(double? ball) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepBlue,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.lemon.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.lemon,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Допуск (Нулевая сессия)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lemon,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${ball ?? 0} б.",
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, RatingPlanSection section) {
    final hasControlDots =
        section.controlDots != null && section.controlDots!.isNotEmpty;

    double totalScore = 0;
    double maxScore = 0;

    if (hasControlDots) {
      for (var dot in section.controlDots!) {
        totalScore += dot.mark?.ball ?? 0;
        maxScore += dot.maxBall ?? 0;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: appPanelDecoration(),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Row(
          children: [
            Expanded(
              child: Text(
                section.title ?? "Раздел без названия",
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (hasControlDots)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getScoreColor(
                    totalScore,
                    maxScore,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "${totalScore.toStringAsFixed(1)} / ${maxScore.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _getScoreColor(totalScore, maxScore),
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          _getSectionLabel(section.sectionType),
          style: const TextStyle(color: AppColors.mutedText),
        ),
        initiallyExpanded: true,
        children: hasControlDots
            ? section.controlDots!.map((dot) => _buildControlDot(dot)).toList()
            : [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Нет контрольных точек',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildControlDot(ControlDot dot) {
    final hasScore = dot.mark != null && dot.mark!.ball! > 0;
    final percentage = dot.maxBall != null && dot.maxBall! > 0
        ? ((dot.mark?.ball ?? 0) / dot.maxBall! * 100)
        : 0.0;

    final scoreColor = _getScoreColor(dot.mark?.ball ?? 0, dot.maxBall ?? 0);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 4,
                  backgroundColor: AppColors.outline,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
              Icon(
                hasScore ? Icons.check_rounded : Icons.schedule_rounded,
                size: 18,
                color: hasScore ? scoreColor : AppColors.mutedText,
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dot.title ?? "Контрольная точка",
                  style: TextStyle(
                    color: hasScore ? AppColors.ink : AppColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Срок: ${_formatDate(dot.date)}",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${dot.mark?.ball ?? 0}",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: scoreColor,
                ),
              ),
              Text(
                "из ${dot.maxBall ?? 0}",
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedText,
                ),
              ),
              if (percentage > 0)
                Text(
                  "${percentage.toStringAsFixed(0)}%",
                  style: TextStyle(fontSize: 11, color: scoreColor),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score, double maxScore) {
    if (maxScore == 0) return AppColors.mutedText;
    final percentage = score / maxScore;

    if (percentage >= 0.85) return AppColors.success;
    if (percentage >= 0.70) return AppColors.deepBlue;
    if (percentage >= 0.50) return AppColors.amber;
    return AppColors.magenta;
  }

  String _getSectionLabel(int type) {
    switch (type) {
      case 10:
        return "Текущий контроль";
      case 20:
        return "Зачет";
      case 30:
        return "Экзамен";
      case 40:
        return "Курсовая работа";
      default:
        return "Раздел";
    }
  }
}
