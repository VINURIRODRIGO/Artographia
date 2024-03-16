import json
import re
from pathlib import Path

import uvicorn
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from re_edge_gpt import Chatbot, ConversationStyle

app = FastAPI()

class Payload(BaseModel):
    text: str

def clean_text(text):
    # Remove [^(number)^] pattern with numbers
    cleaned_text = re.sub(r'\[\^\d+\^\]', '', text)
    # Remove unicode characters
    cleaned_text = re.sub(r'\\u[0-9a-fA-F]{4}', '', cleaned_text)
    # Remove special characters like /\ and "},
    cleaned_text = re.sub(r'[\\/\}",]+', '', cleaned_text)
    # Remove **,
    cleaned_text = re.sub(r'\*\*', '', cleaned_text)
    # Remove ","
    cleaned_text = re.sub(r'\,",', '', cleaned_text)
    # Remove any remaining special characters
    cleaned_text = re.sub(r'[^\w\s.]', '', cleaned_text)
    # Remove extra spaces
    cleaned_text = re.sub(r'\s+', ' ', cleaned_text)
    # Stop at "Generating answers for you..."
    cleaned_text = re.sub(r'Generating answers for you\.\.\..*$', '', cleaned_text)
    return cleaned_text.strip()


@app.post('/get-response')
async def get_response(payload: Payload):
    bot = None
    question = payload.text
    try:
        cookies = json.loads(open(
            str(Path(str(Path.cwd()) + "/backend/bing_cookies.json")), encoding="utf-8").read())
        bot = await Chatbot.create(cookies=cookies)
        response = await bot.ask(
            prompt=question,
            conversation_style=ConversationStyle.balanced,
            simplify_response=True
        )
        # If you are using non ascii char you need set ensure_ascii=False
        print(json.dumps(response, indent=2, ensure_ascii=True))
        assert response
    except Exception as error:
        raise error
   
    data = response['text']
    answer = data.split("web_search_results")[0]
    
    emoji_index = answer.find('😊')

    if emoji_index != -1:
        # Stop the content when the emoji is found
        answer = answer[:emoji_index]
    
    cleaned_answer = clean_text(answer)
    res = {"response": cleaned_answer}

    return JSONResponse(res, 200)

if __name__ == "__main__":
    uvicorn.run(app)
