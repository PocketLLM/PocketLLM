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

# Structured output

Structured output allows agents to return data in a specific, predictable format. Instead of parsing natural language responses, you get structured data in the form of JSON objects, Pydantic models, or dataclasses that your application can directly use.

LangChain's [`create_agent`](https://reference.langchain.com/python/langchain/agents/#langchain.agents.create_agent) handles structured output automatically. The user sets their desired structured output schema, and when the model generates the structured data, it's captured, validated, and returned in the `'structured_response'` key of the agent's state.

```python  theme={null}
def create_agent(
    ...
    response_format: Union[
        ToolStrategy[StructuredResponseT],
        ProviderStrategy[StructuredResponseT],
        type[StructuredResponseT],
    ]
```

## Response Format

Controls how the agent returns structured data:

* **`ToolStrategy[StructuredResponseT]`**: Uses tool calling for structured output
* **`ProviderStrategy[StructuredResponseT]`**: Uses provider-native structured output
* **`type[StructuredResponseT]`**: Schema type - automatically selects best strategy based on model capabilities
* **`None`**: No structured output

When a schema type is provided directly, LangChain automatically chooses:

* `ProviderStrategy` for models supporting native structured output (e.g. [OpenAI](/oss/python/integrations/providers/openai), [Grok](/oss/python/integrations/providers/xai))
* `ToolStrategy` for all other models

The structured response is returned in the `structured_response` key of the agent's final state.

## Provider strategy

Some model providers support structured output natively through their APIs (currently only OpenAI and Grok). This is the most reliable method when available.

To use this strategy, configure a `ProviderStrategy`:

```python  theme={null}
class ProviderStrategy(Generic[SchemaT]):
    schema: type[SchemaT]
```

<ParamField path="schema" required>
  The schema defining the structured output format. Supports:

  * **Pydantic models**: `BaseModel` subclasses with field validation
  * **Dataclasses**: Python dataclasses with type annotations
  * **TypedDict**: Typed dictionary classes
  * **JSON Schema**: Dictionary with JSON schema specification
</ParamField>

