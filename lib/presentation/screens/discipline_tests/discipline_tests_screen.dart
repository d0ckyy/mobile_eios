import 'package:eios/core/theme/app_theme.dart';
import 'package:eios/data/models/test_profile_for_pass.dart';
import 'package:eios/data/models/test_session.dart';
import 'package:eios/data/repositories/tests_repository.dart';
import 'package:eios/presentation/screens/discipline_tests/test_session_screen.dart';
import 'package:flutter/material.dart';

class DisciplineTestsScreen extends StatefulWidget {
  final int disciplineId;
  final String disciplineName;

  const DisciplineTestsScreen({
    super.key,
    required this.disciplineId,
    required this.disciplineName,
  });

  @override
  State<DisciplineTestsScreen> createState() => _DisciplineTestsScreenState();
}

class _DisciplineTestsScreenState extends State<DisciplineTestsScreen> {
  final TestsRepository _repository = TestsRepository();

  late Future<List<TestProfileForPass>> _testsFuture;
  bool _isOpeningTest = false;

  @override
  void initState() {
    super.initState();
    _testsFuture = _loadTests();
  }

  Future<List<TestProfileForPass>> _loadTests() {
    return _repository.getTestsForDiscipline(disciplineId: widget.disciplineId);
  }

  Future<void> _refresh() async {
    final future = _loadTests();
    setState(() => _testsFuture = future);
    await future;
  }

  Future<void> _openTest(TestProfileForPass test) async {
    if (_isOpeningTest) {
      return;
    }

    final shouldContinueSession = _shouldContinueSession(test);
    final profileId = test.testProfile?.id;
    final sessionId = shouldContinueSession ? test.activeSessionId : null;

    if (profileId == null && sessionId == null) {
      _showSnackBar('Не удалось определить профиль теста');
      return;
    }

    setState(() => _isOpeningTest = true);

    try {
      final TestSession session;

      if (sessionId != null) {
        session = await _repository.getSession(sessionId: sessionId);
      } else {
        session = await _repository.startSession(profileId: profileId!);
      }

      if (!mounted) return;

      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => TestSessionScreen(
            session: session,
            testTitle: test.testProfile?.testTitle ?? 'Тест',
          ),
        ),
      );

      if (completed == true && mounted) {
        await _refresh();
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Не удалось открыть тест: $e');
    } finally {
      if (mounted) {
        setState(() => _isOpeningTest = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Тесты'),
            Text(
              widget.disciplineName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<TestProfileForPass>>(
        future: _testsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: appPanelDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 52,
                        color: AppColors.magenta,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Не удалось загрузить тесты',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final tests = snapshot.data ?? const <TestProfileForPass>[];

          if (tests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: appPanelDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.quiz_outlined,
                        size: 52,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'По этой дисциплине пока нет тестов',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: tests.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final test = tests[index];
                return _TestCard(
                  test: test,
                  onOpen: _canOpen(test) && !_isOpeningTest
                      ? () => _openTest(test)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  bool _canOpen(TestProfileForPass test) {
    if (_shouldContinueSession(test)) {
      return true;
    }

    if (test.testProfile?.id == null) {
      return false;
    }

    return test.canStartSession || _canRetake(test);
  }

  bool _canRetake(TestProfileForPass test) {
    return test.result != null && _hasAttemptsLeft(test);
  }

  bool _shouldContinueSession(TestProfileForPass test) {
    return test.activeSessionId != null && test.result == null;
  }

  bool _hasAttemptsLeft(TestProfileForPass test) {
    final attemptsCount = test.attemptsCount;

    if (attemptsCount == null) {
      return true;
    }

    return (test.attemptsUsedCount ?? 0) < attemptsCount;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.fixed, content: Text(message)),
    );
  }
}

class _TestCard extends StatelessWidget {
  final TestProfileForPass test;
  final VoidCallback? onOpen;

  const _TestCard({required this.test, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final canRetake = test.result != null && _hasAttemptsLeft(test);
    final canContinue = test.activeSessionId != null && test.result == null;
    final canStart = test.canStartSession;
    final buttonLabel = canContinue
        ? 'Продолжить'
        : canRetake
        ? 'Перепройти'
        : canStart
        ? 'Начать'
        : 'Недоступно';
    final canOpen = onOpen != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: appPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            test.testProfile?.testTitle ?? 'Тест без названия',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if ((test.controlDot?.ratingPlanControlDotTitle ?? '').isNotEmpty)
            Text(
              test.controlDot!.ratingPlanControlDotTitle!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
            ),
          if ((test.controlDot?.ratingPlanSectionTitle ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              test.controlDot!.ratingPlanSectionTitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: 'Вопросы',
                value: '${test.questionsCount ?? 0}',
              ),
              if (test.durationInMinutes != null)
                _MetricChip(
                  label: 'Время',
                  value: '${test.durationInMinutes} мин',
                ),
              if (test.attemptsCount != null)
                _MetricChip(
                  label: 'Попытки',
                  value: '${test.attemptsUsedCount ?? 0}/${test.attemptsCount}',
                ),
              if (test.result != null)
                _MetricChip(
                  label: 'Результат',
                  value: '${test.result!.toStringAsFixed(0)}%',
                  accent: AppColors.magenta,
                ),
            ],
          ),
          if (test.avalibleDatetimeStart != null ||
              test.avalibleDatetimeEnd != null) ...[
            const SizedBox(height: 14),
            Text(
              _availabilityLabel(test),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: canOpen
                ? ElevatedButton(onPressed: onOpen, child: Text(buttonLabel))
                : OutlinedButton(onPressed: null, child: Text(buttonLabel)),
          ),
        ],
      ),
    );
  }

  String _availabilityLabel(TestProfileForPass test) {
    final start = _formatDateTime(test.avalibleDatetimeStart);
    final end = _formatDateTime(test.avalibleDatetimeEnd);

    if (start != null && end != null) {
      return 'Доступно: $start - $end';
    }
    if (start != null) {
      return 'Доступно с $start';
    }
    if (end != null) {
      return 'Доступно до $end';
    }
    return '';
  }

  String? _formatDateTime(String? value) {
    if (value == null || value.isEmpty) return null;

    final date = DateTime.tryParse(value);
    if (date == null) return value;

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  bool _hasAttemptsLeft(TestProfileForPass test) {
    final attemptsCount = test.attemptsCount;

    if (attemptsCount == null) {
      return true;
    }

    return (test.attemptsUsedCount ?? 0) < attemptsCount;
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;

  const _MetricChip({required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) {
    final chipAccent = accent ?? AppColors.deepBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: chipAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: chipAccent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
