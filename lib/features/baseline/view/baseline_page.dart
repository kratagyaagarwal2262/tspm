import '../../../core/router/exports.dart';

class BaselinePage extends StatelessWidget {
  const BaselinePage({super.key, this.repository});
  final BaselineRepository? repository;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => BaselineBloc(
      repository:
          repository ?? BaselineRepository(store: ProtectedBaselineStore()),
    )..add(const BaselineLoadRequested()),
    child: const _BaselineHost(),
  );
}

class _BaselineHost extends StatefulWidget {
  const _BaselineHost();
  @override
  State<_BaselineHost> createState() => _BaselineHostState();
}

class _BaselineHostState extends State<_BaselineHost>
    with WidgetsBindingObserver {
  final Map<OnboardingField, TextEditingController> _controllers = {};
  bool _allowExit = false;
  bool _dialogOpen = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(context.read<BaselineBloc>().flush());
    }
  }

  void _edit(OnboardingDraft Function(OnboardingDraft) update) =>
      context.read<BaselineBloc>().add(BaselineDraftChanged(update: update));
  Future<void> _back() async {
    final BaselineBloc bloc = context.read<BaselineBloc>();
    final BaselineState state = bloc.state;
    if (state is BaselineEditing && state.draft.step.index > 0) {
      FocusScope.of(context).unfocus();
      bloc.add(const BaselineBackPressed());
      return;
    }
    if (state is BaselineCompleting) return;
    bool saved = state is! BaselineEditing || await bloc.flush();
    if (!mounted) return;
    if (!saved) {
      saved =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(AppStrings.unsavedExitTitle),
              content: const Text(AppStrings.unsavedExitMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(AppStrings.stay),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(AppStrings.leave),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (!mounted || !saved) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_exitRoute());
    });
  }

  Future<void> _exitRoute() async {
    final bool popped = await Navigator.of(context).maybePop();
    if (!mounted || popped) return;
    await SystemNavigator.pop();
  }

  Future<void> _confirm(BaselineEditing state) async {
    if (_dialogOpen || !state.confirmationPending) return;
    _dialogOpen = true;
    final MapEntry<OutlierField, double> entry =
        state.validation.confirmationsRequired.entries.first;
    final bool accepted =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(AppStrings.outlierTitle),
            content: Text(
              '${AppStrings.outlierValue(entry.key == OutlierField.height ? AppStrings.height : AppStrings.startingWeight, entry.value, entry.key == OutlierField.height ? LengthUnit.cm.name : WeightUnit.kg.name)}\n\n${AppStrings.outlierExplanation}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.changeEntry),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(AppStrings.confirmEntry),
              ),
            ],
          ),
        ) ??
        false;
    _dialogOpen = false;
    if (!mounted) return;
    context.read<BaselineBloc>().add(
      BaselineOutlierAnswered(
        field: entry.key,
        canonicalValue: entry.value,
        accepted: accepted,
      ),
    );
  }

  TextEditingController _controller(
    OnboardingDraft draft,
    OnboardingField field,
  ) {
    final String value =
        draft.quantities[field]?.rawText ?? draft.text[field] ?? '';
    final TextEditingController controller = _controllers.putIfAbsent(
      field,
      () => TextEditingController(text: value),
    );
    if (controller.text != value) {
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    return controller;
  }

  Future<void> _editTime(OnboardingDraft draft) async {
    final DateTime selected = draft.startingTime.selectedLocalDateTime;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime(selected.year, selected.month, selected.day),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (!mounted || date == null) return;
    final TimeOfDay? clock = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: selected.hour, minute: selected.minute),
    );
    if (!mounted || clock == null) return;
    _edit(
      (current) => current.withStartingTime(
        ObservationTime.fromSelectedLocal(
          DateTime(date.year, date.month, date.day, clock.hour, clock.minute),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<BaselineBloc, BaselineState>(
        listener: (context, state) {
          if (state is BaselineEditing && state.confirmationPending) {
            unawaited(_confirm(state));
          }
        },
        builder: (context, state) => PopScope(
          canPop:
              _allowExit ||
              state is BaselineCompleted ||
              state is BaselineLoadFailed,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) unawaited(_back());
          },
          child: _content(context, state),
        ),
      );
  Widget _content(BuildContext context, BaselineState state) {
    if (state is BaselineCompleted) {
      return Column(
        children: [
          if (state.refreshFailure != null)
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.medium),
                child: Column(
                  children: [
                    const Text(AppStrings.refreshFailed),
                    TextButton(
                      onPressed: () => context.read<BaselineBloc>().add(
                        const BaselineRetryPressed(),
                      ),
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: BaselineLandingPage(
              baseline: state.baseline,
              justCompleted: state.justCompleted,
              onReviewProfile: () => Navigator.of(context).pushNamed(
                AppRoutes.profile,
                arguments: ProfileRouteArgs(baseline: state.baseline),
              ),
            ),
          ),
        ],
      );
    }
    if (state is BaselineLoading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    if (state is BaselineLoadFailed) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.baselineTitle)),
        body: BaselineReadingBody(
          children: [
            const Text(AppStrings.loadFailed),
            const SizedBox(height: AppDimensions.medium),
            const Text(AppStrings.loadProtection),
            const SizedBox(height: AppDimensions.large),
            FilledButton(
              onPressed: () => context.read<BaselineBloc>().add(
                const BaselineRetryPressed(),
              ),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }
    if (state is BaselineCompleting) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.baselineTitle),
          automaticallyImplyLeading: false,
        ),
        body: BaselineReadingBody(
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                state.saveFailure == null
                    ? AppStrings.completing
                    : AppStrings.completeFailed,
              ),
            ),
            if (state.saveFailure != null) ...[
              const SizedBox(height: AppDimensions.medium),
              const Text(AppStrings.uncertainSave),
              FilledButton(
                onPressed: state.saving
                    ? null
                    : () => context.read<BaselineBloc>().add(
                        const BaselineRetryPressed(),
                      ),
                child: const Text(AppStrings.retry),
              ),
              if (state.saveFailure?.writeOutcome == WriteOutcome.notCommitted)
                TextButton(
                  onPressed: () => context.read<BaselineBloc>().add(
                    const BaselineBackPressed(),
                  ),
                  child: const Text(AppStrings.editAnswers),
                ),
            ],
          ],
        ),
      );
    }
    final BaselineEditing editing = state as BaselineEditing;
    final OnboardingDraft draft = editing.draft;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.baselineTitle),
        leading: IconButton(
          onPressed: _back,
          tooltip: AppStrings.back,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: BaselineReadingBody(
        children: [
          Semantics(
            header: true,
            child: Text(
              AppStrings.stepProgress(draft.step.index + 1),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: AppDimensions.small),
          _step(editing),
          const SizedBox(height: AppDimensions.large),
          Semantics(
            liveRegion: true,
            child: Text(
              editing.saveFailure != null
                  ? AppStrings.unsavedDraft
                  : editing.saving
                  ? AppStrings.savingDraft
                  : AppStrings.savedDraft,
            ),
          ),
          if (editing.saveFailure != null)
            TextButton(
              onPressed: () => context.read<BaselineBloc>().add(
                const BaselineRetryPressed(),
              ),
              child: const Text(AppStrings.retry),
            ),
          const SizedBox(height: AppDimensions.medium),
          FilledButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              context.read<BaselineBloc>().add(
                draft.step == OnboardingStep.goalAndApplicability
                    ? const BaselineCompletePressed()
                    : const BaselineNextPressed(),
              );
            },
            child: Text(
              draft.step == OnboardingStep.goalAndApplicability
                  ? AppStrings.finishSetup
                  : AppStrings.continueLabel,
            ),
          ),
          if (draft.step.index > 0)
            TextButton(onPressed: _back, child: const Text(AppStrings.back)),
        ],
      ),
    );
  }

  Widget _step(BaselineEditing state) {
    final OnboardingDraft draft = state.draft;
    final FormProblems problems = state.validation;
    TextEditingController controllerFor(OnboardingField field) =>
        _controller(draft, field);
    return switch (draft.step) {
      OnboardingStep.purposeAndUnits => _PurposeAndUnitsStep(
        draft: draft,
        onUnitsChanged: (units) => context.read<BaselineBloc>().add(
          BaselineUnitsChanged(units: units),
        ),
      ),
      OnboardingStep.requiredBaseline => _RequiredBaselineStep(
        draft: draft,
        problems: problems,
        controllerFor: controllerFor,
        onEdit: _edit,
        onEditTime: () => _editTime(draft),
      ),
      OnboardingStep.measurements => _MeasurementsStep(
        draft: draft,
        problems: problems,
        controllerFor: controllerFor,
        onEdit: _edit,
      ),
      OnboardingStep.activity => _ActivityStep(
        draft: draft,
        problems: problems,
        controllerFor: controllerFor,
        onEdit: _edit,
      ),
      OnboardingStep.goalAndApplicability => _GoalAndApplicabilityStep(
        draft: draft,
        problems: problems,
        controllerFor: controllerFor,
        onEdit: _edit,
      ),
    };
  }
}

