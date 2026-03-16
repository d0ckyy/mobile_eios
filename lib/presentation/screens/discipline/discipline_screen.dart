import 'package:eios/data/models/discipline.dart';
import 'package:eios/data/models/record_book.dart';
import 'package:eios/core/theme/app_theme.dart';
import 'package:eios/presentation/screens/messages/messages_screen.dart';
import 'package:eios/presentation/screens/discipline_tests/discipline_tests_screen.dart';
import 'package:eios/presentation/screens/rating_plan/rating_plan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/discipline_list_bloc.dart';
import 'bloc/discipline_list_event.dart';
import 'bloc/discipline_list_state.dart';

class DisciplineListScreen extends StatelessWidget {
  const DisciplineListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DisciplineListBloc()..add(DisciplineListStarted()),
      child: const _DisciplineListView(),
    );
  }
}

class _DisciplineListView extends StatelessWidget {
  const _DisciplineListView();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DisciplineListBloc, DisciplineListState>(
          listenWhen: (prev, curr) => curr.snackBarMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.snackBarMessage!)));
            context.read<DisciplineListBloc>().add(
              DisciplineListSnackBarDismissed(),
            );
          },
        ),
        BlocListener<DisciplineListBloc, DisciplineListState>(
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
        BlocListener<DisciplineListBloc, DisciplineListState>(
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
            context.read<DisciplineListBloc>().add(
              DisciplineListNavigationHandled(),
            );
          },
        ),
      ],
      child: BlocBuilder<DisciplineListBloc, DisciplineListState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text("Успеваемость")),
            body: state.isSemestersLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      children: [
                        const _Selectors(),
                        if (state.isLoadingDisciplines) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: const LinearProgressIndicator(minHeight: 6),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Expanded(
                          child:
                              state.recordBooks.isEmpty &&
                                  !state.isLoadingDisciplines
                              ? Center(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(28),
                                    decoration: appPanelDecoration(),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.auto_stories_outlined,
                                          size: 44,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "Дисциплины не найдены",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: () async {
                                    context.read<DisciplineListBloc>().add(
                                      DisciplineListRefreshed(),
                                    );
                                  },
                                  child: _RecordBooksList(
                                    recordBooks: state.recordBooks,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _Selectors extends StatelessWidget {
  const _Selectors();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisciplineListBloc, DisciplineListState>(
      buildWhen: (prev, curr) =>
          prev.selectedYear != curr.selectedYear ||
          prev.selectedPeriod != curr.selectedPeriod ||
          prev.availableSemesters != curr.availableSemesters,
      builder: (context, state) {
        final years = state.availableYears;
        final periods = state.availablePeriods;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: appPanelDecoration(),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: state.selectedYear,
                  decoration: InputDecoration(
                    labelText: 'Год',
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  items: years
                      .map(
                        (y) => DropdownMenuItem(value: y, child: Text(y ?? "")),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      context.read<DisciplineListBloc>().add(
                        DisciplineListYearChanged(val),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: state.selectedPeriod,
                  decoration: InputDecoration(
                    labelText: 'Семестр',
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  items: periods
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      context.read<DisciplineListBloc>().add(
                        DisciplineListPeriodChanged(val),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecordBooksList extends StatelessWidget {
  final List<RecordBook> recordBooks;

  const _RecordBooksList({required this.recordBooks});

  @override
  Widget build(BuildContext context) {
    if (recordBooks.length == 1) {
      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: recordBooks.first.disciplines?.length ?? 0,
        separatorBuilder: (_, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _DisciplineCard(
            discipline: recordBooks.first.disciplines![index],
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: recordBooks.length,
      itemBuilder: (context, index) {
        return _RecordBookSection(recordBook: recordBooks[index]);
      },
    );
  }
}

class _RecordBookSection extends StatelessWidget {
  final RecordBook recordBook;

  const _RecordBookSection({required this.recordBook});

  @override
  Widget build(BuildContext context) {
    final disciplines = recordBook.disciplines ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.deepBlue,
            ),
          ),
          title: Text(
            recordBook.displayName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          subtitle: Text(
            '${disciplines.length} дисциплин(ы)',
            style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
          ),
          children: disciplines
              .map(
                (d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _DisciplineCard(discipline: d),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _DisciplineCard extends StatelessWidget {
  final Discipline discipline;

  const _DisciplineCard({required this.discipline});

  @override
  Widget build(BuildContext context) {
    final hasMessages = (discipline.unreadedMessageCount ?? 0) > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          discipline.title ?? "Без названия",
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: hasMessages
            ? Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _InfoChip(
                  icon: Icons.forum_outlined,
                  label: 'Сообщений: ${discipline.unreadedMessageCount}',
                  accent: AppColors.magenta,
                ),
              )
            : null,
        trailing: SizedBox(
          width: 40,
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openMessages(context),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Badge(
                    isLabelVisible: hasMessages,
                    backgroundColor: AppColors.magenta,
                    label: Text(
                      '${discipline.unreadedMessageCount ?? 0}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: Icon(
                      hasMessages ? Icons.forum_rounded : Icons.forum_outlined,
                      size: 22,
                      color: hasMessages
                          ? AppColors.magenta
                          : AppColors.mutedText,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        onTap: () => _showActions(context),
      ),
    );
  }

  void _openMessages(BuildContext context) {
    final id = discipline.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: ID дисциплины не найден')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessagesScreen(
          disciplineId: id,
          disciplineName: discipline.title ?? 'Дисциплина',
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    final hasMessages = (discipline.unreadedMessageCount ?? 0) > 0;
    final canOpenTests = discipline.id != null;

    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  discipline.title ?? "Дисциплина",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.deepBlue,
                  ),
                ),
                title: const Text('Рейтинг-план'),
                subtitle: const Text('Просмотр оценок и заданий'),
                trailing: _buildBadge(discipline.unreadedCount),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.read<DisciplineListBloc>().add(
                    DisciplineListRatingPlanRequested(discipline),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.lemon.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.quiz_outlined,
                    color: AppColors.deepBlue,
                  ),
                ),
                title: const Text('Тесты'),
                subtitle: const Text('Доступные тесты по дисциплине'),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mutedText,
                ),
                onTap: canOpenTests
                    ? () {
                        Navigator.pop(sheetCtx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DisciplineTestsScreen(
                              disciplineId: discipline.id!,
                              disciplineName: discipline.title ?? 'Дисциплина',
                            ),
                          ),
                        );
                      }
                    : null,
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.magenta.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Badge(
                    isLabelVisible: hasMessages,
                    backgroundColor: AppColors.magenta,
                    child: const Icon(
                      Icons.forum_outlined,
                      color: AppColors.magenta,
                    ),
                  ),
                ),
                title: const Text('Общение'),
                subtitle: Text(
                  hasMessages
                      ? 'Новых сообщений: ${discipline.unreadedMessageCount}'
                      : 'Чат по дисциплине',
                ),
                trailing: hasMessages
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.magenta,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${discipline.unreadedMessageCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.mutedText,
                      ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _openMessages(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(int? count) {
    if (count == null || count == 0) {
      return const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.mutedText,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.deepBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "$count",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;

  const _InfoChip({required this.icon, required this.label, this.accent});

  @override
  Widget build(BuildContext context) {
    final chipColor = accent ?? AppColors.deepBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
