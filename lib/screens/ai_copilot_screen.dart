import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import '../theme/app_theme.dart';

class AiCopilotScreen extends StatefulWidget {
  const AiCopilotScreen({super.key});

  @override
  State<AiCopilotScreen> createState() => _AiCopilotScreenState();
}

class _AiCopilotScreenState extends State<AiCopilotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  AiFeature _activeFeature = AiFeature.chat;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<AiProvider>().send(text, feature: _activeFeature);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();

    // Auto-scroll when new messages arrive
    if (ai.messages.isNotEmpty) _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Copilot'),
        actions: [
          if (ai.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, size: 22),
              tooltip: 'Clear chat',
              onPressed: () => ai.clearMessages(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Feature chips
          _FeatureBar(
            active: _activeFeature,
            onChanged: (f) => setState(() => _activeFeature = f),
          ),

          // Messages
          Expanded(
            child: ai.messages.isEmpty
                ? _EmptyState(
                    feature: _activeFeature,
                    onSuggestion: (text) {
                      _controller.text = text;
                      _send();
                    },
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: ai.messages.length + (ai.isLoading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == ai.messages.length && ai.isLoading) {
                        return _TypingIndicator();
                      }
                      return _MessageBubble(message: ai.messages[i]);
                    },
                  ),
          ),

          // Input bar
          _InputBar(
            controller: _controller,
            isLoading: ai.isLoading,
            onSend: _send,
            hint: _hintForFeature(_activeFeature),
          ),
        ],
      ),
    );
  }

  String _hintForFeature(AiFeature f) {
    switch (f) {
      case AiFeature.washAdvisor:
        return 'Describe your laundry load...';
      case AiFeature.stainHelper:
        return 'Describe the stain...';
      case AiFeature.errorExplainer:
        return 'Describe the error...';
      case AiFeature.washInsights:
        return 'Ask about your wash patterns...';
      case AiFeature.chat:
        return 'Ask me anything about laundry...';
    }
  }
}

// ─── Feature Selector Bar ───
class _FeatureBar extends StatelessWidget {
  final AiFeature active;
  final ValueChanged<AiFeature> onChanged;
  const _FeatureBar({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _chip(context, AiFeature.chat, Icons.chat_bubble_outline, 'Chat'),
          _chip(
            context,
            AiFeature.washAdvisor,
            Icons.auto_awesome,
            'Wash Advisor',
          ),
          _chip(
            context,
            AiFeature.stainHelper,
            Icons.cleaning_services,
            'Stain Help',
          ),
          _chip(
            context,
            AiFeature.errorExplainer,
            Icons.error_outline,
            'Error Help',
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, AiFeature f, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    final isActive = active == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(
          icon,
          size: 18,
          color: isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.6),
        ),
        label: Text(label),
        selected: isActive,
        onSelected: (_) => onChanged(f),
        labelStyle: TextStyle(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive ? cs.primary : cs.onSurface,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ─── Empty State with suggestions ───
class _EmptyState extends StatelessWidget {
  final AiFeature feature;
  final ValueChanged<String> onSuggestion;
  const _EmptyState({required this.feature, required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final suggestions = _suggestionsForFeature(feature);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 56,
              color: cs.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _titleForFeature(feature),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _subtitleForFeature(feature),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.subtextColor(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Try asking:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            ...suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onSuggestion(s),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(color: cs.primary, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleForFeature(AiFeature f) {
    switch (f) {
      case AiFeature.washAdvisor:
        return 'Wash Advisor';
      case AiFeature.stainHelper:
        return 'Stain Expert';
      case AiFeature.errorExplainer:
        return 'Error Diagnostics';
      case AiFeature.washInsights:
        return 'Wash Insights';
      case AiFeature.chat:
        return 'LaundryIQ Copilot';
    }
  }

  String _subtitleForFeature(AiFeature f) {
    switch (f) {
      case AiFeature.washAdvisor:
        return 'Describe your laundry and I\'ll recommend the perfect program, temperature, and spin speed.';
      case AiFeature.stainHelper:
        return 'Tell me about a stain and I\'ll give you step-by-step removal advice with ideal wash settings.';
      case AiFeature.errorExplainer:
        return 'Describe a machine error and I\'ll explain what happened and how to fix it.';
      case AiFeature.washInsights:
        return 'I\'ll analyze your wash history and suggest ways to save energy and get better results.';
      case AiFeature.chat:
        return 'Your AI laundry assistant. Ask me anything about fabrics, detergents, sorting, or machine care.';
    }
  }

  List<String> _suggestionsForFeature(AiFeature f) {
    switch (f) {
      case AiFeature.washAdvisor:
        return [
          'I have a heavy load of jeans, shirts, and underwear',
          'Delicate silk blouse with a wool sweater',
          'Baby clothes that need sanitizing',
          'Bedsheets and pillow covers, lightly soiled',
        ];
      case AiFeature.stainHelper:
        return [
          'Red wine stain on a white cotton shirt',
          'Grease stain on my jeans from cooking',
          'Grass stains on my kid\'s school uniform',
          'Coffee spill on a polyester dress',
        ];
      case AiFeature.errorExplainer:
        return [
          'Door locked error during spin cycle',
          'No water error when starting a wash',
          'High unbalanced load during final spin',
          'Drain pump error mid-cycle',
        ];
      case AiFeature.washInsights:
        return ['Analyze my recent wash history'];
      case AiFeature.chat:
        return [
          'How often should I run tub clean?',
          'What temperature kills bacteria?',
          'How to wash a down jacket?',
          'Tips for reducing wrinkles',
        ];
    }
  }
}

// ─── Message Bubble ───
class _MessageBubble extends StatelessWidget {
  final AiMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = message.role == AiMessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser &&
                message.feature != null &&
                message.feature != AiFeature.chat)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  _featureLabel(message.feature!),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isUser
                        ? cs.onPrimary.withValues(alpha: 0.7)
                        : cs.primary,
                  ),
                ),
              ),
            SelectableText(
              message.text,
              style: TextStyle(
                color: isUser ? cs.onPrimary : cs.onSurface,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            // "Apply" button for wash advisor recommendations
            if (!isUser &&
                message.structuredData != null &&
                message.feature == AiFeature.washAdvisor)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _applyRecommendation(context, message.structuredData!),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Apply Settings'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(
                        color: cs.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _featureLabel(AiFeature f) {
    switch (f) {
      case AiFeature.washAdvisor:
        return 'WASH ADVISOR';
      case AiFeature.stainHelper:
        return 'STAIN EXPERT';
      case AiFeature.errorExplainer:
        return 'ERROR DIAGNOSTICS';
      case AiFeature.washInsights:
        return 'WASH INSIGHTS';
      case AiFeature.chat:
        return '';
    }
  }

  void _applyRecommendation(BuildContext context, Map<String, dynamic> data) {
    // Navigate to home tab and apply the recommended settings
    Navigator.of(context).pop(data);
  }
}

// ─── Typing Indicator ───
class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Thinking...',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Input Bar ───
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final String hint;
  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isLoading ? null : onSend,
            icon: const Icon(Icons.send, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              disabledBackgroundColor: cs.primary.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
