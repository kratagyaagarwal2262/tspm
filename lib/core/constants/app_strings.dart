abstract final class AppStrings {
  static const String appTitle = 'Flutter Demo';
  static const String homeTitle = 'Flutter Demo Home Page';
  static const String counterPrompt =
      'You have pushed the button this many times:';
  static const String incrementTooltip = 'Increment';
  static const String unknownRoute = 'Page not found';
  static const String openProduct = 'Open baseline setup';
  static const String baselineTitle = 'Your baseline';
  static const String baselinePurpose =
      'Start with what you know. Your answers are protected and saved on this device. No account or internet connection is needed.';
  static const String evidencePurpose =
      'A starting weight is a reported observation. Future estimates and trends need more evidence; setup does not calculate them.';
  static const String continueLabel = 'Continue';
  static const String back = 'Back';
  static const String finishSetup = 'Save baseline';
  static const String retry = 'Retry';
  static const String savedDraft = 'Draft saved on this device';
  static const String savingDraft = 'Saving draft…';
  static const String unsavedDraft =
      'Draft not saved. Your answers remain here.';
  static const String loadFailed = 'Could not load your baseline';
  static const String loadProtection =
      'Saved data has been kept. Retry loading; setup cannot replace unreadable data.';
  static const String completing = 'Saving your baseline…';
  static const String completeFailed = 'Could not save your baseline';
  static const String uncertainSave =
      'The save could not be confirmed. Retry the same baseline to check safely.';
  static const String editAnswers = 'Return to answers';
  static const String setupSaved = 'Baseline saved';
  static const String landingTitle = 'Your starting point';
  static const String landingEvidence =
      'Your reported starting weight is saved. More observations are needed to understand a trend. Logging and estimates arrive in a later increment.';
  static const String reviewProfile = 'Review profile';
  static const String profileTitle = 'Saved profile';
  static const String reportedInputs = 'Reported baseline inputs';
  static const String readOnly =
      'Read-only review of the answers saved on this device.';
  static const String unknown = 'Unknown';
  static const String optional = 'Optional · leave blank for unknown';
  static const String requiredBaseline = 'A starting point';
  static const String measurements = 'Measurements, if known';
  static const String activity = 'Your usual activity';
  static const String goalAndApplicability = 'Your intention';
  static const String age = 'Age (years)';
  static const String equationInput = 'Equation input';
  static const String equationExplanation =
      'Choose the sex input used by future equations. This is separate from pregnancy and breastfeeding.';
  static const String male = 'Male';
  static const String female = 'Female';
  static const String height = 'Height';
  static const String startingWeight = 'Starting weight';
  static const String weightUnits = 'Weight units';
  static const String lengthUnits = 'Length units';
  static const String editWeightTime = 'Edit weight date and time';
  static const String waist = 'Waist';
  static const String neck = 'Neck';
  static const String hip = 'Hip';
  static const String bodyFat = 'Reported body fat (%)';
  static const String bodyFatSource = 'Body-fat source';
  static const String activityLevel = 'Activity level';
  static const String steps = 'Typical daily steps';
  static const String trainingDays = 'Training days per week';
  static const String trainingType = 'Training type';
  static const String restDays = 'Rest days per week';
  static const String loss = 'Weight loss';
  static const String maintenance = 'Maintenance';
  static const String goalIntent = 'Goal intention';
  static const String targetWeight = 'Target weight';
  static const String lossRate = 'Intended weekly loss rate';
  static const String milestone = 'Body-fat milestone (%)';
  static const String pregnancy = 'Pregnancy';
  static const String breastfeeding = 'Breastfeeding';
  static const String no = 'No';
  static const String yes = 'Yes';
  static const String availabilityTitle = 'What these inputs support';
  static const String availability =
      'Age, equation input, height and starting weight provide a baseline. Missing measurements and activity remain unknown. Trends require later observations; no numerical estimate is available in setup.';
  static const String applicabilityLimited =
      'Automated weight-loss targets will be withheld while pregnancy or breastfeeding is yes or unknown.';
  static const String applicabilityClear =
      'Pregnancy and breastfeeding are recorded as no. Future automated targets still require sufficient evidence.';
  static const String outlierTitle = 'Check this entry';
  static const String outlierExplanation =
      'This value is outside the usual entry range. Check the value and units, or confirm that you intended it.';
  static const String changeEntry = 'Review entry';
  static const String confirmEntry = 'Keep this value';
  static const String unsavedExitTitle = 'Leave with unsaved answers?';
  static const String unsavedExitMessage =
      'The latest answers could not be saved. Leaving may lose them.';
  static const String stay = 'Keep editing';
  static const String leave = 'Leave unsaved';
  static const String chooseRequired = 'Choose an answer to continue.';
  static const String requiredInput = 'Enter this value to continue.';
  static const String invalidNumber = 'Enter a valid whole number.';
  static const String adultOnly =
      'Setup is available for adults aged 18 and over.';
  static const String positiveNumber =
      'Enter a finite number greater than zero.';
  static const String percentRange =
      'Enter a percentage greater than 0 and less than 100.';
  static const String dayRange = 'Enter a whole number from 0 to 7.';
  static const String sourceRequired =
      'Add the source of the reported body-fat value.';
  static const String invalidTime = 'Choose a valid date and time.';
  static const String originalUnits = 'Original entry units';
  static const String reportedSource = 'Source: manually reported scale entry';
  static const String goal = 'Saved intention';
  static const String goalDate = 'Intention recorded on';
  static const String unitOfEntry = 'Entry units';
  static const String applicability = 'Applicability';
  static const String refreshFailed =
      'Could not reload the saved baseline. Previously loaded answers are shown.';
  static const List<String> activityLabels = [
    'Sedentary',
    'Lightly active',
    'Moderately active',
    'Very active',
    'Extremely active',
  ];
  static const List<String> rateLabels = [
    '0.25% of weight per week',
    '0.5% of weight per week',
    '0.75% of weight per week',
    '1% of weight per week',
  ];
  static String stepProgress(int step) => 'Step $step of 5';
  static String weightClock(String day, String clock, String offset) =>
      'Reported weight time: $day at $clock ($offset)';
  static String offsetLabel(String sign, String hours, String minutes) =>
      'UTC$sign$hours:$minutes';
  static String quantityLabel(String label, String unit) => '$label ($unit)';
  static String outlierValue(String label, double value, String unit) =>
      '$label: $value $unit';
  static String originalEntry(String weight, String length) =>
      'Weight: $weight · Height: $length';
  static String ageDate(String day) => 'Age recorded on $day';
  static const String noUnknownOptional = 'None';
  static String unknownInputs(String labels) =>
      'Unknown optional inputs: $labels';
}
