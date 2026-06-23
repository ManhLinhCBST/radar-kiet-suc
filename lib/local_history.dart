import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_runtime.dart';

class SavedNodeResult {
  SavedNodeResult({
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'score': score,
      'level': level,
      'message': message,
    };
  }

  factory SavedNodeResult.fromJson(Map<String, dynamic> json) {
    return SavedNodeResult(
      id: _text(json['id']),
      name: _text(json['name']),
      score: _double(json['score']),
      level: _text(json['level']),
      message: _text(json['message']),
    );
  }
}

class SavedActionResult {
  SavedActionResult({
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

  Map<String, dynamic> toJson() {
    return {
      'node_id': nodeId,
      'title': title,
      'detail': detail,
      'priority': priority,
      'duration_minutes': durationMinutes,
      'effort': effort,
    };
  }

  factory SavedActionResult.fromJson(Map<String, dynamic> json) {
    return SavedActionResult(
      nodeId: _text(json['node_id']),
      title: _text(json['title']),
      detail: _text(json['detail']),
      priority: _text(json['priority']),
      durationMinutes: _int(json['duration_minutes']),
      effort: _text(json['effort']),
    );
  }
}

class CheckinRecord {
  CheckinRecord({
    required this.id,
    required this.dateIso,
    required this.createdAtIso,
    required this.systemScore,
    required this.systemLevel,
    required this.systemMessage,
    required this.questionCount,
    required this.nodes,
    required this.actions,
  });

  final String id;
  final String dateIso;
  final String createdAtIso;
  final double systemScore;
  final String systemLevel;
  final String systemMessage;
  final int questionCount;
  final List<SavedNodeResult> nodes;
  final List<SavedActionResult> actions;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_iso': dateIso,
      'created_at_iso': createdAtIso,
      'system_score': systemScore,
      'system_level': systemLevel,
      'system_message': systemMessage,
      'question_count': questionCount,
      'nodes': nodes.map((item) => item.toJson()).toList(),
      'actions': actions.map((item) => item.toJson()).toList(),
    };
  }

  factory CheckinRecord.fromJson(Map<String, dynamic> json) {
    return CheckinRecord(
      id: _text(json['id']),
      dateIso: _text(json['date_iso']),
      createdAtIso: _text(json['created_at_iso']),
      systemScore: _double(json['system_score']),
      systemLevel: _text(json['system_level']),
      systemMessage: _text(json['system_message']),
      questionCount: _int(json['question_count']),
      nodes: _list(json['nodes'])
          .map((item) => SavedNodeResult.fromJson(_map(item)))
          .toList(),
      actions: _list(json['actions'])
          .map((item) => SavedActionResult.fromJson(_map(item)))
          .toList(),
    );
  }

  factory CheckinRecord.fromRuntimeResult({
    required RuntimeResult result,
    required int questionCount,
  }) {
    final now = DateTime.now();
    final dateIso = _dateKey(now);

    return CheckinRecord(
      id: dateIso,
      dateIso: dateIso,
      createdAtIso: now.toIso8601String(),
      systemScore: result.systemScore,
      systemLevel: result.systemLevel,
      systemMessage: result.systemMessage,
      questionCount: questionCount,
      nodes: result.nodeResults
          .map(
            (node) => SavedNodeResult(
              id: node.id,
              name: node.name,
              score: node.score,
              level: node.level,
              message: node.message,
            ),
          )
          .toList(),
      actions: result.actions
          .map(
            (action) => SavedActionResult(
              nodeId: action.nodeId,
              title: action.title,
              detail: action.detail,
              priority: action.priority,
              durationMinutes: action.durationMinutes,
              effort: action.effort,
            ),
          )
          .toList(),
    );
  }
}

class NodeTrend {
  NodeTrend({
    required this.id,
    required this.name,
    required this.previousScore,
    required this.currentScore,
    required this.delta,
  });

  final String id;
  final String name;
  final double previousScore;
  final double currentScore;
  final double delta;

  String get direction {
    if (delta <= -2) {
      return 'improving';
    }

    if (delta >= 2) {
      return 'worsening';
    }

    return 'flat';
  }

  String get directionText {
    if (direction == 'improving') {
      return 'đang tốt lên';
    }

    if (direction == 'worsening') {
      return 'đang xấu đi';
    }

    return 'gần như ổn định';
  }
}

class TrajectorySummary {
  TrajectorySummary({
    required this.hasEnoughData,
    required this.state,
    required this.direction,
    required this.message,
    required this.previousScore,
    required this.currentScore,
    required this.delta,
    required this.improvingNodes,
    required this.worseningNodes,
  });

  final bool hasEnoughData;
  final String state;
  final String direction;
  final String message;
  final double previousScore;
  final double currentScore;
  final double delta;
  final List<NodeTrend> improvingNodes;
  final List<NodeTrend> worseningNodes;

