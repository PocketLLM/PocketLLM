# Short-term memory

## Overview

Memory is a system that remembers information about previous interactions. For AI agents, memory is crucial because it lets them remember previous interactions, learn from feedback, and adapt to user preferences. As agents tackle more complex tasks with numerous user interactions, this capability becomes essential for both efficiency and user satisfaction.

Short term memory lets your application remember previous interactions within a single thread or conversation.

<Note>
  A thread organizes multiple interactions in a session, similar to the way email groups messages in a single conversation.
</Note>

Conversation history is the most common form of short-term memory. Long conversations pose a challenge to today's LLMs; a full history may not fit inside an LLM's context window, resulting in an context loss or errors.

Even if your model supports the full context length, most LLMs still perform poorly over long contexts. They get "distracted" by stale or off-topic content, all while suffering from slower response times and higher costs.

Chat models accept context using [messages](/oss/python/langchain/messages), which include instructions (a system message) and inputs (human messages). In chat applications, messages alternate between human inputs and model responses, resulting in a list of messages that grows longer over time. Because context windows are limited, many applications can benefit from using techniques to remove or "forget" stale information.

## Usage

To add short-term memory (thread-level persistence) to an agent, you need to specify a `checkpointer` when creating an agent.

<Info>
  LangChain's agent manages short-term memory as a part of your agent's state.

  By storing these in the graph's state, the agent can access the full context for a given conversation while maintaining separation between different threads.

  State is persisted to a database (or memory) using a checkpointer so the thread can be resumed at any time.

  Short-term memory updates when the agent is invoked or a step (like a tool call) is completed, and the state is read at the start of each step.
</Info>

```python  theme={null}
from langchain.agents import create_agent
from langgraph.checkpoint.memory import InMemorySaver  # [!code highlight]


agent = create_agent(
    "gpt-5",
    [get_user_info],
    checkpointer=InMemorySaver(),  # [!code highlight]
)

agent.invoke(
    {"messages": [{"role": "user", "content": "Hi! My name is Bob."}]},
    {"configurable": {"thread_id": "1"}},  # [!code highlight]
)
```

### In production

In production, use a checkpointer backed by a database:

```shell  theme={null}
pip install langgraph-checkpoint-postgres
```

```python  theme={null}
from langchain.agents import create_agent

from langgraph.checkpoint.postgres import PostgresSaver  # [!code highlight]


DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"
with PostgresSaver.from_conn_string(DB_URI) as checkpointer:
    checkpointer.setup() # auto create tables in PostgresSql
    agent = create_agent(
        "gpt-5",
        [get_user_info],
        checkpointer=checkpointer,  # [!code highlight]
    )
```

## Customizing agent memory

