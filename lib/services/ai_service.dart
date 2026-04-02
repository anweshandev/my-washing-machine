import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Manages all AI interactions via Firebase AI (Google AI / Gemini).
class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  static const String _model = 'gemini-2.5-flash';

  // Cache loaded prompts so we don't re-read assets each time
  final Map<String, String> _promptCache = {};

  // Template IDs — set these once you upload prompts to Firebase
  // When set, the service will use templateGenerativeModel instead
  String? washAdvisorTemplateId;
  String? stainHelperTemplateId;
  String? errorExplainerTemplateId;
  String? laundryCopilotTemplateId;
  String? washInsightsTemplateId;

  /// Load a prompt .md file from assets, extracting only the content (skip YAML frontmatter).
  Future<String> _loadPrompt(String name) async {
    if (_promptCache.containsKey(name)) return _promptCache[name]!;
    final raw = await rootBundle.loadString('prompts/$name.md');
    // Strip YAML frontmatter (between --- markers)
    final lines = raw.split('\n');
    int start = 0;
    if (lines.isNotEmpty && lines[0].trim() == '---') {
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim() == '---') {
          start = i + 1;
          break;
        }
      }
    }
    final content = lines.sublist(start).join('\n').trim();
    _promptCache[name] = content;
    return content;
  }

  /// Build prompt content from a template string by replacing {{variable}} placeholders.
  String _fillTemplate(String template, Map<String, String> variables) {
    var result = template;
    for (final entry in variables.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    // Remove any unfilled optional blocks like {{#if ...}}...{{/if}}
    result = result.replaceAll(
      RegExp(r'\{\{#if\s+\w+\}\}.*?\{\{/if\}\}', dotAll: true),
      '',
    );
    return result;
  }

  /// Parse the prompt into system instruction + user message parts.
  List<Content> _parsePromptParts(String filled) {
    final parts = <Content>[];
    final userMatch = RegExp(
      r'\{\{role "user"\}\}\s*(.*?)$',
      dotAll: true,
    ).firstMatch(filled);

    // We'll use system instruction in the model config and user message as content
    if (userMatch != null) {
      parts.add(Content.text(userMatch.group(1)!.trim()));
    }
    return parts;
  }

  /// Extract system instruction from prompt.
  String? _extractSystemInstruction(String filled) {
    final match = RegExp(
      r'\{\{role "system"\}\}\s*(.*?)(?=\{\{role "user"\}\})',
      dotAll: true,
    ).firstMatch(filled);
    return match?.group(1)?.trim();
  }

  /// Core generation method — uses inline prompt with system instruction.
  Future<String?> _generate({
    required String promptName,
    required Map<String, String> variables,
  }) async {
    final template = await _loadPrompt(promptName);
    final filled = _fillTemplate(template, variables);

    final systemInstruction = _extractSystemInstruction(filled);
    final userParts = _parsePromptParts(filled);

    final model = FirebaseAI.googleAI().generativeModel(
      model: _model,
      systemInstruction: systemInstruction != null
          ? Content.system(systemInstruction)
          : null,
    );

    final response = await model.generateContent(userParts);
    return response.text;
  }

  // ─── Public API ───

  /// Get wash program recommendation from a natural language description.
  Future<Map<String, dynamic>?> getWashAdvice(String userMessage) async {
    final text = await _generate(
      promptName: 'wash_advisor',
      variables: {'userMessage': userMessage},
    );
    return _tryParseJson(text);
  }

  /// Get stain removal advice.
  Future<Map<String, dynamic>?> getStainHelp(String userMessage) async {
    final text = await _generate(
      promptName: 'stain_helper',
      variables: {'userMessage': userMessage},
    );
    return _tryParseJson(text);
  }

  /// Get error explanation and troubleshooting.
  Future<Map<String, dynamic>?> explainError({
    required String errorName,
    required int errorCode,
    required String processState,
    String? additionalContext,
  }) async {
    final text = await _generate(
      promptName: 'error_explainer',
      variables: {
        'errorName': errorName,
        'errorCode': errorCode.toString(),
        'processState': processState,
        'additionalContext': ?additionalContext,
      },
    );
    return _tryParseJson(text);
  }

  /// General laundry copilot chat — returns plain text (not JSON).
  Future<String?> chat(String userMessage) async {
    final text = await _generate(
      promptName: 'laundry_copilot',
      variables: {'userMessage': userMessage},
    );
    return text;
  }

  /// Analyze wash history and provide insights.
  Future<Map<String, dynamic>?> getWashInsights({
    required int historyCount,
    required String historyData,
  }) async {
    final text = await _generate(
      promptName: 'wash_insights',
      variables: {
        'historyCount': historyCount.toString(),
        'historyData': historyData,
      },
    );
    return _tryParseJson(text);
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
