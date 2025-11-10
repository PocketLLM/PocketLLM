"""Image generation helper agent."""

from __future__ import annotations

from typing import Any

from langchain_classic.chains import LLMChain
from langchain_classic.prompts import PromptTemplate

from .base import AgentContext, AgentRunResult, BaseConversationalAgent
from .memory import AgentMemoryStore
from .retrieval import _DeterministicLLM

_IMAGE_PROMPT = PromptTemplate(
    input_variables=["concept"],
    template=(
        "You are an art director preparing prompts for diffusion models. Expand the concept with composition, lighting, "
        "camera settings, mood, palette, and artist references. Include explicit aspect ratio guidance.\n\nConcept:\n{concept}\n\nEnhanced Prompt:"
    ),
)


class ImageAgent(BaseConversationalAgent):
    """Prepares descriptive prompts for downstream image models."""

    def __init__(self, memory_store: AgentMemoryStore) -> None:
        super().__init__(
            name="image",
            description="Enhances concepts for image generation models with cinematic detail.",
            capabilities=["prompt_augmentation", "style_injection", "visual_guidance"],
            memory_store=memory_store,
        )
        self._chain = LLMChain(llm=_DeterministicLLM(), prompt=_IMAGE_PROMPT)

    async def run(self, context: AgentContext, *, prompt: str, **_: Any) -> AgentRunResult:
        memory = await self._load_history(context)
        enhanced = await self._chain.apredict(concept=prompt)
        memory.chat_memory.add_user_message(prompt)
        memory.chat_memory.add_ai_message(enhanced)
        await self._persist_history(context, memory.chat_memory)
        return AgentRunResult(output=enhanced, data={"enhanced_prompt": enhanced})


__all__ = ["ImageAgent"]
