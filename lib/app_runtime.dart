import 'dart:convert';

import 'package:flutter/services.dart';

class RuntimeBundle {
  RuntimeBundle({
    required this.questionLibrary,
    required this.observationEngine,
    required this.nodeEngine,
    required this.meaningEngine,
    required this.recommendationEngine,
  });

  final Map<String, dynamic> questionLibrary;
  final Map<String, dynamic> observationEngine;
  final Map<String, dynamic> nodeEngine;
  final Map<String, dynamic> meaningEngine;
  final Map<String, dynamic> recommendationEngine;
}

class CoreNode {
  CoreNode({
    required this.id,
    required this.name,
    required this.dailyMin,
  });

  final String id;
  final String name;
  final int dailyMin;
}

class QuestionItem {
  QuestionItem({
    required this.id,
    required this.node,
    required this.title,
    required this.publicTitle,
    required this.publicHelp,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.lowLabel,
    required this.highLabel,
    required this.riskDirection,
    required this.priority,
  });

  final String id;
  final String node;
  final String title;
  final String publicTitle;
  final String publicHelp;
  final double min;
  final double max;
  final double defaultValue;
  final String lowLabel;
  final String highLabel;
  final String riskDirection;
  final String priority;

  String get displayTitle {
    if (publicTitle.trim().isNotEmpty) {
      return publicTitle;
    }

    return title;
  }
}

class ObservationRule {
  ObservationRule({
    required this.questionId,
    required this.node,
    required this.riskCurve,
    required this.validMin,
    required this.validMax,
    required this.greenMin,
    required this.greenMax,
    required this.yellowMin,
    required this.yellowMax,
    required this.redMin,
    required this.redMax,
  });

  final String questionId;
  final String node;
  final String riskCurve;
  final double validMin;
  final double validMax;
  final double greenMin;
  final double greenMax;
  final double yellowMin;
  final double yellowMax;
  final double redMin;
  final double redMax;
}

class NodeQuestionWeight {
  NodeQuestionWeight({
    required this.questionId,
    required this.internalWeight,
  });

  final String questionId;
  final double internalWeight;
}

class NodeRule {
  NodeRule({
    required this.id,
    required this.name,
    required this.nodeWeight,
    required this.questions,
  });

  final String id;
  final String name;
  final double nodeWeight;
  final List<NodeQuestionWeight> questions;
}

class MeaningRule {
  MeaningRule({
    required this.id,
    required this.name,
    required this.lowMessage,
    required this.mediumMessage,
    required this.highMessage,
  });

  final String id;
  final String name;
  final String lowMessage;
  final String mediumMessage;
  final String highMessage;
}

class ActionItem {
  ActionItem({
    required this.id,
    required this.title,
    required this.detail,
    required this.priority,
    required this.durationMinutes,
    required this.effort,
  });

  final String id;
  final String title;
  final String detail;
  final String priority;
  final int durationMinutes;
  final String effort;
}

class RecommendationRule {
  RecommendationRule({
    required this.nodeId,
    required this.name,
    required this.mediumActions,
    required this.highActions,
  });

  final String nodeId;
  final String name;
  final List<ActionItem> mediumActions;
  final List<ActionItem> highActions;
}

class QuestionRisk {
  QuestionRisk({
    required this.questionId,
    required this.node,
    required this.answer,
    required this.risk,
  });

  final String questionId;
  final String node;
  final double answer;
  final double risk;
}

class NodeResult {
  NodeResult({
    required this.id,
    required this.name,
    required this.score,
    required this.level,
    required this.message,
  });

  final String id;
  final String name;
  final double score;
  final String level;
  final String message;

  String get levelText {
    if (level == 'low') {
      return 'Ổn';
    }

    if (level == 'medium') {
      return 'Cảnh báo';
    }

    return 'Căng';
  }
}

class RuntimeAction {
  RuntimeAction({
    required this.nodeId,
    required this.title,
    required this.detail,
    required this.priority,
    required this.durationMinutes,
    required this.effort,
  });