class _BaselineChoice<T> extends StatelessWidget {
  const _BaselineChoice({
    required this.label,
    required this.value,
    required this.values,
    required this.name,
    required this.onChanged,
    required this.error,
    required this.unknown,
    this.onUnknown,
  });
  final String label;
  final T? value;
  final List<T> values;
  final String Function(T) name;
  final ValueChanged<T> onChanged;
  final bool error, unknown;
  final VoidCallback? onUnknown;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.medium),
    child: DropdownButtonFormField<T>(
      key: ValueKey<String>(label),
      initialValue: value,
      isExpanded: true,
      itemHeight: null,
      decoration: InputDecoration(
        labelText: label,
        errorText: error ? AppStrings.chooseRequired : null,
      ),
      hint: unknown ? const Text(AppStrings.unknown) : null,
      items: [
        if (unknown)
          const DropdownMenuItem(value: null, child: Text(AppStrings.unknown)),
        ...values.map(
          (v) => DropdownMenuItem(
            value: v,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.small,
              ),
              child: Text(name(v)),
            ),
          ),
        ),
      ],
      onChanged: (v) {
        if (v == null) {
          onUnknown?.call();
        } else {
          onChanged(v);
        }
      },
    ),
  );
}

class _PurposeAndUnitsStep extends StatelessWidget {
  const _PurposeAndUnitsStep({
    required this.draft,
    required this.onUnitsChanged,
  });
  final OnboardingDraft draft;
  final ValueChanged<UnitPreferences> onUnitsChanged;
  @override
  Widget build(BuildContext context) {
    final OnboardingDraft d = draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(AppStrings.baselinePurpose),
        const SizedBox(height: AppDimensions.medium),
        const Text(AppStrings.evidencePurpose),
        const SizedBox(height: AppDimensions.large),
        _choice<WeightUnit>(
          AppStrings.weightUnits,
          d.units.weight,
          WeightUnit.values,
          (v) => v.name,
          (v) => onUnitsChanged(
            UnitPreferences(weight: v, length: d.units.length),
          ),
        ),
        _choice<LengthUnit>(
          AppStrings.lengthUnits,
          d.units.length,
          LengthUnit.values,
          (v) => v.name,
          (v) => onUnitsChanged(
            UnitPreferences(weight: d.units.weight, length: v),
          ),
        ),
      ],
    );
  }
}