  factory TrajectorySummary.notEnough() {
    return TrajectorySummary(
      hasEnoughData: false,
      state: 'not_enough_data',
      direction: 'unknown',
      message: 'Cần ít nhất 2 ngày check-in để đọc xu hướng.',
      previousScore: 0,
      currentScore: 0,
      delta: 0,
      improvingNodes: <NodeTrend>[],
      worseningNodes: <NodeTrend>[],
    );
  }

  factory TrajectorySummary.fromRecords(List<CheckinRecord> records) {
    final sorted = [...records]
      ..sort((a, b) => a.dateIso.compareTo(b.dateIso));

    if (sorted.length < 2) {
      return TrajectorySummary.notEnough();
    }

    final previous = sorted[sorted.length - 2];
    final current = sorted[sorted.length - 1];

    final delta = current.systemScore - previous.systemScore;

    final state = _stateFromDelta(delta);
    final direction = _directionFromDelta(delta);

    final previousNodeMap = <String, SavedNodeResult>{};

    for (final node in previous.nodes) {
      previousNodeMap[node.id] = node;
    }

    final trends = <NodeTrend>[];

    for (final currentNode in current.nodes) {
      final previousNode = previousNodeMap[currentNode.id];

      if (previousNode == null) {
        continue;
      }

      trends.add(
        NodeTrend(
          id: currentNode.id,
          name: currentNode.name,
          previousScore: previousNode.score,
          currentScore: currentNode.score,
          delta: currentNode.score - previousNode.score,
        ),
      );
    }

    final improving = trends
        .where((item) => item.delta <= -2)
        .toList()
      ..sort((a, b) => a.delta.compareTo(b.delta));

    final worsening = trends
        .where((item) => item.delta >= 2)
        .toList()
      ..sort((a, b) => b.delta.compareTo(a.delta));

    return TrajectorySummary(
      hasEnoughData: true,
      state: state,
      direction: direction,
      message: _messageFromState(state, delta),
      previousScore: previous.systemScore,
      currentScore: current.systemScore,
      delta: delta,
      improvingNodes: improving,
      worseningNodes: worsening,
    );
  }

  static String _directionFromDelta(double delta) {
    if (delta <= -2) {
      return 'improving';
    }

    if (delta >= 2) {
      return 'worsening';
    }

    return 'flat';
  }

  static String _stateFromDelta(double delta) {
    if (delta <= -10) {
      return 'recovering';
    }

    if (delta <= -2) {
      return 'mild_recovering';
    }

    if (delta < 2) {
      return 'stable';
    }

    if (delta < 10) {
      return 'mild_declining';
    }

    if (delta < 20) {
      return 'declining';
    }

    return 'collapsing';
  }

  static String _messageFromState(String state, double delta) {
    final d = delta.toStringAsFixed(1);

    if (state == 'recovering') {
      return 'Hệ đang hồi phục rõ. Điểm hao mòn giảm $d điểm so với lần trước.';
    }

    if (state == 'mild_recovering') {
      return 'Hệ đang hồi nhẹ. Điểm hao mòn giảm $d điểm so với lần trước.';
    }

    if (state == 'stable') {
      return 'Hệ tương đối ổn định. Điểm hao mòn không đổi nhiều so với lần trước.';
    }

    if (state == 'mild_declining') {
      return 'Hệ đang xấu đi nhẹ. Điểm hao mòn tăng $d điểm so với lần trước.';
    }

    if (state == 'declining') {
      return 'Hệ đang suy giảm rõ. Điểm hao mòn tăng $d điểm so với lần trước.';
    }

    return 'Hệ đang lao dốc. Điểm hao mòn tăng $d điểm so với lần trước.';
  }
}

class HistoryStore {
  static const String storageKey = 'body_battery_checkin_history_v1';

