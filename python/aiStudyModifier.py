import json
from langchain_openai import ChatOpenAI
import pandas as pd
from jsonschema import validate, ValidationError
from langchain_core.messages import SystemMessage, HumanMessage


def modify_ai_study(url, api_token, query):
    """
    Modifies a preexisting json following wearIts JSON spec using kimi.
    
    Parameters
    ----------
    url : str
        GenAI url endpoint.
    api_token : str
        User API key.
    query : str
        Description of the modification to make in as much detail as possible.
    
    Output
    ------
    Saves the validated study JSON to 'study_output.json' in Codebook_RMD 'data' folder.
    
    Raises
    ------
    ValidationError
        If the model fails to return valid JSON after max_retries attempts.
    json.JSONDecodeError
        If the response cannot be parsed as JSON after max_retries attempts.
    """

    with open('../schema/0.1.0/study.json') as f:
        schema = json.load(f)

    with open('Codebook_RMD/Data/study_output.json') as f:
        schemaToModify = json.load(f)

    itemRepository = pd.read_csv('Codebook_RMD/Data/itemRepository.csv')

    llm = ChatOpenAI(
        model="Kimi-K2.5",
        base_url=url,
        api_key=api_token,
        temperature=0,
        timeout=300,
        max_tokens=16000
    )

    system_prompt = f"""You are a synthetic study modifier. You take a preexisting study JSON: {schemaToModify} and modify it based on the user's request. This may involve making changes, additions, or removing features. Always return the whole JSON with the modification applied.
Return ONLY valid JSON, no markdown, no explanation.
Use 'Item.Type' as the field name, NOT 'Type'.
Match this schema exactly: {schema}

Additionally, you may reference this {itemRepository} item repository. It contains metadata about scales and items used by scientists. If one of the scales or items is applicable, generate based on the provided info. If there are no applicable items, generate new ones.

RULES:
- Return a JSON object, NOT a list at the top level
- 'Conditional.Type' must be one of: '1','2','3','4','5','6' or null — never a boolean
- Do not invent new field names
"""

    max_retries = 5
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
            break
        except (ValidationError, json.JSONDecodeError) as e:
            print(f"✗ Attempt {attempt + 1} failed: {e.message if hasattr(e, 'message') else str(e)}")
            if attempt == max_retries - 1:
                raise
            messages.append({"role": "assistant", "content": response.content})
            messages.append({"role": "user", "content": f"That was invalid JSON. Error: {e.message if hasattr(e, 'message') else str(e)}. Please fix and try again, returning only valid JSON."})

    with open("Codebook_RMD/Data/study_output.json", "w") as f:
        json.dump(data, f, indent=2)

    print("Modified and saved to Codebook_RMD/Data/study_output.json")