class _RequiredBaselineStep extends StatelessWidget {
  const _RequiredBaselineStep({
    required this.draft,
    required this.problems,
    required this.controllerFor,
    required this.onEdit,
    required this.onEditTime,
  });
  final OnboardingDraft draft;
  final FormProblems problems;
  final TextEditingController Function(OnboardingField) controllerFor;
  final void Function(OnboardingDraft Function(OnboardingDraft)) onEdit;
  final VoidCallback onEditTime;
  @override
  Widget build(BuildContext context) {
    final OnboardingDraft d = draft;
    final FormProblems p = problems;
    final String length = d.units.length.name;
    final String weight = d.units.weight.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(AppStrings.requiredBaseline),
        _BaselineField(
          draft: d,
          problems: p,
          field: OnboardingField.age,
          label: AppStrings.age,
          controllerFor: controllerFor,
          onEdit: onEdit,
        ),
        const Text(AppStrings.equationExplanation),
        const SizedBox(height: AppDimensions.small),
        _choice<EquationSexInput>(
          AppStrings.equationInput,
          d.equationInput,
          EquationSexInput.values,
          (v) =>
              v == EquationSexInput.male ? AppStrings.male : AppStrings.female,
          (v) => onEdit((current) => current.copyWith(equationInput: v)),
          error: p.missingEquationInput,
        ),
        _BaselineField(
          draft: d,
          problems: p,
          field: OnboardingField.height,
          label: AppStrings.quantityLabel(AppStrings.height, length),
          controllerFor: controllerFor,
          onEdit: onEdit,
          unit: length,
        ),
        _BaselineField(
          draft: d,
          problems: p,
          field: OnboardingField.startingWeight,
          label: AppStrings.quantityLabel(AppStrings.startingWeight, weight),
          controllerFor: controllerFor,
          onEdit: onEdit,
          unit: weight,
        ),
        Text(baselineTimeLabel(d.startingTime)),
        TextButton(
          onPressed: onEditTime,
          child: const Text(AppStrings.editWeightTime),
        ),
        if (p.invalidStartingTime) const Text(AppStrings.invalidTime),
      ],
    );
  }
}

