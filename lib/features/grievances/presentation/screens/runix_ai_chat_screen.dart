import 'dart:async';
import 'dart:ui';
import 'package:citizen_app/features/grievances/data/runix_ai_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.agentTitle,
    this.department,
    this.slaHours,
    this.confidenceScore,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? agentTitle;
  final String? department;
  final int? slaHours;
  final double? confidenceScore;
}

class RunixAiChatScreen extends StatefulWidget {
  const RunixAiChatScreen({super.key});

  @override
  State<RunixAiChatScreen> createState() => _RunixAiChatScreenState();
}

class _RunixAiChatScreenState extends State<RunixAiChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _aiService = RunixAiService();

  bool _isTyping = false;
  String _selectedAgent = 'Auto-Detect & Dispatch Agent (Master Router)';

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          'Welcome to RunixGov AI Master Dispatcher! Type any question or'
          ' complaint, and our Master AI Router will automatically classify'
          ' your request and allocate the dedicated department agent.',
      isUser: false,
      timestamp: DateTime.now(),
      agentTitle: 'RunixGov Master Dispatcher Agent',
      department: 'Government AI Routing Core',
    ),
  ];

  final List<String> _agents = [
    'Auto-Detect & Dispatch Agent (Master Router)',
    'PWD Roads & Infrastructure Agent',
    'PHED Water & Pipeline Agent',
    'BSPHCL Power Distribution Agent',
    'PMC Sanitation & Waste Agent',
    'Traffic Management & Safety Agent',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    _scrollToBottom();

    var activeAgentTitle = _selectedAgent;
    String? activeDept;
    int? activeSla;
    double? activeConfidence;

    if (_selectedAgent.startsWith('Auto-Detect')) {
      // Step 1: Master Dispatcher Agent auto-classifies the query
      final classification = await _aiService.classifyGrievance(
        title: text,
        description: text,
      );

      activeAgentTitle = classification.agentTitle;
      activeDept = classification.department;
      activeSla = classification.slaHours;
      activeConfidence = classification.confidenceScore;
    }

    // Step 2: Query the LLM with the allocated agent identity
    final responseText = await _aiService.sendCustomPrompt(
      prompt: text,
      systemPrompt:
          'You are $activeAgentTitle ($activeDept) developed by Runix Tech'
          ' Lab for SamadhanAI. Answer the citizen query accurately.',
    );

    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add(
        ChatMessage(
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
          agentTitle: activeAgentTitle,
          department: activeDept,
          slaHours: activeSla,
          confidenceScore: activeConfidence,
        ),
      );
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        unawaited(
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RunixGov AI Assistant',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Local GGUF LLM Model Active',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF81C784),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Agent Selector Bar (Glass) ──
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F4C81).withValues(alpha: 0.85),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.smart_toy,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Specialized Agent:',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedAgent,
                          dropdownColor: const Color(0xFF0F4C81),
                          isExpanded: true,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          items: _agents.map((agent) {
                            final isAuto = agent.startsWith('Auto-Detect');
                            return DropdownMenuItem(
                              value: agent,
                              child: Row(
                                children: [
                                  Icon(
                                    isAuto
                                        ? Icons.auto_awesome
                                        : Icons.psychology_outlined,
                                    size: 16,
                                    color: isAuto
                                        ? const Color(0xFFFFD54F)
                                        : Colors.white.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      agent,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedAgent = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Chat Messages ──
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg);
              },
            ),
          ),

          // ── Typing Indicator ──
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0F4C81),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$_selectedAgent is thinking...',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

          // ── Input Bar ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isTyping,
                    decoration: InputDecoration(
                      hintText: _isTyping
                          ? 'RunixGov AI is thinking...'
                          : 'Ask RunixGov AI or test custom prompt...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF9CA3AF),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            const BorderSide(color: Color(0xFF0F4C81)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) {
                      if (!_isTyping) {
                        unawaited(_sendMessage());
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  backgroundColor: _isTyping
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF0F4C81),
                  onPressed: _isTyping
                      ? null
                      : () {
                          unawaited(_sendMessage());
                        },
                  child:
                      const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: msg.isUser
            ? _buildUserBubble(msg)
            : _buildAiBubble(msg),
      ),
    );
  }

  Widget _buildUserBubble(ChatMessage msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C81),
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomRight: Radius.zero,
        ),
      ),
      child: Text(
        msg.text,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildAiBubble(ChatMessage msg) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16).copyWith(
        bottomLeft: Radius.zero,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomLeft: Radius.zero,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (msg.agentTitle != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF0F4C81)
                          .withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.smart_toy_rounded,
                            size: 14,
                            color: Color(0xFF0F4C81),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            msg.agentTitle!,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F4C81),
                            ),
                          ),
                        ],
                      ),
                      if (msg.department != null ||
                          msg.slaHours != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          [
                            msg.department ?? 'Core AI',
                            if (msg.slaHours != null)
                              'SLA: ${msg.slaHours}h',
                            if (msg.confidenceScore != null)
                              'Match: ${(msg.confidenceScore! * 100).toInt()}%',
                          ].join(' • '),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A5276),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              Text(
                msg.text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF1A1A2E),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