  final String nodeId;
  final String title;
  final String detail;
  final String priority;
  final int durationMinutes;
  final String effort;
}

class RuntimeResult {
  RuntimeResult({
    required this.systemScore,
    required this.systemLevel,
    required this.systemMessage,
    required this.questionRisks,
    required this.nodeResults,
    required this.actions,
  });

  final double systemScore;
  final String systemLevel;
  final String systemMessage;
  final List<QuestionRisk> questionRisks;
  final List<NodeResult> nodeResults;
  final List<RuntimeAction> actions;

  String get systemLevelText {
    if (systemLevel == 'low') {
      return 'Ổn';
    }

    if (systemLevel == 'medium') {
      return 'Cảnh báo';
    }

    return 'Căng';
  }
}

class AppRuntime {
  AppRuntime({
    required this.bundle,
    required this.coreNodes,
    required this.questions,
    required this.observationRules,
    required this.nodeRules,
    required this.meaningRules,
    required this.recommendationRules,
    required this.dailyQuestionCount,
  });

  final RuntimeBundle bundle;
  final List<CoreNode> coreNodes;
  final List<QuestionItem> questions;
  final Map<String, ObservationRule> observationRules;
  final Map<String, NodeRule> nodeRules;
  final Map<String, MeaningRule> meaningRules;
  final Map<String, RecommendationRule> recommendationRules;
  final int dailyQuestionCount;

  static Future<AppRuntime> load() async {
    final bundle = RuntimeBundle(
      questionLibrary: await _loadJson('assets/data/question_library.json'),
      observationEngine: await _loadJson('assets/data/observation_engine.json'),
      nodeEngine: await _loadJson('assets/data/node_engine.json'),
      meaningEngine: await _loadJson('assets/data/meaning_engine.json'),
      recommendationEngine:
          await _loadJson('assets/data/recommendation_engine.json'),
    );

    final coreNodes = _list(bundle.questionLibrary['core_nodes'])
        .map((item) {
          final map = _map(item);

          return CoreNode(
            id: _text(map['id']),
            name: _text(map['name']),
            dailyMin: _int(map['daily_min']),
          );
        })
        .where((item) => item.id.isNotEmpty)
        .toList();

    final questions = _list(bundle.questionLibrary['questions'])
        .map((item) {
          final map = _map(item);
          final min = _double(map['min']);
          final max = _double(map['max']);
          final fallbackDefault = max >= 12 ? 6.0 : 5.0;

          return QuestionItem(
            id: _text(map['id']),
            node: _text(map['node']),
            title: _text(map['title']),
            publicTitle: _text(map['public_title']),
            publicHelp: _text(map['public_help']),
            min: min,
            max: max,
            defaultValue: map.containsKey('default')
                ? _double(map['default'])
                : fallbackDefault,
            lowLabel: _text(map['low_label']).isNotEmpty
                ? _text(map['low_label'])
                : _formatNumber(min),
            highLabel: _text(map['high_label']).isNotEmpty
                ? _text(map['high_label'])
                : _formatNumber(max),
            riskDirection: _text(map['risk_direction']),
            priority: _text(map['priority']),
          );
        })
        .where((item) => item.id.isNotEmpty)
        .toList();

    final observationRules = <String, ObservationRule>{};

    for (final item in _list(bundle.observationEngine['observations'])) {
      final map = _map(item);
      final questionId = _text(map['question_id']);

      if (questionId.isEmpty) {
        continue;
      }

      observationRules[questionId] = ObservationRule(
        questionId: questionId,
        node: _text(map['node']),
        riskCurve: _text(map['risk_curve']),
        validMin: _double(map['valid_min']),
        validMax: _double(map['valid_max']),
        greenMin: _double(map['green_min']),
        greenMax: _double(map['green_max']),
        yellowMin: _double(map['yellow_min']),
        yellowMax: _double(map['yellow_max']),
        redMin: _double(map['red_min']),
        redMax: _double(map['red_max']),
      );
    }

    final nodeRules = <String, NodeRule>{};

    for (final item in _list(bundle.nodeEngine['nodes'])) {
      final map = _map(item);
      final id = _text(map['id']);
      final qWeights = <NodeQuestionWeight>[];

      for (final qItem in _list(map['questions'])) {
        final qMap = _map(qItem);

        qWeights.add(
          NodeQuestionWeight(
            questionId: _text(qMap['question_id']),
            internalWeight: _double(qMap['internal_weight']),
          ),
        );
      }

      if (id.isEmpty) {
        continue;
      }

      nodeRules[id] = NodeRule(
        id: id,
        name: _nodeNameFromCore(coreNodes, id),
        nodeWeight: _double(map['node_weight']),
        questions: qWeights,
      );
    }

    final meaningRules = <String, MeaningRule>{};

    for (final item in _list(bundle.meaningEngine['nodes'])) {
      final map = _map(item);
      final id = _text(map['id']);

      if (id.isEmpty) {
        continue;
      }

      meaningRules[id] = MeaningRule(
        id: id,
        name: _text(map['name']),
        lowMessage: _text(map['low_message']),
        mediumMessage: _text(map['medium_message']),
        highMessage: _text(map['high_message']),
      );
    }

    final recommendationRules = <String, RecommendationRule>{};

    for (final item in _list(bundle.recommendationEngine['nodes'])) {
      final map = _map(item);
      final id = _text(map['id']);

      if (id.isEmpty) {
        continue;
      }

      recommendationRules[id] = RecommendationRule(
        nodeId: id,
        name: _text(map['name']),
        mediumActions: _actions(map['medium_actions']),
        highActions: _actions(map['high_actions']),
      );
    }

    final strategy = _map(bundle.questionLibrary['strategy']);
    final dailyQuestionCount = _int(strategy['daily_question_count']);

    return AppRuntime(
      bundle: bundle,
      coreNodes: coreNodes,
      questions: questions,
      observationRules: observationRules,
      nodeRules: nodeRules,
      meaningRules: meaningRules,
      recommendationRules: recommendationRules,
      dailyQuestionCount: dailyQuestionCount <= 0 ? 8 : dailyQuestionCount,
    );
  }

