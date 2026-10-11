import 'package:flutter/material.dart';

/// Floating citizen-help launcher with a paired male/female staff mark.
class WebsiteStaffChatButton extends StatelessWidget {
  const WebsiteStaffChatButton({super.key});

  static const _navy = Color(0xFF102C45);
  static const _green = Color(0xFF07966B);

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 9,
    shadowColor: const Color(0x330D2D43),
    shape: const CircleBorder(),
    child: InkWell(
      onTap: () => _showHelp(context),
      customBorder: const CircleBorder(),
      child: const Tooltip(
        message: 'Chat with SamadhanAI staff',
        child: SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StaffAvatar(
                    icon: Icons.man_rounded,
                    background: Color(0xFFE1F0F6),
                    foreground: Color(0xFF075078),
                    radius: 15,
                  ),
                  SizedBox(width: 2),
                  _StaffAvatar(
                    icon: Icons.woman_rounded,
                    background: Color(0xFFFCE9E4),
                    foreground: Color(0xFFB94F58),
                    radius: 15,
                  ),
                ],
              ),
              Positioned(
                right: 2,
                bottom: 1,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: _green,
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0x660B2031),
      builder: (_) => _CitizenHelpDialog(pageContext: context),
    );
  }
}

class _StaffAvatar extends StatelessWidget {
  const _StaffAvatar({
    required this.icon,
    required this.background,
    required this.foreground,
    this.radius = 19,
  });
  final IconData icon;
  final Color background;
  final Color foreground;
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: background,
    child: Icon(icon, color: foreground, size: radius * 1.3),
  );
}

class _StaffPortraitPair extends StatelessWidget {
  const _StaffPortraitPair({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _StaffAvatar(
        icon: Icons.man_rounded,
        background: const Color(0xFFE1F0F6),
        foreground: const Color(0xFF075078),
        radius: size * .36,
      ),
      SizedBox(width: size * .025),
      _StaffAvatar(
        icon: Icons.woman_rounded,
        background: const Color(0xFFFCE9E4),
        foreground: const Color(0xFFB94F58),
        radius: size * .36,
      ),
    ],
  );
}

