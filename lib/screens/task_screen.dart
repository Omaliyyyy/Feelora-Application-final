import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import '../services/firestore_service.dart';

class TaskScreen extends StatefulWidget {
  final MoodData moodData;
  final int currentDay;

  const TaskScreen({
    super.key,
    required this.moodData,
    required this.currentDay,
  });

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final _db = FirestoreService();
  late final Stream<DocumentSnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _db.userStream();
  }

  @override
  Widget build(BuildContext context) {
    final mood = widget.moodData;

    return Scaffold(
      backgroundColor: kBackground,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          // ── Parse task states ────────────────────────────
          final taskStates = {for (var t in mood.tasks) t.title: false};

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final days = data['days'] as Map<String, dynamic>? ?? {};
            final today =
                days['${widget.currentDay}'] as Map<String, dynamic>? ?? {};
            final storedMood = today['mood'] as String?;
            final stored =
                today['tasks'] as Map<String, dynamic>? ?? {};

            if (storedMood == mood.label) {
              for (final t in mood.tasks) {
                taskStates[t.title] = stored[t.title] == true;
              }
            }
          }

          final completed = taskStates.values.where((v) => v).length;
          final total = mood.tasks.length;
          final allDone = completed == total;

          return SafeArea(
            child: Column(
              children: [
                // ── App bar ──────────────────────────────────
                _AppBar(mood: mood, currentDay: widget.currentDay),

                // ── Mood header ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: mood.lightColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(mood.emoji,
                                  style: const TextStyle(fontSize: 28)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mood.label,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: mood.color,
                                ),
                              ),
                              Text(
                                '$completed of $total completed',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: kTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        mood.goal,
                        style: const TextStyle(
                          fontSize: 14,
                          color: kTextSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: total > 0 ? completed / total : 0,
                          backgroundColor: kBorder,
                          color: mood.color,
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Task list ────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    itemCount: mood.tasks.length,
                    itemBuilder: (context, i) {
                      final task = mood.tasks[i];
                      final done = taskStates[task.title] ?? false;
                      return _TaskCard(
                        task: task,
                        isDone: done,
                        moodColor: mood.color,
                        lightColor: mood.lightColor,
                        onToggle: () => _db.toggleTask(
                          widget.currentDay,
                          task.title,
                          !done,
                        ),
                      );
                    },
                  ),
                ),

                // ── Bottom action bar ────────────────────────
                _BottomBar(
                  completed: completed,
                  total: total,
                  allDone: allDone,
                  currentDay: widget.currentDay,
                  moodColor: mood.color,
                  lightColor: mood.lightColor,
                  onBack: () => Navigator.pop(context),
                  onNextDay: () async {
                    await _db.advanceDay(widget.currentDay);
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final MoodData mood;
  final int currentDay;
  const _AppBar({required this.mood, required this.currentDay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: kTextPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBorder),
            ),
            child: Text(
              'Day $currentDay',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task Card ─────────────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final TaskData task;
  final bool isDone;
  final Color moodColor;
  final Color lightColor;
  final VoidCallback onToggle;

  const _TaskCard({
    required this.task,
    required this.isDone,
    required this.moodColor,
    required this.lightColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDone ? lightColor : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDone ? moodColor : kBorder,
                width: isDone ? 1.5 : 1,
              ),
              boxShadow: isDone
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(top: 2),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isDone ? moodColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? moodColor : kBorder,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDone ? moodColor : kTextPrimary,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: moodColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDone
                              ? moodColor.withOpacity(0.65)
                              : kTextSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
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

// ── Bottom Action Bar ─────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int completed;
  final int total;
  final bool allDone;
  final int currentDay;
  final Color moodColor;
  final Color lightColor;
  final VoidCallback onBack;
  final VoidCallback onNextDay;

  const _BottomBar({
    required this.completed,
    required this.total,
    required this.allDone,
    required this.currentDay,
    required this.moodColor,
    required this.lightColor,
    required this.onBack,
    required this.onNextDay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
      decoration: BoxDecoration(
        color: kBackground,
        border: Border(top: BorderSide(color: kBorder, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Partial progress feedback ────────────────
          if (completed > 0 && !allDone)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F5EC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBEE0CF)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      "You're improving — keep going!",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kAccent.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── All done banner ──────────────────────────
          if (allDone)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: moodColor.withOpacity(0.35)),
              ),
              child: Column(
                children: [
                  Text(
                    '🎉 All tasks completed!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: moodColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Amazing work today. Want to check in again?',
                    style: TextStyle(
                      fontSize: 13,
                      color: moodColor.withOpacity(0.75),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // ── Primary action button ────────────────────
          if (allDone) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNextDay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  currentDay < 21
                      ? 'Start Day ${currentDay + 1} →'
                      : '🌿 Complete Journey',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onBack,
                child: const Text(
                  'Check mood again',
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 17),
                label: const Text('Back to Moods'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kTextSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: kBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
