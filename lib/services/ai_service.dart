import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';

// ignore_for_file: experimental_member_use

/// Manages all AI interactions via Firebase AI template prompts.
class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  // Template IDs (from Firebase prompt manager)
  static const String _washAdvisorTemplate = 'wash-advisor-for-washer';
  static const String _stainHelperTemplate = 'stain-helper-for-washer';
  static const String _errorExplainerTemplate = 'error-template-for-washer';
  static const String _laundryCopilotTemplate = 'laundry-copilot-for-washer';
  static const String _washInsightsTemplate = 'wash-insights-for-washer';

  late final TemplateGenerativeModel _templateModel = FirebaseAI.googleAI()
      .templateGenerativeModel();

  // ─── Public API ───

  /// Get wash program recommendation from a natural language description.
  Future<Map<String, dynamic>?> getWashAdvice(String userMessage) async {
    final response = await _templateModel.generateContent(
      _washAdvisorTemplate,
      inputs: {'userMessage': userMessage},
    );
    return _tryParseJson(response.text);
  }

  /// Get stain removal advice.
  Future<Map<String, dynamic>?> getStainHelp(String userMessage) async {
    final response = await _templateModel.generateContent(
      _stainHelperTemplate,
      inputs: {'userMessage': userMessage},
    );
    return _tryParseJson(response.text);
  }

  /// Get error explanation and troubleshooting.
  Future<Map<String, dynamic>?> explainError({
    required String errorName,
    required int errorCode,
    required String processState,
    String? additionalContext,
  }) async {
    final response = await _templateModel.generateContent(
      _errorExplainerTemplate,
      inputs: {
        'errorName': errorName,
        'errorCode': errorCode.toString(),
        'processState': processState,
        'additionalContext': ?additionalContext,
      },
    );
    return _tryParseJson(response.text);
  }

  /// General laundry copilot chat — returns plain text (not JSON).
  Future<String?> chat(String userMessage) async {
    final response = await _templateModel.generateContent(
      _laundryCopilotTemplate,
      inputs: {'userMessage': userMessage},
    );
    return response.text;
  }

  /// Analyze wash history and provide insights.
  Future<Map<String, dynamic>?> getWashInsights({
    required int historyCount,
    required String historyData,
  }) async {
    final response = await _templateModel.generateContent(
      _washInsightsTemplate,
      inputs: {
        'historyCount': historyCount.toString(),
        'historyData': historyData,
      },
    );
    return _tryParseJson(response.text);
  }

  /// Attempt to parse JSON from AI response, stripping markdown fences if present.
  Map<String, dynamic>? _tryParseJson(String? text) {
    if (text == null) return null;
    var cleaned = text.trim();
    // Strip markdown code fences if the model wrapped them anyway
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
    }
    try {
      return jsonDecode(cleaned.trim()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
