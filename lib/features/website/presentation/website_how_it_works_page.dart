import 'package:flutter/material.dart';
import 'package:citizen_app/features/website/presentation/website_staff_chat_button.dart';

/// A dedicated, plain-language guide to the citizen grievance workflow.
class WebsiteHowItWorksPage extends StatelessWidget {
  const WebsiteHowItWorksPage({super.key});

  static const _steps = <(String, String, IconData, String)>[
    (
      'Tell us what needs attention',
      'Choose a category, describe the public issue, and add a location or photos when useful.',
      Icons.edit_note_rounded,
      '01',
    ),
    (
      'Review and submit your report',
      'Check the details before sending. Suggestions may help organize your report when those services are available.',
      Icons.fact_check_outlined,
      '02',
    ),
    (
      'Follow updates in your account',
      'Sign in to see status information and updates that have been recorded for your report.',
      Icons.track_changes_rounded,
      '03',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FA),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF102C45),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: const Center(
              child: Text(
                'CITIZEN GUIDE     •     HOW SAMADHANAI WORKS',
                style: TextStyle(
                  color: Color(0xFFB7F1DD),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .8,
                ),
              ),
            ),
          ),
          _GuideNavigation(compact: compact),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _GuideHero(compact: compact),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 20 : 40,
                          vertical: compact ? 34 : 54,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1480),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'A clear path from report to follow-up',
                                style: TextStyle(
                                  color: Color(0xFF102C45),
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Use SamadhanAI to submit a public-service concern and keep its available updates together in one place.',
                                style: TextStyle(
                                  color: Color(0xFF43596A),
                                  fontSize: 16,
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: 28),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final stacked = constraints.maxWidth < 900;
                                  final cards = [
                                    for (final step in _steps)
                                      _StepCard(step: step),
                                  ];
                                  return stacked
                                      ? Column(
                                          children: [
                                            for (
                                              var i = 0;
                                              i < cards.length;
                                              i++
                                            ) ...[
                                              cards[i],
                                              if (i < cards.length - 1)
                                                const SizedBox(height: 14),
                                            ],
                                          ],
                                        )
                                      : Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            for (
                                              var i = 0;
                                              i < cards.length;
                                              i++
                                            ) ...[
                                              Expanded(child: cards[i]),
                                              if (i < cards.length - 1)
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                  ),
                                                  child: Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: Color(0xFF078C68),
                                                  ),
                                                ),
                                            ],
                                          ],
                                        );
                                },
                              ),
                              const SizedBox(height: 32),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF4F4),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFD4E5E5),
                                  ),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF075078),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'SamadhanAI displays the report status and service information available in your account. It does not promise an agency response time or automatic delivery to every government department.',
                                        style: TextStyle(
                                          color: Color(0xFF294657),
                                          fontSize: 14,
                                          height: 1.55,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              Wrap(
                                spacing: 14,
                                runSpacing: 12,
                                children: [
                                  FilledButton.icon(
                                    onPressed: () => Navigator.of(
                                      context,
                                    ).pushNamed('/register'),
                                    icon: const Icon(Icons.add_circle_outline),
                                    label: const Text('Report an issue'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF07966B),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 17,
                                      ),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        Navigator.of(context).pushNamed('/'),
                                    icon: const Icon(Icons.arrow_back_rounded),
                                    label: const Text('Back to SamadhanAI'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF102C45),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 17,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  right: 22,
                  bottom: 22,
                  child: WebsiteStaffChatButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideNavigation extends StatelessWidget {
  const _GuideNavigation({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 40, vertical: 17),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1480),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).pushNamed('/'),
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Samadhan',
                      style: TextStyle(
                        color: Color(0xFF102C45),
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: 'AI',
                      style: TextStyle(
                        color: Color(0xFF07966B),
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (!compact)
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/download'),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download App'),
              ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF07966B),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GuideHero extends StatelessWidget {
  const _GuideHero({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 24 : 72,
      vertical: compact ? 48 : 72,
    ),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFE6F5F2), Color(0xFFEEF4FA), Color(0xFFFFF7E9)],
      ),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HOW IT WORKS',
              style: TextStyle(
                color: Color(0xFF078C68),
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              'From your voice\nto a clearer follow-up.',
              style: TextStyle(
                color: const Color(0xFF102C45),
                fontSize: compact ? 38 : 56,
                height: 1.04,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const Text(
                'A simple guide to raising a civic concern, reviewing your report, and checking the updates available to you.',
                style: TextStyle(
                  color: Color(0xFF43596A),
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});
  final (String, String, IconData, String) step;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 230),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDCE5E8)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0B102C45),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F5EF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(step.$3, color: const Color(0xFF078C68), size: 28),
            ),
            const Spacer(),
            Text(
              step.$4,
              style: const TextStyle(
                color: Color(0xFFB3C3CC),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          step.$1,
          style: const TextStyle(
            color: Color(0xFF102C45),
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          step.$2,
          style: const TextStyle(
            color: Color(0xFF43596A),
            fontSize: 15,
            height: 1.55,
          ),
        ),
      ],
    ),
  );
}