By default, agents use [`AgentState`](https://reference.langchain.com/python/langchain/agents/#langchain.agents.AgentState) to manage short term memory, specifically the conversation history via a `messages` key.

You can extend [`AgentState`](https://reference.langchain.com/python/langchain/agents/#langchain.agents.AgentState) to add additional fields. Custom state schemas are passed to [`create_agent`](https://reference.langchain.com/python/langchain/agents/#langchain.agents.create_agent) using the [`state_schema`](https://reference.langchain.com/python/langchain/middleware/#langchain.agents.middleware.AgentMiddleware.state_schema) parameter.

```python  theme={null}
from langchain.agents import create_agent, AgentState
from langgraph.checkpoint.memory import InMemorySaver


class CustomAgentState(AgentState):  # [!code highlight]
    user_id: str  # [!code highlight]
    preferences: dict  # [!code highlight]

agent = create_agent(
    "gpt-5",
    [get_user_info],
    state_schema=CustomAgentState,  # [!code highlight]
    checkpointer=InMemorySaver(),
)

# Custom state can be passed in invoke
result = agent.invoke(
    {
        "messages": [{"role": "user", "content": "Hello"}],
        "user_id": "user_123",  # [!code highlight]
        "preferences": {"theme": "dark"}  # [!code highlight]
    },
    {"configurable": {"thread_id": "1"}})
```

## Common patterns

With [short-term memory](#add-short-term-memory) enabled, long conversations can exceed the LLM's context window. Common solutions are:

<CardGroup cols={2}>
  <Card title="Trim messages" icon="scissors" href="#trim-messages" arrow>
    Remove first or last N messages (before calling LLM)
  </Card>

  <Card title="Delete messages" icon="trash" href="#delete-messages" arrow>
    Delete messages from LangGraph state permanently
  </Card>

  <Card title="Summarize messages" icon="layer-group" href="#summarize-messages" arrow>
    Summarize earlier messages in the history and replace them with a summary
  </Card>

  <Card title="Custom strategies" icon="gears">
    Custom strategies (e.g., message filtering, etc.)
  </Card>
</CardGroup>

This allows the agent to keep track of the conversation without exceeding the LLM's context window.

### Trim messages

Most LLMs have a maximum supported context window (denominated in tokens).

One way to decide when to truncate messages is to count the tokens in the message history and truncate whenever it approaches that limit. If you're using LangChain, you can use the trim messages utility and specify the number of tokens to keep from the list, as well as the `strategy` (e.g., keep the last `max_tokens`) to use for handling the boundary.

To trim message history in an agent, use the [`@before_model`](https://reference.langchain.com/python/langchain/middleware/#langchain.agents.middleware.before_model) middleware decorator:

```python  theme={null}
from langchain.messages import RemoveMessage
from langgraph.graph.message import REMOVE_ALL_MESSAGES
from langgraph.checkpoint.memory import InMemorySaver
from langchain.agents import create_agent, AgentState
from langchain.agents.middleware import before_model
from langgraph.runtime import Runtime
from langchain_core.runnables import RunnableConfig
from typing import Any


@before_model
def trim_messages(state: AgentState, runtime: Runtime) -> dict[str, Any] | None:
    """Keep only the last few messages to fit context window."""
    messages = state["messages"]

    if len(messages) <= 3:
        return None  # No changes needed

    first_msg = messages[0]
    recent_messages = messages[-3:] if len(messages) % 2 == 0 else messages[-4:]
    new_messages = [first_msg] + recent_messages

    return {
        "messages": [
            RemoveMessage(id=REMOVE_ALL_MESSAGES),
            *new_messages
        ]
    }

agent = create_agent(
    model,
    tools=tools,
    middleware=[trim_messages],
    checkpointer=InMemorySaver(),
)

config: RunnableConfig = {"configurable": {"thread_id": "1"}}

agent.invoke({"messages": "hi, my name is bob"}, config)
agent.invoke({"messages": "write a short poem about cats"}, config)
agent.invoke({"messages": "now do the same but for dogs"}, config)
final_response = agent.invoke({"messages": "what's my name?"}, config)

final_response["messages"][-1].pretty_print()
"""
================================== Ai Message ==================================

Your name is Bob. You told me that earlier.
If you'd like me to call you a nickname or use a different name, just say the word.
"""
```

### Delete messages

You can delete messages from the graph state to manage the message history.

This is useful when you want to remove specific messages or clear the entire message history.

To delete messages from the graph state, you can use the `RemoveMessage`.

For `RemoveMessage` to work, you need to use a state key with [`add_messages`](https://reference.langchain.com/python/langgraph/graphs/#langgraph.graph.message.add_messages) [reducer](/oss/python/langgraph/graph-api#reducers).

The default [`AgentState`](https://reference.langchain.com/python/langchain/agents/#langchain.agents.AgentState) provides this.

To remove specific messages:

```python  theme={null}
from langchain.messages import RemoveMessage  # [!code highlight]

def delete_messages(state):
    messages = state["messages"]
    if len(messages) > 2:
        # remove the earliest two messages
        return {"messages": [RemoveMessage(id=m.id) for m in messages[:2]]}  # [!code highlight]
```

To remove **all** messages:

```python  theme={null}
from langgraph.graph.message import REMOVE_ALL_MESSAGES  # [!code highlight]

def delete_messages(state):
    return {"messages": [RemoveMessage(id=REMOVE_ALL_MESSAGES)]}  # [!code highlight]
```

<Warning>
  When deleting messages, **make sure** that the resulting message history is valid. Check the limitations of the LLM provider you're using. For example:

  * Some providers expect message history to start with a `user` message
  * Most providers require `assistant` messages with tool calls to be followed by corresponding `tool` result messages.
</Warning>

```python  theme={null}
from langchain.messages import RemoveMessage
from langchain.agents import create_agent, AgentState
from langchain.agents.middleware import after_model
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.runtime import Runtime
from langchain_core.runnables import RunnableConfig


@after_model
def delete_old_messages(state: AgentState, runtime: Runtime) -> dict | None:
    """Remove old messages to keep conversation manageable."""
    messages = state["messages"]
    if len(messages) > 2:
        # remove the earliest two messages
        return {"messages": [RemoveMessage(id=m.id) for m in messages[:2]]}
    return None


agent = create_agent(
    "gpt-5-nano",
    tools=[],
    system_prompt="Please be concise and to the point.",
    middleware=[delete_old_messages],
    checkpointer=InMemorySaver(),
)

config: RunnableConfig = {"configurable": {"thread_id": "1"}}

for event in agent.stream(
    {"messages": [{"role": "user", "content": "hi! I'm bob"}]},
    config,
    stream_mode="values",
):
    print([(message.type, message.content) for message in event["messages"]])

for event in agent.stream(
    {"messages": [{"role": "user", "content": "what's my name?"}]},
    config,
    stream_mode="values",
):
    print([(message.type, message.content) for message in event["messages"]])
```

```
[('human', "hi! I'm bob")]
[('human', "hi! I'm bob"), ('ai', 'Hi Bob! Nice to meet you. How can I help you today? I can answer questions, brainstorm ideas, draft text, explain things, or help with code.')]
[('human', "hi! I'm bob"), ('ai', 'Hi Bob! Nice to meet you. How can I help you today? I can answer questions, brainstorm ideas, draft text, explain things, or help with code.'), ('human', "what's my name?")]
[('human', "hi! I'm bob"), ('ai', 'Hi Bob! Nice to meet you. How can I help you today? I can answer questions, brainstorm ideas, draft text, explain things, or help with code.'), ('human', "what's my name?"), ('ai', 'Your name is Bob. How can I help you today, Bob?')]
[('human', "what's my name?"), ('ai', 'Your name is Bob. How can I help you today, Bob?')]
```

### Summarize messages

The problem with trimming or removing messages, as shown above, is that you may lose information from culling of the message queue.
Because of this, some applications benefit from a more sophisticated approach of summarizing the message history using a chat model.

<img src="https://mintcdn.com/langchain-5e9cc07a/ybiAaBfoBvFquMDz/oss/images/summary.png?fit=max&auto=format&n=ybiAaBfoBvFquMDz&q=85&s=c8ed3facdccd4ef5c7e52902c72ba938" alt="" data-og-width="609" width="609" data-og-height="242" height="242" data-path="oss/images/summary.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/langchain-5e9cc07a/ybiAaBfoBvFquMDz/oss/images/summary.png?w=280&fit=max&auto=format&n=ybiAaBfoBvFquMDz&q=85&s=4208b9b0cc9f459f3dc4e5219918471b 280w, https://mintcdn.com/langchain-5e9cc07a/ybiAaBfoBvFquMDz/oss/images/summary.png?w=560&fit=max&auto=format&n=ybiAaBfoBvFquMDz&q=85&s=7acb77c081545f57042368f4e9d0c8cb 560w, https://mintcdn.com/langchain-5e9cc07a/ybiAaBfoBvFquMDz/oss/images/summary.png?w=840&fit=max&auto=format&n=ybiAaBfoBvFquMDz&q=85&s=2fcfdb0c481d2e1d361e76db763a41e5 840w, https://mintcdn.com/langchain-5e9cc07a/ybiAaBfoBvFquMDz/oss/images/summary.png?w=1100&fit=max&auto=format&n=ybiAaBfoBvFquMDz&q=85&s=4abdac693a562788aa0db8681bef8ea7 1100w, https://mintcdn.com/langchain-5e9cc07a/ybiAaBfoBvFquMDz/oss/images/summary.png?w=1650&fit=max&auto=format&n=ybiAaBfoBvFquMDz&q=85&s=40acfefa91dcb11b247a6e4a7705f22b 1650w, https://mintcdn.com/langchain-5e9cc07a/ybiAaBfoBvFquMDz/oss/images/summary.png?w=2500&fit=max&auto=format&n=ybiAaBfoBvFquMDz&q=85&s=8d765aaf7551e8b0fc2720de7d2ac2a8 2500w" />

To summarize message history in an agent, use the built-in [`SummarizationMiddleware`](/oss/python/langchain/middleware#summarization):

```python  theme={null}
from langchain.agents import create_agent
from langchain.agents.middleware import SummarizationMiddleware
from langgraph.checkpoint.memory import InMemorySaver
from langchain_core.runnables import RunnableConfig


checkpointer = InMemorySaver()

agent = create_agent(
    model="gpt-4o",
    tools=[],
    middleware=[
        SummarizationMiddleware(
            model="gpt-4o-mini",
            max_tokens_before_summary=4000,  # Trigger summarization at 4000 tokens
            messages_to_keep=20,  # Keep last 20 messages after summary
        )
    ],
    checkpointer=checkpointer,
)

config: RunnableConfig = {"configurable": {"thread_id": "1"}}
agent.invoke({"messages": "hi, my name is bob"}, config)
agent.invoke({"messages": "write a short poem about cats"}, config)
agent.invoke({"messages": "now do the same but for dogs"}, config)
final_response = agent.invoke({"messages": "what's my name?"}, config)

final_response["messages"][-1].pretty_print()
"""
================================== Ai Message ==================================

Your name is Bob!
"""
```

See [`SummarizationMiddleware`](/oss/python/langchain/middleware#summarization) for more configuration options.

## Access memory

You can access and modify the short-term memory (state) of an agent in several ways:

### Tools

#### Read short-term memory in a tool

Access short term memory (state) in a tool using the `ToolRuntime` parameter.

The `tool_runtime` parameter is hidden from the tool signature (so the model doesn't see it), but the tool can access the state through it.

```python  theme={null}
from langchain.agents import create_agent, AgentState
from langchain.tools import tool, ToolRuntime


class CustomState(AgentState):
    user_id: str

@tool
def get_user_info(
    runtime: ToolRuntime
) -> str:
    """Look up user info."""
    user_id = runtime.state["user_id"]
    return "User is John Smith" if user_id == "user_123" else "Unknown user"

agent = create_agent(
    model="gpt-5-nano",
    tools=[get_user_info],
    state_schema=CustomState,
)

result = agent.invoke({
    "messages": "look up user information",
    "user_id": "user_123"
})
print(result["messages"][-1].content)
# > User is John Smith.
```

#### Write short-term memory from tools

To modify the agent's short-term memory (state) during execution, you can return state updates directly from the tools.

This is useful for persisting intermediate results or making information accessible to subsequent tools or prompts.

```python  theme={null}
from langchain.tools import tool, ToolRuntime
from langchain_core.runnables import RunnableConfig
from langchain.messages import ToolMessage
from langchain.agents import create_agent, AgentState
from langgraph.types import Command
from pydantic import BaseModel


class CustomState(AgentState):  # [!code highlight]
    user_name: str

class CustomContext(BaseModel):
    user_id: str

@tool
def update_user_info(
    runtime: ToolRuntime[CustomContext, CustomState],
) -> Command:
    """Look up and update user info."""
    user_id = runtime.context.user_id 
    name = "John Smith" if user_id == "user_123" else "Unknown user"
    return Command(update={  # [!code highlight]
        "user_name": name,
        # update the message history
        "messages": [
            ToolMessage(
                "Successfully looked up user information",
                tool_call_id=runtime.tool_call_id
            )
        ]
    })

@tool
def greet(
    runtime: ToolRuntime[CustomContext, CustomState]
) -> str:
    """Use this to greet the user once you found their info."""
    user_name = runtime.state["user_name"]
    return f"Hello {user_name}!"

agent = create_agent(
    model="gpt-5-nano",
    tools=[update_user_info, greet],
    state_schema=CustomState, # [!code highlight]
    context_schema=CustomContext,  
)

agent.invoke(
    {"messages": [{"role": "user", "content": "greet the user"}]},
    context=CustomContext(user_id="user_123"),
)
```

### Prompt

Access short term memory (state) in middleware to create dynamic prompts based on conversation history or custom state fields.

```python  theme={null}
from langchain.agents import create_agent
from typing import TypedDict
from langchain.agents.middleware import dynamic_prompt, ModelRequest


class CustomContext(TypedDict):
    user_name: str


def get_weather(city: str) -> str:
    """Get the weather in a city."""
    return f"The weather in {city} is always sunny!"


@dynamic_prompt
def dynamic_system_prompt(request: ModelRequest) -> str:
    user_name = request.runtime.context["user_name"]
    system_prompt = f"You are a helpful assistant. Address the user as {user_name}."
    return system_prompt


agent = create_agent(
    model="gpt-5-nano",
    tools=[get_weather],
    middleware=[dynamic_system_prompt],
    context_schema=CustomContext,
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "What is the weather in SF?"}]},
    context=CustomContext(user_name="John Smith"),
)
for msg in result["messages"]:
    msg.pretty_print()

```

```shell title="Output" theme={null}
================================ Human Message =================================

What is the weather in SF?
================================== Ai Message ==================================
Tool Calls:
  get_weather (call_WFQlOGn4b2yoJrv7cih342FG)
 Call ID: call_WFQlOGn4b2yoJrv7cih342FG
  Args:
    city: San Francisco
================================= Tool Message =================================
Name: get_weather

The weather in San Francisco is always sunny!
================================== Ai Message ==================================

Hi John Smith, the weather in San Francisco is always sunny!
```

### Before model

Access short term memory (state) in [`@before_model`](https://reference.langchain.com/python/langchain/middleware/#langchain.agents.middleware.before_model) middleware to process messages before model calls.

```mermaid  theme={null}
%%{
    init: {
        "fontFamily": "monospace",
        "flowchart": {
        "curve": "basis"
        },
        "themeVariables": {"edgeLabelBackground": "transparent"}
    }
}%%
graph TD
    S(["\_\_start\_\_"])
    PRE(before_model)
    MODEL(model)
    TOOLS(tools)
    END(["\_\_end\_\_"])
    S --> PRE
    PRE --> MODEL
    MODEL -.-> TOOLS
    MODEL -.-> END
    TOOLS --> PRE
    classDef blueHighlight fill:#0a1c25,stroke:#0a455f,color:#bae6fd;
    class S blueHighlight;
    class END blueHighlight;
```

```python  theme={null}
from langchain.messages import RemoveMessage
from langgraph.graph.message import REMOVE_ALL_MESSAGES
from langgraph.checkpoint.memory import InMemorySaver
from langchain.agents import create_agent, AgentState
from langchain.agents.middleware import before_model
from langgraph.runtime import Runtime
from typing import Any


@before_model
def trim_messages(state: AgentState, runtime: Runtime) -> dict[str, Any] | None:
    """Keep only the last few messages to fit context window."""
    messages = state["messages"]

    if len(messages) <= 3:
        return None  # No changes needed

    first_msg = messages[0]
    recent_messages = messages[-3:] if len(messages) % 2 == 0 else messages[-4:]
    new_messages = [first_msg] + recent_messages

    return {
        "messages": [
            RemoveMessage(id=REMOVE_ALL_MESSAGES),
            *new_messages
        ]
    }

agent = create_agent(
    model,
    tools=tools,
    middleware=[trim_messages]
)

config: RunnableConfig = {"configurable": {"thread_id": "1"}}

agent.invoke({"messages": "hi, my name is bob"}, config)
agent.invoke({"messages": "write a short poem about cats"}, config)
agent.invoke({"messages": "now do the same but for dogs"}, config)
final_response = agent.invoke({"messages": "what's my name?"}, config)

final_response["messages"][-1].pretty_print()
"""
================================== Ai Message ==================================

Your name is Bob. You told me that earlier.
If you'd like me to call you a nickname or use a different name, just say the word.
"""
```

### After model

Access short term memory (state) in [`@after_model`](https://reference.langchain.com/python/langchain/middleware/#langchain.agents.middleware.after_model) middleware to process messages after model calls.

```mermaid  theme={null}
%%{
    init: {
        "fontFamily": "monospace",
        "flowchart": {
        "curve": "basis"
        },
        "themeVariables": {"edgeLabelBackground": "transparent"}
    }
}%%
graph TD
    S(["\_\_start\_\_"])
    MODEL(model)
    POST(after_model)
    TOOLS(tools)
    END(["\_\_end\_\_"])
    S --> MODEL
    MODEL --> POST
    POST -.-> END
    POST -.-> TOOLS
    TOOLS --> MODEL
    classDef blueHighlight fill:#0a1c25,stroke:#0a455f,color:#bae6fd;
    class S blueHighlight;
    class END blueHighlight;
    class POST greenHighlight;
```

```python  theme={null}
from langchain.messages import RemoveMessage
from langgraph.checkpoint.memory import InMemorySaver
from langchain.agents import create_agent, AgentState
from langchain.agents.middleware import after_model
from langgraph.runtime import Runtime


@after_model
def validate_response(state: AgentState, runtime: Runtime) -> dict | None:
    """Remove messages containing sensitive words."""
    STOP_WORDS = ["password", "secret"]
    last_message = state["messages"][-1]
    if any(word in last_message.content for word in STOP_WORDS):
        return {"messages": [RemoveMessage(id=last_message.id)]}
    return None

agent = create_agent(
    model="gpt-5-nano",
    tools=[],
    middleware=[validate_response],
    checkpointer=InMemorySaver(),
)
```

***

<Callout icon="pen-to-square" iconType="regular">
  [Edit the source of this page on GitHub.](https://github.com/langchain-ai/docs/edit/main/src/oss/langchain/short-term-memory.mdx)
</Callout>

<Tip icon="terminal" iconType="regular">
  [Connect these docs programmatically](/use-these-docs) to Claude, VSCode, and more via MCP for    real-time answers.
</Tip>

# Streaming

LangChain implements a streaming system to surface real-time updates.

Streaming is crucial for enhancing the responsiveness of applications built on LLMs. By displaying output progressively, even before a complete response is ready, streaming significantly improves user experience (UX), particularly when dealing with the latency of LLMs.

## Overview

LangChain's streaming system lets you surface live feedback from agent runs to your application.

What's possible with LangChain streaming:

* <Icon icon="brain" size={16} /> [**Stream agent progress**](#agent-progress) — get state updates after each agent step.
* <Icon icon="square-binary" size={16} /> [**Stream LLM tokens**](#llm-tokens) — stream language model tokens as they're generated.
* <Icon icon="table" size={16} /> [**Stream custom updates**](#custom-updates) — emit user-defined signals (e.g., `"Fetched 10/100 records"`).
* <Icon icon="layer-plus" size={16} /> [**Stream multiple modes**](#stream-multiple-modes) — choose from `updates` (agent progress), `messages` (LLM tokens + metadata), or `custom` (arbitrary user data).

## Agent progress

To stream agent progress, use the [`stream`](https://reference.langchain.com/python/langgraph/graphs/#langgraph.graph.state.CompiledStateGraph.stream) or [`astream`](https://reference.langchain.com/python/langgraph/graphs/#langgraph.graph.state.CompiledStateGraph.astream) methods with `stream_mode="updates"`. This emits an event after every agent step.

For example, if you have an agent that calls a tool once, you should see the following updates:

* **LLM node**: [`AIMessage`](https://reference.langchain.com/python/langchain/messages/#langchain.messages.AIMessage) with tool call requests
* **Tool node**: [`ToolMessage`](https://reference.langchain.com/python/langchain/messages/#langchain.messages.ToolMessage) with execution result
* **LLM node**: Final AI response

```python title="Streaming agent progress" theme={null}
from langchain.agents import create_agent


def get_weather(city: str) -> str:
    """Get weather for a given city."""

    return f"It's always sunny in {city}!"

agent = create_agent(
    model="gpt-5-nano",
    tools=[get_weather],
)
for chunk in agent.stream(  # [!code highlight]
    {"messages": [{"role": "user", "content": "What is the weather in SF?"}]},
    stream_mode="updates",
):
    for step, data in chunk.items():
        print(f"step: {step}")
        print(f"content: {data['messages'][-1].content_blocks}")
```

```shell title="Output" theme={null}
step: model
content: [{'type': 'tool_call', 'name': 'get_weather', 'args': {'city': 'San Francisco'}, 'id': 'call_OW2NYNsNSKhRZpjW0wm2Aszd'}]

step: tools
content: [{'type': 'text', 'text': "It's always sunny in San Francisco!"}]

step: model
content: [{'type': 'text', 'text': 'It's always sunny in San Francisco!'}]
```

## LLM tokens

To stream tokens as they are produced by the LLM, use `stream_mode="messages"`. Below you can see the output of the agent streaming tool calls and the final response.

```python title="Streaming LLM tokens" theme={null}
from langchain.agents import create_agent


def get_weather(city: str) -> str:
    """Get weather for a given city."""

    return f"It's always sunny in {city}!"

agent = create_agent(
    model="gpt-5-nano",
    tools=[get_weather],
)
for token, metadata in agent.stream(  # [!code highlight]
    {"messages": [{"role": "user", "content": "What is the weather in SF?"}]},
    stream_mode="messages",
):
    print(f"node: {metadata['langgraph_node']}")
    print(f"content: {token.content_blocks}")
    print("\n")
```

```shell title="Output" expandable theme={null}
node: model
content: [{'type': 'tool_call_chunk', 'id': 'call_vbCyBcP8VuneUzyYlSBZZsVa', 'name': 'get_weather', 'args': '', 'index': 0}]


node: model
content: [{'type': 'tool_call_chunk', 'id': None, 'name': None, 'args': '{"', 'index': 0}]


node: model
content: [{'type': 'tool_call_chunk', 'id': None, 'name': None, 'args': 'city', 'index': 0}]


node: model
content: [{'type': 'tool_call_chunk', 'id': None, 'name': None, 'args': '":"', 'index': 0}]


node: model
content: [{'type': 'tool_call_chunk', 'id': None, 'name': None, 'args': 'San', 'index': 0}]


node: model
content: [{'type': 'tool_call_chunk', 'id': None, 'name': None, 'args': ' Francisco', 'index': 0}]


node: model
content: [{'type': 'tool_call_chunk', 'id': None, 'name': None, 'args': '"}', 'index': 0}]


node: model
content: []


node: tools
content: [{'type': 'text', 'text': "It's always sunny in San Francisco!"}]


node: model
content: []


node: model
content: [{'type': 'text', 'text': 'Here'}]


node: model
content: [{'type': 'text', 'text': ''s'}]


node: model
content: [{'type': 'text', 'text': ' what'}]


node: model
content: [{'type': 'text', 'text': ' I'}]


node: model
content: [{'type': 'text', 'text': ' got'}]


node: model
content: [{'type': 'text', 'text': ':'}]


node: model
content: [{'type': 'text', 'text': ' "'}]


node: model
content: [{'type': 'text', 'text': "It's"}]


node: model
content: [{'type': 'text', 'text': ' always'}]


node: model
content: [{'type': 'text', 'text': ' sunny'}]


node: model
content: [{'type': 'text', 'text': ' in'}]


node: model
content: [{'type': 'text', 'text': ' San'}]


node: model
content: [{'type': 'text', 'text': ' Francisco'}]


node: model
content: [{'type': 'text', 'text': '!"\n\n'}]
```

## Custom updates

To stream updates from tools as they are executed, you can use [`get_stream_writer`](https://reference.langchain.com/python/langgraph/config/#langgraph.config.get_stream_writer).

```python title="Streaming custom updates" theme={null}
from langchain.agents import create_agent
from langgraph.config import get_stream_writer  # [!code highlight]


def get_weather(city: str) -> str:
    """Get weather for a given city."""
    writer = get_stream_writer()  # [!code highlight]
    # stream any arbitrary data
    writer(f"Looking up data for city: {city}")
    writer(f"Acquired data for city: {city}")
    return f"It's always sunny in {city}!"

agent = create_agent(
    model="claude-sonnet-4-5-20250929",
    tools=[get_weather],
)

for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "What is the weather in SF?"}]},
    stream_mode="custom"  # [!code highlight]
):
    print(chunk)
```

```shell title="Output" theme={null}
Looking up data for city: San Francisco
Acquired data for city: San Francisco
```

<Note>
  If you add [`get_stream_writer`](https://reference.langchain.com/python/langgraph/config/#langgraph.config.get_stream_writer) inside your tool, you won't be able to invoke the tool outside of a LangGraph execution context.
</Note>

## Stream multiple modes

You can specify multiple streaming modes by passing stream mode as a list: `stream_mode=["updates", "custom"]`:

```python title="Streaming multiple modes" theme={null}
from langchain.agents import create_agent
from langgraph.config import get_stream_writer


def get_weather(city: str) -> str:
    """Get weather for a given city."""
    writer = get_stream_writer()
    writer(f"Looking up data for city: {city}")
    writer(f"Acquired data for city: {city}")
    return f"It's always sunny in {city}!"

agent = create_agent(
    model="gpt-5-nano",
    tools=[get_weather],
)

for stream_mode, chunk in agent.stream(  # [!code highlight]
    {"messages": [{"role": "user", "content": "What is the weather in SF?"}]},
    stream_mode=["updates", "custom"]
):
    print(f"stream_mode: {stream_mode}")
    print(f"content: {chunk}")
    print("\n")
```

```shell title="Output" theme={null}
stream_mode: updates
content: {'model': {'messages': [AIMessage(content='', response_metadata={'token_usage': {'completion_tokens': 280, 'prompt_tokens': 132, 'total_tokens': 412, 'completion_tokens_details': {'accepted_prediction_tokens': 0, 'audio_tokens': 0, 'reasoning_tokens': 256, 'rejected_prediction_tokens': 0}, 'prompt_tokens_details': {'audio_tokens': 0, 'cached_tokens': 0}}, 'model_provider': 'openai', 'model_name': 'gpt-5-nano-2025-08-07', 'system_fingerprint': None, 'id': 'chatcmpl-C9tlgBzGEbedGYxZ0rTCz5F7OXpL7', 'service_tier': 'default', 'finish_reason': 'tool_calls', 'logprobs': None}, id='lc_run--480c07cb-e405-4411-aa7f-0520fddeed66-0', tool_calls=[{'name': 'get_weather', 'args': {'city': 'San Francisco'}, 'id': 'call_KTNQIftMrl9vgNwEfAJMVu7r', 'type': 'tool_call'}], usage_metadata={'input_tokens': 132, 'output_tokens': 280, 'total_tokens': 412, 'input_token_details': {'audio': 0, 'cache_read': 0}, 'output_token_details': {'audio': 0, 'reasoning': 256}})]}}


stream_mode: custom
content: Looking up data for city: San Francisco


stream_mode: custom
content: Acquired data for city: San Francisco


stream_mode: updates
content: {'tools': {'messages': [ToolMessage(content="It's always sunny in San Francisco!", name='get_weather', tool_call_id='call_KTNQIftMrl9vgNwEfAJMVu7r')]}}


stream_mode: updates
content: {'model': {'messages': [AIMessage(content='San Francisco weather: It's always sunny in San Francisco!\n\n', response_metadata={'token_usage': {'completion_tokens': 764, 'prompt_tokens': 168, 'total_tokens': 932, 'completion_tokens_details': {'accepted_prediction_tokens': 0, 'audio_tokens': 0, 'reasoning_tokens': 704, 'rejected_prediction_tokens': 0}, 'prompt_tokens_details': {'audio_tokens': 0, 'cached_tokens': 0}}, 'model_provider': 'openai', 'model_name': 'gpt-5-nano-2025-08-07', 'system_fingerprint': None, 'id': 'chatcmpl-C9tljDFVki1e1haCyikBptAuXuHYG', 'service_tier': 'default', 'finish_reason': 'stop', 'logprobs': None}, id='lc_run--acbc740a-18fe-4a14-8619-da92a0d0ee90-0', usage_metadata={'input_tokens': 168, 'output_tokens': 764, 'total_tokens': 932, 'input_token_details': {'audio': 0, 'cache_read': 0}, 'output_token_details': {'audio': 0, 'reasoning': 704}})]}}
```

## Disable streaming

In some applications you might need to disable streaming of individual tokens for a given model.

This is useful in [multi-agent](/oss/python/langchain/multi-agent) systems to control which agents stream their output.

See the [Models](/oss/python/langchain/models#disable-streaming) guide to learn how to disable streaming.

***

<Callout icon="pen-to-square" iconType="regular">
  [Edit the source of this page on GitHub.](https://github.com/langchain-ai/docs/edit/main/src/oss/langchain/streaming.mdx)
</Callout>

<Tip icon="terminal" iconType="regular">
  [Connect these docs programmatically](/use-these-docs) to Claude, VSCode, and more via MCP for    real-time answers.
</Tip>
# Memory

AI applications need [memory](/oss/python/concepts/memory) to share context across multiple interactions. In LangGraph, you can add two types of memory:

* [Add short-term memory](#add-short-term-memory) as a part of your agent's [state](/oss/python/langgraph/graph-api#state) to enable multi-turn conversations.
* [Add long-term memory](#add-long-term-memory) to store user-specific or application-level data across sessions.

## Add short-term memory

**Short-term** memory (thread-level [persistence](/oss/python/langgraph/persistence)) enables agents to track multi-turn conversations. To add short-term memory:

```python  theme={null}
from langgraph.checkpoint.memory import InMemorySaver  # [!code highlight]
from langgraph.graph import StateGraph

checkpointer = InMemorySaver()  # [!code highlight]

builder = StateGraph(...)
graph = builder.compile(checkpointer=checkpointer)  # [!code highlight]

graph.invoke(
    {"messages": [{"role": "user", "content": "hi! i am Bob"}]},
    {"configurable": {"thread_id": "1"}},  # [!code highlight]
)
```

### Use in production

In production, use a checkpointer backed by a database:

```python  theme={null}
from langgraph.checkpoint.postgres import PostgresSaver

DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"
with PostgresSaver.from_conn_string(DB_URI) as checkpointer:  # [!code highlight]
    builder = StateGraph(...)
    graph = builder.compile(checkpointer=checkpointer)  # [!code highlight]
```

<Accordion title="Example: using Postgres checkpointer">
  ```
  pip install -U "psycopg[binary,pool]" langgraph langgraph-checkpoint-postgres
  ```

  <Tip>
    You need to call `checkpointer.setup()` the first time you're using Postgres checkpointer
  </Tip>

  <Tabs>
    <Tab title="Sync">
      ```python  theme={null}
      from langchain.chat_models import init_chat_model
      from langgraph.graph import StateGraph, MessagesState, START
      from langgraph.checkpoint.postgres import PostgresSaver  # [!code highlight]

      model = init_chat_model(model="claude-haiku-4-5-20251001")

      DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"
      with PostgresSaver.from_conn_string(DB_URI) as checkpointer:  # [!code highlight]
          # checkpointer.setup()

          def call_model(state: MessagesState):
              response = model.invoke(state["messages"])
              return {"messages": response}

          builder = StateGraph(MessagesState)
          builder.add_node(call_model)
          builder.add_edge(START, "call_model")

          graph = builder.compile(checkpointer=checkpointer)  # [!code highlight]

          config = {
              "configurable": {
                  "thread_id": "1"  # [!code highlight]
              }
          }

          for chunk in graph.stream(
              {"messages": [{"role": "user", "content": "hi! I'm bob"}]},
              config,  # [!code highlight]
              stream_mode="values"
          ):
              chunk["messages"][-1].pretty_print()

          for chunk in graph.stream(
              {"messages": [{"role": "user", "content": "what's my name?"}]},
              config,  # [!code highlight]
              stream_mode="values"
          ):
              chunk["messages"][-1].pretty_print()
      ```
    </Tab>

    <Tab title="Async">
      ```python  theme={null}
      from langchain.chat_models import init_chat_model
      from langgraph.graph import StateGraph, MessagesState, START
      from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver  # [!code highlight]

      model = init_chat_model(model="claude-haiku-4-5-20251001")

      DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"
      async with AsyncPostgresSaver.from_conn_string(DB_URI) as checkpointer:  # [!code highlight]
          # await checkpointer.setup()

          async def call_model(state: MessagesState):
              response = await model.ainvoke(state["messages"])
              return {"messages": response}

          builder = StateGraph(MessagesState)
          builder.add_node(call_model)
          builder.add_edge(START, "call_model")

          graph = builder.compile(checkpointer=checkpointer)  # [!code highlight]

          config = {
              "configurable": {
                  "thread_id": "1"  # [!code highlight]
              }
          }

          async for chunk in graph.astream(
              {"messages": [{"role": "user", "content": "hi! I'm bob"}]},
              config,  # [!code highlight]
              stream_mode="values"
          ):
              chunk["messages"][-1].pretty_print()

          async for chunk in graph.astream(
              {"messages": [{"role": "user", "content": "what's my name?"}]},
              config,  # [!code highlight]
              stream_mode="values"
          ):
              chunk["messages"][-1].pretty_print()
      ```
    </Tab>
  </Tabs>
</Accordion>

<Accordion title="Example: using [MongoDB](https://pypi.org/project/langgraph-checkpoint-mongodb/) checkpointer">
  ```
  pip install -U pymongo langgraph langgraph-checkpoint-mongodb
  ```

  <Note>
    **Setup**
    To use the MongoDB checkpointer, you will need a MongoDB cluster. Follow [this guide](https://www.mongodb.com/docs/guides/atlas/cluster/) to create a cluster if you don't already have one.
  </Note>

  <Tabs>
    <Tab title="Sync">
      ```python  theme={null}
      from langchain.chat_models import init_chat_model
      from langgraph.graph import StateGraph, MessagesState, START
      from langgraph.checkpoint.mongodb import MongoDBSaver  # [!code highlight]

      model = init_chat_model(model="claude-haiku-4-5-20251001")

      DB_URI = "localhost:27017"
      with MongoDBSaver.from_conn_string(DB_URI) as checkpointer:  # [!code highlight]

          def call_model(state: MessagesState):
              response = model.invoke(state["messages"])
              return {"messages": response}

          builder = StateGraph(MessagesState)
          builder.add_node(call_model)
          builder.add_edge(START, "call_model")

          graph = builder.compile(checkpointer=checkpointer)  # [!code highlight]

          config = {
              "configurable": {
                  "thread_id": "1"  # [!code highlight]
              }
          }

          for chunk in graph.stream(
              {"messages": [{"role": "user", "content": "hi! I'm bob"}]},
              config,  # [!code highlight]
              stream_mode="values"
          ):
              chunk["messages"][-1].pretty_print()

          for chunk in graph.stream(
              {"messages": [{"role": "user", "content": "what's my name?"}]},
              config,  # [!code highlight]
              stream_mode="values"
          ):
              chunk["messages"][-1].pretty_print()
      ```
    </Tab>

    <Tab title="Async">
      ```python  theme={null}
      from langchain.chat_models import init_chat_model
      from langgraph.graph import StateGraph, MessagesState, START
      from langgraph.checkpoint.mongodb.aio import AsyncMongoDBSaver  # [!code highlight]

      model = init_chat_model(model="claude-haiku-4-5-20251001")

      DB_URI = "localhost:27017"
      async with AsyncMongoDBSaver.from_conn_string(DB_URI) as checkpointer:  # [!code highlight]

          async def call_model(state: MessagesState):
              response = await model.ainvoke(state["messages"])
              return {"messages": response}

          builder = StateGraph(MessagesState)
          builder.add_node(call_model)
          builder.add_edge(START, "call_model")

          graph = builder.compile(checkpointer=checkpointer)  # [!code highlight]

          config = {
              "configurable": {
                  "thread_id": "1"  # [!code highlight]
              }
          }

          async for chunk in graph.astream(
              {"messages": [{"role": "user", "content": "hi! I'm bob"}]},
              config,  # [!code highlight]
              stream_mode="values"
          ):
              chunk["messages"][-1].pretty_print()

          async for chunk in graph.astream(
              {"messages": [{"role": "user", "content": "what's my name?"}]},
              config,  # [!code highlight]
              stream_mode="values"
          ):
              chunk["messages"][-1].pretty_print()
      ```
    </Tab>
  </Tabs>
</Accordion>

<Accordion title="Example: using [Redis](https://pypi.org/project/langgraph-checkpoint-redis/) checkpointer">
  ```
  pip install -U langgraph langgraph-checkpoint-redis
  ```

  <Tip>
    You need to call `checkpointer.setup()` the first time you're using Redis checkpointer
  </Tip>

  <Tabs>
    <Tab title="Sync">
      ```python  theme={null}
      from langchain.chat_models import init_chat_model
      from langgraph.graph import StateGraph, MessagesState, START
      from langgraph.checkpoint.redis import RedisSaver  # [!code highlight]

      model = init_chat_model(model="claude-haiku-4-5-20251001")

      DB_URI = "redis://localhost:6379"
      with RedisSaver.from_conn_string(DB_URI) as checkpointer:  # [!code highlight]
          # checkpointer.setup()

          def call_model(state: MessagesState):
              response = model.invoke(state["messages"])
              return {"messages": response}

          builder = StateGraph(MessagesState)
          builder.add_node(call_model)
          builder.add_edge(START, "call_model")

          graph = builder.compile(checkpointer=checkpointer)  # [!code highlight]

          config = {
              "configurable": {
                  "thread_id": "1"  # [!code highlight]
              }
          }

          for chunk in graph.stream(
              {"messages": [{"role": "user", "content": "hi! I'm bob"}]},
              config,  # [!code highlight]
              stream_mode="values"
          ):
              chunk["messages"][-1].pretty_print()

          for chunk in graph.stream(
              {"messages": [{"role": "user", "content": "what's my name?"}]},
              config,  # [!code highlight]
              stream_mode="values"
          ):
              chunk["messages"][-1].pretty_print()
      ```
    </Tab>

    <Tab title="Async">
      ```python  theme={null}
      from langchain.chat_models import init_chat_model
      from langgraph.graph import StateGraph, MessagesState, START
      from langgraph.checkpoint.redis.aio import AsyncRedisSaver  # [!code highlight]

      model = init_chat_model(model="claude-haiku-4-5-20251001")

      DB_URI = "redis://localhost:6379"
      async with AsyncRedisSaver.from_conn_string(DB_URI) as checkpointer:  # [!code highlight]
          # await checkpointer.asetup()

          async def call_model(state: MessagesState):
              response = await model.ainvoke(state["messages"])
              return {"messages": response}

          builder = StateGraph(MessagesState)
          builder.add_node(call_model)
          builder.add_edge(START, "call_model")

          graph = builder.compile(checkpointer=checkpointer)  # [!code highlight]

          config = {
              "configurable": {
                  "thread_id": "1"  # [!code highlight]
              }
          }

          async for chunk in graph.astream(
              {"messages": [{"role": "user", "content": "hi! I'm bob"}]},
              config,  # [!code highlight]
              stream_mode="values"
          ):
              chunk["messages"][-1].pretty_print()

          async for chunk in graph.astream(
              {"messages": [{"role": "user", "content": "what's my name?"}]},
              config,  # [!code highlight]
              stream_mode="values"
          ):
              chunk["messages"][-1].pretty_print()
      ```
    </Tab>
  </Tabs>
</Accordion>

### Use in subgraphs

If your graph contains [subgraphs](/oss/python/langgraph/use-subgraphs), you only need to provide the checkpointer when compiling the parent graph. LangGraph will automatically propagate the checkpointer to the child subgraphs.

```python  theme={null}
from langgraph.graph import START, StateGraph
from langgraph.checkpoint.memory import InMemorySaver
from typing import TypedDict

class State(TypedDict):
    foo: str

# Subgraph

def subgraph_node_1(state: State):
    return {"foo": state["foo"] + "bar"}

subgraph_builder = StateGraph(State)
subgraph_builder.add_node(subgraph_node_1)
subgraph_builder.add_edge(START, "subgraph_node_1")
subgraph = subgraph_builder.compile()  # [!code highlight]

# Parent graph

builder = StateGraph(State)
builder.add_node("node_1", subgraph)  # [!code highlight]
builder.add_edge(START, "node_1")

checkpointer = InMemorySaver()
graph = builder.compile(checkpointer=checkpointer)  # [!code highlight]
```

If you want the subgraph to have its own memory, you can compile it with the appropriate checkpointer option. This is useful in [multi-agent](/oss/python/langchain/multi-agent) systems, if you want agents to keep track of their internal message histories.

```python  theme={null}
subgraph_builder = StateGraph(...)
subgraph = subgraph_builder.compile(checkpointer=True)  # [!code highlight]
```

## Add long-term memory

Use long-term memory to store user-specific or application-specific data across conversations.

```python  theme={null}
from langgraph.store.memory import InMemoryStore  # [!code highlight]
from langgraph.graph import StateGraph

store = InMemoryStore()  # [!code highlight]

builder = StateGraph(...)
graph = builder.compile(store=store)  # [!code highlight]
```

### Use in production

In production, use a store backed by a database:

```python  theme={null}
from langgraph.store.postgres import PostgresStore

DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"
with PostgresStore.from_conn_string(DB_URI) as store:  # [!code highlight]
    builder = StateGraph(...)
    graph = builder.compile(store=store)  # [!code highlight]
```

<Accordion title="Example: using Postgres store">
  ```
  pip install -U "psycopg[binary,pool]" langgraph langgraph-checkpoint-postgres
  ```

  <Tip>
    You need to call `store.setup()` the first time you're using Postgres store
  </Tip>

  <Tabs>
    <Tab title="Sync">
      ```python  theme={null}
      from langchain_core.runnables import RunnableConfig
      from langchain.chat_models import init_chat_model
      from langgraph.graph import StateGraph, MessagesState, START
      from langgraph.checkpoint.postgres import PostgresSaver
      from langgraph.store.postgres import PostgresStore  # [!code highlight]
      from langgraph.store.base import BaseStore

      model = init_chat_model(model="claude-haiku-4-5-20251001")

      DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"

      with (
          PostgresStore.from_conn_string(DB_URI) as store,  # [!code highlight]
          PostgresSaver.from_conn_string(DB_URI) as checkpointer,
      ):
          # store.setup()
          # checkpointer.setup()

          def call_model(
              state: MessagesState,
              config: RunnableConfig,
              *,
              store: BaseStore,  # [!code highlight]
          ):
              user_id = config["configurable"]["user_id"]
              namespace = ("memories", user_id)
              memories = store.search(namespace, query=str(state["messages"][-1].content))  # [!code highlight]
              info = "\n".join([d.value["data"] for d in memories])
              system_msg = f"You are a helpful assistant talking to the user. User info: {info}"

              # Store new memories if the user asks the model to remember
              last_message = state["messages"][-1]
              if "remember" in last_message.content.lower():
                  memory = "User name is Bob"
                  store.put(namespace, str(uuid.uuid4()), {"data": memory})  # [!code highlight]

              response = model.invoke(
                  [{"role": "system", "content": system_msg}] + state["messages"]
              )
              return {"messages": response}

          builder = StateGraph(MessagesState)
          builder.add_node(call_model)
          builder.add_edge(START, "call_model")

          graph = builder.compile(
              checkpointer=checkpointer,
              store=store,  # [!code highlight]
          )

          config = {
              "configurable": {
                  "thread_id": "1",  # [!code highlight]
                  "user_id": "1",  # [!code highlight]
              }
          }
          for chunk in graph.stream(
              {"messages": [{"role": "user", "content": "Hi! Remember: my name is Bob"}]},
              config,  # [!code highlight]
              stream_mode="values",
          ):
              chunk["messages"][-1].pretty_print()

          config = {
              "configurable": {
                  "thread_id": "2",  # [!code highlight]
                  "user_id": "1",
              }
          }

          for chunk in graph.stream(
              {"messages": [{"role": "user", "content": "what is my name?"}]},
              config,  # [!code highlight]
              stream_mode="values",
          ):
              chunk["messages"][-1].pretty_print()
      ```
    </Tab>

    <Tab title="Async">
      ```python  theme={null}
      from langchain_core.runnables import RunnableConfig
      from langchain.chat_models import init_chat_model
      from langgraph.graph import StateGraph, MessagesState, START
      from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
      from langgraph.store.postgres.aio import AsyncPostgresStore  # [!code highlight]
      from langgraph.store.base import BaseStore

      model = init_chat_model(model="claude-haiku-4-5-20251001")

      DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"

      async with (
          AsyncPostgresStore.from_conn_string(DB_URI) as store,  # [!code highlight]
          AsyncPostgresSaver.from_conn_string(DB_URI) as checkpointer,
      ):
          # await store.setup()
          # await checkpointer.setup()

          async def call_model(
              state: MessagesState,
              config: RunnableConfig,
              *,
              store: BaseStore,  # [!code highlight]
          ):
              user_id = config["configurable"]["user_id"]
              namespace = ("memories", user_id)
              memories = await store.asearch(namespace, query=str(state["messages"][-1].content))  # [!code highlight]
              info = "\n".join([d.value["data"] for d in memories])
              system_msg = f"You are a helpful assistant talking to the user. User info: {info}"

              # Store new memories if the user asks the model to remember
              last_message = state["messages"][-1]
              if "remember" in last_message.content.lower():
                  memory = "User name is Bob"
                  await store.aput(namespace, str(uuid.uuid4()), {"data": memory})  # [!code highlight]

              response = await model.ainvoke(
                  [{"role": "system", "content": system_msg}] + state["messages"]
              )
              return {"messages": response}

          builder = StateGraph(MessagesState)
          builder.add_node(call_model)
          builder.add_edge(START, "call_model")

          graph = builder.compile(
              checkpointer=checkpointer,
              store=store,  # [!code highlight]
          )

          config = {
              "configurable": {
                  "thread_id": "1",  # [!code highlight]
                  "user_id": "1",  # [!code highlight]
              }
          }
          async for chunk in graph.astream(
              {"messages": [{"role": "user", "content": "Hi! Remember: my name is Bob"}]},
              config,  # [!code highlight]
              stream_mode="values",
          ):
              chunk["messages"][-1].pretty_print()

          config = {
              "configurable": {
                  "thread_id": "2",  # [!code highlight]
                  "user_id": "1",
              }
          }

          async for chunk in graph.astream(
              {"messages": [{"role": "user", "content": "what is my name?"}]},
              config,  # [!code highlight]
              stream_mode="values",
          ):
              chunk["messages"][-1].pretty_print()
      ```
    </Tab>
  </Tabs>
</Accordion>

<Accordion title="Example: using [Redis](https://pypi.org/project/langgraph-checkpoint-redis/) store">
  ```
  pip install -U langgraph langgraph-checkpoint-redis
  ```

  <Tip>
    You need to call `store.setup()` the first time you're using Redis store
  </Tip>

  <Tabs>
    <Tab title="Sync">
      ```python  theme={null}
      from langchain_core.runnables import RunnableConfig
      from langchain.chat_models import init_chat_model
      from langgraph.graph import StateGraph, MessagesState, START
      from langgraph.checkpoint.redis import RedisSaver
      from langgraph.store.redis import RedisStore  # [!code highlight]
      from langgraph.store.base import BaseStore

      model = init_chat_model(model="claude-haiku-4-5-20251001")

      DB_URI = "redis://localhost:6379"

      with (
          RedisStore.from_conn_string(DB_URI) as store,  # [!code highlight]
          RedisSaver.from_conn_string(DB_URI) as checkpointer,
      ):
          store.setup()
          checkpointer.setup()

          def call_model(
              state: MessagesState,
              config: RunnableConfig,
              *,
              store: BaseStore,  # [!code highlight]
          ):
              user_id = config["configurable"]["user_id"]
              namespace = ("memories", user_id)
              memories = store.search(namespace, query=str(state["messages"][-1].content))  # [!code highlight]
              info = "\n".join([d.value["data"] for d in memories])
              system_msg = f"You are a helpful assistant talking to the user. User info: {info}"

              # Store new memories if the user asks the model to remember
              last_message = state["messages"][-1]
              if "remember" in last_message.content.lower():
                  memory = "User name is Bob"
                  store.put(namespace, str(uuid.uuid4()), {"data": memory})  # [!code highlight]

              response = model.invoke(
                  [{"role": "system", "content": system_msg}] + state["messages"]
              )
              return {"messages": response}

          builder = StateGraph(MessagesState)
          builder.add_node(call_model)
          builder.add_edge(START, "call_model")

          graph = builder.compile(
              checkpointer=checkpointer,
              store=store,  # [!code highlight]
          )

          config = {
              "configurable": {
                  "thread_id": "1",  # [!code highlight]
                  "user_id": "1",  # [!code highlight]
              }
          }
          for chunk in graph.stream(
              {"messages": [{"role": "user", "content": "Hi! Remember: my name is Bob"}]},
              config,  # [!code highlight]
              stream_mode="values",
          ):
              chunk["messages"][-1].pretty_print()

          config = {
              "configurable": {
                  "thread_id": "2",  # [!code highlight]
                  "user_id": "1",
              }
          }

          for chunk in graph.stream(
              {"messages": [{"role": "user", "content": "what is my name?"}]},
              config,  # [!code highlight]
              stream_mode="values",
          ):
              chunk["messages"][-1].pretty_print()
      ```
    </Tab>

    <Tab title="Async">
      ```python  theme={null}
      from langchain_core.runnables import RunnableConfig
      from langchain.chat_models import init_chat_model
      from langgraph.graph import StateGraph, MessagesState, START
      from langgraph.checkpoint.redis.aio import AsyncRedisSaver
      from langgraph.store.redis.aio import AsyncRedisStore  # [!code highlight]
      from langgraph.store.base import BaseStore

      model = init_chat_model(model="claude-haiku-4-5-20251001")

      DB_URI = "redis://localhost:6379"

      async with (
          AsyncRedisStore.from_conn_string(DB_URI) as store,  # [!code highlight]
          AsyncRedisSaver.from_conn_string(DB_URI) as checkpointer,
      ):
          # await store.setup()
          # await checkpointer.asetup()

          async def call_model(
              state: MessagesState,
              config: RunnableConfig,
              *,
              store: BaseStore,  # [!code highlight]
          ):
              user_id = config["configurable"]["user_id"]
              namespace = ("memories", user_id)
              memories = await store.asearch(namespace, query=str(state["messages"][-1].content))  # [!code highlight]
              info = "\n".join([d.value["data"] for d in memories])
              system_msg = f"You are a helpful assistant talking to the user. User info: {info}"

              # Store new memories if the user asks the model to remember
              last_message = state["messages"][-1]
              if "remember" in last_message.content.lower():
                  memory = "User name is Bob"
                  await store.aput(namespace, str(uuid.uuid4()), {"data": memory})  # [!code highlight]

              response = await model.ainvoke(
                  [{"role": "system", "content": system_msg}] + state["messages"]
              )
              return {"messages": response}

          builder = StateGraph(MessagesState)
          builder.add_node(call_model)
          builder.add_edge(START, "call_model")

          graph = builder.compile(
              checkpointer=checkpointer,
              store=store,  # [!code highlight]
          )

          config = {
              "configurable": {
                  "thread_id": "1",  # [!code highlight]
                  "user_id": "1",  # [!code highlight]
              }
          }
          async for chunk in graph.astream(
              {"messages": [{"role": "user", "content": "Hi! Remember: my name is Bob"}]},
              config,  # [!code highlight]
              stream_mode="values",
          ):
              chunk["messages"][-1].pretty_print()

          config = {
              "configurable": {
                  "thread_id": "2",  # [!code highlight]
                  "user_id": "1",
              }
          }

          async for chunk in graph.astream(
              {"messages": [{"role": "user", "content": "what is my name?"}]},
              config,  # [!code highlight]
              stream_mode="values",
          ):
              chunk["messages"][-1].pretty_print()
      ```
    </Tab>
  </Tabs>
</Accordion>

### Use semantic search

Enable semantic search in your graph's memory store to let graph agents search for items in the store by semantic similarity.

```python  theme={null}
from langchain.embeddings import init_embeddings
from langgraph.store.memory import InMemoryStore

# Create store with semantic search enabled
embeddings = init_embeddings("openai:text-embedding-3-small")
store = InMemoryStore(
    index={
        "embed": embeddings,
        "dims": 1536,
    }
)

store.put(("user_123", "memories"), "1", {"text": "I love pizza"})
store.put(("user_123", "memories"), "2", {"text": "I am a plumber"})

items = store.search(
    ("user_123", "memories"), query="I'm hungry", limit=1
)
```

<Accordion title="Long-term memory with semantic search">
  ```python  theme={null}

  from langchain.embeddings import init_embeddings
  from langchain.chat_models import init_chat_model
  from langgraph.store.base import BaseStore
  from langgraph.store.memory import InMemoryStore
  from langgraph.graph import START, MessagesState, StateGraph

  model = init_chat_model("gpt-4o-mini")

  # Create store with semantic search enabled
  embeddings = init_embeddings("openai:text-embedding-3-small")
  store = InMemoryStore(
      index={
          "embed": embeddings,
          "dims": 1536,
      }
  )

  store.put(("user_123", "memories"), "1", {"text": "I love pizza"})
  store.put(("user_123", "memories"), "2", {"text": "I am a plumber"})

  def chat(state, *, store: BaseStore):
      # Search based on user's last message
      items = store.search(
          ("user_123", "memories"), query=state["messages"][-1].content, limit=2
      )
      memories = "\n".join(item.value["text"] for item in items)
      memories = f"## Memories of user\n{memories}" if memories else ""
      response = model.invoke(
          [
              {"role": "system", "content": f"You are a helpful assistant.\n{memories}"},
              *state["messages"],
          ]
      )
      return {"messages": [response]}


  builder = StateGraph(MessagesState)
  builder.add_node(chat)
  builder.add_edge(START, "chat")
  graph = builder.compile(store=store)

  for message, metadata in graph.stream(
      input={"messages": [{"role": "user", "content": "I'm hungry"}]},
      stream_mode="messages",
  ):
      print(message.content, end="")
  ```
</Accordion>

## Manage short-term memory

With [short-term memory](#add-short-term-memory) enabled, long conversations can exceed the LLM's context window. Common solutions are:

* [Trim messages](#trim-messages): Remove first or last N messages (before calling LLM)
* [Delete messages](#delete-messages) from LangGraph state permanently
* [Summarize messages](#summarize-messages): Summarize earlier messages in the history and replace them with a summary
* [Manage checkpoints](#manage-checkpoints) to store and retrieve message history
* Custom strategies (e.g., message filtering, etc.)

This allows the agent to keep track of the conversation without exceeding the LLM's context window.

### Trim messages

Most LLMs have a maximum supported context window (denominated in tokens). One way to decide when to truncate messages is to count the tokens in the message history and truncate whenever it approaches that limit. If you're using LangChain, you can use the trim messages utility and specify the number of tokens to keep from the list, as well as the `strategy` (e.g., keep the last `max_tokens`) to use for handling the boundary.

To trim message history, use the [`trim_messages`](https://python.langchain.com/api_reference/core/messages/langchain_core.messages.utils.trim_messages.html) function:

```python  theme={null}
from langchain_core.messages.utils import (  # [!code highlight]
    trim_messages,  # [!code highlight]
    count_tokens_approximately  # [!code highlight]
)  # [!code highlight]

def call_model(state: MessagesState):
    messages = trim_messages(  # [!code highlight]
        state["messages"],
        strategy="last",
        token_counter=count_tokens_approximately,
        max_tokens=128,
        start_on="human",
        end_on=("human", "tool"),
    )
    response = model.invoke(messages)
    return {"messages": [response]}

builder = StateGraph(MessagesState)
builder.add_node(call_model)
...
```

<Accordion title="Full example: trim messages">
  ```python  theme={null}
  from langchain_core.messages.utils import (
      trim_messages,  # [!code highlight]
      count_tokens_approximately  # [!code highlight]
  )
  from langchain.chat_models import init_chat_model
  from langgraph.graph import StateGraph, START, MessagesState

  model = init_chat_model("claude-sonnet-4-5-20250929")
  summarization_model = model.bind(max_tokens=128)

  def call_model(state: MessagesState):
      messages = trim_messages(  # [!code highlight]
          state["messages"],
          strategy="last",
          token_counter=count_tokens_approximately,
          max_tokens=128,
          start_on="human",
          end_on=("human", "tool"),
      )
      response = model.invoke(messages)
      return {"messages": [response]}

  checkpointer = InMemorySaver()
  builder = StateGraph(MessagesState)
  builder.add_node(call_model)
  builder.add_edge(START, "call_model")
  graph = builder.compile(checkpointer=checkpointer)

  config = {"configurable": {"thread_id": "1"}}
  graph.invoke({"messages": "hi, my name is bob"}, config)
  graph.invoke({"messages": "write a short poem about cats"}, config)
  graph.invoke({"messages": "now do the same but for dogs"}, config)
  final_response = graph.invoke({"messages": "what's my name?"}, config)

  final_response["messages"][-1].pretty_print()
  ```

  ```
  ================================== Ai Message ==================================

  Your name is Bob, as you mentioned when you first introduced yourself.
  ```
</Accordion>

### Delete messages

You can delete messages from the graph state to manage the message history. This is useful when you want to remove specific messages or clear the entire message history.

To delete messages from the graph state, you can use the `RemoveMessage`. For `RemoveMessage` to work, you need to use a state key with [`add_messages`](https://reference.langchain.com/python/langgraph/graphs/#langgraph.graph.message.add_messages) [reducer](/oss/python/langgraph/graph-api#reducers), like [`MessagesState`](/oss/python/langgraph/graph-api#messagesstate).

To remove specific messages:

```python  theme={null}
from langchain.messages import RemoveMessage  # [!code highlight]

def delete_messages(state):
    messages = state["messages"]
    if len(messages) > 2:
        # remove the earliest two messages
        return {"messages": [RemoveMessage(id=m.id) for m in messages[:2]]}  # [!code highlight]
```

To remove **all** messages:

```python  theme={null}
from langgraph.graph.message import REMOVE_ALL_MESSAGES  # [!code highlight]

def delete_messages(state):
    return {"messages": [RemoveMessage(id=REMOVE_ALL_MESSAGES)]}  # [!code highlight]
```

<Warning>
  When deleting messages, **make sure** that the resulting message history is valid. Check the limitations of the LLM provider you're using. For example:

  * some providers expect message history to start with a `user` message
  * most providers require `assistant` messages with tool calls to be followed by corresponding `tool` result messages.
</Warning>

<Accordion title="Full example: delete messages">
  ```python  theme={null}
  from langchain.messages import RemoveMessage  # [!code highlight]

  def delete_messages(state):
      messages = state["messages"]
      if len(messages) > 2:
          # remove the earliest two messages
          return {"messages": [RemoveMessage(id=m.id) for m in messages[:2]]}  # [!code highlight]

  def call_model(state: MessagesState):
      response = model.invoke(state["messages"])
      return {"messages": response}

  builder = StateGraph(MessagesState)
  builder.add_sequence([call_model, delete_messages])
  builder.add_edge(START, "call_model")

  checkpointer = InMemorySaver()
  app = builder.compile(checkpointer=checkpointer)

  for event in app.stream(
      {"messages": [{"role": "user", "content": "hi! I'm bob"}]},
      config,
      stream_mode="values"
  ):
      print([(message.type, message.content) for message in event["messages"]])

  for event in app.stream(
      {"messages": [{"role": "user", "content": "what's my name?"}]},
      config,
      stream_mode="values"
  ):
      print([(message.type, message.content) for message in event["messages"]])
  ```

  ```
  [('human', "hi! I'm bob")]
  [('human', "hi! I'm bob"), ('ai', 'Hi Bob! How are you doing today? Is there anything I can help you with?')]
  [('human', "hi! I'm bob"), ('ai', 'Hi Bob! How are you doing today? Is there anything I can help you with?'), ('human', "what's my name?")]
  [('human', "hi! I'm bob"), ('ai', 'Hi Bob! How are you doing today? Is there anything I can help you with?'), ('human', "what's my name?"), ('ai', 'Your name is Bob.')]
  [('human', "what's my name?"), ('ai', 'Your name is Bob.')]
  ```
</Accordion>

### Summarize messages

The problem with trimming or removing messages, as shown above, is that you may lose information from culling of the message queue. Because of this, some applications benefit from a more sophisticated approach of summarizing the message history using a chat model.

<img src="https://mintcdn.com/langchain-5e9cc07a/ybiAaBfoBvFquMDz/oss/images/summary.png?fit=max&auto=format&n=ybiAaBfoBvFquMDz&q=85&s=c8ed3facdccd4ef5c7e52902c72ba938" alt="" data-og-width="609" width="609" data-og-height="242" height="242" data-path="oss/images/summary.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/langchain-5e9cc07a/ybiAaBfoBvFquMDz/oss/images/summary.png?w=280&fit=max&auto=format&n=ybiAaBfoBvFquMDz&q=85&s=4208b9b0cc9f459f3dc4e5219918471b 280w, https://mintcdn.com/langchain-5e9cc07a/ybiAaBfoBvFquMDz/oss/images/summary.png?w=560&fit=max&auto=format&n=ybiAaBfoBvFquMDz&q=85&s=7acb77c081545f57042368f4e9d0c8cb 560w, https://mintcdn.com/langchain-5e9cc07a/ybiAaBfoBvFquMDz/oss/images/summary.png?w=840&fit=max&auto=format&n=ybiAaBfoBvFquMDz&q=85&s=2fcfdb0c481d2e1d361e76db763a41e5 840w, https://mintcdn.com/langchain-5e9cc07a/ybiAaBfoBvFquMDz/oss/images/summary.png?w=1100&fit=max&auto=format&n=ybiAaBfoBvFquMDz&q=85&s=4abdac693a562788aa0db8681bef8ea7 1100w, https://mintcdn.com/langchain-5e9cc07a/ybiAaBfoBvFquMDz/oss/images/summary.png?w=1650&fit=max&auto=format&n=ybiAaBfoBvFquMDz&q=85&s=40acfefa91dcb11b247a6e4a7705f22b 1650w, https://mintcdn.com/langchain-5e9cc07a/ybiAaBfoBvFquMDz/oss/images/summary.png?w=2500&fit=max&auto=format&n=ybiAaBfoBvFquMDz&q=85&s=8d765aaf7551e8b0fc2720de7d2ac2a8 2500w" />

Prompting and orchestration logic can be used to summarize the message history. For example, in LangGraph you can extend the [`MessagesState`](/oss/python/langgraph/graph-api#working-with-messages-in-graph-state) to include a `summary` key:

```python  theme={null}
from langgraph.graph import MessagesState
class State(MessagesState):
    summary: str
```

Then, you can generate a summary of the chat history, using any existing summary as context for the next summary. This `summarize_conversation` node can be called after some number of messages have accumulated in the `messages` state key.

```python  theme={null}
def summarize_conversation(state: State):

    # First, we get any existing summary
    summary = state.get("summary", "")

    # Create our summarization prompt
    if summary:

        # A summary already exists
        summary_message = (
            f"This is a summary of the conversation to date: {summary}\n\n"
            "Extend the summary by taking into account the new messages above:"
        )

    else:
        summary_message = "Create a summary of the conversation above:"

    # Add prompt to our history
    messages = state["messages"] + [HumanMessage(content=summary_message)]
    response = model.invoke(messages)

    # Delete all but the 2 most recent messages
    delete_messages = [RemoveMessage(id=m.id) for m in state["messages"][:-2]]
    return {"summary": response.content, "messages": delete_messages}
```

<Accordion title="Full example: summarize messages">
  ```python  theme={null}
  from typing import Any, TypedDict

  from langchain.chat_models import init_chat_model
  from langchain.messages import AnyMessage
  from langchain_core.messages.utils import count_tokens_approximately
  from langgraph.graph import StateGraph, START, MessagesState
  from langgraph.checkpoint.memory import InMemorySaver
  from langmem.short_term import SummarizationNode, RunningSummary  # [!code highlight]

  model = init_chat_model("claude-sonnet-4-5-20250929")
  summarization_model = model.bind(max_tokens=128)

  class State(MessagesState):
      context: dict[str, RunningSummary]  # [!code highlight]

  class LLMInputState(TypedDict):  # [!code highlight]
      summarized_messages: list[AnyMessage]
      context: dict[str, RunningSummary]

  summarization_node = SummarizationNode(  # [!code highlight]
      token_counter=count_tokens_approximately,
      model=summarization_model,
      max_tokens=256,
      max_tokens_before_summary=256,
      max_summary_tokens=128,
  )

  def call_model(state: LLMInputState):  # [!code highlight]
      response = model.invoke(state["summarized_messages"])
      return {"messages": [response]}

  checkpointer = InMemorySaver()
  builder = StateGraph(State)
  builder.add_node(call_model)
  builder.add_node("summarize", summarization_node)  # [!code highlight]
  builder.add_edge(START, "summarize")
  builder.add_edge("summarize", "call_model")
  graph = builder.compile(checkpointer=checkpointer)

  # Invoke the graph
  config = {"configurable": {"thread_id": "1"}}
  graph.invoke({"messages": "hi, my name is bob"}, config)
  graph.invoke({"messages": "write a short poem about cats"}, config)
  graph.invoke({"messages": "now do the same but for dogs"}, config)
  final_response = graph.invoke({"messages": "what's my name?"}, config)

  final_response["messages"][-1].pretty_print()
  print("\nSummary:", final_response["context"]["running_summary"].summary)
  ```

  1. We will keep track of our running summary in the `context` field

  (expected by the `SummarizationNode`).

  1. Define private state that will be used only for filtering

  the inputs to `call_model` node.

  1. We're passing a private input state here to isolate the messages returned by the summarization node

  ```
  ================================== Ai Message ==================================

  From our conversation, I can see that you introduced yourself as Bob. That's the name you shared with me when we began talking.

  Summary: In this conversation, I was introduced to Bob, who then asked me to write a poem about cats. I composed a poem titled "The Mystery of Cats" that captured cats' graceful movements, independent nature, and their special relationship with humans. Bob then requested a similar poem about dogs, so I wrote "The Joy of Dogs," which highlighted dogs' loyalty, enthusiasm, and loving companionship. Both poems were written in a similar style but emphasized the distinct characteristics that make each pet special.
  ```
</Accordion>

### Manage checkpoints

You can view and delete the information stored by the checkpointer.

<a id="checkpoint" />

#### View thread state

<Tabs>
  <Tab title="Graph/Functional API">
    ```python  theme={null}
    config = {
        "configurable": {
            "thread_id": "1",  # [!code highlight]
            # optionally provide an ID for a specific checkpoint,
            # otherwise the latest checkpoint is shown
            # "checkpoint_id": "1f029ca3-1f5b-6704-8004-820c16b69a5a"  # [!code highlight]

        }
    }
    graph.get_state(config)  # [!code highlight]
    ```

    ```
    StateSnapshot(
        values={'messages': [HumanMessage(content="hi! I'm bob"), AIMessage(content='Hi Bob! How are you doing today?), HumanMessage(content="what's my name?"), AIMessage(content='Your name is Bob.')]}, next=(),
        config={'configurable': {'thread_id': '1', 'checkpoint_ns': '', 'checkpoint_id': '1f029ca3-1f5b-6704-8004-820c16b69a5a'}},
        metadata={
            'source': 'loop',
            'writes': {'call_model': {'messages': AIMessage(content='Your name is Bob.')}},
            'step': 4,
            'parents': {},
            'thread_id': '1'
        },
        created_at='2025-05-05T16:01:24.680462+00:00',
        parent_config={'configurable': {'thread_id': '1', 'checkpoint_ns': '', 'checkpoint_id': '1f029ca3-1790-6b0a-8003-baf965b6a38f'}},
        tasks=(),
        interrupts=()
    )
    ```
  </Tab>

  <Tab title="Checkpointer API">
    ```python  theme={null}
    config = {
        "configurable": {
            "thread_id": "1",  # [!code highlight]
            # optionally provide an ID for a specific checkpoint,
            # otherwise the latest checkpoint is shown
            # "checkpoint_id": "1f029ca3-1f5b-6704-8004-820c16b69a5a"  # [!code highlight]

        }
    }
    checkpointer.get_tuple(config)  # [!code highlight]
    ```

    ```
    CheckpointTuple(
        config={'configurable': {'thread_id': '1', 'checkpoint_ns': '', 'checkpoint_id': '1f029ca3-1f5b-6704-8004-820c16b69a5a'}},
        checkpoint={
            'v': 3,
            'ts': '2025-05-05T16:01:24.680462+00:00',
            'id': '1f029ca3-1f5b-6704-8004-820c16b69a5a',
            'channel_versions': {'__start__': '00000000000000000000000000000005.0.5290678567601859', 'messages': '00000000000000000000000000000006.0.3205149138784782', 'branch:to:call_model': '00000000000000000000000000000006.0.14611156755133758'}, 'versions_seen': {'__input__': {}, '__start__': {'__start__': '00000000000000000000000000000004.0.5736472536395331'}, 'call_model': {'branch:to:call_model': '00000000000000000000000000000005.0.1410174088651449'}},
            'channel_values': {'messages': [HumanMessage(content="hi! I'm bob"), AIMessage(content='Hi Bob! How are you doing today?), HumanMessage(content="what's my name?"), AIMessage(content='Your name is Bob.')]},
        },
        metadata={
            'source': 'loop',
            'writes': {'call_model': {'messages': AIMessage(content='Your name is Bob.')}},
            'step': 4,
            'parents': {},
            'thread_id': '1'
        },
        parent_config={'configurable': {'thread_id': '1', 'checkpoint_ns': '', 'checkpoint_id': '1f029ca3-1790-6b0a-8003-baf965b6a38f'}},
        pending_writes=[]
    )
    ```
  </Tab>
</Tabs>

<a id="checkpoints" />

#### View the history of the thread

<Tabs>
  <Tab title="Graph/Functional API">
    ```python  theme={null}
    config = {
        "configurable": {
            "thread_id": "1"  # [!code highlight]
        }
    }
    list(graph.get_state_history(config))  # [!code highlight]
    ```

    ```
    [
        StateSnapshot(
            values={'messages': [HumanMessage(content="hi! I'm bob"), AIMessage(content='Hi Bob! How are you doing today? Is there anything I can help you with?'), HumanMessage(content="what's my name?"), AIMessage(content='Your name is Bob.')]},
            next=(),
            config={'configurable': {'thread_id': '1', 'checkpoint_ns': '', 'checkpoint_id': '1f029ca3-1f5b-6704-8004-820c16b69a5a'}},
            metadata={'source': 'loop', 'writes': {'call_model': {'messages': AIMessage(content='Your name is Bob.')}}, 'step': 4, 'parents': {}, 'thread_id': '1'},
            created_at='2025-05-05T16:01:24.680462+00:00',
            parent_config={'configurable': {'thread_id': '1', 'checkpoint_ns': '', 'checkpoint_id': '1f029ca3-1790-6b0a-8003-baf965b6a38f'}},
            tasks=(),
            interrupts=()
        ),
        StateSnapshot(
            values={'messages': [HumanMessage(content="hi! I'm bob"), AIMessage(content='Hi Bob! How are you doing today? Is there anything I can help you with?'), HumanMessage(content="what's my name?")]},
            next=('call_model',),
            config={'configurable': {'thread_id': '1', 'checkpoint_ns': '', 'checkpoint_id': '1f029ca3-1790-6b0a-8003-baf965b6a38f'}},
            metadata={'source': 'loop', 'writes': None, 'step': 3, 'parents': {}, 'thread_id': '1'},
            created_at='2025-05-05T16:01:23.863421+00:00',
            parent_config={...}
            tasks=(PregelTask(id='8ab4155e-6b15-b885-9ce5-bed69a2c305c', name='call_model', path=('__pregel_pull', 'call_model'), error=None, interrupts=(), state=None, result={'messages': AIMessage(content='Your name is Bob.')}),),
            interrupts=()
        ),
        StateSnapshot(
            values={'messages': [HumanMessage(content="hi! I'm bob"), AIMessage(content='Hi Bob! How are you doing today? Is there anything I can help you with?')]},
            next=('__start__',),
            config={...},
            metadata={'source': 'input', 'writes': {'__start__': {'messages': [{'role': 'user', 'content': "what's my name?"}]}}, 'step': 2, 'parents': {}, 'thread_id': '1'},
            created_at='2025-05-05T16:01:23.863173+00:00',
            parent_config={...}
            tasks=(PregelTask(id='24ba39d6-6db1-4c9b-f4c5-682aeaf38dcd', name='__start__', path=('__pregel_pull', '__start__'), error=None, interrupts=(), state=None, result={'messages': [{'role': 'user', 'content': "what's my name?"}]}),),
            interrupts=()
        ),
        StateSnapshot(
            values={'messages': [HumanMessage(content="hi! I'm bob"), AIMessage(content='Hi Bob! How are you doing today? Is there anything I can help you with?')]},
            next=(),
            config={...},
            metadata={'source': 'loop', 'writes': {'call_model': {'messages': AIMessage(content='Hi Bob! How are you doing today? Is there anything I can help you with?')}}, 'step': 1, 'parents': {}, 'thread_id': '1'},
            created_at='2025-05-05T16:01:23.862295+00:00',
            parent_config={...}
            tasks=(),
            interrupts=()
        ),
        StateSnapshot(
            values={'messages': [HumanMessage(content="hi! I'm bob")]},
            next=('call_model',),
            config={...},
            metadata={'source': 'loop', 'writes': None, 'step': 0, 'parents': {}, 'thread_id': '1'},
            created_at='2025-05-05T16:01:22.278960+00:00',
            parent_config={...}
            tasks=(PregelTask(id='8cbd75e0-3720-b056-04f7-71ac805140a0', name='call_model', path=('__pregel_pull', 'call_model'), error=None, interrupts=(), state=None, result={'messages': AIMessage(content='Hi Bob! How are you doing today? Is there anything I can help you with?')}),),
            interrupts=()
        ),
        StateSnapshot(
            values={'messages': []},
            next=('__start__',),
            config={'configurable': {'thread_id': '1', 'checkpoint_ns': '', 'checkpoint_id': '1f029ca3-0870-6ce2-bfff-1f3f14c3e565'}},
            metadata={'source': 'input', 'writes': {'__start__': {'messages': [{'role': 'user', 'content': "hi! I'm bob"}]}}, 'step': -1, 'parents': {}, 'thread_id': '1'},
            created_at='2025-05-05T16:01:22.277497+00:00',
            parent_config=None,
            tasks=(PregelTask(id='d458367b-8265-812c-18e2-33001d199ce6', name='__start__', path=('__pregel_pull', '__start__'), error=None, interrupts=(), state=None, result={'messages': [{'role': 'user', 'content': "hi! I'm bob"}]}),),
            interrupts=()
        )
    ]
    ```
  </Tab>

  <Tab title="Checkpointer API">
    ```python  theme={null}
    config = {
        "configurable": {
            "thread_id": "1"  # [!code highlight]
        }
    }
    list(checkpointer.list(config))  # [!code highlight]
    ```

    ```
    [
        CheckpointTuple(
            config={'configurable': {'thread_id': '1', 'checkpoint_ns': '', 'checkpoint_id': '1f029ca3-1f5b-6704-8004-820c16b69a5a'}},
            checkpoint={
                'v': 3,
                'ts': '2025-05-05T16:01:24.680462+00:00',
                'id': '1f029ca3-1f5b-6704-8004-820c16b69a5a',
                'channel_versions': {'__start__': '00000000000000000000000000000005.0.5290678567601859', 'messages': '00000000000000000000000000000006.0.3205149138784782', 'branch:to:call_model': '00000000000000000000000000000006.0.14611156755133758'},
                'versions_seen': {'__input__': {}, '__start__': {'__start__': '00000000000000000000000000000004.0.5736472536395331'}, 'call_model': {'branch:to:call_model': '00000000000000000000000000000005.0.1410174088651449'}},
                'channel_values': {'messages': [HumanMessage(content="hi! I'm bob"), AIMessage(content='Hi Bob! How are you doing today? Is there anything I can help you with?'), HumanMessage(content="what's my name?"), AIMessage(content='Your name is Bob.')]},
            },
            metadata={'source': 'loop', 'writes': {'call_model': {'messages': AIMessage(content='Your name is Bob.')}}, 'step': 4, 'parents': {}, 'thread_id': '1'},
            parent_config={'configurable': {'thread_id': '1', 'checkpoint_ns': '', 'checkpoint_id': '1f029ca3-1790-6b0a-8003-baf965b6a38f'}},
            pending_writes=[]
        ),
        CheckpointTuple(
            config={'configurable': {'thread_id': '1', 'checkpoint_ns': '', 'checkpoint_id': '1f029ca3-1790-6b0a-8003-baf965b6a38f'}},
            checkpoint={
                'v': 3,
                'ts': '2025-05-05T16:01:23.863421+00:00',
                'id': '1f029ca3-1790-6b0a-8003-baf965b6a38f',
                'channel_versions': {'__start__': '00000000000000000000000000000005.0.5290678567601859', 'messages': '00000000000000000000000000000006.0.3205149138784782', 'branch:to:call_model': '00000000000000000000000000000006.0.14611156755133758'},
                'versions_seen': {'__input__': {}, '__start__': {'__start__': '00000000000000000000000000000004.0.5736472536395331'}, 'call_model': {'branch:to:call_model': '00000000000000000000000000000005.0.1410174088651449'}},
                'channel_values': {'messages': [HumanMessage(content="hi! I'm bob"), AIMessage(content='Hi Bob! How are you doing today? Is there anything I can help you with?'), HumanMessage(content="what's my name?")], 'branch:to:call_model': None}
            },
            metadata={'source': 'loop', 'writes': None, 'step': 3, 'parents': {}, 'thread_id': '1'},
            parent_config={...},
            pending_writes=[('8ab4155e-6b15-b885-9ce5-bed69a2c305c', 'messages', AIMessage(content='Your name is Bob.'))]
        ),
        CheckpointTuple(
            config={...},
            checkpoint={
                'v': 3,
                'ts': '2025-05-05T16:01:23.863173+00:00',
                'id': '1f029ca3-1790-616e-8002-9e021694a0cd',
                'channel_versions': {'__start__': '00000000000000000000000000000004.0.5736472536395331', 'messages': '00000000000000000000000000000003.0.7056767754077798', 'branch:to:call_model': '00000000000000000000000000000003.0.22059023329132854'},
                'versions_seen': {'__input__': {}, '__start__': {'__start__': '00000000000000000000000000000001.0.7040775356287469'}, 'call_model': {'branch:to:call_model': '00000000000000000000000000000002.0.9300422176788571'}},
                'channel_values': {'__start__': {'messages': [{'role': 'user', 'content': "what's my name?"}]}, 'messages': [HumanMessage(content="hi! I'm bob"), AIMessage(content='Hi Bob! How are you doing today? Is there anything I can help you with?')]}
            },
            metadata={'source': 'input', 'writes': {'__start__': {'messages': [{'role': 'user', 'content': "what's my name?"}]}}, 'step': 2, 'parents': {}, 'thread_id': '1'},
            parent_config={...},
            pending_writes=[('24ba39d6-6db1-4c9b-f4c5-682aeaf38dcd', 'messages', [{'role': 'user', 'content': "what's my name?"}]), ('24ba39d6-6db1-4c9b-f4c5-682aeaf38dcd', 'branch:to:call_model', None)]
        ),
        CheckpointTuple(
            config={...},
            checkpoint={
                'v': 3,
                'ts': '2025-05-05T16:01:23.862295+00:00',
                'id': '1f029ca3-178d-6f54-8001-d7b180db0c89',
                'channel_versions': {'__start__': '00000000000000000000000000000002.0.18673090920108737', 'messages': '00000000000000000000000000000003.0.7056767754077798', 'branch:to:call_model': '00000000000000000000000000000003.0.22059023329132854'},
                'versions_seen': {'__input__': {}, '__start__': {'__start__': '00000000000000000000000000000001.0.7040775356287469'}, 'call_model': {'branch:to:call_model': '00000000000000000000000000000002.0.9300422176788571'}},
                'channel_values': {'messages': [HumanMessage(content="hi! I'm bob"), AIMessage(content='Hi Bob! How are you doing today? Is there anything I can help you with?')]}
            },
            metadata={'source': 'loop', 'writes': {'call_model': {'messages': AIMessage(content='Hi Bob! How are you doing today? Is there anything I can help you with?')}}, 'step': 1, 'parents': {}, 'thread_id': '1'},
            parent_config={...},
            pending_writes=[]
        ),
        CheckpointTuple(
            config={...},
            checkpoint={
                'v': 3,
                'ts': '2025-05-05T16:01:22.278960+00:00',
                'id': '1f029ca3-0874-6612-8000-339f2abc83b1',
                'channel_versions': {'__start__': '00000000000000000000000000000002.0.18673090920108737', 'messages': '00000000000000000000000000000002.0.30296526818059655', 'branch:to:call_model': '00000000000000000000000000000002.0.9300422176788571'},
                'versions_seen': {'__input__': {}, '__start__': {'__start__': '00000000000000000000000000000001.0.7040775356287469'}},
                'channel_values': {'messages': [HumanMessage(content="hi! I'm bob")], 'branch:to:call_model': None}
            },
            metadata={'source': 'loop', 'writes': None, 'step': 0, 'parents': {}, 'thread_id': '1'},
            parent_config={...},
            pending_writes=[('8cbd75e0-3720-b056-04f7-71ac805140a0', 'messages', AIMessage(content='Hi Bob! How are you doing today? Is there anything I can help you with?'))]
        ),
        CheckpointTuple(
            config={'configurable': {'thread_id': '1', 'checkpoint_ns': '', 'checkpoint_id': '1f029ca3-0870-6ce2-bfff-1f3f14c3e565'}},
            checkpoint={
                'v': 3,
                'ts': '2025-05-05T16:01:22.277497+00:00',
                'id': '1f029ca3-0870-6ce2-bfff-1f3f14c3e565',
                'channel_versions': {'__start__': '00000000000000000000000000000001.0.7040775356287469'},
                'versions_seen': {'__input__': {}},
                'channel_values': {'__start__': {'messages': [{'role': 'user', 'content': "hi! I'm bob"}]}}
            },
            metadata={'source': 'input', 'writes': {'__start__': {'messages': [{'role': 'user', 'content': "hi! I'm bob"}]}}, 'step': -1, 'parents': {}, 'thread_id': '1'},
            parent_config=None,
            pending_writes=[('d458367b-8265-812c-18e2-33001d199ce6', 'messages', [{'role': 'user', 'content': "hi! I'm bob"}]), ('d458367b-8265-812c-18e2-33001d199ce6', 'branch:to:call_model', None)]
        )
    ]
    ```
  </Tab>
</Tabs>

#### Delete all checkpoints for a thread

```python  theme={null}
thread_id = "1"
checkpointer.delete_thread(thread_id)
```

## Prebuilt memory tools

**LangMem** is a LangChain-maintained library that offers tools for managing long-term memories in your agent. See the [LangMem documentation](https://langchain-ai.github.io/langmem/) for usage examples.

***

<Callout icon="pen-to-square" iconType="regular">
  [Edit the source of this page on GitHub.](https://github.com/langchain-ai/docs/edit/main/src/oss/langgraph/add-memory.mdx)
</Callout>

<Tip icon="terminal" iconType="regular">
  [Connect these docs programmatically](/use-these-docs) to Claude, VSCode, and more via MCP for    real-time answers.
</Tip>
