import '../models/investigation_action.dart';

class SmartActionDecision {
  final bool needsReason;
  final String message;

  const SmartActionDecision({
    required this.needsReason,
    required this.message,
  });

  const SmartActionDecision.allowed()
      : needsReason = false,
        message = '';
}

/// Offline duplicate/action-frequency rules for investigation work.
///
/// It never blocks an officer permanently. Normally-once actions require a
/// recorded justification when repeated; naturally repeatable actions remain
/// available without warning.
class SmartCaseService {
  static const Set<String> _normallyOnce = {
    'po_visit',
    'sketch_map',
    'index',
    'fir_received',
    'complainant_examined',
  };

  static const Set<String> _repeatable = {
    'witness_statement',
    'raid_search',
    'arrest',
    'seizure',
    'requisition',
    'report_collection',
    'court_forwarding',
    'other',
    'diary_closing',
  };

  SmartActionDecision assessBeforeSave({
    required InvestigationActionEntry proposed,
    required List<InvestigationActionEntry> existing,
  }) {
    final category = categoryFor(proposed.actionType);
    if (_repeatable.contains(category)) {
      return const SmartActionDecision.allowed();
    }

    final previous = existing.where(
      (entry) => categoryFor(entry.actionType) == category,
    );
    if (previous.isEmpty) {
      return const SmartActionDecision.allowed();
    }

    final latest = previous.reduce(
      (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
    );
    final title = displayName(category);
    return SmartActionDecision(
      needsReason: _normallyOnce.contains(category),
      message: '$title এই মামলায় আগে ${latest.actionDate.isEmpty ? 'একবার' : latest.actionDate} তারিখে নথিভুক্ত হয়েছে। পুনরায় করলে কারণ লিখুন।',
    );
  }

  String categoryFor(String actionType) {
    final text = actionType.toLowerCase().trim();
    if (text.contains('po visit') || text.contains('place of occurrence')) {
      return 'po_visit';
    }
    if (text.contains('rough sketch') || text.contains('sketch map')) {
      return 'sketch_map';
    }
    if (text == 'index prepared' || text.contains('index of sketch')) {
      return 'index';
    }
    if (text.contains('complainant') || text.contains('victim examination')) {
      return 'complainant_examined';
    }
    if (text.contains('witness')) return 'witness_statement';
    if (text.contains('raid') || text.contains('search')) return 'raid_search';
    if (text.contains('arrest')) return 'arrest';
    if (text.contains('seizure') || text.contains('recovery')) return 'seizure';
    if (text.contains('requisition') || text.contains('prayer sent')) {
      return 'requisition';
    }
    if (text.contains('report collection')) return 'report_collection';
    if (text.contains('court forwarding')) return 'court_forwarding';
    if (text.contains('closing')) return 'diary_closing';
    if (text.contains('fir')) return 'fir_received';
    return 'other';
  }

  String displayName(String category) {
    switch (category) {
      case 'po_visit':
        return 'PO Visit';
      case 'sketch_map':
        return 'Rough Sketch Map';
      case 'index':
        return 'Index';
      case 'complainant_examined':
        return 'Complainant Examination';
      case 'fir_received':
        return 'FIR receipt';
      default:
        return 'এই investigation action';
    }
  }
}