  Map<String, double> defaultAnswers() {
    final result = <String, double>{};

    for (final question in questions) {
      result[question.id] = question.defaultValue;
    }

    return result;
  }

  List<QuestionItem> visibleQuestions({
    required bool fullMode,
  }) {
    if (fullMode) {
      return questions;
    }

    return _selectDailyQuestions();
  }

  RuntimeResult calculate({
    required List<QuestionItem> visibleQuestions,
    required Map<String, double> answers,
  }) {
    final visibleIds = visibleQuestions.map((item) => item.id).toSet();
    final questionRisks = <QuestionRisk>[];

    for (final question in visibleQuestions) {
      final answer = answers[question.id] ?? question.defaultValue;
      final risk = _riskForQuestion(question, answer);

      questionRisks.add(
        QuestionRisk(
          questionId: question.id,
          node: question.node,
          answer: answer,
          risk: risk,
        ),
      );
    }

    final riskByQuestionId = <String, QuestionRisk>{};

    for (final item in questionRisks) {
      riskByQuestionId[item.questionId] = item;
    }

    final nodeResults = <NodeResult>[];

    double systemWeightedSum = 0;
    double systemWeightSum = 0;

    for (final node in coreNodes) {
      final nodeRule = nodeRules[node.id];

      if (nodeRule == null) {
        continue;
      }

      final activeWeights = nodeRule.questions
          .where((item) => visibleIds.contains(item.questionId))
          .toList();

      if (activeWeights.isEmpty) {
        continue;
      }

      double nodeWeightedSum = 0;
      double nodeWeightSum = 0;

      for (final qWeight in activeWeights) {
        final qRisk = riskByQuestionId[qWeight.questionId];

        if (qRisk == null) {
          continue;
        }

        nodeWeightedSum += qRisk.risk * qWeight.internalWeight;
        nodeWeightSum += qWeight.internalWeight;
      }

      if (nodeWeightSum <= 0) {
        continue;
      }

      final nodeScore = (nodeWeightedSum / nodeWeightSum) * 100;
      final level = _level(nodeScore);
      final message = _meaningForNode(node.id, level);

      nodeResults.add(
        NodeResult(
          id: node.id,
          name: node.name,
          score: nodeScore,
          level: level,
          message: message,
        ),
      );

      systemWeightedSum += nodeScore * nodeRule.nodeWeight;
      systemWeightSum += nodeRule.nodeWeight;
    }

    nodeResults.sort((a, b) => b.score.compareTo(a.score));

    final systemScore =
        systemWeightSum <= 0 ? 0.0 : systemWeightedSum / systemWeightSum;

    final systemLevel = _level(systemScore);
    final systemMessage = _systemMessage(systemScore);
    final actions = _buildActions(nodeResults.take(3).toList());

    return RuntimeResult(
      systemScore: systemScore,
      systemLevel: systemLevel,
      systemMessage: systemMessage,
      questionRisks: questionRisks,
      nodeResults: nodeResults,
      actions: actions,
    );
  }

