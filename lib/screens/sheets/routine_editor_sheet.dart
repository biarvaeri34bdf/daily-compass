import 'package:flutter/material.dart';

import '../../assets.dart';
import '../../game/models.dart';
import '../../theme.dart';

/// Edit the steps of one routine. Returns the edited list on SAVE, null on
/// dismiss.
class RoutineEditorSheet extends StatefulWidget {
  const RoutineEditorSheet({
    super.key,
    required this.routine,
    required this.loadFailed,
    required this.onRestoreDefaults,
  });

  final Routine routine;
  final bool loadFailed;
  final List<RoutineStep> Function() onRestoreDefaults;

  @override
  State<RoutineEditorSheet> createState() => _RoutineEditorSheetState();
}

class _RoutineEditorSheetState extends State<RoutineEditorSheet> {
  List<RoutineStep> _steps = <RoutineStep>[];
  List<TextEditingController> _controllers = <TextEditingController>[];
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _failed = widget.loadFailed;
    _adopt(List<RoutineStep>.of(widget.routine.steps));
  }

  void _adopt(List<RoutineStep> steps) {
    for (final c in _controllers) {
      c.dispose();
    }
    _steps = steps;
    _controllers = _steps
        .map((s) => TextEditingController(text: s.title))
        .toList(growable: true);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addStep() {
    setState(() {
      _steps.add(
        RoutineStep(
          id: 's${DateTime.now().microsecondsSinceEpoch}',
          title: '',
          category: StepCategory.mind,
        ),
      );
      _controllers.add(TextEditingController());
    });
  }

  void _removeAt(int index) {
    setState(() {
      _steps.removeAt(index);
      _controllers.removeAt(index).dispose();
    });
  }

  void _save() {
    final result = <RoutineStep>[];
    for (var i = 0; i < _steps.length; i++) {
      final title = _controllers[i].text.trim();
      if (title.isEmpty) continue;
      result.add(_steps[i].copyWith(title: title));
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.72;
    return SizedBox(
      height: height,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ROUTINE EDITOR',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.routine.kind.label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            if (_failed) _errorBanner(),
            Expanded(child: _steps.isEmpty ? _emptyState() : _list()),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Text(
              'COULD NOT LOAD YOUR ROUTINE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.ink,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _adopt(widget.onRestoreDefaults());
              _failed = false;
            }),
            child: const Text(
              'RESTORE DEFAULTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(
            AppAssets.spriteAnchor,
            width: 72,
            height: 72,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            'NO STEPS YET',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ADD YOUR FIRST STEP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _list() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _steps.length,
      itemBuilder: (context, index) {
        final step = _steps[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controllers[index],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Step title',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<StepCategory>(
                value: step.category,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(12),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: step.category.color,
                ),
                items: StepCategory.values
                    .map(
                      (c) => DropdownMenuItem<StepCategory>(
                        value: c,
                        child: Text(
                          c.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: c.color,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _steps[index] = step.copyWith(category: value));
                },
              ),
              IconButton(
                onPressed: () => _removeAt(index),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 22,
                  color: AppColors.textMuted,
                ),
                tooltip: 'Remove step',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _footer() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _addStep,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ADD STEP',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'SAVE',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
