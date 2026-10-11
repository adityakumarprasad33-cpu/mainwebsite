import 'package:flutter/material.dart';

/// Floating citizen-help launcher with a paired male/female staff mark.
class WebsiteStaffChatButton extends StatelessWidget {
  const WebsiteStaffChatButton({super.key});

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
              _StaffPortraitPair(size: 42),
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

class _StaffPortraitPair extends StatelessWidget {
  const _StaffPortraitPair({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFFEAF4F2),
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFD4E9E3)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(1.5),
      child: ClipOval(
        child: Image.asset(
          'assets/images/chat_support_staff.jpg',
          width: size,
          height: size,
          fit: BoxFit.cover,
          semanticLabel: 'SamadhanAI support staff answering citizen calls',
          errorBuilder: (context, error, stackTrace) => _StaffGlyphPair(
            size: size,
          ),
        ),
      ),
    ),
  );
}

class _StaffGlyphPair extends StatelessWidget {
  const _StaffGlyphPair({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFEAF4F2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: size * .22,
          backgroundColor: const Color(0xFFE1F0F6),
          child: Icon(
            Icons.man_rounded,
            color: const Color(0xFF075078),
            size: size * .32,
          ),
        ),
        SizedBox(width: size * .015),
        CircleAvatar(
          radius: size * .22,
          backgroundColor: const Color(0xFFFCE9E4),
          child: Icon(
            Icons.woman_rounded,
            color: const Color(0xFFB94F58),
            size: size * .32,
          ),
        ),
      ],
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

  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage.bot(
      'Namaste! Welcome to SamadhanAI help. Choose a question below and I’ll show you a preset answer.',
    ),
  ];

  void _ask(_HelpTopic topic) {
    setState(() {
      _messages
        ..add(_ChatMessage.citizen(topic.question))
        ..add(
          _ChatMessage.bot(
            topic.answer,
            route: topic.route,
            action: topic.action,
          ),
        );
    });
    _scrollToLatest();
  }

  void _sendTypedQuestion() {
    final question = _inputController.text.trim();
    if (question.isEmpty) return;

    _inputController.clear();
    if (_containsPrivateData(question)) {
      setState(() {
        _messages.add(
          const _ChatMessage.bot(
            'Please don’t share personal or confidential details here, including passwords, OTPs, API keys, tokens, phone numbers, email addresses, identity numbers, or private report details. That message was not sent or saved. Ask a general SamadhanAI question instead.',
          ),
        );
      });
      _scrollToLatest();
      return;
    }

    final topic = _findTopic(question);
    setState(() {
      _messages
        ..add(_ChatMessage.citizen(question))
        ..add(
          _ChatMessage.bot(
            topic?.answer ??
                'I can answer general questions about reporting an issue, tracking a report, privacy, app availability, and using SamadhanAI. Try one of the suggested questions below.',
            route: topic?.route,
            action: topic?.action,
          ),
        );
    });
    _scrollToLatest();
  }

  _HelpTopic? _findTopic(String question) {
    final normalized = question
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final paddedQuestion = ' $normalized ';
    final words = normalized.split(' ').toSet();
    const keywords = <List<String>>[
      [
        'what is samadhanai',
        'what is samadhan ai',
        'what is this app',
        'what does samadhanai do',
        'about samadhanai',
      ],
      [
        'password',
        'passwords',
        'passcode',
        'otp',
        'otps',
        'one time code',
        'api key',
        'api keys',
        'token',
        'tokens',
        'credential',
        'credentials',
        'secret',
        'secrets',
      ],
      ['report', 'submit', 'complaint', 'grievance', 'civic issue', 'lodge'],
      ['details', 'photo', 'picture', 'location', 'evidence', 'attach'],
      ['track', 'tracking', 'status', 'progress', 'my report', 'follow up'],
      [
        'department',
        'government',
        'automatically sent',
        'assigned',
        'forwarded',
      ],
      [
        'response time',
        'when will',
        'how long',
        'reply',
        'hear back',
        'status update',
      ],
      [
        'ai',
        'use ai',
        'artificial intelligence',
        'classify',
        'suggest wording',
      ],
      [
        'access my account',
        'access my report',
        'see my data',
        'account lookup',
        'personal data',
      ],
      ['save', 'saved', 'store', 'stored', 'privacy', 'chat history'],
      ['android', 'download app', 'apk', 'android app'],
      ['iphone', 'ios', 'apple app'],
      ['emergency', 'urgent', 'immediate danger'],
      [
        'retrieve my password',
        'staff get my password',
        'staff access credentials',
      ],
    ];
    var bestScore = 0;
    var secondBestScore = 0;
    _HelpTopic? bestTopic;
    for (var i = 0; i < _topics.length; i++) {
      var topicScore = 0;
      for (final keyword in keywords[i]) {
        final isPhrase = keyword.contains(' ');
        final matches = isPhrase
            ? paddedQuestion.contains(' $keyword ')
            : words.contains(keyword);
        if (matches) {
          topicScore += isPhrase
              ? 3 + keyword.split(' ').length
              : keyword.length <= 3
              ? 3
              : 2;
        }
      }
      if (topicScore > bestScore) {
        secondBestScore = bestScore;
        bestScore = topicScore;
        bestTopic = _topics[i];
      } else if (topicScore > secondBestScore) {
        secondBestScore = topicScore;
      }
    }
    if (bestScore < 2 || (bestScore - secondBestScore < 2)) return null;
    return bestTopic;
  }

  bool _containsPrivateData(String text) {
    final patterns = <RegExp>[
      RegExp(r'\b[\w.+-]+@[\w.-]+\.[a-z]{2,}\b', caseSensitive: false),
      RegExp(r'(?:\+?91[\s-]?)?[6-9]\d{9}\b'),
      RegExp(r'\b\d{4}[ -]?\d{4}[ -]?\d{4}\b'),
      RegExp(r'\b(?:my\s+)?password\s*(?:is|:|=)\s*\S+', caseSensitive: false),
      RegExp(
        r'\b(?:otp|one[\s-]?time code|verification code)\s*(?:is|:|=)?\s*\d{4,8}\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(?:api[\s_-]*key|access[\s_-]*token|secret|private[\s_-]*key)\s*(?:is|:|=)\s*[A-Za-z0-9_/+=.-]{8,}',
        caseSensitive: false,
      ),
      RegExp(r'\bAIza[0-9A-Za-z_-]{20,}\b'),
      RegExp(r'\bsk-[0-9A-Za-z_-]{20,}\b'),
    ];
    return patterns.any((pattern) => pattern.hasMatch(text));
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final panelHeight = (media.size.height - media.viewInsets.bottom - 36)
        .clamp(180.0, 700.0)
        .toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SizedBox(
          height: panelHeight,
          child: Column(
            children: [
              _header(),
              _privacyNote(),
              Expanded(child: _conversation()),
              _questionPicker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(16, 13, 10, 13),
    decoration: const BoxDecoration(
      color: Color(0xFFF8FBFA),
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      border: Border(bottom: BorderSide(color: Color(0xFFE4ECE9))),
    ),
    child: Row(
      children: [
        const _StaffPortraitPair(size: 48),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SamadhanAI Help Desk',
                style: TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Preset answers · No AI',
                style: TextStyle(color: Color(0xFF596D7A), fontSize: 13),
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
  );

  Widget _privacyNote() => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(14, 11, 14, 3),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6E8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF0E0BF)),
    ),
    child: const Text(
      'Preset FAQ only. No AI, account lookup, backend messages, or saved chat. Never share passwords, OTPs, API keys, or private report details.',
      style: TextStyle(
        color: Color(0xFF59462A),
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _conversation() => ListView.builder(
    controller: _scrollController,
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    itemCount: _messages.length,
    itemBuilder: (context, index) => _MessageBubble(
      message: _messages[index],
      onAction: _messages[index].route == null
          ? null
          : () {
              Navigator.of(context).pop();
              Navigator.of(widget.pageContext).pushNamed(
                _messages[index].route!,
              );
            },
    ),
  );

  Widget _questionPicker() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 9, 14, 13),
    decoration: const BoxDecoration(
      color: Color(0xFFF8FBFA),
      border: Border(top: BorderSide(color: Color(0xFFE4ECE9))),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lightbulb_outline_rounded,
              size: 16,
              color: _green,
            ),
            const SizedBox(width: 5),
            const Text(
              'Suggested questions',
              style: TextStyle(
                color: _navy,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 39,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _topics.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final topic = _topics[index];
              return ActionChip(
                label: Text(topic.question),
                onPressed: () => _ask(topic),
                labelStyle: const TextStyle(
                  color: _navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                side: const BorderSide(color: Color(0xFFDCE8E3)),
                backgroundColor: Colors.white,
                shape: const StadiumBorder(),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                maxLength: 240,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendTypedQuestion(),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Type a general question…',
                  hintStyle: const TextStyle(
                    color: Color(0xFF72828C),
                    fontSize: 13,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: Color(0xFFDCE8E3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: Color(0xFFDCE8E3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: _green, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            IconButton.filled(
              tooltip: 'Send question',
              onPressed: _sendTypedQuestion,
              style: IconButton.styleFrom(backgroundColor: _green),
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Answers come from preset FAQs. Messages stay in this page and are not saved or sent.',
          style: TextStyle(color: Color(0xFF72828C), fontSize: 10.5),
        ),
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onAction});
  final _ChatMessage message;
  final VoidCallback? onAction;

  static const _navy = Color(0xFF102C45);

  @override
  Widget build(BuildContext context) {
    final isCitizen = message.isCitizen;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isCitizen
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isCitizen) ...[
            const _StaffPortraitPair(size: 29),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isCitizen ? const Color(0xFF087F68) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(15),
                  topRight: const Radius.circular(15),
                  bottomLeft: Radius.circular(isCitizen ? 15 : 4),
                  bottomRight: Radius.circular(isCitizen ? 4 : 15),
                ),
                border: isCitizen
                    ? null
                    : Border.all(color: const Color(0xFFE1EAE6)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080D2D43),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCitizen)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 3),
                      child: Text(
                        'SamadhanAI Staff',
                        style: TextStyle(
                          color: Color(0xFF477365),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isCitizen ? Colors.white : _navy,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  if (onAction != null) ...[
                    const SizedBox(height: 5),
                    TextButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text(message.action!),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isCitizen) ...[
            const SizedBox(width: 7),
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFFE8EEF8),
              child: Icon(Icons.person_rounded, size: 18, color: _navy),
            ),
          ],
        ],
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

class _ChatMessage {
  const _ChatMessage._(
    this.text, {
    required this.isCitizen,
    this.route,
    this.action,
  });

  const _ChatMessage.bot(String text, {String? route, String? action})
    : this._(text, isCitizen: false, route: route, action: action);

  const _ChatMessage.citizen(String text) : this._(text, isCitizen: true);

  final String text;
  final bool isCitizen;
  final String? route;
  final String? action;
}
