import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_runtime.dart';
import 'local_history.dart';

void main() {
  runApp(const RadarKietSucApp());
}

class RadarKietSucApp extends StatelessWidget {
  const RadarKietSucApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radar Kiệt Sức',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4F46E5),
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
      ),
      home: const CheckinInputPage(),
    );
  }
}

class CheckinInputPage extends StatefulWidget {
  const CheckinInputPage({super.key});

  @override
  State<CheckinInputPage> createState() => _CheckinInputPageState();
}

class _CheckinInputPageState extends State<CheckinInputPage> {
  final HistoryStore _historyStore = HistoryStore();

  late Future<AppRuntime> _futureRuntime;

  Map<String, double> _answers = <String, double>{};
  List<CheckinRecord> _records = <CheckinRecord>[];
  TrajectorySummary _trajectory = TrajectorySummary.notEnough();

  bool _fullMode = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _futureRuntime = _loadRuntime();
  }

  Future<AppRuntime> _loadRuntime() async {
    final runtime = await AppRuntime.load();
    final records = await _historyStore.loadRecords();

    _answers = runtime.defaultAnswers();
    _records = records;
    _trajectory = TrajectorySummary.fromRecords(records);

    return runtime;
  }

  Future<void> _reloadHistory() async {
    final records = await _historyStore.loadRecords();

    setState(() {
      _records = records;
      _trajectory = TrajectorySummary.fromRecords(records);
    });
  }

  void _reset(AppRuntime runtime) {
    setState(() {
      _answers = runtime.defaultAnswers();
    });
  }

  Future<void> _clearHistory() async {
    await _historyStore.clear();

    setState(() {
      _records = <CheckinRecord>[];
      _trajectory = TrajectorySummary.notEnough();
    });
  }

  Future<void> _seedDemoHistory() async {
    await _historyStore.seedDemo3Days();

    final records = await _historyStore.loadRecords();

    if (!mounted) {
      return;
    }

    setState(() {
      _records = records;
      _trajectory = TrajectorySummary.fromRecords(records);
    });
  }

  Future<void> _exportHistoryJson() async {
    final json = await _historyStore.exportRecordsJson();

    await Clipboard.setData(
      ClipboardData(text: json),
    );
  }

  Future<void> _openResult(AppRuntime runtime) async {
    if (_saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final visibleQuestions = runtime.visibleQuestions(
        fullMode: _fullMode,
      );

      final result = runtime.calculate(
        visibleQuestions: visibleQuestions,
        answers: _answers,
      );

      await _historyStore.saveResult(
        result: result,
        questionCount: visibleQuestions.length,
      );

      final records = await _historyStore.loadRecords();
      final trajectory = TrajectorySummary.fromRecords(records);

      if (!mounted) {
        return;
      }

      setState(() {
        _records = records;
        _trajectory = trajectory;
        _saving = false;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultPage(
            result: result,
            questionCount: visibleQuestions.length,
            records: records,
            trajectory: trajectory,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không lưu được kết quả: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppRuntime>(
      future: _futureRuntime,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Radar Kiệt Sức'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Không tải được Runtime V3:\n${snapshot.error}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        final runtime = snapshot.data!;
        final visibleQuestions = runtime.visibleQuestions(
          fullMode: _fullMode,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Radar Kiệt Sức'),
            actions: [
              IconButton(
                tooltip: 'Cách đọc chỉ số',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HelpPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.help_outline),
              ),
              IconButton(
                tooltip: 'Lịch sử',
                onPressed: () async {
                  final navigator = Navigator.of(context);

                  await _reloadHistory();

                  if (!mounted) {
                    return;
                  }

                  navigator.push(
                    MaterialPageRoute(
                      builder: (_) => HistoryPage(
                        records: _records,
                        trajectory: _trajectory,
                        onClear: _clearHistory,
                        onSeedDemo: _seedDemoHistory,
                        onExport: _exportHistoryJson,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
              ),
              IconButton(
                tooltip: 'Đặt lại câu trả lời',
                onPressed: () => _reset(runtime),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.icon(
                onPressed: _saving ? null : () => _openResult(runtime),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.analytics_outlined),
                label: Text(
                  _saving ? 'Đang lưu kết quả...' : 'Xem kết quả hôm nay',
                ),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _IntroCard(
                runtime: runtime,
                visibleQuestionCount: visibleQuestions.length,
                fullMode: _fullMode,
                historyCount: _records.length,
                trajectory: _trajectory,
                onModeChanged: (value) {
                  setState(() {
                    _fullMode = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              for (final node in runtime.coreNodes)
                _NodeSection(
                  node: node,
                  questions: visibleQuestions
                      .where((item) => item.node == node.id)
                      .toList(),
                  answers: _answers,
                  onChanged: (id, value) {
                    setState(() {
                      _answers[id] = value;
                    });
                  },
                ),
              const SizedBox(height: 90),
            ],
          ),
        );
      },
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.runtime,
    required this.visibleQuestionCount,
    required this.fullMode,
    required this.historyCount,
    required this.trajectory,
    required this.onModeChanged,
  });

  final AppRuntime runtime;
  final int visibleQuestionCount;
  final bool fullMode;
  final int historyCount;
  final TrajectorySummary trajectory;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final modeText = fullMode
        ? 'Full ${runtime.questions.length} câu'
        : 'Nhanh $visibleQuestionCount câu hôm nay';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Radar Kiệt Sức',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Runtime V3: đọc engine JSON, chấm điểm thật, lưu lịch sử trong máy và đọc xu hướng hồi/suy giảm.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.4,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SoftChip(text: modeText),
                _SoftChip(text: 'Lịch sử $historyCount ngày'),
                _SoftChip(text: 'Observation ${runtime.observationRules.length} rule'),
                _SoftChip(text: 'Node ${runtime.nodeRules.length} rule'),
              ],
            ),
            const SizedBox(height: 12),
            _TrajectoryMiniCard(
              trajectory: trajectory,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Làm full 32 câu'),
              subtitle: const Text(
                'Tắt đi để dùng bài check-in nhanh 8 câu/ngày.',
              ),
              value: fullMode,
              onChanged: onModeChanged,
            ),
            Text(
              'Điểm càng cao nghĩa là rủi ro hao mòn / kiệt sức càng cao. App này không thay thế tư vấn y tế.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrajectoryMiniCard extends StatelessWidget {
  const _TrajectoryMiniCard({
    required this.trajectory,
  });

  final TrajectorySummary trajectory;

  @override
  Widget build(BuildContext context) {
    final title = trajectory.hasEnoughData
        ? 'Xu hướng: ${_trajectoryTitle(trajectory.state)}'
        : 'Xu hướng: chưa đủ dữ liệu';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE7E7EF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            trajectory.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}

class _NodeSection extends StatelessWidget {
  const _NodeSection({
    required this.node,
    required this.questions,
    required this.answers,
    required this.onChanged,
  });

  final CoreNode node;
  final List<QuestionItem> questions;
  final Map<String, double> answers;
  final void Function(String id, double value) onChanged;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          node.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        subtitle: Text('${questions.length} câu'),
        children: [
          const SizedBox(height: 8),
          for (final question in questions)
            _QuestionCard(
              question: question,
              value: answers[question.id] ?? question.defaultValue,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final QuestionItem question;
  final double value;
  final void Function(String id, double value) onChanged;

  @override
  Widget build(BuildContext context) {
    final divisions = (question.max - question.min).round().clamp(1, 20);
    final displayValue = _formatValue(value);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE7E7EF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.displayTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
          ),
          if (question.publicHelp.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              question.publicHelp,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                    height: 1.35,
                  ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                displayValue,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Expanded(
                child: Slider(
                  value: value.clamp(question.min, question.max),
                  min: question.min,
                  max: question.max,
                  divisions: divisions,
                  label: displayValue,
                  onChanged: (newValue) {
                    onChanged(question.id, newValue);
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  question.lowLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ),
              Expanded(
                child: Text(
                  question.highLabel,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  const ResultPage({
    super.key,
    required this.result,
    required this.questionCount,
    required this.records,
    required this.trajectory,
  });

  final RuntimeResult result;
  final int questionCount;
  final List<CheckinRecord> records;
  final TrajectorySummary trajectory;

  @override
  Widget build(BuildContext context) {
    final topNodes = result.nodeResults.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả hôm nay'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ScoreCard(
            result: result,
            questionCount: questionCount,
            historyCount: records.length,
          ),
          const SizedBox(height: 12),
          _TrajectoryDetailCard(
            trajectory: trajectory,
          ),
          const SizedBox(height: 12),
          _SectionTitle(
            title: 'Điểm nghẽn chính',
            subtitle: 'Diễn giải lấy từ meaning_engine.json.',
          ),
          const SizedBox(height: 8),
          for (final node in topNodes)
            _NodeResultCard(
              node: node,
            ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: 'Việc nên làm hôm nay',
            subtitle: 'Khuyến nghị lấy từ recommendation_engine.json.',
          ),
          const SizedBox(height: 8),
          for (final action in result.actions)
            _ActionCard(
              action: action,
            ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Sửa câu trả lời'),
          ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.records,
    required this.trajectory,
    required this.onClear,
    required this.onSeedDemo,
    required this.onExport,
  });

  final List<CheckinRecord> records;
  final TrajectorySummary trajectory;
  final Future<void> Function() onClear;
  final Future<void> Function() onSeedDemo;
  final Future<void> Function() onExport;

  @override
  Widget build(BuildContext context) {
    final reversed = records.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử check-in'),
        actions: [
          IconButton(
            tooltip: 'Xuất dữ liệu JSON',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);

              await onExport();

              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Đã copy lịch sử JSON vào clipboard.'),
                ),
              );
            },
            icon: const Icon(Icons.ios_share),
          ),
          IconButton(
            tooltip: 'Tạo dữ liệu mẫu 3 ngày',
            onPressed: () async {
              final navigator = Navigator.of(context);

              await onSeedDemo();

              navigator.pop();
            },
            icon: const Icon(Icons.auto_fix_high),
          ),
          IconButton(
            tooltip: 'Xóa lịch sử',
            onPressed: () async {
              final navigator = Navigator.of(context);

              await onClear();

              navigator.pop();
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TrajectoryDetailCard(
            trajectory: trajectory,
          ),
          const SizedBox(height: 12),
          _SectionTitle(
            title: 'Các lần check-in',
            subtitle: 'Mỗi ngày lưu một bản. Check-in lại trong ngày sẽ ghi đè bản hôm nay.',
          ),
          const SizedBox(height: 8),
          if (reversed.isEmpty)
            const Card(
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chưa có dữ liệu lịch sử.'),
              ),
            ),
          for (final record in reversed)
            Card(
              elevation: 0,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                title: Text(
                  record.dateIso,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text('${record.questionCount} câu đã dùng'),
                trailing: Text(
                  record.systemScore.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.result,
    required this.questionCount,
    required this.historyCount,
  });

  final RuntimeResult result;
  final int questionCount;
  final int historyCount;

  @override
  Widget build(BuildContext context) {
    final progress = (result.systemScore / 100).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chỉ số hao mòn hôm nay',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  result.systemScore.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Text(
                    '/ 100',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SoftChip(text: 'Mức: ${result.systemLevelText}'),
                _SoftChip(text: '$questionCount câu đã dùng'),
                _SoftChip(text: 'Lịch sử $historyCount ngày'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              result.systemMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrajectoryDetailCard extends StatelessWidget {
  const _TrajectoryDetailCard({
    required this.trajectory,
  });

  final TrajectorySummary trajectory;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xu hướng hệ',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _trajectoryTitle(trajectory.state),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              trajectory.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                    height: 1.35,
                  ),
            ),
            if (trajectory.hasEnoughData) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SoftChip(
                    text: 'Trước ${trajectory.previousScore.toStringAsFixed(1)}',
                  ),
                  _SoftChip(
                    text: 'Nay ${trajectory.currentScore.toStringAsFixed(1)}',
                  ),
                  _SoftChip(
                    text: 'Đổi ${trajectory.delta.toStringAsFixed(1)}',
                  ),
                ],
              ),
              if (trajectory.improvingNodes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Đang tốt lên',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                for (final node in trajectory.improvingNodes.take(3))
                  Text(
                    '${node.name}: ${node.previousScore.toStringAsFixed(1)} → ${node.currentScore.toStringAsFixed(1)}',
                  ),
              ],
              if (trajectory.worseningNodes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Đang xấu đi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                for (final node in trajectory.worseningNodes.take(3))
                  Text(
                    '${node.name}: ${node.previousScore.toStringAsFixed(1)} → ${node.currentScore.toStringAsFixed(1)}',
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _NodeResultCard extends StatelessWidget {
  const _NodeResultCard({
    required this.node,
  });

  final NodeResult node;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    node.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text(
                  node.score.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(width: 8),
                _SoftChip(text: node.levelText),
              ],
            ),
            if (node.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                node.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                      height: 1.35,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.action,
  });

  final RuntimeAction action;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      if (action.durationMinutes > 0) '${action.durationMinutes} phút',
      if (action.effort.isNotEmpty) 'mức ${action.effort}',
      if (action.priority.isNotEmpty) action.priority,
    ].join(' • ');

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.3,
                        ),
                  ),
                  if (action.detail.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      action.detail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                            height: 1.35,
                          ),
                    ),
                  ],
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      meta,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black45,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

String _trajectoryTitle(String state) {
  if (state == 'recovering') {
    return 'Đang hồi phục rõ';
  }

  if (state == 'mild_recovering') {
    return 'Đang hồi nhẹ';
  }

  if (state == 'stable') {
    return 'Tương đối ổn định';
  }

  if (state == 'mild_declining') {
    return 'Đang xấu đi nhẹ';
  }

  if (state == 'declining') {
    return 'Đang suy giảm rõ';
  }

  if (state == 'collapsing') {
    return 'Đang lao dốc';
  }

  return 'Chưa đủ dữ liệu';
}

String _formatValue(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }

  return value.toStringAsFixed(1);
}








class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cách đọc chỉ số'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HelpBlock(
            title: 'Chỉ số hao mòn là gì?',
            body: 'Đây là chỉ số ước lượng mức hao mòn của hệ trong ngày. Điểm càng cao nghĩa là hệ đang bị kéo nhiều hơn bởi tải, thiếu hồi phục, thiếu dự trữ hoặc mất cân bằng nhịp sống.',
          ),
          _HelpBlock(
            title: 'Cách đọc điểm 0–100',
            body: '0–39 là vùng tương đối nhẹ. 40–69 là vùng cần chú ý. 70–100 là vùng căng, nên giảm tải và tăng hồi phục. Đây không phải chẩn đoán bệnh, mà là radar giúp nhận biết xu hướng.',
          ),
          _HelpBlock(
            title: 'Vì sao điểm cao là xấu?',
            body: 'Trong app này, điểm không phải “pin còn lại”, mà là “mức hao mòn”. Điểm cao nghĩa là hệ đang chịu nhiều áp lực hơn khả năng hồi phục.',
          ),
          _HelpBlock(
            title: 'Node là gì?',
            body: 'Node là các trục chính của hệ: nạp, chuyển hóa, dự trữ, tải, phục hồi, thích nghi, hao mòn và mất kiểm soát. Node nào điểm cao hơn thì node đó đang góp phần kéo hệ lệch nhiều hơn.',
          ),
          _HelpBlock(
            title: 'Cách đọc xu hướng',
            body: 'Xu hướng so sánh điểm hôm nay với lần check-in trước. Nếu điểm giảm rõ, hệ đang hồi. Nếu điểm tăng rõ, hệ đang suy giảm. Nếu không đổi nhiều, hệ tạm ổn định.',
          ),
          _HelpBlock(
            title: 'Cách dùng khuyến nghị',
            body: 'Khuyến nghị là việc nhỏ nên làm trong ngày, ưu tiên giảm tải và tăng hồi phục. Không cần làm tất cả. Chọn 1–2 việc dễ làm nhất nhưng làm thật.',
          ),
          _HelpBlock(
            title: 'Giới hạn an toàn',
            body: 'App không thay thế khám bệnh, không thay thế xét nghiệm, không thay thế tư vấn y tế. Nếu có triệu chứng nặng, kéo dài hoặc bất thường, cần gặp bác sĩ hoặc cơ sở y tế.',
          ),
          _HelpBlock(
            title: 'Khi nào không tự xử lý?',
            body: 'Nếu có đau ngực, khó thở, ngất, yếu liệt, lú lẫn, sốt cao kéo dài, chảy máu bất thường, đau dữ dội, ý nghĩ tự hại bản thân hoặc tình trạng xấu nhanh, cần đi viện hoặc gọi cấp cứu.',
          ),
        ],
      ),
    );
  }
}

class _HelpBlock extends StatelessWidget {
  const _HelpBlock({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                height: 1.45,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

