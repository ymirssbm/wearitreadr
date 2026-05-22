import json
import os
from typing import Literal, Optional
from langchain_core.messages import SystemMessage, HumanMessage, AIMessage
from langchain_openai import ChatOpenAI

class StudyAssistant:
    """
    A chatbot dispatcher that routes user requests to appropriate study generation/modification tools.
    """
    
    def __init__(self, url: str, api_token: str, schema_path: str = 'schema', 
                 output_path: str = 'Codebook_RMD/Data'):
        self.url = url
        self.api_token = api_token
        self.schema_path = schema_path
        self.output_path = output_path
        self.conversation_history = []
        
        self.router_llm = ChatOpenAI(
            model="Kimi-K2.5",
            base_url=url,
            api_key=api_token,
            temperature=0,
            timeout=60,
            max_tokens=500
        )
    
    def _determine_action(self, user_input: str) -> dict:
        study_exists = os.path.exists(os.path.join(self.output_path, 'study_output.json'))
        
        system_prompt = f"""You are a routing assistant for a study generation system.

Available actions:
1. "generate" - Create a new study from scratch
2. "modify" - Modify an existing study (only if study_output.json exists)
3. "chat" - Answer questions, provide help, or clarify requirements
4. "help" - Show available commands

Current state: {"A study file exists" if study_exists else "No study file exists yet"}

Analyze the user's message and return ONLY a JSON object with this exact format:
{{
  "action": "generate" | "modify" | "chat" | "help",
  "query": "the user's actual request or question",
  "reasoning": "brief explanation of your choice"
}}

Guidelines:
- If user wants to create/generate a NEW study -> "generate"
- If user wants to change/modify/update EXISTING study -> "modify" (only if file exists)
- If user asks questions, needs clarification, or general conversation -> "chat"
- If user asks how to use the system or what they can do -> "help"
- If modify is requested but no file exists, use "chat" to inform them
"""
        
        messages = [
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_input)
        ]
        
        try:
            response = self.router_llm.invoke(messages)
            raw = response.content.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()
            decision = json.loads(raw)
            return decision
        except (json.JSONDecodeError, Exception) as e:
            print(f"Routing error: {e}")
            return {"action": "chat", "query": user_input, "reasoning": "fallback"}
    
    def _handle_chat(self, user_input: str) -> str:
        system_prompt = """You are a helpful assistant for a study generation system.

You help users:
- Understand how to create synthetic research studies
- Plan what details to include in their study descriptions
- Troubleshoot issues with study generation
- Answer questions about the system

Be concise, friendly, and helpful. Guide users toward successfully creating or modifying studies.
"""
        
        messages = [SystemMessage(content=system_prompt)]
        
        for msg in self.conversation_history[-6:]:
            messages.append(msg)
        
        messages.append(HumanMessage(content=user_input))
        
        response = self.router_llm.invoke(messages)
        return response.content
    
    def _show_help(self) -> str:
        study_exists = os.path.exists(os.path.join(self.output_path, 'study_output.json'))
        
        help_text = """
🔬 Study Assistant Help
━━━━━━━━━━━━━━━━━━━━━━

AVAILABLE COMMANDS:

📝 Generate a new study:
   "Create a study about [topic]..."
   "Generate a new survey for [purpose]..."
   
   Example: "Create a study measuring stress levels in college students 
             using validated PHQ-9 and GAD-7 scales"

✏️  Modify existing study:
   "Add a question about..."
   "Remove the section on..."
   "Change the scale from..."
   
   Example: "Add a demographic section with age and gender questions"

❓ Ask questions:
   "What information do I need to provide?"
   "How detailed should my description be?"
   "What scales are available?"

━━━━━━━━━━━━━━━━━━━━━━
"""
        
        if study_exists:
            help_text += "\n✅ Current status: A study file exists (you can modify it)"
        else:
            help_text += "\n📋 Current status: No study file yet (generate one first)"
        
        return help_text
    
    def chat(self, user_input: str) -> dict:
        """
        Main chat interface - processes user input and routes to appropriate handler.
        
        Returns dict with:
        - action: str (generate/modify/chat/help)
        - response: str (the message to show user)
        - query: str (cleaned query for generate/modify)
        """
        self.conversation_history.append(HumanMessage(content=user_input))
        
        if user_input.lower().strip() in ['help', '?', 'commands', 'what can you do']:
            response = self._show_help()
            self.conversation_history.append(AIMessage(content=response))
            return {"action": "help", "response": response, "query": ""}
        
        decision = self._determine_action(user_input)
        action = decision.get('action', 'chat')
        query = decision.get('query', user_input)
        reasoning = decision.get('reasoning', '')
        
        print(f"[Routing] Action: {action} | Reasoning: {reasoning}")
        
        if action == 'help':
            response = self._show_help()
            self.conversation_history.append(AIMessage(content=response))
            return {"action": "help", "response": response, "query": ""}
        
        elif action == 'generate':
            return {"action": "generate", "response": "", "query": query}
        
        elif action == 'modify':
            study_exists = os.path.exists(os.path.join(self.output_path, 'study_output.json'))
            if not study_exists:
                response = "⚠️  No existing study found. Please generate a study first before modifying."
                self.conversation_history.append(AIMessage(content=response))
                return {"action": "chat", "response": response, "query": ""}
            else:
                return {"action": "modify", "response": "", "query": query}
        
        else:  # chat
            response = self._handle_chat(user_input)
            self.conversation_history.append(AIMessage(content=response))
            return {"action": "chat", "response": response, "query": ""}
    
    def reset_conversation(self):
        self.conversation_history = []
