import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/form_notice.dart';
import '../models/officer_profile.dart';
import '../models/structured_bnss_form.dart';
import '../services/structured_bnss_forms_service.dart';
import 'investigo_ui.dart';

class StructuredBnssFormPanel extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;
  final FormNotice form;
  final void Function(StructuredBnssFormState state, String renderedBody) onChanged;

  const StructuredBnssFormPanel({
    super.key,
    required this.profile,
    required this.caseFile,
    required this.form,
    required this.onChanged,
  });

  @override
  State<StructuredBnssFormPanel> createState() => _StructuredBnssFormPanelState();
}

class _StructuredBnssFormPanelState extends State<StructuredBnssFormPanel> {
  final StructuredBnssFormsService _service = StructuredBnssFormsService();
  late StructuredFormSchema _schema;
  late StructuredBnssFormState _state;
  late bool _legacyBodyNeedsMigration;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<Map<String, TextEditingController>>> _rowControllers = {};
  int _simpleStepIndex = 0;

  bool get _bn => widget.form.templateId.endsWith('__bn');
  String _l(String en, String bn) => _bn ? bn : en;

  @override
  void initState() {
    super.initState();
    _schema = _service.schemaFor(widget.form.templateId);
    _legacyBodyNeedsMigration = widget.form.workflowData.isEmpty && widget.form.body.trim().isNotEmpty;
    _state = _service.initialState(
      templateId: widget.form.templateId,
      officer: widget.profile,
      caseFile: widget.caseFile,
      existing: widget.form.workflowData,
    );
    _buildControllers();
    if (!_legacyBodyNeedsMigration) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final rows in _rowControllers.values) {
      for (final row in rows) {
        for (final c in row.values) {
          c.dispose();
        }
      }
    }
    super.dispose();
  }

  void _buildControllers() {
    for (final field in _schema.fields) {
      if ([StructuredFormFieldType.choice, StructuredFormFieldType.yesNo, StructuredFormFieldType.checklist].contains(field.type)) continue;
      _controllers[field.key] = TextEditingController(text: _state.values[field.key] ?? '');
    }
    for (final group in _schema.rowGroups) {
      final dataRows = _state.rows[group.key] ?? const [];
      _rowControllers[group.key] = dataRows.map((data) {
        return {
          for (final column in group.columns)
            column.key: TextEditingController(text: data[column.key] ?? ''),
        };
      }).toList();
    }
  }

  StructuredBnssFormState _snapshot() {
    final values = Map<String, String>.from(_state.values);
    for (final entry in _controllers.entries) {
      values[entry.key] = entry.value.text.trim();
    }
    final rows = <String, List<Map<String, String>>>{};
    for (final group in _schema.rowGroups) {
      rows[group.key] = (_rowControllers[group.key] ?? const []).map((row) {
        return {
          for (final entry in row.entries) entry.key: entry.value.text.trim(),
        };
      }).toList();
    }
    return StructuredBnssFormState(
      values: values,
      checks: {for (final e in _state.checks.entries) e.key: List<String>.from(e.value)},
      rows: rows,
    );
  }

  void _emit() {
    _state = _snapshot();
    final body = _service.renderBody(
      templateId: widget.form.templateId,
      officer: widget.profile,
      caseFile: widget.caseFile,
      state: _state,
    );
    widget.onChanged(_state, body);
  }

  Future<void> _pickDate(String key) async {
    final current = DateTime.tryParse(_controllers[key]?.text ?? '') ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    _controllers[key]?.text = date.toIso8601String().split('T').first;
    setState(() {});
    _emit();
  }

  Future<void> _pickTime(String key) async {
    final raw = _controllers[key]?.text ?? '';
    final parts = raw.split(':');
    final initial = parts.length >= 2
        ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0)
        : TimeOfDay.now();
    final time = await showTimePicker(context: context, initialTime: initial);
    if (time == null) return;
    _controllers[key]?.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    setState(() {});
    _emit();
  }

  void _addRow(StructuredFormRowGroupSpec group) {
    final rows = _rowControllers[group.key] ??= [];
    if (rows.length >= group.maxRows) return;
    setState(() {
      rows.add({for (final c in group.columns) c.key: TextEditingController()});
    });
    _emit();
  }

  void _removeRow(StructuredFormRowGroupSpec group, int index) {
    final rows = _rowControllers[group.key] ?? [];
    if (rows.length <= group.minRows) return;
    setState(() {
      final removed = rows.removeAt(index);
      for (final c in removed.values) {
        c.dispose();
      }
    });
    _emit();
  }

  Widget _field(StructuredFormFieldSpec field) {
    final label = '${_l(field.labelEn, field.labelBn)}${field.required ? ' *' : ''}';
    final helper = _l(field.helperEn, field.helperBn);
    switch (field.type) {
      case StructuredFormFieldType.date:
      case StructuredFormFieldType.time:
        final controller = _controllers.putIfAbsent(field.key, () => TextEditingController(text: _state.values[field.key] ?? ''));
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: controller,
            readOnly: true,
            onTap: () => field.type == StructuredFormFieldType.date ? _pickDate(field.key) : _pickTime(field.key),
            decoration: InputDecoration(
              labelText: label,
              helperText: helper.isEmpty ? null : helper,
              border: const OutlineInputBorder(),
              suffixIcon: Icon(field.type == StructuredFormFieldType.date ? Icons.calendar_today : Icons.schedule),
            ),
          ),
        );
      case StructuredFormFieldType.choice:
        final current = _state.values[field.key];
        final valid = field.options.any((e) => e.value == current) ? current : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DropdownButtonFormField<String>(
            value: valid,
            decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
            items: field.options.map((option) => DropdownMenuItem(value: option.value, child: Text(_l(option.labelEn, option.labelBn)))).toList(),
            onChanged: (value) {
              setState(() {
                final map = Map<String, String>.from(_state.values);
                map[field.key] = value ?? '';
                _state = _state.copyWith(values: map);
              });
              _emit();
            },
          ),
        );
      case StructuredFormFieldType.yesNo:
        final current = _state.values[field.key];
        void setValue(String value) {
          setState(() {
            final map = Map<String, String>.from(_state.values);
            map[field.key] = value;
            _state = _state.copyWith(values: map);
          });
          _emit();
        }
        Widget option(String value, String text, IconData icon) {
          final selected = current == value;
          return Expanded(
            child: SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => setValue(value),
                icon: Icon(icon),
                label: Text(text),
                style: OutlinedButton.styleFrom(
                  backgroundColor: selected ? InvestigoUi.primary : Colors.white,
                  foregroundColor: selected ? Colors.white : InvestigoUi.text,
                  side: BorderSide(color: selected ? InvestigoUi.primary : const Color(0xFFDDE3EF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              if (helper.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(helper, style: const TextStyle(color: InvestigoUi.muted)),
              ],
              const SizedBox(height: 10),
              Row(children: [
                option('Yes', _l('Yes', 'হ্যাঁ'), Icons.check_rounded),
                const SizedBox(width: 10),
                option('No', _l('No', 'না'), Icons.close_rounded),
              ]),
            ],
          ),
        );
      case StructuredFormFieldType.checklist:
        final selected = Set<String>.from(_state.checks[field.key] ?? const []);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                ...field.options.map((option) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: selected.contains(option.value),
                      title: Text(_l(option.labelEn, option.labelBn)),
                      onChanged: (checked) {
                        setState(() {
                          final next = Set<String>.from(_state.checks[field.key] ?? const []);
                          if (checked == true) {
                            next.add(option.value);
                          } else {
                            next.remove(option.value);
                          }
                          final checks = {for (final e in _state.checks.entries) e.key: List<String>.from(e.value)};
                          checks[field.key] = next.toList();
                          _state = _state.copyWith(checks: checks);
                        });
                        _emit();
                      },
                    )),
              ],
            ),
          ),
        );
      case StructuredFormFieldType.text:
      case StructuredFormFieldType.multiline:
        final controller = _controllers.putIfAbsent(field.key, () => TextEditingController(text: _state.values[field.key] ?? ''));
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: controller,
            maxLines: field.maxLines,
            onChanged: (_) => _emit(),
            decoration: InputDecoration(
              labelText: label,
              helperText: helper.isEmpty ? null : helper,
              alignLabelWithHint: field.maxLines > 1,
              border: const OutlineInputBorder(),
            ),
          ),
        );
    }
  }

  Widget _rowGroup(StructuredFormRowGroupSpec group) {
    final rows = _rowControllers[group.key] ?? const [];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(_l(group.titleEn, group.titleBn), style: const TextStyle(fontWeight: FontWeight.w800))),
                FilledButton.icon(
                  onPressed: rows.length >= group.maxRows ? null : () => _addRow(group),
                  icon: const Icon(Icons.add),
                  label: Text(_l('Add row', 'সারি যোগ করুন')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...rows.asMap().entries.map((entry) {
              final row = entry.value;
              return Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(.35),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: Text('${_l('Row', 'সারি')} ${entry.key + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                        IconButton(
                          onPressed: rows.length <= group.minRows ? null : () => _removeRow(group, entry.key),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ]),
                      ...group.columns.map((column) {
                        final controller = row[column.key]!;
                        final label = '${_l(column.labelEn, column.labelBn)}${column.required ? ' *' : ''}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextField(
                            controller: controller,
                            maxLines: column.maxLines,
                            onChanged: (_) => _emit(),
                            decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errors = _service.validate(widget.form.templateId, _snapshot());
    final stepCount = _schema.fields.length + _schema.rowGroups.length;
    final safeTotal = stepCount == 0 ? 1 : stepCount;
    final safeIndex = _simpleStepIndex.clamp(0, safeTotal - 1).toInt();
    final field = safeIndex < _schema.fields.length
        ? _schema.fields[safeIndex]
        : null;
    final groupIndex = safeIndex - _schema.fields.length;
    final group = field == null &&
            groupIndex >= 0 &&
            groupIndex < _schema.rowGroups.length
        ? _schema.rowGroups[groupIndex]
        : null;

    return Container(
      decoration: InvestigoUi.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InvestigoProgressHeader(
            title: _l('Fill the form step by step', 'এক ধাপ করে ফর্ম পূরণ করুন'),
            subtitle: _l(
              'Only the current question is shown.',
              'এখন শুধু এই তথ্যটিই দিন।',
            ),
            current: safeIndex + 1,
            total: safeTotal,
          ),
          if (_legacyBodyNeedsMigration) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6E5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _l('Old form data found', 'আগের ফর্মের ডাটা পাওয়া গেছে'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(_l(
                    'Review it first. It will not be overwritten automatically.',
                    'না দেখে পুরনো লেখা মুছে যাবে না। আগে দেখে নিন।',
                  )),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _legacyBodyNeedsMigration = false);
                      _emit();
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: Text(_l('Start simple editing', 'সহজভাবে পূরণ শুরু করুন')),
                  ),
                ],
              ),
            ),
          ],
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _l(
                '${errors.length} required item(s) are still incomplete.',
                'এখনও ${errors.length}টি প্রয়োজনীয় তথ্য বাকি আছে।',
              ),
              style: const TextStyle(
                color: InvestigoUi.warning,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (field != null) _field(field),
          if (group != null) _rowGroup(group),
          if (field == null && group == null)
            Text(_l('No structured question for this form.', 'এই ফর্মে অতিরিক্ত প্রশ্ন নেই।')),
          const SizedBox(height: 8),
          Row(
            children: [
              if (safeIndex > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _simpleStepIndex = safeIndex - 1),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(_l('Back', 'আগের')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: safeIndex >= safeTotal - 1
                      ? () {
                          _emit();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_l(
                                'Form facts updated. Preview and Final Save when ready.',
                                'তথ্য আপডেট হয়েছে। এবার Preview দেখে Final Save করুন।',
                              )),
                            ),
                          );
                        }
                      : () => setState(() => _simpleStepIndex = safeIndex + 1),
                  icon: Icon(safeIndex >= safeTotal - 1
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded),
                  label: Text(safeIndex >= safeTotal - 1
                      ? _l('Done', 'শেষ')
                      : _l('Next', 'পরবর্তী')),
                  style: InvestigoUi.primaryButtonStyle(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
