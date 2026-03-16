import 'dart:async';

import 'package:eios/core/exceptions/app_exceptions.dart';
import 'package:eios/core/theme/app_theme.dart';
import 'package:eios/data/models/session_question.dart';
import 'package:eios/data/models/test_session.dart';
import 'package:eios/data/models/test_session_result.dart';
import 'package:eios/data/repositories/tests_repository.dart';
import 'package:flutter/material.dart';

class TestSessionScreen extends StatefulWidget {
  final TestSession session;
  final String testTitle;

  const TestSessionScreen({
    super.key,
    required this.session,
    required this.testTitle,
  });

  @override
  State<TestSessionScreen> createState() => _TestSessionScreenState();
}

class _TestSessionScreenState extends State<TestSessionScreen> {
  final TestsRepository _repository = TestsRepository();
  final TextEditingController _shortAnswerController = TextEditingController();
  Timer? _countdownTimer;

  static const int _singleChoiceType = 0;
  static const int _multipleChoiceType = 1;
  static const int _sequenceType = 2;
  static const int _correspondenceType = 3;
  static const int _customAnswerType = 4;
  static const int _starRatingType = 10;
  static const String _expiredMessage =
      'Время на выполнение теста закончилось. Завершите попытку.';

  late final TestSession _session;
  SessionQuestion? _question;
  int _questionIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _sessionExpired = false;
  String? _errorMessage;
  int? _secondsLeft;