class _HelpAction extends StatelessWidget {
  const _HelpAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 19),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF102C45),
      alignment: Alignment.centerLeft,
      minimumSize: const Size.fromHeight(48),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      side: const BorderSide(color: Color(0xFFDCE5E8)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class _CitizenHelpDialog extends StatefulWidget {
  const _CitizenHelpDialog({required this.pageContext});
  final BuildContext pageContext;

  @override
  State<_CitizenHelpDialog> createState() => _CitizenHelpDialogState();
}

class _CitizenHelpDialogState extends State<_CitizenHelpDialog> {
  static const _navy = Color(0xFF102C45);
  static const _green = Color(0xFF07966B);

  static const _topics = <_HelpTopic>[
    _HelpTopic(
      'What is SamadhanAI?',
      'SamadhanAI is a digital service for submitting civic grievances and viewing the status information available in your account. This website also explains the service and app availability.',
    ),
    _HelpTopic(
      'Should I enter passwords, OTPs, or API keys here?',
      'No. Never share passwords, one-time codes, API keys, access tokens, payment details, or login credentials in this help panel. SamadhanAI staff will not ask you to disclose those secrets here.',
    ),
    _HelpTopic(
      'How do I report a civic issue?',
      'Choose “Report an Issue” or “Report a civic issue” and sign in or create an account. Select a category, describe the issue, and add a location or relevant photos if useful.',
      route: '/register',
      action: 'Report an issue',
    ),
    _HelpTopic(
      'What details should I include?',
      'Add a clear description, the place where the issue is happening, and relevant evidence if you have it. Share only information needed to explain the issue; avoid posting passwords, identity documents, or other private details.',
    ),
    _HelpTopic(
      'How do I track a report?',
      'Sign in and open My Grievances to see status information recorded for your reports. Updates depend on the service and authorized workflow.',
      route: '/login',
      action: 'Sign in to track',
    ),
    _HelpTopic(
      'Are reports automatically sent to government departments?',
      'Not necessarily. Department assignment and delivery depend on the configured services and authorized workflows. SamadhanAI does not promise that every report is automatically sent to a government department.',
    ),
    _HelpTopic(
      'When will I get a response or status update?',
      'The website cannot promise a response time. Check your account for updates that are available. For an urgent issue, contact the responsible local authority directly.',
    ),
    _HelpTopic(
      'Does SamadhanAI use AI?',
      'When the AI service is configured and available, it may help classify a complaint or suggest wording. Review any suggestion yourself. AI output is not an official decision or a guarantee.',
    ),
    _HelpTopic(
      'Can this help chat access my account or report?',
      'No. This is a preset FAQ. It cannot sign in, look up reports, view personal data, or send messages to the application or an AI service.',
    ),
    _HelpTopic(
      'What happens to the questions I select?',
      'The answers are built into this website. Selecting a question stays in your browser; this help panel does not send or save your chat selections.',
    ),
    _HelpTopic(
      'Is the Android app available?',
      'The Download App page shows the current release status. Download links are enabled only when a verified Android release is configured.',
      route: '/download',
      action: 'View app status',
    ),
    _HelpTopic(
      'Is an iPhone app available?',
      'iOS availability has not been verified. Check the Download App page for the current platform status.',
      route: '/download',
      action: 'View app status',
    ),
    _HelpTopic(
      'What should I do in an emergency?',
      'Do not rely on a grievance report for immediate help. Contact your local emergency service or responsible authority directly.',
    ),
    _HelpTopic(
      'Can staff retrieve my password or API credentials?',
      'No. This help panel does not handle credentials or private account data. Use the sign-in page’s account recovery options if you cannot access your account.',
      route: '/login',
      action: 'Open sign in',
    ),
  ];

  _HelpTopic? _openTopic;

  @override
  Widget build(BuildContext context) {
    final panelHeight = (MediaQuery.sizeOf(context).height - 36)
        .clamp(360.0, 670.0)
        .toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SizedBox(
          height: panelHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const _StaffPortraitPair(size: 50),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SamadhanAI Staff',
                            style: TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Citizen help • preset answers',
                            style: TextStyle(
                              color: Color(0xFF596D7A),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close help',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6E8),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFF0E0BF)),
                  ),
                  child: const Text(
                    'Preset FAQ only. No AI, account lookup, backend messages, or saved chat. Never enter passwords, OTPs, API keys, access tokens, or private report details.',
                    style: TextStyle(
                      color: Color(0xFF59462A),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(2, 12, 2, 7),
                  child: Text(
                    'Choose a question',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _topics.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 7),
                    itemBuilder: (context, index) {
                      final topic = _topics[index];
                      final expanded = _openTopic == topic;
                      return Container(
                        decoration: BoxDecoration(
                          color: expanded
                              ? const Color(0xFFF0F7F5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: expanded
                                ? const Color(0xFFB6DDD0)
                                : const Color(0xFFDCE5E8),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(
                            () => _openTopic = expanded ? null : topic,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        topic.question,
                                        style: const TextStyle(
                                          color: _navy,
                                          fontSize: 14,
                                          height: 1.3,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      expanded
                                          ? Icons.remove_rounded
                                          : Icons.add_rounded,
                                      color: _green,
                                    ),
                                  ],
                                ),
                                if (expanded) ...[
                                  const SizedBox(height: 9),
                                  Text(
                                    topic.answer,
                                    style: const TextStyle(
                                      color: Color(0xFF43596A),
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                  if (topic.route != null) ...[
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(
                                            widget.pageContext,
                                          ).pushNamed(topic.route!);
                                        },
                                        icon: const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 17,
                                        ),
                                        label: Text(topic.action!),
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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

class _HelpTopic {
  const _HelpTopic(
    this.question,
    this.answer, {
    this.route,
    this.action,
  });
  final String question;
  final String answer;
  final String? route;
  final String? action;
}
