class Questionnaire {
  final String id;
  final String title;
  final List<String> instructions;
  final List<QuestionItem> questions;
  final bool useSlider; // For example, WSAS uses a slider.
  final bool structuredFormat; // For ICECAP-A structured layout.

  Questionnaire({
    required this.id,
    required this.title,
    required this.instructions,
    required this.questions,
    this.useSlider = false,
    this.structuredFormat = false,
  });
}

class QuestionItem {
  final String questionText;
  final List<String> options;
  final bool displayNumber;
  final bool useSlider; // ✅ Added for WSAS slider support
  final bool isTimePicker; // ✅ Added for HH:MM selection
  final bool isNumericInput; // ✅ Added for Minutes/Hours selection

  QuestionItem({
    required this.questionText,
    required this.options,
    this.displayNumber = true,
    this.useSlider = false, // Default false
    this.isTimePicker = false, // Default false
    this.isNumericInput = false, // Default false
  });
}



// ----------------- WSAS QUESTIONNAIRE (Uses Slider: 1 to 8) -----------------
final Questionnaire wsasQuestionnaire = Questionnaire(
  id: "wsas",
  title: "Work and Social Adjustment Scale (WSAS)",
  instructions: [
    "Please rate how much your [problem] impairs your ability to perform each activity on a scale from 0 (not at all impaired) to 8 (very severely impaired)."
  ],
  questions: [
    QuestionItem(questionText: "My ability to work is impaired.", options: [], useSlider: true),
    QuestionItem(questionText: "My home management is impaired.", options: [], useSlider: true),
    QuestionItem(questionText: "My social leisure activities are impaired.", options: [], useSlider: true),
    QuestionItem(questionText: "My private leisure activities are impaired.", options: [], useSlider: true),
    QuestionItem(questionText: "My ability to form and maintain close relationships is impaired.", options: [], useSlider: true),
  ],
);


// ----------------- ICECAP-A QUESTIONNAIRE (Structured Format) -----------------
final Questionnaire icecapAQuestionnaire = Questionnaire(
  id: "icecapA",
  title: "ICECAP-A Quality of Life",
  instructions: [
    "For each statement below, select the one that best describes your overall quality of life at the moment."
  ],
  questions: [
    QuestionItem(
      questionText: "Feeling settled and secure",
      options: [
        "I am able to feel settled and secure in all areas of my life (4)",
        "I am able to feel settled and secure in many areas of my life (3)",
        "I am able to feel settled and secure in a few areas of my life (2)",
        "I am unable to feel settled and secure in any areas of my life (1)",
      ],
    ),
    QuestionItem(
      questionText: "Love, friendship and support",
      options: [
        "I can have a lot of love, friendship and support (4)",
        "I can have quite a lot of love, friendship and support (3)",
        "I can have a little love, friendship and support (2)",
        "I cannot have any love, friendship and support (1)",
      ],
    ),
    QuestionItem(
      questionText: "Being independent",
      options: [
        "I am able to be completely independent (4)",
        "I am able to be independent in many things (3)",
        "I am able to be independent in a few things (2)",
        "I am unable to be at all independent (1)",
      ],
    ),
    QuestionItem(
      questionText: "Achievement and progress",
      options: [
        "I can achieve and progress in all aspects of my life (4)",
        "I can achieve and progress in many aspects of my life (3)",
        "I can achieve and progress in a few aspects of my life (2)",
        "I cannot achieve and progress in any aspects of my life (1)",
      ],
    ),
    QuestionItem(
      questionText: "Enjoyment and pleasure",
      options: [
        "I can have a lot of enjoyment and pleasure (4)",
        "I can have quite a lot of enjoyment and pleasure (3)",
        "I can have a little enjoyment and pleasure (2)",
        "I cannot have any enjoyment and pleasure (1)",
      ],
    ),
  ],
  structuredFormat: true,
);

