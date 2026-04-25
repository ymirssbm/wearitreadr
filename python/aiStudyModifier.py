# Import json
import json
with open('../schema/0.1.0/study.json') as f:
    schema = json.load(f)


# Setup endpoint and env for api key
endpoint = "https://genai-fa2026-resource-1.services.ai.azure.com/api/projects/Ethan_Kile_GenAI_Project/openai/v1"


# Setup model

from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    model="Kimi-K2.5",
    base_url=endpoint + "/openai/v1",
    api_key=os.getenv("API_KEY"),
    temperature=0,
    timeout=300,
    max_tokens=16000
)


# Pull in item repo
import pandas as pd
itemRepository = pd.read_csv('itemRepository.csv')

# System prompt
with open('study_output.json') as f:
    schemaToModify = json.load(f)

system_prompt = f"""You are a synthetic study generator who takes a preexisting json: {schemaToModify} and modifies it. This may involve making changes, additions, or removing features based on what is asked of you.
Return ONLY valid JSON, no markdown, no explanation.
Use 'Item.Type' as the field name, NOT 'Type'.
Match this schema exactly: {schema}

Additionally, you may reference this {itemRepository} item repository. It contains metadata about scales and items used by scientists. If one of the scales or items is applicable, generate based on the provided info. If there is not applicable items, generate new one's.

RULES:
- Return a JSON object, NOT a list at the top level
- 'Conditional.Type' must be one of: '1','2','3','4','5','6' or null — never a boolean
- Do not invent new field names

"""

# Run model
import json
from jsonschema import validate, ValidationError
from langchain_core.messages import SystemMessage, HumanMessage

max_retries = 3
messages = [
    SystemMessage(content=system_prompt),
    HumanMessage(content=query)
]

for attempt in range(max_retries):
    response = llm.invoke(messages)
    try:
        raw = response.content.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()
        data = json.loads(raw)
        validate(instance=data, schema=schema)
        print("✓ Valid on attempt", attempt + 1)
        break  # success — exit the loop
    except (ValidationError, json.JSONDecodeError) as e:
        print(f"✗ Attempt {attempt + 1} failed: {e.message if hasattr(e, 'message') else str(e)}")
        if attempt == max_retries - 1:
            raise
        # Feed the error back so the model can self-correct
        messages.append({"role": "assistant", "content": response.content})
        messages.append({"role": "user", "content": f"That was invalid JSON. Error: {e.message if hasattr(e, 'message') else str(e)}. Please fix and try again, returning only valid JSON."})



with open("study_output.json", "w") as f:
    json.dump(data, f, indent=2)

print("Saved to study_output.json")
