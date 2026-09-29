# TSPM domain glossary

These words have one meaning across the product spec, UI, data model and tests.

| Term | Meaning and rule |
|---|---|
| Weight observation | One timestamped scale reading. Several may exist on the same local day; none alone establishes fat gain or loss. |
| Current weight | The most recent weight observation, shown with its measurement time. It is not the trend weight. |
| Trend weight | A summary inferred from repeated weight observations over a stated window. Its coverage and provisional status travel with the value. |
| Time-normalized weight | A statistical estimate adjusted to one reference time band using the person's own repeated within-day observations. It is unavailable before the evidence gate and is never an explanation of water, food or glycogen mass. |
| Daily intake | User-entered total calories for one local day. A missing day is unknown; a recorded zero is an explicit entry. Optional macros do not silently replace the calorie total. |
| Total daily expenditure | A source-labeled estimate intended to cover the full day's energy use. It can drive a daily energy gap when intake exists. |
| Session expenditure | Calories attributed to one walk, run or workout. It is contextual activity data and is never automatically added to a total daily expenditure. |
| Equation TDEE | A calculated baseline expenditure estimate from profile inputs and activity assumptions. It is separate from a logged daily total and from reverse TDEE. |
| Reverse TDEE | A later inferred maintenance-expenditure range from sustained intake and trend-weight history. It is not a direct measurement. |
| Daily energy gap | Total daily expenditure minus daily intake on a day with both values. Positive means estimated deficit; negative means estimated surplus. |
| Confidence | A qualitative statement about data coverage, consistency and source quality. It is not a probability of fat loss or proof of a cause. |
| Possible plateau | A later guarded interpretation of sustained trend slowdown with sufficient comparable observations. It is not triggered by one unchanged weight. |
| Goal version | A goal and accepted calorie range effective from a date. Changing the goal creates a new version rather than rewriting the prior plan. |