// ----------------- PSQI QUESTIONNAIRE -----------------
final Questionnaire psqiQuestionnaire = Questionnaire(
  id: "psqi",
  title: "Pittsburgh Sleep Quality Index (PSQI)",
  instructions: [
    "Answer the following questions about your sleep habits over the past month."
  ],
  questions: [
  QuestionItem(
    questionText: "What time have you usually gone to bed at night?",
    options: [],
    isTimePicker: true, // ⏰ Use a Time Picker for HH:MM
  ),
  QuestionItem(
    questionText: "How long (in minutes) does it usually take you to fall asleep?",
    options: [],
    isNumericInput: true, // 🔢 Restrict to numbers only
  ),
  QuestionItem(
    questionText: "What time have you usually gotten up in the morning?",
    options: [],
    isTimePicker: true, // ⏰ Use a Time Picker
  ),
  QuestionItem(
    questionText: "How many hours of actual sleep did you get at night?",
    options: [],
    isNumericInput: true, // 🔢 Restrict to numbers only
  ),
    // Q5 (Label only; no answer field)
    QuestionItem(
      questionText: "During the past month, how often have you had trouble sleeping because you...",
      options: [],
    ),
    // Q5 sub-items (do not display number)
    QuestionItem(
      questionText: "5a. Cannot get to sleep within 30 minutes",
      options: [
        "Not during the past month",
        "Less than once a week",
        "Once or twice a week",
        "Three or more times a week"
      ],
      displayNumber: false,
    ),
    QuestionItem(
      questionText: "5b. Wake up in the middle of the night or early morning",
      options: [
        "Not during the past month",
        "Less than once a week",
        "Once or twice a week",
        "Three or more times a week"
      ],
      displayNumber: false,
    ),
    QuestionItem(
      questionText: "5c. Have to get up to use the bathroom",
      options: [
        "Not during the past month",
        "Less than once a week",
        "Once or twice a week",
        "Three or more times a week"
      ],
      displayNumber: false,
    ),
    QuestionItem(
      questionText: "5d. Cannot breathe comfortably",
      options: [
        "Not during the past month",
        "Less than once a week",
        "Once or twice a week",
        "Three or more times a week"
      ],
      displayNumber: false,
    ),
    QuestionItem(
      questionText: "5e. Cough or snore loudly",
      options: [
        "Not during the past month",
        "Less than once a week",
        "Once or twice a week",
        "Three or more times a week"
      ],
      displayNumber: false,
    ),
    QuestionItem(
      questionText: "5f. Feel too cold",
      options: [
        "Not during the past month",
        "Less than once a week",
        "Once or twice a week",
        "Three or more times a week"
      ],
      displayNumber: false,
    ),
    QuestionItem(
      questionText: "5g. Feel too hot",
      options: [
        "Not during the past month",
        "Less than once a week",
        "Once or twice a week",
        "Three or more times a week"
      ],
      displayNumber: false,
    ),
    QuestionItem(
      questionText: "5h. Have bad dreams",
      options: [
        "Not during the past month",
        "Less than once a week",
        "Once or twice a week",
        "Three or more times a week"
      ],
      displayNumber: false,
    ),
    QuestionItem(
      questionText: "5i. Have pain",
      options: [
        "Not during the past month",
        "Less than once a week",
        "Once or twice a week",
        "Three or more times a week"
      ],
      displayNumber: false,
    ),
    QuestionItem(
      questionText: "5j. Other reasons, please describe:",
      options: [],
      displayNumber: false,
    ),
    // Q6
    QuestionItem(
      questionText: "During the past month, how often have you taken medicine to help you sleep (prescribed or over the counter)?",
      options: [
        "Not during the past month",
        "Less than once a week",
        "Once or twice a week",
        "Three or more times a week"
      ],
    ),
    // Q7
    QuestionItem(
      questionText: "During the past month, how often have you had trouble staying awake while driving, eating meals, or engaging in social activity?",
      options: [
        "No problem at all",
        "Only a very slight problem",
        "Somewhat of a problem",
        "A very big problem"
      ],
    ),
    // Q8
    QuestionItem(
      questionText: "During the past month, how much of a problem has it been for you to keep up enough enthusiasm to get things done?",
      options: [
        "Very good",
        "Fairly good",
        "Fairly bad",
        "Very bad"
      ],
    ),
    // Q9
    QuestionItem(
      questionText: "During the past month, how would you rate your sleep quality overall?",
      options: [
        "Very good",
        "Fairly good",
        "Fairly bad",
        "Very bad"
      ],
    ),
    // Q10
    QuestionItem(
      questionText: "Do you have a bed partner or roommate?",
      options: [
        "No bed partner or roommate",
        "Partner/room mate in other room",
        "Partner in same room but not same bed",
        "Partner in same bed"
      ],
    ),
    // Q10 sub-items (do not display number)
    QuestionItem(
      questionText: "10a. Loud snoring",
      options: [
        "Not during the past month",
        "Less than once a week",
        "Once or twice a week",
        "Three or more times a week"
      ],
      displayNumber: false,
    ),
    QuestionItem(
      questionText: "10b. Long pauses between breaths while asleep",
      options: [
        "Not during the past month",
        "Less than once a week",
        "Once or twice a week",
        "Three or more times a week"
      ],
      displayNumber: false,
    ),
    QuestionItem(
      questionText: "10c. Legs twitching or jerking while you sleep",
      options: [
        "Not during the past month",
        "Less than once a week",
        "Once or twice a week",
        "Three or more times a week"
      ],
      displayNumber: false,
    ),
    QuestionItem(
      questionText: "10d. Episodes of disorientation or confusion during sleep",
      options: [
        "Not during the past month",
        "Less than once a week",
        "Once or twice a week",
        "Three or more times a week"
      ],
      displayNumber: false,
    ),
    QuestionItem(
      questionText: "10e. Other restlessness while you sleep, please describe:",
      options: [],
      displayNumber: false,
    ),
  ],
);