  int? _singleChoiceAnswerId;
  final List<int> _multipleChoiceAnswerIds = <int>[];
  int? _selectedStars;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _loadCurrentQuestion();
  }

  @override
  void dispose() {
    _stopCountdown();
    _shortAnswerController.dispose();
    super.dispose();
  }

  int get _totalQuestions => _session.sessionQuestionsId.length;

  bool get _isLastQuestion => _questionIndex == _totalQuestions - 1;

  Future<void> _loadCurrentQuestion() async {
    if (_session.sessionQuestionsId.isEmpty) {
      _stopCountdown();
      setState(() {
        _question = null;
        _errorMessage = 'В этой сессии нет вопросов.';
        _isLoading = false;
      });
      return;
    }

    _stopCountdown();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _sessionExpired = false;
    });

    try {
      final question = await _repository.getSessionQuestion(
        questionId: _session.sessionQuestionsId[_questionIndex],
      );

      _fillAnswerState(question);
      _startCountdown(question.secondsLeft);

      if (!mounted) return;

      setState(() {
        _question = question;
        _isLoading = false;
      });
    } on LockedException catch (e) {
      if (!mounted) return;
      _showExpiredState(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _question = null;
        _errorMessage = 'Не удалось загрузить вопрос: $e';
        _isLoading = false;
      });
    }
  }

  void _fillAnswerState(SessionQuestion question) {
    _singleChoiceAnswerId = null;
    _multipleChoiceAnswerIds.clear();
    _selectedStars = question.selectedStars;
    _shortAnswerController.text = question.shortAnswer ?? '';

    if (question.questionType == _singleChoiceType) {
      for (final answer in question.sessionQuestionAnswers) {
        if (answer.selected) {
          _singleChoiceAnswerId = answer.id;
          break;
        }
      }
      return;
    }

    if (question.questionType == _multipleChoiceType) {
      for (final answer in question.sessionQuestionAnswers) {
        if (answer.selected) {
          _multipleChoiceAnswerIds.add(answer.id);
        }
      }
    }
  }

  Future<void> _openQuestion(int nextIndex) async {
    if (_isLoading || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _saveCurrentQuestion();

      if (!mounted) return;

      setState(() {
        _questionIndex = nextIndex;
        _isSubmitting = false;
      });

      await _loadCurrentQuestion();
    } on LockedException catch (e) {
      if (!mounted) return;
      _showExpiredState(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar('Не удалось сохранить ответ: $e');
    }
  }

  Future<void> _saveCurrentQuestion() async {
    final question = _question;
    if (question == null) {
      return;
    }

    final payload = _buildSavePayload(question);
    if (payload == null) {
      return;
    }

    await _repository.saveSessionQuestion(data: payload);
  }

  Map<String, dynamic>? _buildSavePayload(SessionQuestion question) {
    switch (question.questionType) {
      case _singleChoiceType:
        return <String, dynamic>{
          'Id': question.id,
          'SessionQuestionAnswers': _buildChoiceAnswers(question),
        };
      case _multipleChoiceType:
        return <String, dynamic>{
          'Id': question.id,
          'SessionQuestionAnswers': _buildChoiceAnswers(question),
        };
      case _customAnswerType:
        return <String, dynamic>{
          'Id': question.id,
          'ShortAnswer': _shortAnswerController.text.trim(),
        };
      case _starRatingType:
        return <String, dynamic>{
          'Id': question.id,
          'SelectedStars': _selectedStars,
        };
      default:
        return null;
    }
  }

  List<Map<String, dynamic>> _buildChoiceAnswers(SessionQuestion question) {
    final answers = <Map<String, dynamic>>[];

    for (final answer in question.sessionQuestionAnswers) {
      final selected = question.questionType == _singleChoiceType
          ? _singleChoiceAnswerId == answer.id
          : _multipleChoiceAnswerIds.contains(answer.id);

      if (!selected) {
        continue;
      }

      answers.add(<String, dynamic>{'Id': answer.id, 'Selected': true});
    }

    return answers;
  }

  Future<void> _finishSession() async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      try {
        await _saveCurrentQuestion();
      } on LockedException {
        _sessionExpired = true;
      }

      final result = await _repository.finishSession(sessionId: _session.id);

      if (!mounted) return;

      _stopCountdown();
      setState(() => _isSubmitting = false);
      await _showResultDialog(result);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on LockedException catch (e) {
      if (!mounted) return;
      _showExpiredState(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar('Не удалось завершить тест: $e');
    }
  }

  Future<void> _finishExpiredSession() async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _repository.finishSession(sessionId: _session.id);

      if (!mounted) return;

      _stopCountdown();
      setState(() => _isSubmitting = false);
      await _showResultDialog(result);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar('Не удалось завершить тест: $e');
    }
  }

  Future<void> _showResultDialog(TestSessionResult result) {
    final value = result.result?.toStringAsFixed(0) ?? '0';

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Тест завершен'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.testProfile?.testTitle ?? widget.testTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text('Результат: $value%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _startCountdown(int? secondsLeft) {
    _stopCountdown();
    _secondsLeft = secondsLeft;

    if (secondsLeft == null || secondsLeft <= 0) {
      if (secondsLeft == 0) {
        _showExpiredState(_expiredMessage);
      }
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _secondsLeft == null) {
        timer.cancel();
        return;
      }

      if (_secondsLeft! <= 1) {
        timer.cancel();
        _showExpiredState(_expiredMessage);
        return;
      }

      setState(() {
        _secondsLeft = _secondsLeft! - 1;
      });
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _showExpiredState(String message) {
    _stopCountdown();
    setState(() {
      _question = null;
      _sessionExpired = true;
      _errorMessage = message;
      _secondsLeft = 0;
      _isLoading = false;
      _isSubmitting = false;
    });
  }

  void _toggleMultipleChoice(int answerId) {
    setState(() {
      if (_multipleChoiceAnswerIds.contains(answerId)) {
        _multipleChoiceAnswerIds.remove(answerId);
      } else {
        _multipleChoiceAnswerIds.add(answerId);
      }
    });
  }

  bool _isChoiceQuestion(SessionQuestion question) {
    return question.questionType == _singleChoiceType ||
        question.questionType == _multipleChoiceType;
  }

  bool _isShortAnswerQuestion(SessionQuestion question) {
    return question.questionType == _customAnswerType;
  }

  bool _isStarQuestion(SessionQuestion question) {
    return question.questionType == _starRatingType;
  }

  bool _isUnsupportedQuestion(SessionQuestion question) {
    return question.questionType == _sequenceType ||
        question.questionType == _correspondenceType;
  }

  @override
  Widget build(BuildContext context) {
    final question = _question;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.testTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(question),
    );
  }

  Widget _buildBody(SessionQuestion? question) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
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
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_sessionExpired)
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _finishExpiredSession,
                    icon: const Icon(Icons.task_alt_rounded),
                    label: const Text('Завершить тест'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _loadCurrentQuestion,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Повторить'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (question == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          _QuestionInfoCard(
            index: _questionIndex + 1,
            total: _totalQuestions,
            title: _stripHtml(question.htmlText),
            typeName: question.questionTypeName,
            secondsLeft: _secondsLeft,
            imageUrl: _extractImageUrl(question.htmlText),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: appPanelDecoration(),
                child: _buildAnswerBlock(question),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_questionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _openQuestion(_questionIndex - 1),
                    child: const Text('Назад'),
                  ),
                ),
              if (_questionIndex > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : _isLastQuestion
                      ? _finishSession
                      : () => _openQuestion(_questionIndex + 1),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_isLastQuestion ? 'Завершить' : 'Далее'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerBlock(SessionQuestion question) {
    if (_isUnsupportedQuestion(question)) {
      return const Text(
        'Типы вопросов на последовательность и соответствие пока не поддерживаются в мобильной версии.',
        style: TextStyle(fontSize: 14, color: AppColors.mutedText, height: 1.4),
      );
    }

    if (_isChoiceQuestion(question)) {
      if (question.sessionQuestionAnswers.isEmpty) {
        return const Text(
          'Для этого вопроса нет вариантов ответа.',
          style: TextStyle(fontSize: 14, color: AppColors.mutedText),
        );
      }

      final singleChoice = question.questionType == _singleChoiceType;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: question.sessionQuestionAnswers.map((answer) {
          final selected = singleChoice
              ? _singleChoiceAnswerId == answer.id
              : _multipleChoiceAnswerIds.contains(answer.id);

          return _AnswerTile(
            title: _stripHtml(answer.htmlText),
            selected: selected,
            singleChoice: singleChoice,
            onTap: () {
              if (singleChoice) {
                setState(() => _singleChoiceAnswerId = answer.id);
                return;
              }

              _toggleMultipleChoice(answer.id);
            },
          );
        }).toList(),
      );
    }

    if (_isShortAnswerQuestion(question)) {
      return TextField(
        controller: _shortAnswerController,
        maxLines: 5,
        maxLength: 128,
        decoration: const InputDecoration(
          labelText: 'Ваш ответ',
          alignLabelWithHint: true,
        ),
      );
    }

    if (_isStarQuestion(question)) {
      final maxStars = question.maxStars ?? 0;
      if (maxStars <= 0) {
        return const Text(
          'Для этого вопроса не настроена шкала.',
          style: TextStyle(fontSize: 14, color: AppColors.mutedText),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((question.scaleExplanation ?? '').isNotEmpty)
            Text(
              question.scaleExplanation!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: List.generate(maxStars, (index) {
              final starValue = index + 1;
              final selected = (_selectedStars ?? 0) >= starValue;

              return InkWell(
                onTap: () => setState(() => _selectedStars = starValue),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    selected ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 32,
                    color: selected ? AppColors.amber : AppColors.mutedText,
                  ),
                ),
              );
            }),
          ),
        ],
      );
    }

    return const Text(
      'Этот тип вопроса пока не поддерживается.',
      style: TextStyle(fontSize: 14, color: AppColors.mutedText),
    );
  }

  String? _extractImageUrl(String? input) {
    if (input == null || input.isEmpty) {
      return null;
    }

    final match = RegExp(
      r'<img[^>]+src="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(input);

    return match?.group(1);
  }

  String _stripHtml(String? input) {
    if (input == null || input.isEmpty) {
      return 'Текст вопроса отсутствует';
    }

    var text = input
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>|</div>|</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return text.isEmpty ? 'Текст вопроса отсутствует' : text;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.fixed, content: Text(message)),
    );
  }
}

class _QuestionInfoCard extends StatelessWidget {
  final int index;
  final int total;
  final String title;
  final String? typeName;
  final int? secondsLeft;
  final String? imageUrl;

  const _QuestionInfoCard({
    required this.index,
    required this.total,
    required this.title,
    required this.typeName,
    required this.secondsLeft,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: appPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Вопрос $index из $total',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.background,
                  child: const Text(
                    'Не удалось загрузить изображение',
                    style: TextStyle(color: AppColors.mutedText),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if ((typeName ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(typeName!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (secondsLeft != null) ...[
            const SizedBox(height: 8),
            Text(
              'Осталось: ${_formatSeconds(secondsLeft!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  static String _formatSeconds(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final restSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$restSeconds';
  }
}

class _AnswerTile extends StatelessWidget {
  final String title;
  final bool selected;
  final bool singleChoice;
  final VoidCallback onTap;

  const _AnswerTile({
    required this.title,
    required this.selected,
    required this.singleChoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? AppColors.surfaceMuted : AppColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.outline,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    singleChoice
                        ? (selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded)
                        : (selected
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded),
                    size: 20,
                    color: selected ? AppColors.primary : AppColors.mutedText,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.ink,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
