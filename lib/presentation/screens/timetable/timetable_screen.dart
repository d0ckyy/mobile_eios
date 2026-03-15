import 'package:eios/data/models/time_table_lesson_discipline.dart';
import 'package:eios/core/theme/app_theme.dart';
import 'package:eios/presentation/screens/rating_plan/rating_plan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import 'bloc/timetable_bloc.dart';
import 'bloc/timetable_event.dart';
import 'bloc/timetable_state.dart';

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);

class TimeTableScreen extends StatelessWidget {
  const TimeTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TimetableBloc()..add(TimetableStarted()),
      child: const _TimetableView(),
    );
  }
}

class _TimetableView extends StatelessWidget {
  const _TimetableView();

  static const List<String> _months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static const List<String> _periodLesson = [
    '08:00 - 09:30',
    '09:45 - 11:15',
    '11:35 - 13:05',
    '13:20 - 14:50',
    '15:00 - 16:30',
    '16:40 - 18:10',
    '18:15 - 19:45',
    '19:50 - 21:20',
  ];

  List<_DayLessonSlot> _buildDaySlots(TimetableState state) {
    final lessonsByNumber = <int, List<TimeTableLessonDiscipline>>{
      for (var i = 1; i <= _periodLesson.length; i++)
        i: <TimeTableLessonDiscipline>[],
    };
    final seenKeys = <int, Set<String>>{
      for (var i = 1; i <= _periodLesson.length; i++) i: <String>{},
    };

    for (final groupData in state.timetableData ?? const []) {
      final lessons = groupData.timeTable?.lessons ?? const [];

      for (final lesson in lessons) {
        final number = lesson.number;
        if (number == null || number < 1 || number > _periodLesson.length) {
          continue;
        }

        for (final discipline in lesson.disciplines ?? const []) {
          final uniqueKey = [
            discipline.id,
            discipline.title,
            discipline.teacher?.fio,
            discipline.auditorium?.number,
            discipline.group,
            discipline.subgroupNumber,
          ].join('|');

          if (seenKeys[number]!.add(uniqueKey)) {
            lessonsByNumber[number]!.add(discipline);
          }
        }
      }
    }

    return List.generate(_periodLesson.length, (index) {
      final number = index + 1;
      return _DayLessonSlot(
        number: number,
        time: _periodLesson[index],
        disciplines: List.unmodifiable(lessonsByNumber[number]!),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Расписание')),
      body: MultiBlocListener(
        listeners: [
          BlocListener<TimetableBloc, TimetableState>(
            listenWhen: (prev, curr) => curr.snackBarMessage != null,
            listener: (context, state) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.snackBarMessage!)));
              context.read<TimetableBloc>().add(TimetableSnackBarDismissed());
            },
          ),
          // ── Навигация на рейтинг-план ──
          BlocListener<TimetableBloc, TimetableState>(
            listenWhen: (prev, curr) => curr.ratingPlanToNavigate != null,
            listener: (context, state) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RatingPlanScreen(
                    plan: state.ratingPlanToNavigate!,
                    disciplineTitle:
                        state.ratingPlanDisciplineTitle ?? 'Дисциплина',
                  ),
                ),
              );
              context.read<TimetableBloc>().add(TimetableNavigationHandled());
            },
          ),
          BlocListener<TimetableBloc, TimetableState>(
            listenWhen: (prev, curr) =>
                prev.isLoadingRatingPlan != curr.isLoadingRatingPlan,
            listener: (context, state) {
              if (state.isLoadingRatingPlan) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
              } else {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
        child: BlocBuilder<TimetableBloc, TimetableState>(
          builder: (context, state) {
            final daySlots = _buildDaySlots(state);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: appPanelDecoration(),
                    child: TableCalendar(
                      locale: 'ru_RU',
                      firstDay: kFirstDay,
                      lastDay: kLastDay,
                      focusedDay: state.focusedDay,
                      calendarFormat: state.calendarFormat,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Месяц',
                        CalendarFormat.twoWeeks: '2 недели',
                        CalendarFormat.week: 'Неделя',
                      },
                      headerStyle: HeaderStyle(
                        formatButtonShowsNext: false,
                        formatButtonDecoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        formatButtonTextStyle: const TextStyle(
                          color: AppColors.deepBlue,
                          fontWeight: FontWeight.w600,
                        ),
                        titleCentered: true,
                        titleTextStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        leftChevronIcon: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.deepBlue,
                        ),
                        rightChevronIcon: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.deepBlue,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                        weekendStyle: TextStyle(
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: AppColors.lemon.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.deepBlue,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        defaultTextStyle: const TextStyle(color: AppColors.ink),
                        weekendTextStyle: const TextStyle(color: AppColors.ink),
                        outsideTextStyle: const TextStyle(
                          color: Color(0xFFA6A9B0),
                        ),
                        markerDecoration: const BoxDecoration(
                          color: AppColors.magenta,
                          shape: BoxShape.circle,
                        ),
                      ),
                      selectedDayPredicate: (day) =>
                          isSameDay(state.selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        if (!isSameDay(state.selectedDay, selectedDay)) {
                          context.read<TimetableBloc>().add(
                            TimetableDateSelected(
                              selectedDay: selectedDay,
                              focusedDay: focusedDay,
                            ),
                          );
                        }
                      },
                      onFormatChanged: (format) {
                        context.read<TimetableBloc>().add(
                          TimetableFormatChanged(format),
                        );
                      },
                      onPageChanged: (focusedDay) {
                        context.read<TimetableBloc>().add(
                          TimetablePageChanged(focusedDay),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.deepBlue,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Выбранный день',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.white.withValues(alpha: 0.7),
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${state.selectedDay.day} "
                          "${_months[state.selectedDay.month - 1]} "
                          "${state.selectedDay.year}",
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Container(
                            decoration: appPanelDecoration(),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    16,
                                    18,
                                    12,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Пары на день',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const Spacer(),
                                      Text(
                                        '1-8',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 6,
                                    ),
                                    itemCount: daySlots.length,
                                    separatorBuilder: (_, index) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final slot = daySlots[index];

                                      return _DayLessonRow(
                                        slot: slot,
                                        onDisciplineTap: (discipline) {
                                          context.read<TimetableBloc>().add(
                                            TimetableRatingPlanRequested(
                                              discipline,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DayLessonRow extends StatelessWidget {
  final _DayLessonSlot slot;
  final ValueChanged<TimeTableLessonDiscipline> onDisciplineTap;

  const _DayLessonRow({required this.slot, required this.onDisciplineTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '${slot.number}.',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.deepBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 108,
            child: Text(
              slot.time,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: slot.disciplines.isEmpty
                ? const Text(
                    'Нет занятий',
                    style: TextStyle(fontSize: 14, color: AppColors.mutedText),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < slot.disciplines.length; i++) ...[
                        _DayDisciplineItem(
                          discipline: slot.disciplines[i],
                          onTap: () => onDisciplineTap(slot.disciplines[i]),
                        ),
                        if (i != slot.disciplines.length - 1)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DayDisciplineItem extends StatelessWidget {
  final TimeTableLessonDiscipline discipline;
  final VoidCallback onTap;

  const _DayDisciplineItem({required this.discipline, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final details = [
      if ((discipline.teacher?.fio ?? '').trim().isNotEmpty)
        discipline.teacher!.fio!,
      if (discipline.remote == true)
        'Онлайн'
      else if (discipline.auditorium != null)
        'Ауд. ${discipline.auditorium?.number ?? '—'}',
      if ((discipline.group ?? '').trim().isNotEmpty) discipline.group!,
    ].join(' · ');

    final isTappable = discipline.id != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isTappable ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discipline.title ?? 'Без названия',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        details,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isTappable) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_outward_rounded,
                  size: 16,
                  color: AppColors.mutedText,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DayLessonSlot {
  final int number;
  final String time;
  final List<TimeTableLessonDiscipline> disciplines;

  const _DayLessonSlot({
    required this.number,
    required this.time,
    required this.disciplines,
  });
}