  Future<List<CheckinRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);

    if (raw == null || raw.trim().isEmpty) {
      return <CheckinRecord>[];
    }

    final decoded = jsonDecode(raw);

    final records = _list(decoded)
        .map((item) => CheckinRecord.fromJson(_map(item)))
        .where((item) => item.dateIso.isNotEmpty)
        .toList();

    records.sort((a, b) => a.dateIso.compareTo(b.dateIso));

    return records;
  }

  Future<void> saveResult({
    required RuntimeResult result,
    required int questionCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await loadRecords();

    final newRecord = CheckinRecord.fromRuntimeResult(
      result: result,
      questionCount: questionCount,
    );

    records.removeWhere((item) => item.id == newRecord.id);
    records.add(newRecord);
    records.sort((a, b) => a.dateIso.compareTo(b.dateIso));

    final trimmed = records.length > 120
        ? records.sublist(records.length - 120)
        : records;

    final encoded = jsonEncode(
      trimmed.map((item) => item.toJson()).toList(),
    );

    await prefs.setString(storageKey, encoded);
  }


  Future<void> seedDemo3Days() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();

    final day1 = today.subtract(const Duration(days: 2));
    final day2 = today.subtract(const Duration(days: 1));
    final day3 = today;

    final records = <CheckinRecord>[
      _demoRecord(
        date: day1,
        systemScore: 76,
        systemLevel: 'high',
        systemMessage: 'Dữ liệu mẫu: hệ đang khá căng, nhiều node bị kéo lên vùng rủi ro cao.',
        nodeScores: <String, double>{
          'nap': 72,
          'chuyen_hoa': 64,
          'du_tru': 82,
          'tai': 84,
          'phuc_hoi': 78,
          'thich_nghi': 70,
          'hao_mon': 76,
          'mat_kiem_soat': 52,
        },
      ),
      _demoRecord(
        date: day2,
        systemScore: 63,
        systemLevel: 'medium',
        systemMessage: 'Dữ liệu mẫu: hệ đã hạ tải một phần, nhưng vẫn còn trong vùng cảnh báo.',
        nodeScores: <String, double>{
          'nap': 60,
          'chuyen_hoa': 58,
          'du_tru': 68,
          'tai': 70,
          'phuc_hoi': 61,
          'thich_nghi': 58,
          'hao_mon': 64,
          'mat_kiem_soat': 42,
        },
      ),
      _demoRecord(
        date: day3,
        systemScore: 48,
        systemLevel: 'medium',
        systemMessage: 'Dữ liệu mẫu: hệ đang hồi phục, điểm hao mòn đã giảm rõ so với hai ngày trước.',
        nodeScores: <String, double>{
          'nap': 46,
          'chuyen_hoa': 42,
          'du_tru': 52,
          'tai': 55,
          'phuc_hoi': 45,
          'thich_nghi': 43,
          'hao_mon': 48,
          'mat_kiem_soat': 34,
        },
      ),
    ];

    final encoded = jsonEncode(
      records.map((item) => item.toJson()).toList(),
    );

    await prefs.setString(storageKey, encoded);
  }

  CheckinRecord _demoRecord({
    required DateTime date,
    required double systemScore,
    required String systemLevel,
    required String systemMessage,
    required Map<String, double> nodeScores,
  }) {
    final dateIso = _dateKey(date);
    final createdAt = DateTime(
      date.year,
      date.month,
      date.day,
      8,
      0,
    );

    final nodeNames = <String, String>{
      'nap': 'Nạp',
      'chuyen_hoa': 'Chuyển hóa',
      'du_tru': 'Dự trữ',
      'tai': 'Tải',
      'phuc_hoi': 'Phục hồi',
      'thich_nghi': 'Thích nghi',
      'hao_mon': 'Hao mòn',
      'mat_kiem_soat': 'Mất kiểm soát',
    };

    final nodes = nodeScores.entries.map((entry) {
      final name = nodeNames[entry.key] ?? entry.key;

      return SavedNodeResult(
        id: entry.key,
        name: name,
        score: entry.value,
        level: _scoreLevel(entry.value),
        message: 'Dữ liệu mẫu: $name có điểm ${entry.value.toStringAsFixed(1)}.',
      );
    }).toList();

    return CheckinRecord(
      id: dateIso,
      dateIso: dateIso,
      createdAtIso: createdAt.toIso8601String(),
      systemScore: systemScore,
      systemLevel: systemLevel,
      systemMessage: systemMessage,
      questionCount: 32,
      nodes: nodes,
      actions: <SavedActionResult>[
        SavedActionResult(
          nodeId: 'tai',
          title: 'Giảm một nguồn tải',
          detail: 'Dữ liệu mẫu: chọn một nguồn tải lớn nhất trong ngày và giảm một nấc.',
          priority: 'high',
          durationMinutes: 10,
          effort: 'medium',
        ),
        SavedActionResult(
          nodeId: 'phuc_hoi',
          title: 'Tạo một phiên hồi phục thật',
          detail: 'Dữ liệu mẫu: dành 15-20 phút không điện thoại, không công việc, không thông tin mới.',
          priority: 'high',
          durationMinutes: 20,
          effort: 'low',
        ),
      ],
    );
  }

  String _scoreLevel(double score) {
    if (score < 40) {
      return 'low';
    }

    if (score < 70) {
      return 'medium';
    }

    return 'high';
  }
  Future<String> exportRecordsJson() async {
    final records = await loadRecords();

    final payload = <String, dynamic>{
      'schema': 'body_battery_history_export_v1',
      'exported_at': DateTime.now().toIso8601String(),
      'record_count': records.length,
      'records': records.map((item) => item.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}

String _dateKey(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
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


