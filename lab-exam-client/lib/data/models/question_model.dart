// ============================================================
// File: lib/data/models/question_model.dart
// Project: Lab Exam Client - Koreliurm Labs
// Author: Pownkumar A (Founder of Koreliurm)
// Created: 2026-05-15
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Dart model mapping GET /question/assigned/{reg_no} response.
//              Decodes visible_examples_json and constraints_json strings.
// ============================================================

import 'dart:convert';
import 'attached_file_model.dart';

class ExampleItem {
  final String input;
  final String output;

  const ExampleItem({required this.input, required this.output});

  factory ExampleItem.fromJson(Map<String, dynamic> j) =>
      ExampleItem(input: j['input'] as String? ?? '', output: j['output'] as String? ?? '');
}

class QuestionModel {
  final int id;
  final int sessionId;
  final String language;
  final String title;
  final String statement;
  final String? starterCode;
  final List<ExampleItem> visibleExamples;
  final List<String> constraints;
  final DateTime? createdAt;
  /// Files attached by faculty — empty when none are attached.
  final List<AttachedFile> attachedFiles;

  const QuestionModel({
    required this.id,
    required this.sessionId,
    required this.language,
    required this.title,
    required this.statement,
    this.starterCode,
    required this.visibleExamples,
    required this.constraints,
    this.createdAt,
    this.attachedFiles = const [],
  });

  factory QuestionModel.fromJson(Map<String, dynamic> j) {
    // Server stores examples/constraints as JSON strings.
    List<ExampleItem> examples = [];
    if (j['visible_examples_json'] != null) {
      final raw = jsonDecode(j['visible_examples_json'] as String) as List;
      examples = raw.map((e) => ExampleItem.fromJson(e as Map<String, dynamic>)).toList();
    }

    List<String> constraints = [];
    if (j['constraints_json'] != null) {
      constraints = List<String>.from(jsonDecode(j['constraints_json'] as String) as List);
    }

    return QuestionModel(
      id: j['id'] as int,
      sessionId: j['session_id'] as int,
      language: j['language'] as String,
      title: j['title'] as String,
      statement: j['statement'] as String,
      starterCode: j['starter_code'] as String?,
      visibleExamples: examples,
      constraints: constraints,
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'] as String) : null,
      attachedFiles: (j['attached_files'] as List<dynamic>? ?? [])
          .map((f) => AttachedFile.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}
