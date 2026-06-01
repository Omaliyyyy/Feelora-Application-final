import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = FirestoreService();
  final _auth = AuthService();
  late final Stream<DocumentSnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _db.userStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          // ── Parse Firestore data ──────────────────────────
          int currentDay = 1;
          String? todayMood;
          Map<String, dynamic> todayTasks = {};

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            currentDay = (data['currentDay'] as num?)?.toInt() ?? 1;
            final days = data['days'] as Map<String, dynamic>? ?? {};
            final today = days['$currentDay'] as Map<String, dynamic>? ?? {};
            todayMood = today['mood'] as String?;
            todayTasks =
                today['tasks'] as Map<String, dynamic>? ?? {};
          }

          final completedCount =
              todayTasks.values.where((v) => v == true).length;
          final totalTasks = todayTasks.length;
          final allDone = totalTasks > 0 && completedCount == totalTasks;

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: kCard,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border:
                                          Border.all(color: kBorder),
                                    ),
                                    child: Text(
                                      'Day $currentDay of 21',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: kTextSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Feelora',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: kTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/progress'),
                          icon: const Icon(
                            Icons.bar_chart_rounded,
                            color: kTextSecondary,
                          ),
                          tooltip: 'Progress',
                        ),
                        IconButton(
                          onPressed: () async {
                            await _auth.signOut();
                            if (mounted) {
                              Navigator.pushReplacementNamed(
                                  context, '/login');
                            }
                          },
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: kTextSecondary,
                            size: 22,
                          ),
                          tooltip: 'Sign out',
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Progress bar ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: currentDay / 21,
                        backgroundColor: kBorder,
                        color: kAccent,
                        minHeight: 5,
                      ),
                    ),
                  ),
                ),

                // ── Today status card ────────────────────────
                if (todayMood != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      child: _TodayCard(
                        mood: todayMood,
                        completedCount: completedCount,
                        totalTasks: totalTasks,
                        allDone: allDone,
                        currentDay: currentDay,
                        onContinue: () {
                          final m = getMoodByLabel(todayMood!);
                          if (m != null) {
                            Navigator.pushNamed(context, '/tasks',
                                arguments: {
                                  'mood': m,
                                  'day': currentDay,
                                });
                          }
                        },
                        onNextDay: () => _db.advanceDay(currentDay),
                      ),
                    ),
                  ),

                // ── Section title ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todayMood != null
                              ? 'How are you feeling now?'
                              : 'How are you feeling today?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pick your mood to get your daily tasks.',
                          style: TextStyle(
                              fontSize: 14, color: kTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Mood cards ───────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final mood = kMoods[i];
                        final selected = mood.label == todayMood;
                        return _MoodCard(
                          mood: mood,
                          isSelected: selected,
                          onTap: () async {
                            await _db.setDayMood(currentDay, mood);
                            if (mounted) {
                              Navigator.pushNamed(context, '/tasks',
                                  arguments: {
                                    'mood': mood,
                                    'day': currentDay,
                                  });
                            }
                          },
                        );
                      },
                      childCount: kMoods.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Today Status Card ─────────────────────────────────────────────────────────
class _TodayCard extends StatelessWidget {
  final String mood;
  final int completedCount;
  final int totalTasks;
  final bool allDone;
  final int currentDay;
  final VoidCallback onContinue;
  final VoidCallback onNextDay;

  const _TodayCard({
    required this.mood,
    required this.completedCount,
    required this.totalTasks,
    required this.allDone,
    required this.currentDay,
    required this.onContinue,
    required this.onNextDay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allDone ? kAccent : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: allDone ? kAccent : kBorder,
          width: allDone ? 0 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (allDone ? kAccent : Colors.black).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            getMoodByLabel(mood)?.emoji ?? '😶',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allDone ? '🎉 All done today!' : 'Today: $mood',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: allDone ? Colors.white : kTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  allDone
                      ? 'Ready for Day ${currentDay < 21 ? currentDay + 1 : 1}?'
                      : '$completedCount / $totalTasks tasks done',
                  style: TextStyle(
                    fontSize: 12,
                    color: allDone
                        ? Colors.white.withOpacity(0.85)
                        : kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (allDone)
            _CardButton(
              label: 'Next Day →',
              bg: Colors.white.withOpacity(0.25),
              fg: Colors.white,
              onTap: onNextDay,
            )
          else
            _CardButton(
              label: 'Continue',
              bg: kAccent.withOpacity(0.12),
              fg: kAccent,
              onTap: onContinue,
            ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _CardButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Mood Card ─────────────────────────────────────────────────────────────────
class _MoodCard extends StatelessWidget {
  final MoodData mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodCard({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? mood.lightColor : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? mood.color : kBorder,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: mood.color.withOpacity(0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Row(
              children: [
                // Emoji container
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: mood.lightColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(mood.emoji,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mood.label,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? mood.color : kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        mood.goal,
                        style: const TextStyle(
                          fontSize: 12,
                          color: kTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: isSelected ? 22 : 14,
                  color: isSelected ? mood.color : kTextSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