LangChain automatically uses `ProviderStrategy` when you pass a schema type directly to [`create_agent.response_format`](https://reference.langchain.com/python/langchain/agents/#langchain.agents.create_agent\(response_format\)) and the model supports native structured output:

<CodeGroup>
  ```python Pydantic Model theme={null}
  from pydantic import BaseModel
  from langchain.agents import create_agent


  class ContactInfo(BaseModel):
      """Contact information for a person."""
      name: str = Field(description="The name of the person")
      email: str = Field(description="The email address of the person")
      phone: str = Field(description="The phone number of the person")

  agent = create_agent(
      model="gpt-5",
      tools=tools,
      response_format=ContactInfo  # Auto-selects ProviderStrategy
  )

  result = agent.invoke({
      "messages": [{"role": "user", "content": "Extract contact info from: John Doe, john@example.com, (555) 123-4567"}]
  })

  result["structured_response"]
  # ContactInfo(name='John Doe', email='john@example.com', phone='(555) 123-4567')
  ```

  ```python Dataclass theme={null}
  from dataclasses import dataclass
  from langchain.agents import create_agent


  @dataclass
  class ContactInfo:
      """Contact information for a person."""
      name: str # The name of the person
      email: str # The email address of the person
      phone: str # The phone number of the person

  agent = create_agent(
      model="gpt-5",
      tools=tools,
      response_format=ContactInfo  # Auto-selects ProviderStrategy
  )

  result = agent.invoke({
      "messages": [{"role": "user", "content": "Extract contact info from: John Doe, john@example.com, (555) 123-4567"}]
  })

  result["structured_response"]
  # ContactInfo(name='John Doe', email='john@example.com', phone='(555) 123-4567')
  ```

  ```python TypedDict theme={null}
  from typing_extensions import TypedDict
  from langchain.agents import create_agent


  class ContactInfo(TypedDict):
      """Contact information for a person."""
      name: str # The name of the person
      email: str # The email address of the person
      phone: str # The phone number of the person

  agent = create_agent(
      model="gpt-5",
      tools=tools,
      response_format=ContactInfo  # Auto-selects ProviderStrategy
  )

  result = agent.invoke({
      "messages": [{"role": "user", "content": "Extract contact info from: John Doe, john@example.com, (555) 123-4567"}]
  })

  result["structured_response"]
  # {'name': 'John Doe', 'email': 'john@example.com', 'phone': '(555) 123-4567'}
  ```

  ```python JSON Schema theme={null}
  from langchain.agents import create_agent


  contact_info_schema = {
      "type": "object",
      "description": "Contact information for a person.",
      "properties": {
          "name": {"type": "string", "description": "The name of the person"},
          "email": {"type": "string", "description": "The email address of the person"},
          "phone": {"type": "string", "description": "The phone number of the person"}
      },
      "required": ["name", "email", "phone"]
  }

  agent = create_agent(
      model="gpt-5",
      tools=tools,
      response_format=contact_info_schema  # Auto-selects ProviderStrategy
  )

  result = agent.invoke({
      "messages": [{"role": "user", "content": "Extract contact info from: John Doe, john@example.com, (555) 123-4567"}]
  })

  result["structured_response"]
  # {'name': 'John Doe', 'email': 'john@example.com', 'phone': '(555) 123-4567'}
  ```
</CodeGroup>

Provider-native structured output provides high reliability and strict validation because the model provider enforces the schema. Use it when available.

<Note>
  If the provider natively supports structured output for your model choice, it is functionally equivalent to write `response_format=ProductReview` instead of `response_format=ToolStrategy(ProductReview)`. In either case, if structured output is not supported, the agent will fall back to a tool calling strategy.
</Note>

## Tool calling strategy

For models that don't support native structured output, LangChain uses tool calling to achieve the same result. This works with all models that support tool calling, which is most modern models.

To use this strategy, configure a `ToolStrategy`:

```python  theme={null}
class ToolStrategy(Generic[SchemaT]):
    schema: type[SchemaT]
    tool_message_content: str | None
    handle_errors: Union[
        bool,
        str,
        type[Exception],
        tuple[type[Exception], ...],
        Callable[[Exception], str],
    ]
```

<ParamField path="schema" required>
  The schema defining the structured output format. Supports:

  * **Pydantic models**: `BaseModel` subclasses with field validation
  * **Dataclasses**: Python dataclasses with type annotations
  * **TypedDict**: Typed dictionary classes
  * **JSON Schema**: Dictionary with JSON schema specification
  * **Union types**: Multiple schema options. The model will choose the most appropriate schema based on the context.
</ParamField>

<ParamField path="tool_message_content">
  Custom content for the tool message returned when structured output is generated.
  If not provided, defaults to a message showing the structured response data.
</ParamField>

<ParamField path="handle_errors">
  Error handling strategy for structured output validation failures. Defaults to `True`.

  * **`True`**: Catch all errors with default error template
  * **`str`**: Catch all errors with this custom message
  * **`type[Exception]`**: Only catch this exception type with default message
  * **`tuple[type[Exception], ...]`**: Only catch these exception types with default message
  * **`Callable[[Exception], str]`**: Custom function that returns error message
  * **`False`**: No retry, let exceptions propagate
</ParamField>

<CodeGroup>
  ```python Pydantic Model theme={null}
  from pydantic import BaseModel, Field
  from typing import Literal
  from langchain.agents import create_agent
  from langchain.agents.structured_output import ToolStrategy


  class ProductReview(BaseModel):
      """Analysis of a product review."""
      rating: int | None = Field(description="The rating of the product", ge=1, le=5)
      sentiment: Literal["positive", "negative"] = Field(description="The sentiment of the review")
      key_points: list[str] = Field(description="The key points of the review. Lowercase, 1-3 words each.")

  agent = create_agent(
      model="gpt-5",
      tools=tools,
      response_format=ToolStrategy(ProductReview)
  )

  result = agent.invoke({
      "messages": [{"role": "user", "content": "Analyze this review: 'Great product: 5 out of 5 stars. Fast shipping, but expensive'"}]
  })
  result["structured_response"]
  # ProductReview(rating=5, sentiment='positive', key_points=['fast shipping', 'expensive'])
  ```

  ```python Dataclass theme={null}
  from dataclasses import dataclass
  from typing import Literal
  from langchain.agents import create_agent
  from langchain.agents.structured_output import ToolStrategy


  @dataclass
  class ProductReview:
      """Analysis of a product review."""
      rating: int | None  # The rating of the product (1-5)
      sentiment: Literal["positive", "negative"]  # The sentiment of the review
      key_points: list[str]  # The key points of the review

  agent = create_agent(
      model="gpt-5",
      tools=tools,
      response_format=ToolStrategy(ProductReview)
  )

  result = agent.invoke({
      "messages": [{"role": "user", "content": "Analyze this review: 'Great product: 5 out of 5 stars. Fast shipping, but expensive'"}]
  })
  result["structured_response"]
  # ProductReview(rating=5, sentiment='positive', key_points=['fast shipping', 'expensive'])
  ```

  ```python TypedDict theme={null}
  from typing import Literal
  from typing_extensions import TypedDict
  from langchain.agents import create_agent
  from langchain.agents.structured_output import ToolStrategy


  class ProductReview(TypedDict):
      """Analysis of a product review."""
      rating: int | None  # The rating of the product (1-5)
      sentiment: Literal["positive", "negative"]  # The sentiment of the review
      key_points: list[str]  # The key points of the review

  agent = create_agent(
      model="gpt-5",
      tools=tools,
      response_format=ToolStrategy(ProductReview)
  )

  result = agent.invoke({
      "messages": [{"role": "user", "content": "Analyze this review: 'Great product: 5 out of 5 stars. Fast shipping, but expensive'"}]
  })
  result["structured_response"]
  # {'rating': 5, 'sentiment': 'positive', 'key_points': ['fast shipping', 'expensive']}
  ```

  ```python JSON Schema theme={null}
  from langchain.agents import create_agent
  from langchain.agents.structured_output import ToolStrategy


  product_review_schema = {
      "type": "object",
      "description": "Analysis of a product review.",
      "properties": {
          "rating": {
              "type": ["integer", "null"],
              "description": "The rating of the product (1-5)",
              "minimum": 1,
              "maximum": 5
          },
          "sentiment": {
              "type": "string",
              "enum": ["positive", "negative"],
              "description": "The sentiment of the review"
          },
          "key_points": {
              "type": "array",
              "items": {"type": "string"},
              "description": "The key points of the review"
          }
      },
      "required": ["sentiment", "key_points"]
  }

  agent = create_agent(
      model="gpt-5",
      tools=tools,
      response_format=ToolStrategy(product_review_schema)
  )

  result = agent.invoke({
      "messages": [{"role": "user", "content": "Analyze this review: 'Great product: 5 out of 5 stars. Fast shipping, but expensive'"}]
  })
  result["structured_response"]
  # {'rating': 5, 'sentiment': 'positive', 'key_points': ['fast shipping', 'expensive']}
  ```

  ```python Union Types theme={null}
  from pydantic import BaseModel, Field
  from typing import Literal, Union
  from langchain.agents import create_agent
  from langchain.agents.structured_output import ToolStrategy


  class ProductReview(BaseModel):
      """Analysis of a product review."""
      rating: int | None = Field(description="The rating of the product", ge=1, le=5)
      sentiment: Literal["positive", "negative"] = Field(description="The sentiment of the review")
      key_points: list[str] = Field(description="The key points of the review. Lowercase, 1-3 words each.")

  class CustomerComplaint(BaseModel):
      """A customer complaint about a product or service."""
      issue_type: Literal["product", "service", "shipping", "billing"] = Field(description="The type of issue")
      severity: Literal["low", "medium", "high"] = Field(description="The severity of the complaint")
      description: str = Field(description="Brief description of the complaint")

  agent = create_agent(
      model="gpt-5",
      tools=tools,
      response_format=ToolStrategy(Union[ProductReview, CustomerComplaint])
  )

  result = agent.invoke({
      "messages": [{"role": "user", "content": "Analyze this review: 'Great product: 5 out of 5 stars. Fast shipping, but expensive'"}]
  })
  result["structured_response"]
  # ProductReview(rating=5, sentiment='positive', key_points=['fast shipping', 'expensive'])
  ```
</CodeGroup>

### Custom tool message content

The `tool_message_content` parameter allows you to customize the message that appears in the conversation history when structured output is generated:

```python  theme={null}
from pydantic import BaseModel, Field
from typing import Literal
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy


class MeetingAction(BaseModel):
    """Action items extracted from a meeting transcript."""
    task: str = Field(description="The specific task to be completed")
    assignee: str = Field(description="Person responsible for the task")
    priority: Literal["low", "medium", "high"] = Field(description="Priority level")

agent = create_agent(
    model="gpt-5",
    tools=[],
    response_format=ToolStrategy(
        schema=MeetingAction,
        tool_message_content="Action item captured and added to meeting notes!"
    )
)

agent.invoke({
    "messages": [{"role": "user", "content": "From our meeting: Sarah needs to update the project timeline as soon as possible"}]
})
```

```
================================ Human Message =================================

From our meeting: Sarah needs to update the project timeline as soon as possible
================================== Ai Message ==================================
Tool Calls:
  MeetingAction (call_1)
 Call ID: call_1
  Args:
    task: Update the project timeline
    assignee: Sarah
    priority: high
================================= Tool Message =================================
Name: MeetingAction

Action item captured and added to meeting notes!
```

Without `tool_message_content`, our final [`ToolMessage`](https://reference.langchain.com/python/langchain/messages/#langchain.messages.ToolMessage) would be:

```
================================= Tool Message =================================
Name: MeetingAction

Returning structured response: {'task': 'update the project timeline', 'assignee': 'Sarah', 'priority': 'high'}
```

### Error handling

Models can make mistakes when generating structured output via tool calling. LangChain provides intelligent retry mechanisms to handle these errors automatically.

#### Multiple structured outputs error

When a model incorrectly calls multiple structured output tools, the agent provides error feedback in a [`ToolMessage`](https://reference.langchain.com/python/langchain/messages/#langchain.messages.ToolMessage) and prompts the model to retry:

```python  theme={null}
from pydantic import BaseModel, Field
from typing import Union
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy


class ContactInfo(BaseModel):
    name: str = Field(description="Person's name")
    email: str = Field(description="Email address")

class EventDetails(BaseModel):
    event_name: str = Field(description="Name of the event")
    date: str = Field(description="Event date")

agent = create_agent(
    model="gpt-5",
    tools=[],
    response_format=ToolStrategy(Union[ContactInfo, EventDetails])  # Default: handle_errors=True
)

agent.invoke({
    "messages": [{"role": "user", "content": "Extract info: John Doe (john@email.com) is organizing Tech Conference on March 15th"}]
})
```

```
================================ Human Message =================================

Extract info: John Doe (john@email.com) is organizing Tech Conference on March 15th
None
================================== Ai Message ==================================
Tool Calls:
  ContactInfo (call_1)
 Call ID: call_1
  Args:
    name: John Doe
    email: john@email.com
  EventDetails (call_2)
 Call ID: call_2
  Args:
    event_name: Tech Conference
    date: March 15th
================================= Tool Message =================================
Name: ContactInfo

Error: Model incorrectly returned multiple structured responses (ContactInfo, EventDetails) when only one is expected.
 Please fix your mistakes.
================================= Tool Message =================================
Name: EventDetails

Error: Model incorrectly returned multiple structured responses (ContactInfo, EventDetails) when only one is expected.
 Please fix your mistakes.
================================== Ai Message ==================================
Tool Calls:
  ContactInfo (call_3)
 Call ID: call_3
  Args:
    name: John Doe
    email: john@email.com
================================= Tool Message =================================
Name: ContactInfo

Returning structured response: {'name': 'John Doe', 'email': 'john@email.com'}
```

#### Schema validation error

When structured output doesn't match the expected schema, the agent provides specific error feedback:

```python  theme={null}
from pydantic import BaseModel, Field
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy


class ProductRating(BaseModel):
    rating: int | None = Field(description="Rating from 1-5", ge=1, le=5)
    comment: str = Field(description="Review comment")

agent = create_agent(
    model="gpt-5",
    tools=[],
    response_format=ToolStrategy(ProductRating),  # Default: handle_errors=True
    system_prompt="You are a helpful assistant that parses product reviews. Do not make any field or value up."
)

agent.invoke({
    "messages": [{"role": "user", "content": "Parse this: Amazing product, 10/10!"}]
})
```

```
================================ Human Message =================================

Parse this: Amazing product, 10/10!
================================== Ai Message ==================================
Tool Calls:
  ProductRating (call_1)
 Call ID: call_1
  Args:
    rating: 10
    comment: Amazing product
================================= Tool Message =================================
Name: ProductRating

Error: Failed to parse structured output for tool 'ProductRating': 1 validation error for ProductRating.rating
  Input should be less than or equal to 5 [type=less_than_equal, input_value=10, input_type=int].
 Please fix your mistakes.
================================== Ai Message ==================================
Tool Calls:
  ProductRating (call_2)
 Call ID: call_2
  Args:
    rating: 5
    comment: Amazing product
================================= Tool Message =================================
Name: ProductRating

Returning structured response: {'rating': 5, 'comment': 'Amazing product'}
```

#### Error handling strategies

You can customize how errors are handled using the `handle_errors` parameter:

**Custom error message:**

```python  theme={null}
ToolStrategy(
    schema=ProductRating,
    handle_errors="Please provide a valid rating between 1-5 and include a comment."
)
```

If `handle_errors` is a string, the agent will *always* prompt the model to re-try with a fixed tool message:

```
================================= Tool Message =================================
Name: ProductRating

Please provide a valid rating between 1-5 and include a comment.
```

**Handle specific exceptions only:**

```python  theme={null}
ToolStrategy(
    schema=ProductRating,
    handle_errors=ValueError  # Only retry on ValueError, raise others
)
```

If `handle_errors` is an exception type, the agent will only retry (using the default error message) if the exception raised is the specified type. In all other cases, the exception will be raised.

**Handle multiple exception types:**

```python  theme={null}
ToolStrategy(
    schema=ProductRating,
    handle_errors=(ValueError, TypeError)  # Retry on ValueError and TypeError
)
```

If `handle_errors` is a tuple of exceptions, the agent will only retry (using the default error message) if the exception raised is one of the specified types. In all other cases, the exception will be raised.

**Custom error handler function:**

```python  theme={null}
def custom_error_handler(error: Exception) -> str:
    if isinstance(error, StructuredOutputValidationError):
        return "There was an issue with the format. Try again.
    elif isinstance(error, MultipleStructuredOutputsError):
        return "Multiple structured outputs were returned. Pick the most relevant one."
    else:
        return f"Error: {str(error)}"

ToolStrategy(
    schema=ToolStrategy(Union[ContactInfo, EventDetails]),
    handle_errors=custom_error_handler
)
```

On `StructuredOutputValidationError`:

```
================================= Tool Message =================================
Name: ToolStrategy

There was an issue with the format. Try again.
```

On `MultipleStructuredOutputsError`:

```
================================= Tool Message =================================
Name: ToolStrategy

Multiple structured outputs were returned. Pick the most relevant one.
```

On other errors:

```
================================= Tool Message =================================
Name: ToolStrategy

Error: <error message>
```

**No error handling:**

```python  theme={null}
response_format = ToolStrategy(
    schema=ProductRating,
    handle_errors=False  # All errors raised
)
```

***

<Callout icon="pen-to-square" iconType="regular">
  [Edit the source of this page on GitHub.](https://github.com/langchain-ai/docs/edit/main/src/oss/langchain/structured-output.mdx)
</Callout>

<Tip icon="terminal" iconType="regular">
  [Connect these docs programmatically](/use-these-docs) to Claude, VSCode, and more via MCP for    real-time answers.
</Tip>