class _MeasurementsStep extends StatelessWidget {
  const _MeasurementsStep({
    required this.draft,
    required this.problems,
    required this.controllerFor,
    required this.onEdit,
  });
  final OnboardingDraft draft;
  final FormProblems problems;
  final TextEditingController Function(OnboardingField) controllerFor;
  final void Function(OnboardingDraft Function(OnboardingDraft)) onEdit;
  @override
  Widget build(BuildContext context) {
    final OnboardingDraft d = draft;
    final FormProblems p = problems;
    final String length = d.units.length.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(AppStrings.measurements),
        const Text(AppStrings.optional),
        const SizedBox(height: AppDimensions.medium),
        _BaselineField(
          draft: d,
          problems: p,
          field: OnboardingField.waist,
          label: AppStrings.quantityLabel(AppStrings.waist, length),
          controllerFor: controllerFor,
          onEdit: onEdit,
          unit: length,
        ),
        _BaselineField(
          draft: d,
          problems: p,
          field: OnboardingField.neck,
          label: AppStrings.quantityLabel(AppStrings.neck, length),
          controllerFor: controllerFor,
          onEdit: onEdit,
          unit: length,
        ),
        _BaselineField(
          draft: d,
          problems: p,
          field: OnboardingField.hip,
          label: AppStrings.quantityLabel(AppStrings.hip, length),
          controllerFor: controllerFor,
          onEdit: onEdit,
          unit: length,
        ),
        _BaselineField(
          draft: d,
          problems: p,
          field: OnboardingField.bodyFatPercent,
          label: AppStrings.bodyFat,
          controllerFor: controllerFor,
          onEdit: onEdit,
        ),
        _BaselineField(
          draft: d,
          problems: p,
          field: OnboardingField.bodyFatSource,
          label: AppStrings.bodyFatSource,
          controllerFor: controllerFor,
          onEdit: onEdit,
          numeric: false,
        ),
      ],
    );
  }
}