  List<QuestionItem> _selectDailyQuestions() {
    final selected = <QuestionItem>[];
    final now = DateTime.now();
    final rotationSeed = now.difference(DateTime(now.year, 1, 1)).inDays;

    for (final node in coreNodes) {
      final nodeQuestions =
          questions.where((item) => item.node == node.id).toList();

      nodeQuestions.sort((a, b) {
        final byPriority =
            _priorityRank(a.priority).compareTo(_priorityRank(b.priority));

        if (byPriority != 0) {
          return byPriority;
        }

        return a.id.compareTo(b.id);
      });

      if (nodeQuestions.isEmpty) {
        continue;
      }

      final index = rotationSeed % nodeQuestions.length;
      selected.add(nodeQuestions[index]);
    }

    if (selected.length >= dailyQuestionCount) {
      return selected.take(dailyQuestionCount).toList();
    }

    final remaining = questions
        .where((item) => !selected.any((selected) => selected.id == item.id))
        .toList();

    remaining.sort((a, b) {
      final byPriority =
          _priorityRank(a.priority).compareTo(_priorityRank(b.priority));

      if (byPriority != 0) {
        return byPriority;
      }

      return a.id.compareTo(b.id);
    });

    for (final item in remaining) {
      selected.add(item);

      if (selected.length >= dailyQuestionCount) {
        break;
      }
    }

    return selected;
  }

  double _riskForQuestion(QuestionItem question, double rawAnswer) {
    final rule = observationRules[question.id];

    if (rule == null) {
      return _linearRisk(
        min: question.min,
        max: question.max,
        answer: rawAnswer,
        riskCurve: question.riskDirection,
      );
    }

    final answer = rawAnswer.clamp(rule.validMin, rule.validMax);

    if (_inside(answer, rule.greenMin, rule.greenMax)) {
      return _bandRisk(
        answer: answer,
        min: rule.greenMin,
        max: rule.greenMax,
        lowRisk: 0.0,
        highRisk: 0.39,
        riskCurve: rule.riskCurve,
      );
    }

    if (_inside(answer, rule.yellowMin, rule.yellowMax)) {
      return _bandRisk(
        answer: answer,
        min: rule.yellowMin,
        max: rule.yellowMax,
        lowRisk: 0.40,
        highRisk: 0.69,
        riskCurve: rule.riskCurve,
      );
    }

    if (_inside(answer, rule.redMin, rule.redMax)) {
      return _bandRisk(
        answer: answer,
        min: rule.redMin,
        max: rule.redMax,
        lowRisk: 0.70,
        highRisk: 1.0,
        riskCurve: rule.riskCurve,
      );
    }

    return _linearRisk(
      min: rule.validMin,
      max: rule.validMax,
      answer: answer,
      riskCurve: rule.riskCurve,
    );
  }

  double _bandRisk({
    required double answer,
    required double min,
    required double max,
    required double lowRisk,
    required double highRisk,
    required String riskCurve,
  }) {
    if (max <= min) {
      return highRisk;
    }

    final normalized = ((answer - min) / (max - min)).clamp(0.0, 1.0);

    if (riskCurve == 'low_is_bad') {
      return highRisk - normalized * (highRisk - lowRisk);
    }

    return lowRisk + normalized * (highRisk - lowRisk);
  }

