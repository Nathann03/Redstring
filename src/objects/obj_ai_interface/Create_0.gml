connectedToInternet = 0;
request_sent = 0;
request_result = "";

npc_id = "";
player_question = "";
found_clues = []
asked_questions = [];

interact = 0;
writer = noone;

request = -1;

scr_read_secrets();

/*
curl \
    -H "Authorization: Bearer TOKEN_HERE" \
    -H "Content-Type: application/json" \
    -d '{
      "npc_id": "riley_chen",
      "player_question": "What can you tell me about EVID_11?",
      "generation_backend": "gemini",
      "game_state": {
        "found_clues": [],
        "asked_questions": [],
        "npc_id": "riley_chen"
      }
    }' \
    http://52.15.134.116:8000/dialogue
*/