class _ActivityStep extends StatelessWidget {
  const _ActivityStep({
    required this.draft,
    required this.problems,
    required this.controllerFor,
    required this.onEdit,
  });
  final OnboardingDraft draft;
  final FormProblems problems;
  final TextEditingController Function(OnboardingField) controllerFor;
  final void Function(OnboardingDraft Function(OnboardingDraft)) onEdit;
  @override
  Widget build(BuildContext context) {
    final OnboardingDraft d = draft;
    final FormProblems p = problems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(AppStrings.activity),
        const Text(AppStrings.optional),
        const SizedBox(height: AppDimensions.medium),
        _choice<ActivityLevel>(
          AppStrings.activityLevel,
          d.activityLevel,
          ActivityLevel.values,
          (v) => AppStrings.activityLabels[v.index],
          (v) => onEdit((current) => current.copyWith(activityLevel: v)),
          unknown: true,
          onUnknown: () =>
              onEdit((current) => current.copyWith(clearActivityLevel: true)),
        ),
        _BaselineField(
          draft: d,
          problems: p,
          field: OnboardingField.typicalSteps,
          label: AppStrings.steps,
          controllerFor: controllerFor,
          onEdit: onEdit,
        ),
        _BaselineField(
          draft: d,
          problems: p,
          field: OnboardingField.trainingDays,
          label: AppStrings.trainingDays,
          controllerFor: controllerFor,
          onEdit: onEdit,
        ),
        _BaselineField(
          draft: d,
          problems: p,
          field: OnboardingField.trainingType,
          label: AppStrings.trainingType,
          controllerFor: controllerFor,
          onEdit: onEdit,
          numeric: false,
        ),
        _BaselineField(
          draft: d,
          problems: p,
          field: OnboardingField.restDays,
          label: AppStrings.restDays,
          controllerFor: controllerFor,
          onEdit: onEdit,
        ),
      ],
    );
  }
}

class _GoalAndApplicabilityStep extends StatelessWidget {
  const _GoalAndApplicabilityStep({
    required this.draft,
    required this.problems,
    required this.controllerFor,
    required this.onEdit,
  });
  final OnboardingDraft draft;
  final FormProblems problems;
  final TextEditingController Function(OnboardingField) controllerFor;
  final void Function(OnboardingDraft Function(OnboardingDraft)) onEdit;
  @override
  Widget build(BuildContext context) {
    final OnboardingDraft d = draft;
    final FormProblems p = problems;
    final String weight = d.units.weight.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(AppStrings.goalAndApplicability),
        _choice<GoalIntent>(
          AppStrings.goalIntent,
          d.goalIntent,
          GoalIntent.values,
          (v) =>
              v == GoalIntent.loss ? AppStrings.loss : AppStrings.maintenance,
          (v) => onEdit((current) => current.copyWith(goalIntent: v)),
          error: p.missingGoalIntent,
        ),
        if (d.goalIntent == GoalIntent.loss) ...[
          _BaselineField(
            draft: d,
            problems: p,
            field: OnboardingField.goalWeight,
            label: AppStrings.quantityLabel(AppStrings.targetWeight, weight),
            controllerFor: controllerFor,
            onEdit: onEdit,
            unit: weight,
          ),
          _choice<LossRate>(
            AppStrings.lossRate,
            d.lossRate,
            LossRate.values,
            (v) => AppStrings.rateLabels[v.index],
            (v) => onEdit((current) => current.copyWith(lossRate: v)),
            error: p.missingLossRate,
          ),
        ],
        _BaselineField(
          draft: d,
          problems: p,
          field: OnboardingField.bodyFatMilestone,
          label: AppStrings.milestone,
          controllerFor: controllerFor,
          onEdit: onEdit,
        ),
        _choice<ApplicabilityAnswer>(
          AppStrings.pregnancy,
          d.pregnancy,
          ApplicabilityAnswer.values,
          baselineAnswer,
          (v) => onEdit((current) => current.copyWith(pregnancy: v)),
        ),
        _choice<ApplicabilityAnswer>(
          AppStrings.breastfeeding,
          d.breastfeeding,
          ApplicabilityAnswer.values,
          baselineAnswer,
          (v) => onEdit((current) => current.copyWith(breastfeeding: v)),
        ),
        BaselineSection(
          title: AppStrings.availabilityTitle,
          children: [
            const Text(AppStrings.availability),
            Text(AppStrings.unknownInputs(_unknownInputs(d))),
            const SizedBox(height: AppDimensions.medium),
            Text(baselineApplicability(d.pregnancy, d.breastfeeding)),
          ],
        ),
      ],
    );
  }
}