  double _linearRisk({
    required double min,
    required double max,
    required double answer,
    required String riskCurve,
  }) {
    if (max <= min) {
      return 0;
    }

    final normalized = ((answer - min) / (max - min)).clamp(0.0, 1.0);

    if (riskCurve == 'low_is_bad') {
      return 1.0 - normalized;
    }

    return normalized;
  }

  bool _inside(double value, double min, double max) {
    return value >= min && value <= max;
  }

  String _meaningForNode(String nodeId, String level) {
    final rule = meaningRules[nodeId];

    if (rule == null) {
      return '';
    }

    if (level == 'low') {
      return rule.lowMessage;
    }

    if (level == 'medium') {
      return rule.mediumMessage;
    }

    return rule.highMessage;
  }

  String _systemMessage(double score) {
    if (score < 40) {
      return 'Hôm nay hệ của bạn còn khá ổn. Vẫn nên giữ nhịp ngủ, ăn uống và nghỉ ngơi đều để không bị tụt về cuối ngày.';
    }

    if (score < 70) {
      return 'Hôm nay hệ của bạn đang ở vùng cảnh báo. Nên giảm bớt việc không cần thiết, giữ năng lượng cho việc chính và ưu tiên phục hồi.';
    }

    return 'Hôm nay hệ của bạn đang khá căng. Không nên cố ép thêm. Việc quan trọng nhất là hạ tải, nghỉ thật, ngủ sớm và tránh kéo cơ thể quá giới hạn.';
  }

  List<RuntimeAction> _buildActions(List<NodeResult> topNodes) {
    final result = <RuntimeAction>[];

    for (final node in topNodes) {
      final rule = recommendationRules[node.id];

      if (rule == null) {
        continue;
      }

      final candidates =
          node.level == 'high' ? rule.highActions : rule.mediumActions;

      for (final action in candidates.take(2)) {
        result.add(
          RuntimeAction(
            nodeId: node.id,
            title: action.title,
            detail: action.detail,
            priority: action.priority,
            durationMinutes: action.durationMinutes,
            effort: action.effort,
          ),
        );

        if (result.length >= 6) {
          return result;
        }
      }
    }

    return result;
  }
}

Future<Map<String, dynamic>> _loadJson(String assetPath) async {
  final raw = await rootBundle.loadString(assetPath);
  final decoded = jsonDecode(raw);

  if (decoded is Map<String, dynamic>) {
    return decoded;
  }

  if (decoded is Map) {
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  throw Exception('Không đọc được JSON: $assetPath');
}

List<ActionItem> _actions(dynamic value) {
  return _list(value).map((item) {
    final map = _map(item);

    return ActionItem(
      id: _text(map['id']),
      title: _text(map['title']),
      detail: _text(map['detail']),
      priority: _text(map['priority']),
      durationMinutes: _int(map['duration_minutes']),
      effort: _text(map['effort']),
    );
  }).toList();
}

String _nodeNameFromCore(List<CoreNode> nodes, String id) {
  for (final node in nodes) {
    if (node.id == id) {
      return node.name;
    }
  }

  return id;
}

int _priorityRank(String priority) {
  if (priority == 'critical') {
    return 0;
  }

  if (priority == 'high') {
    return 1;
  }

  if (priority == 'medium') {
    return 2;
  }

  return 3;
}

String _level(double score) {
  if (score < 40) {
    return 'low';
  }

  if (score < 70) {
    return 'medium';
  }

  return 'high';
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }

  return value.toStringAsFixed(1);
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), val),
    );
  }

  return <String, dynamic>{};
}

List<dynamic> _list(dynamic value) {
  if (value is List) {
    return value;
  }

  return <dynamic>[];
}

String _text(dynamic value) {
  if (value == null) {
    return '';
  }

  return value.toString();
}

double _double(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}

int _int(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
}
