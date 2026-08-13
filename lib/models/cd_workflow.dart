enum CdCaseCategory {
  general,
  roadTrafficAccident,
  arms,
  pocso,
  sexualOffence,
}

enum CdWorkflowPhase {
  initial,
  continuation,
  finalisation,
}

enum CdQuestionType {
  yesNo,
  shortText,
  longText,
  time,
  singleChoice,
  multiChoice,
  witnessRepeater,
}

class CdQuestionOption {
  final String value;
  final String labelBn;
  final String labelEn;

  const CdQuestionOption({
    required this.value,
    required this.labelBn,
    required this.labelEn,
  });
}

class CdQuestionDependency {
  final String questionId;
  final String? equalsValue;
  final String? containsValue;

  const CdQuestionDependency.equals({
    required this.questionId,
    required String value,
  })  : equalsValue = value,
        containsValue = null;

  const CdQuestionDependency.contains({
    required this.questionId,
    required String value,
  })  : containsValue = value,
        equalsValue = null;
}

class CdWorkflowQuestion {
  final String id;
  final String group;
  final int order;
  final CdQuestionType type;
  final String titleBn;
  final String titleEn;
  final String hintBn;
  final String hintEn;
  final bool required;
  final List<CdQuestionOption> options;
  final CdQuestionDependency? dependency;

  const CdWorkflowQuestion({
    required this.id,
    required this.group,
    required this.order,
    required this.type,
    required this.titleBn,
    required this.titleEn,
    this.hintBn = '',
    this.hintEn = '',
    this.required = false,
    this.options = const <CdQuestionOption>[],
    this.dependency,
  });
}

class CdWorkflowContext {
  final int cdNumber;
  final CdCaseCategory caseCategory;
  final Set<String> completedActions;
  final Set<String> pendingActions;
  final bool hasVictim;
  final bool hasArrestedAccused;
  final bool hasPcAccused;
  final bool finalisationRequested;

  const CdWorkflowContext({
    required this.cdNumber,
    this.caseCategory = CdCaseCategory.general,
    this.completedActions = const <String>{},
    this.pendingActions = const <String>{},
    this.hasVictim = false,
    this.hasArrestedAccused = false,
    this.hasPcAccused = false,
    this.finalisationRequested = false,
  });

  CdWorkflowPhase get phase {
    if (finalisationRequested) return CdWorkflowPhase.finalisation;
    return cdNumber <= 1
        ? CdWorkflowPhase.initial
        : CdWorkflowPhase.continuation;
  }
}

class CdWorkflowPlan {
  final CdWorkflowPhase phase;
  final CdCaseCategory caseCategory;
  final List<String> recommendedActionIds;
  final List<CdWorkflowQuestion> questions;

  const CdWorkflowPlan({
    required this.phase,
    required this.caseCategory,
    required this.recommendedActionIds,
    required this.questions,
  });
}
