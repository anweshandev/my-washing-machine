import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';

enum AiMessageRole { user, assistant }

class AiMessage {
  final AiMessageRole role;
  final String text;
  final Map<String, dynamic>? structuredData;
  final AiFeature? feature;
  final DateTime timestamp;

  AiMessage({
    required this.role,
    required this.text,
    this.structuredData,
    this.feature,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum AiFeature { washAdvisor, stainHelper, errorExplainer, washInsights, chat }

class AiProvider extends ChangeNotifier {
  final AiService _ai = AiService();

  final List<AiMessage> _messages = [];
  List<AiMessage> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  /// Send a message and get AI response.
  /// [feature] determines which prompt/model is used.
  Future<void> send(
    String userMessage, {
    AiFeature feature = AiFeature.chat,
  }) async {
    _messages.add(
      AiMessage(role: AiMessageRole.user, text: userMessage, feature: feature),
    );
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      switch (feature) {
        case AiFeature.washAdvisor:
          final data = await _ai.getWashAdvice(userMessage);
          _addAssistantMessage(
            data != null
                ? _formatWashAdvice(data)
                : 'Sorry, I couldn\'t generate a recommendation. Please try rephrasing.',
            structuredData: data,
            feature: feature,
          );
          break;

        case AiFeature.stainHelper:
          final data = await _ai.getStainHelp(userMessage);
          _addAssistantMessage(
            data != null
                ? _formatStainHelp(data)
                : 'Sorry, I couldn\'t generate stain advice. Please try again.',
            structuredData: data,
            feature: feature,
          );
          break;

        case AiFeature.errorExplainer:
          // Parse error code from message or use as-is
          final data = await _ai.explainError(
            errorName: userMessage,
            errorCode: 0,
            processState: 'Unknown',
          );
          _addAssistantMessage(
            data != null
                ? _formatErrorExplanation(data)
                : 'Sorry, I couldn\'t analyze this error. Please try again.',
            structuredData: data,
            feature: feature,
          );
          break;

        case AiFeature.washInsights:
          // This is called directly with history data, not from chat
          _addAssistantMessage(
            'Use the insights button on the History tab to analyze your wash patterns.',
            feature: feature,
          );
          break;

        case AiFeature.chat:
          final text = await _ai.chat(userMessage);
          _addAssistantMessage(
            text ?? 'Sorry, I couldn\'t process that. Please try again.',
            feature: feature,
          );
          break;
      }
    } catch (e) {
      _error = e.toString();
      _addAssistantMessage(
        'Something went wrong. Please check your connection and try again.',
        feature: feature,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Explain a specific machine error (called from home screen error banner).
  Future<void> explainMachineError({
    required String errorName,
    required int errorCode,
    required String processState,
  }) async {
    final userMsg =
        'My washing machine shows error: $errorName (code $errorCode) during $processState';
    _messages.add(
      AiMessage(
        role: AiMessageRole.user,
        text: userMsg,
        feature: AiFeature.errorExplainer,
      ),
    );
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _ai.explainError(
        errorName: errorName,
        errorCode: errorCode,
        processState: processState,
      );
      _addAssistantMessage(
        data != null
            ? _formatErrorExplanation(data)
            : 'Sorry, I couldn\'t analyze this error.',
        structuredData: data,
        feature: AiFeature.errorExplainer,
      );
    } catch (e) {
      _error = e.toString();
      _addAssistantMessage(
        'Failed to analyze the error. Please try again.',
        feature: AiFeature.errorExplainer,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Analyze wash history.
  Future<void> analyzeWashHistory(List<Map<String, dynamic>> history) async {
    if (history.isEmpty) {
      _addAssistantMessage(
        'No wash history to analyze yet. Complete a few wash cycles first!',
        feature: AiFeature.washInsights,
      );
      notifyListeners();
      return;
    }

    _messages.add(
      AiMessage(
        role: AiMessageRole.user,
        text: 'Analyze my wash history (${history.length} washes)',
        feature: AiFeature.washInsights,
      ),
    );
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final historyStr = history
          .map((h) {
            return '- ${h['programName']} at ${h['temperature']}°C, ${h['spinSpeed']} RPM';
          })
          .join('\n');

      final data = await _ai.getWashInsights(
        historyCount: history.length,
        historyData: historyStr,
      );
      _addAssistantMessage(
        data != null
            ? _formatWashInsights(data)
            : 'Sorry, I couldn\'t analyze your history.',
        structuredData: data,
        feature: AiFeature.washInsights,
      );
    } catch (e) {
      _error = e.toString();
      _addAssistantMessage(
        'Failed to analyze wash history.',
        feature: AiFeature.washInsights,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  void _addAssistantMessage(
    String text, {
    Map<String, dynamic>? structuredData,
    AiFeature? feature,
  }) {
    _messages.add(
      AiMessage(
        role: AiMessageRole.assistant,
        text: text,
        structuredData: structuredData,
        feature: feature,
      ),
    );
  }

  // ─── Formatters ───

  String _formatWashAdvice(Map<String, dynamic> data) {
    final buf = StringBuffer();
    buf.writeln('🧺 **${data['programName']}**');
    buf.writeln('');
    final temp = data['temperature'];
    buf.writeln('• Temperature: ${temp == 0 ? 'Cold' : '$temp°C'}');
    buf.writeln('• Spin: ${data['spinSpeed']} RPM');
    if (data['preWash'] == true) buf.writeln('• Pre-wash: On');
    if (data['soak'] == true) buf.writeln('• Soak: On');
    if ((data['extraRinse'] ?? 0) > 0) {
      buf.writeln('• Extra rinse: +${data['extraRinse']}');
    }
    if (data['timeSaver'] == true) buf.writeln('• Time saver: On');
    buf.writeln('• Est. time: ~${data['estimatedMinutes']} min');
    buf.writeln('');
    buf.writeln(data['reasoning'] ?? '');
    final tips = data['tips'];
    if (tips is List && tips.isNotEmpty) {
      buf.writeln('');
      buf.writeln('💡 Tips:');
      for (final t in tips) {
        buf.writeln('• $t');
      }
    }
    return buf.toString();
  }

  String _formatStainHelp(Map<String, dynamic> data) {
    final buf = StringBuffer();
    buf.writeln('🔍 Stain type: **${data['stainType']}**');
    buf.writeln('');
    final pretreat = data['pretreatment'];
    if (pretreat is List && pretreat.isNotEmpty) {
      buf.writeln('**Pre-treatment:**');
      for (int i = 0; i < pretreat.length; i++) {
        buf.writeln('${i + 1}. ${pretreat[i]}');
      }
      buf.writeln('');
    }
    buf.writeln('**Wash settings:**');
    buf.writeln('• Program: ${data['programName']}');
    final temp = data['temperature'];
    buf.writeln('• Temperature: ${temp == 0 ? 'Cold' : '$temp°C'}');
    buf.writeln('• Spin: ${data['spinSpeed']} RPM');
    if (data['preWash'] == true) buf.writeln('• Pre-wash: On');
    if (data['soak'] == true) buf.writeln('• Soak: On');
    if ((data['extraRinse'] ?? 0) > 0) {
      buf.writeln('• Extra rinse: +${data['extraRinse']}');
    }
    final warnings = data['warnings'];
    if (warnings is List && warnings.isNotEmpty) {
      buf.writeln('');
      buf.writeln('⚠️ **Warnings:**');
      for (final w in warnings) {
        buf.writeln('• $w');
      }
    }
    buf.writeln('');
    buf.writeln(data['reasoning'] ?? '');
    return buf.toString();
  }

  String _formatErrorExplanation(Map<String, dynamic> data) {
    final buf = StringBuffer();
    final severity = data['severity'] ?? 'unknown';
    final icon = severity == 'high'
        ? '🔴'
        : severity == 'medium'
        ? '🟡'
        : '🟢';
    buf.writeln('$icon **${data['errorName']}** — Severity: $severity');
    buf.writeln('');
    buf.writeln(data['explanation'] ?? '');
    final causes = data['possibleCauses'];
    if (causes is List && causes.isNotEmpty) {
      buf.writeln('');
      buf.writeln('**Possible causes:**');
      for (final c in causes) {
        buf.writeln('• $c');
      }
    }
    final steps = data['troubleshooting'];
    if (steps is List && steps.isNotEmpty) {
      buf.writeln('');
      buf.writeln('**What to try:**');
      for (int i = 0; i < steps.length; i++) {
        buf.writeln('${i + 1}. ${steps[i]}');
      }
    }
    if (data['needsService'] == true) {
      buf.writeln('');
      buf.writeln('🔧 Professional service may be needed.');
    }
    if (data['safeToRetry'] == true) {
      buf.writeln('✅ Safe to retry the wash after addressing the issue.');
    }
    return buf.toString();
  }

  String _formatWashInsights(Map<String, dynamic> data) {
    final buf = StringBuffer();
    buf.writeln('📊 **Wash Habits Analysis**');
    buf.writeln('');
    buf.writeln(data['summary'] ?? '');
    final insights = data['insights'];
    if (insights is List && insights.isNotEmpty) {
      buf.writeln('');
      buf.writeln('**Insights:**');
      for (final i in insights) {
        buf.writeln('• $i');
      }
    }
    final energy = data['energySavingTips'];
    if (energy is List && energy.isNotEmpty) {
      buf.writeln('');
      buf.writeln('⚡ **Energy savings:**');
      for (final e in energy) {
        buf.writeln('• $e');
      }
    }
    final water = data['waterSavingTips'];
    if (water is List && water.isNotEmpty) {
      buf.writeln('');
      buf.writeln('💧 **Water savings:**');
      for (final w in water) {
        buf.writeln('• $w');
      }
    }
    final progs = data['programSuggestions'];
    if (progs is List && progs.isNotEmpty) {
      buf.writeln('');
      buf.writeln('🧺 **Program suggestions:**');
      for (final p in progs) {
        buf.writeln('• $p');
      }
    }
    if (data['maintenanceReminder'] != null) {
      buf.writeln('');
      buf.writeln('🔧 ${data['maintenanceReminder']}');
    }
    return buf.toString();
  }
}
