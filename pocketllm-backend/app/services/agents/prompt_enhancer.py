"""Prompt enhancer agent implementation."""

from __future__ import annotations

import json
import logging
from typing import Any

from langchain_core.messages import AIMessage, BaseMessage, HumanMessage, SystemMessage

from app.core.config import Settings
from app.services.providers.groq import GroqSDKService

from .base import AgentContext, AgentRunResult, BaseConversationalAgent
from .memory import AgentMemoryStore

LOGGER = logging.getLogger("app.services.agents.prompt_enhancer")

_TASK_PROMPTS = {
    "maths": "You are an expert math tutor. Receive a student question and rephrase it for clarity, add instructions for step-by-step solutions, request LaTeX formatting, and specify any constraints (e.g., no calculators, show all work, explain reasoning).",
    "image_generation": "You are an AI art director. Take the user's concept and enhance it with vivid detail, explicit style/genre, composition settings, lighting, mood, camera details (if any), and relevant artist references. Clarify ambiguities. For example, specify colors, setting, foreground/background, and aspect ratio.",
    "code": "You are a professional code reviewer. Rephrase coding requests to specify exact language/version, input/output format, clarify required constraints, add edge/test cases, and request explanations or best practices in the output.",
    "writing": "You are a writing coach. Enhance the prompt for clarity, audience, and intent. Specify structure (intro, body, conclusion), desired tone and style, and any key points to address.",
    "summarization": "You are a summarization expert. Clarify the prompt to specify desired summary length, audience (expert/casual), style (bullet/paragraph), and points of focus (e.g., objective, highlights, key takeaways).",
}

_DEFAULT_PROMPT = (
    "You are a creative writing enhancer. Expand and clarify the prompt to include additional context, vivid detail, motivation, and relevant style cues for more engaging output."
)

_MODEL = "openai/gpt-oss-120b"


class PromptEnhancerAgent(BaseConversationalAgent):
    """Enhance user prompts using Groq models with task-specific system prompts."""

    def __init__(self, settings: Settings, memory_store: AgentMemoryStore) -> None:
        super().__init__(
            name="prompt_enhancer",
            description="Enhances user prompts according to the requested task category.",
            capabilities=[
                "prompt_optimization",
                "task_routing",
                "contextual_memory",
            ],
            memory_store=memory_store,
        )
        self._settings = settings
        self._groq = GroqSDKService(settings)

    async def improve_prompt(self, context: AgentContext, *, task: str, prompt: str) -> AgentRunResult:
        return await self.run(context, prompt=prompt, task=task)

    async def run(self, context: AgentContext, *, prompt: str, task: str | None = None, **_: Any) -> AgentRunResult:
        task_key = (task or "creative_writing").lower()
        system_prompt = _TASK_PROMPTS.get(task_key, _DEFAULT_PROMPT)
        memory = await self._load_history(context)

        history_messages = list(memory.chat_memory.messages)
        model_messages: list[BaseMessage] = [SystemMessage(content=system_prompt)]
        model_messages.extend(history_messages)
        model_messages.append(HumanMessage(content=_format_user_payload(prompt, task_key)))

        try:
            response_text = await self._invoke_groq(model_messages)
        except Exception as exc:  # pragma: no cover - network failure branch
            LOGGER.warning("Groq prompt enhancement failed, falling back to local heuristics: %s", exc)
            response_text = _fallback_enhancement(prompt, task_key)

        enhanced_payload = _coerce_json_payload(response_text, task_key)

        # Persist conversation history
        memory.chat_memory.add_user_message(prompt)
        memory.chat_memory.add_ai_message(enhanced_payload["enhanced_prompt"])
        await self._persist_history(context, memory.chat_memory)

        return AgentRunResult(
            output=enhanced_payload["enhanced_prompt"],
            data={
                "task": task_key,
                "enhanced_prompt": enhanced_payload["enhanced_prompt"],
                "guidance": enhanced_payload.get("guidance"),
                "raw_response": response_text,
            },
        )

    async def _invoke_groq(self, messages: list[Any]) -> str:
        payload = [
            _message_to_dict(message) for message in messages if isinstance(message, (SystemMessage, HumanMessage, AIMessage))
        ]
        response = await self._groq.create_chat_completion(model=_MODEL, messages=payload, temperature=0.2)
        choice = (response.choices or [None])[0]
        if not choice or not getattr(choice, "message", None):
            raise RuntimeError("Groq response did not include choices")
        content = choice.message.get("content") if isinstance(choice.message, dict) else getattr(choice.message, "content", None)
        if not content:
            raise RuntimeError("Groq response did not include text content")
        return str(content)


def _message_to_dict(message: Any) -> dict[str, Any]:
    if isinstance(message, SystemMessage):
        role = "system"
    elif isinstance(message, AIMessage):
        role = "assistant"
    else:
        role = "user"
    return {"role": role, "content": message.content}


def _format_user_payload(prompt: str, task: str) -> str:
    instructions = (
        "Rewrite the provided user prompt so it is maximally useful for the target task. "
        "Return a JSON object with the keys: 'task', 'enhanced_prompt', and 'guidance'. "
        "The 'enhanced_prompt' must be a single paragraph that can be sent directly to the model handling the task. "
        "The 'guidance' key should capture bullet-style guidance or reminders for the downstream agent."
    )
    return (
        f"Task: {task}\n"
        f"User Prompt: {prompt}\n"
        f"Instructions: {instructions}\n"
        "Respond with strict JSON only."
    )


def _coerce_json_payload(response_text: str, task: str) -> dict[str, Any]:
    try:
        payload = json.loads(response_text)
    except json.JSONDecodeError:
        LOGGER.debug("Falling back to heuristic parsing for prompt enhancer response")
        payload = {"enhanced_prompt": response_text.strip(), "guidance": None}
    payload.setdefault("task", task)
    payload.setdefault("enhanced_prompt", "")
    payload.setdefault("guidance", None)
    if not isinstance(payload.get("guidance"), (str, type(None))):
        payload["guidance"] = json.dumps(payload["guidance"])
    return payload


def _fallback_enhancement(prompt: str, task: str) -> str:
    if task == "maths":
        template = (
            "{prompt}\n\nPlease solve step-by-step, show all workings in LaTeX, state any assumptions, and explain the reasoning."
        )
    elif task == "image_generation":
        template = (
            "Describe: {prompt}. Include style, composition, lighting, mood, palette, and aspect ratio (16:9)."
        )
    elif task == "code":
        template = (
            "Provide a coding task in detail for the specified language, include edge cases, input/output examples, and testing guidance. Original request: {prompt}"
        )
    elif task == "writing":
        template = (
            "Outline the writing assignment with intro, body, and conclusion guidance, define tone and audience. Prompt: {prompt}"
        )
    elif task == "summarization":
        template = (
            "Summarize the following with explicit length and key points requirements. Include highlights and takeaways. Source: {prompt}"
        )
    else:
        template = (
            "Expand creatively on the idea with additional context, sensory detail, and motivation. Prompt: {prompt}"
        )
    enhanced_prompt = template.format(prompt=prompt)
    return json.dumps({"task": task, "enhanced_prompt": enhanced_prompt, "guidance": "Derived via heuristic."})


__all__ = ["PromptEnhancerAgent"]
