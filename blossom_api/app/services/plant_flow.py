from fastapi import HTTPException, status


PLANT_ADD_QUESTIONS = [
    {
        "key": "location_type",
        "title": "Where will your plant live?",
        "options": ["Indoor", "Outdoor"],
    },
    {
        "key": "light_condition",
        "title": "How much light does the spot get?",
        "options": ["Low Light", "Indirect", "Direct Sunlight"],
    },
    {
        "key": "caring_style",
        "title": "Describe your caring style",
        "options": ["I'm a bit forgetful", "I love caring for them daily"],
    },
    {
        "key": "pet_safety_priority",
        "title": "Is pet safety a priority?",
        "options": ["Yes, keep it safe", "No pets here"],
    },
]

PLANT_RESULT_FIELDS = [
    {"key": "water_requirements", "title": "Water"},
    {"key": "light_requirements", "title": "Light"},
    {"key": "temperature", "title": "Temperature"},
]


def validate_answers(answers: dict[str, str]) -> dict[str, str]:
    validated_answers: dict[str, str] = {}
    for question in PLANT_ADD_QUESTIONS:
        key = question["key"]
        if key not in answers or answers[key] in (None, ""):
            continue
        value = str(answers[key]).strip()
        if value not in question["options"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid answer for {key}",
            )
        validated_answers[key] = value
    return validated_answers


def get_missing_question_definitions(answered: dict[str, str]) -> list[dict[str, object]]:
    return [question for question in PLANT_ADD_QUESTIONS if question["key"] not in answered]