class _BaselineField extends StatelessWidget {
  const _BaselineField({
    required this.draft,
    required this.problems,
    required this.field,
    required this.label,
    required this.controllerFor,
    required this.onEdit,
    this.unit,
    this.numeric = true,
  });
  final OnboardingDraft draft;
  final FormProblems problems;
  final OnboardingField field;
  final String label;
  final String? unit;
  final bool numeric;
  final TextEditingController Function(OnboardingField) controllerFor;
  final void Function(OnboardingDraft Function(OnboardingDraft)) onEdit;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.medium),
    child: TextFormField(
      key: ValueKey<OnboardingField>(field),
      controller: controllerFor(field),
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        errorText: _error(problems.fields[field]),
      ),
      onChanged: (value) => onEdit((current) {
        final String? selectedUnit = unit;
        if (selectedUnit == null) return current.withText(field, value);
        final double? number = double.tryParse(value.trim());
        final double? canonical =
            number == null || !number.isFinite || number <= 0
            ? null
            : number *
                  (selectedUnit == 'lb'
                      ? 0.45359237
                      : selectedUnit == 'inch'
                      ? 2.54
                      : 1);
        return current.withQuantity(
          field,
          DraftQuantity(
            rawText: value,
            canonicalValue: canonical,
            originalUnitToken: selectedUnit,
            displayUnitToken: selectedUnit,
          ),
        );
      }),
    ),
  );
}

String _unknownInputs(OnboardingDraft draft) {
  final Map<OnboardingField, String> labels = {
    OnboardingField.waist: AppStrings.waist,
    OnboardingField.neck: AppStrings.neck,
    OnboardingField.hip: AppStrings.hip,
    OnboardingField.bodyFatPercent: AppStrings.bodyFat,
    OnboardingField.typicalSteps: AppStrings.steps,
    OnboardingField.trainingDays: AppStrings.trainingDays,
    OnboardingField.trainingType: AppStrings.trainingType,
    OnboardingField.restDays: AppStrings.restDays,
  };
  final List<String> missing = labels.entries
      .where(
        (entry) =>
            draft.quantities[entry.key]?.canonicalValue == null &&
            (draft.text[entry.key]?.trim().isEmpty ?? true),
      )
      .map((entry) => entry.value)
      .toList();
  if (draft.activityLevel == null) missing.add(AppStrings.activityLevel);
  return missing.isEmpty ? AppStrings.noUnknownOptional : missing.join(', ');
}

Widget _heading(String title) =>
    BaselineSection(title: title, children: const []);

String? _error(InputIssue? issue) => switch (issue) {
  null => null,
  InputIssue.required => AppStrings.requiredInput,
  InputIssue.invalidNumber => AppStrings.invalidNumber,
  InputIssue.adultOnly => AppStrings.adultOnly,
  InputIssue.positiveFiniteRequired => AppStrings.positiveNumber,
  InputIssue.invalidDateTime => AppStrings.invalidTime,
  InputIssue.percentageRange => AppStrings.percentRange,
  InputIssue.dayCountRange => AppStrings.dayRange,
  InputIssue.sourceRequired => AppStrings.sourceRequired,
};

Widget _choice<T>(
  String label,
  T? value,
  List<T> values,
  String Function(T) name,
  ValueChanged<T> onChanged, {
  bool error = false,
  bool unknown = false,
  VoidCallback? onUnknown,
}) => _BaselineChoice<T>(
  label: label,
  value: value,
  values: values,
  name: name,
  onChanged: onChanged,
  error: error,
  unknown: unknown,
  onUnknown: onUnknown,
);
