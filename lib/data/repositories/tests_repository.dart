import 'package:dio/dio.dart';
import 'package:eios/core/exceptions/app_exceptions.dart';
import 'package:eios/core/network/api_service.dart';
import 'package:eios/data/models/session_question.dart';
import 'package:eios/data/models/test_profile_for_pass.dart';
import 'package:eios/data/models/test_session.dart';
import 'package:eios/data/models/test_session_result.dart';

class TestsRepository {
  final ApiClient _api = ApiClient();

  static const Duration _testsWriteTimeout = Duration(seconds: 45);

  Future<List<TestProfileForPass>> getTestsForDiscipline({
    required int disciplineId,
  }) async {
    try {
      final activeTests = await _fetchTestsForDiscipline(
        disciplineId: disciplineId,
        archive: false,
      );
      final archivedTests = await _fetchTestsForDiscipline(
        disciplineId: disciplineId,
        archive: true,
      );

      return _mergeTests([...activeTests, ...archivedTests]);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TestSession> startSession({required int profileId}) async {
    try {
      final response = await _api.post(
        '/v1/Session',
        queryParameters: {'profileId': profileId},
        options: Options(
          sendTimeout: _testsWriteTimeout,
          receiveTimeout: _testsWriteTimeout,
        ),
      );
      return TestSession.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TestSession> getSession({required int sessionId}) async {
    try {
      final response = await _api.get('/v1/Session/$sessionId');
      return TestSession.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<SessionQuestion> getSessionQuestion({required int questionId}) async {
    try {
      final response = await _api.get('/v1/SessionQuestion/$questionId');
      return SessionQuestion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<SessionQuestion> saveSessionQuestion({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _api.put(
        '/v1/SessionQuestion',
        data: data,
        options: Options(
          sendTimeout: _testsWriteTimeout,
          receiveTimeout: _testsWriteTimeout,
        ),
      );

      return SessionQuestion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TestSessionResult> finishSession({required int sessionId}) async {
    try {
      final response = await _api.post(
        '/v1/TestPoolResult',
        queryParameters: {'sessionId': sessionId},
        options: Options(
          sendTimeout: _testsWriteTimeout,
          receiveTimeout: _testsWriteTimeout,
        ),
      );
      return TestSessionResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AppException _handleError(DioException error) {
    final statusCode = error.response?.statusCode;
    final message =
        _extractErrorMessage(error.response?.data) ??
        error.message ??
        'Произошла ошибка';
    final responseData = error.response?.data;

    if (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return AppException(
        'Сервер тестирования отвечает слишком долго. Попробуйте еще раз.',
      );
    }

    if (statusCode == 500 && _isSessionQuestionSaveServerError(responseData)) {
      return AppException(
        'Сервер ЭИОС не смог сохранить ответ на вопрос. Это проблема API MRSU, а не введенного ответа. Попробуйте еще раз позже или завершите тест в веб-версии ЭИОС.',
        500,
      );
    }

    switch (statusCode) {
      case 400:
        return BadRequestException(message);
      case 403:
        return ForbiddenException(message);
      case 423:
        return LockedException(message);
      case 404:
        return NotFoundException(message);
      default:
        return AppException(message, statusCode);
    }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final exceptionMessage =
          data['exceptionMessage']?.toString() ??
          data['ExceptionMessage']?.toString();
      final message =
          data['message']?.toString() ?? data['Message']?.toString();

      if (exceptionMessage != null &&
          (message == null || message == 'Произошла ошибка.')) {
        return exceptionMessage;
      }

      return message ?? exceptionMessage;
    }

    return data?.toString();
  }

  bool _isSessionQuestionSaveServerError(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return false;
    }

    final exceptionType =
        data['ExceptionType']?.toString() ?? data['exceptionType']?.toString();
    final exceptionMessage =
        data['ExceptionMessage']?.toString() ??
        data['exceptionMessage']?.toString();

    final isEntityCommandExecution =
        exceptionType ==
            'System.Data.Entity.Core.EntityCommandExecutionException' &&
        exceptionMessage?.contains(
              'An error occurred while executing the command definition',
            ) ==
            true;

    final isEfConcurrencyBug =
        exceptionType == 'System.NotSupportedException' &&
        exceptionMessage?.contains(
              'A second operation started on this context before a previous asynchronous operation completed',
            ) ==
            true;

    return isEntityCommandExecution || isEfConcurrencyBug;
  }

  Future<List<TestProfileForPass>> _fetchTestsForDiscipline({
    required int disciplineId,
    required bool archive,
  }) async {
    final response = await _api.get(
      '/v1/TestProfileForPass',
      queryParameters: {'archive': archive, 'count': 0, 'offset': 0},
    );

    if (response.data is! List) {
      return [];
    }

    return (response.data as List)
        .map(
          (item) => TestProfileForPass.fromJson(item as Map<String, dynamic>),
        )
        .where(
          (item) => item.controlDot?.ratingPlanDisciplineId == disciplineId,
        )
        .toList();
  }

  List<TestProfileForPass> _mergeTests(List<TestProfileForPass> tests) {
    final merged = <String, TestProfileForPass>{};

    for (final test in tests) {
      final key = _testKey(test);
      final existing = merged[key];

      if (existing == null) {
        merged[key] = test;
        continue;
      }

      merged[key] = TestProfileForPass(
        type: existing.type ?? test.type,
        durationInMinutes: existing.durationInMinutes ?? test.durationInMinutes,
        questionsCount: existing.questionsCount ?? test.questionsCount,
        attemptsCount: existing.attemptsCount ?? test.attemptsCount,
        attemptsUsedCount: _maxInt(
          existing.attemptsUsedCount,
          test.attemptsUsedCount,
        ),
        result: test.result ?? existing.result,
        canStartSession: existing.canStartSession || test.canStartSession,
        controlDot: existing.controlDot ?? test.controlDot,
        testProfile: existing.testProfile ?? test.testProfile,
        avalibleDatetimeStart:
            existing.avalibleDatetimeStart ?? test.avalibleDatetimeStart,
        avalibleDatetimeEnd:
            existing.avalibleDatetimeEnd ?? test.avalibleDatetimeEnd,
        activeSessionId: existing.activeSessionId ?? test.activeSessionId,
      );
    }

    return merged.values.toList();
  }

  String _testKey(TestProfileForPass test) {
    final controlDotId = test.controlDot?.ratingPlanControlDotId;
    final profileId = test.testProfile?.id;

    if (controlDotId != null || profileId != null) {
      return '${controlDotId ?? 'no-control-dot'}:${profileId ?? 'no-profile'}';
    }

    return '${test.controlDot?.ratingPlanSectionTitle ?? ''}:'
        '${test.testProfile?.testTitle ?? ''}:'
        '${test.avalibleDatetimeStart ?? ''}:'
        '${test.avalibleDatetimeEnd ?? ''}';
  }

  int? _maxInt(int? first, int? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first > second ? first : second;
  }
}
