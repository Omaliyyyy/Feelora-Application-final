import 'package:flutter/material.dart';

// ── Brand Colors ──────────────────────────────────────────────────────────────
const Color kBackground    = Color(0xFFF7FAF8);
const Color kCard          = Color(0xFFEAF4EF);
const Color kAccent        = Color(0xFF7FBF9F);
const Color kTextPrimary   = Color(0xFF2E3A34);
const Color kTextSecondary = Color(0xFF6B7C73);
const Color kBorder        = Color(0xFFD6E2DB);

// ── Data Models ───────────────────────────────────────────────────────────────
class TaskData {
  final String title;
  final String description;
  const TaskData({required this.title, required this.description});
}

class MoodData {
  final String emoji;
  final String label;
  final String goal;
  final Color color;
  final Color lightColor;
  final List<TaskData> tasks;

  const MoodData({
    required this.emoji,
    required this.label,
    required this.goal,
    required this.color,
    required this.lightColor,
    required this.tasks,
  });
}

// ── Mood Definitions ──────────────────────────────────────────────────────────
const List<MoodData> kMoods = [
  MoodData(
    emoji: '🌧️',
    label: 'Very Low',
    goal: 'Stabilize & gently interrupt the spiral',
    color: Color(0xFF5E7E90),
    lightColor: Color(0xFFE5EEF3),
    tasks: [
      TaskData(
        title: 'Bare Minimum Reset',
        description: 'Drink water · wash face · change location (even just another room)',
      ),
      TaskData(
        title: '2-Minute Emotional Dump',
        description: 'Write everything in your head without filtering — no grammar, no structure',
      ),
      TaskData(
        title: 'Body Grounding',
        description: 'Press your feet firmly into the floor for 60 seconds + slow breathing',
      ),
      TaskData(
        title: 'Safe Comfort Input',
        description: 'Watch/revisit something familiar (comfort show, song, or memory)',
      ),
    ],
  ),
  MoodData(
    emoji: '🌫️',
    label: 'Low',
    goal: 'Create small movement & reduce heaviness',
    color: Color(0xFF5A8E76),
    lightColor: Color(0xFFE3EFE9),
    tasks: [
      TaskData(
        title: '5-Minute Rule',
        description: 'Start any task for just 5 minutes — studying, cleaning, anything',
      ),
      TaskData(
        title: 'Light Exposure',
        description: 'Step outside / balcony / window for sunlight + fresh air',
      ),
      TaskData(
        title: 'One Tiny Win',
        description: 'Do 1 simple thing: make your bed, reply to 1 message, organize 1 item',
      ),
      TaskData(
        title: 'Emotional Check-In',
        description: '"What\'s actually bothering me right now?" — name it specifically',
      ),
    ],
  ),
  MoodData(
    emoji: '😐',
    label: 'Neutral',
    goal: 'Add stimulation & spark feeling',
    color: Color(0xFF3D9E7A),
    lightColor: Color(0xFFDFF2EB),
    tasks: [
      TaskData(
        title: 'Change Your Environment',
        description: 'Move to a café, different room, or rearrange your space slightly',
      ),
      TaskData(
        title: 'Curiosity Task',
        description: 'Learn something random (5–10 mins: podcast, reel, article)',
      ),
      TaskData(
        title: 'Low-Effort Social Touch',
        description: 'Send a meme or short message to someone',
      ),
      TaskData(
        title: 'Music Shift',
        description: 'Play a playlist you don\'t usually listen to',
      ),
    ],
  ),
  MoodData(
    emoji: '🌤️',
    label: 'Improving',
    goal: 'Build momentum & reinforce progress',
    color: Color(0xFFB08A3E),
    lightColor: Color(0xFFF5EED8),
    tasks: [
      TaskData(
        title: 'Progress Reflection',
        description: '"What helped me feel a bit better today?"',
      ),
      TaskData(
        title: 'Slight Challenge Task',
        description: 'Do something mildly uncomfortable — workout, studying, initiating a convo',
      ),
      TaskData(
        title: 'Future Anchor',
        description: 'Plan 1 small thing to look forward to (coffee, walk, call)',
      ),
      TaskData(
        title: 'Gratitude × Specific',
        description: 'Write 3 very specific things — not generic like "family"',
      ),
    ],
  ),
  MoodData(
    emoji: '☀️',
    label: 'Good',
    goal: 'Maximize & invest in your future self',
    color: Color(0xFFD4832A),
    lightColor: Color(0xFFFDF0DC),
    tasks: [
      TaskData(
        title: 'High-Energy Task',
        description: 'Do something productive you\'ve been avoiding',
      ),
      TaskData(
        title: 'Connection Upgrade',
        description: 'Call or meet someone instead of texting',
      ),
      TaskData(
        title: 'Capture the Moment',
        description: 'Journal / voice note: "Why do I feel good right now?"',
      ),
      TaskData(
        title: 'Give Back Energy',
        description: 'Help someone, share advice, or uplift a friend',
      ),
    ],
  ),
];

MoodData? getMoodByLabel(String label) {
  try {
    return kMoods.firstWhere((m) => m.label == label);
  } catch (_) {
    return null;
  }
}
