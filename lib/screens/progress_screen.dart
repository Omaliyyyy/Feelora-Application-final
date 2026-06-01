import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import '../services/firestore_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _db = FirestoreService();
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
          int currentDay = 1;
          Map<String, dynamic> days = {};

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            currentDay = (data['currentDay'] as num?)?.toInt() ?? 1;
            days = data['days'] as Map<String, dynamic>? ?? {};
          }

          // Build mood history (newest first)
          final history = <Map<String, dynamic>>[];
          for (int i = 21; i >= 1; i--) {
            final d = days['$i'] as Map<String, dynamic>?;
            if (d != null && d['mood'] != null) {
              final tasks = d['tasks'] as Map<String, dynamic>? ?? {};
              history.add({
                'day': i,
                'mood': d['mood'] as String,
                'tasks': tasks,
                'date': d['date'] as String? ?? '',
              });
            }
          }

          final daysLogged = history.length;
          final daysLeft = (21 - currentDay).clamp(0, 21);

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: kTextPrimary,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Your Journey',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Stats row ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      children: [
                        _Stat(
                          value: '$currentDay',
                          label: 'Current Day',
                          icon: Icons.today_rounded,
                          color: kAccent,
                        ),
                        const SizedBox(width: 12),
                        _Stat(
                          value: '$daysLogged',
                          label: 'Moods Logged',
                          icon: Icons.mood_rounded,
                          color: const Color(0xFFB08A3E),
                        ),
                        const SizedBox(width: 12),
                        _Stat(
                          value: '$daysLeft',
                          label: 'Days Left',
                          icon: Icons.flag_outlined,
                          color: const Color(0xFF5E7E90),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 21-day grid ──────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 28, 24, 12),
                    child: Text(
                      '21-Day Progress',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: kTextPrimary,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kBorder),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: 21,
                        itemBuilder: (context, index) {
                          final n = index + 1;
                          final d = days['$n'] as Map<String, dynamic>?;
                          final hasMood = d?['mood'] != null;
                          final tasks =
                              d?['tasks'] as Map<String, dynamic>? ?? {};
                          final allDone = tasks.isNotEmpty &&
                              tasks.values.every((v) => v == true);
                          final isToday = n == currentDay;

                          Color bg;
                          Color fg;

                          if (allDone) {
                            bg = kAccent;
                            fg = Colors.white;
                          } else if (hasMood) {
                            bg = kAccent.withOpacity(0.28);
                            fg = kAccent;
                          } else if (isToday) {
                            bg = kCard;
                            fg = kTextPrimary;
                          } else {
                            bg = kBorder.withOpacity(0.5);
                            fg = kTextSecondary;
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(10),
                              border: isToday && !allDone
                                  ? Border.all(
                                      color: kAccent, width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: allDone
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 14)
                                  : Text(
                                      '$n',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: fg,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // ── Legend ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Row(
                      children: [
                        _LegendDot(color: kAccent, label: 'All done'),
                        const SizedBox(width: 14),
                        _LegendDot(
                            color: kAccent.withOpacity(0.28),
                            label: 'Mood logged'),
                        const SizedBox(width: 14),
                        _LegendDot(color: kCard, label: 'Today'),
                      ],
                    ),
                  ),
                ),

                // ── Mood history ─────────────────────────────
                if (history.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 28, 24, 12),
                      child: Text(
                        'Mood History',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final entry = history[i];
                          final moodLabel = entry['mood'] as String;
                          final moodData = getMoodByLabel(moodLabel);
                          final tasks =
                              entry['tasks'] as Map<String, dynamic>;
                          final done = tasks.values
                              .where((v) => v == true)
                              .length;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(16),
                                border:
                                    Border.all(color: kBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: moodData?.lightColor ??
                                          kCard,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        moodData?.emoji ?? '😶',
                                        style: const TextStyle(
                                            fontSize: 20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          moodLabel,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: kTextPrimary,
                                          ),
                                        ),
                                        Text(
                                          '$done / ${tasks.length} tasks done',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: kTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4),
                                        decoration: BoxDecoration(
                                          color: kCard,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  10),
                                        ),
                                        child: Text(
                                          'Day ${entry['day']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: kTextSecondary,
                                          ),
                                        ),
                                      ),
                                      if ((entry['date'] as String)
                                          .isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 3),
                                          child: Text(
                                            entry['date'] as String,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: kTextSecondary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: history.length,
                      ),
                    ),
                  ),
                ] else
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: kTextSecondary)),
      ],
    );
  }
}
