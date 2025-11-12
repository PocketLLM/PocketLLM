Agents Endpoints
Agents API.

Toggle themeWall AssetsCat FrameLampCat ToyLamp LightDeskChairOrange Cat IdleLamp LightScreenScreen LightLamp Light Large
Examples
Real world code examples

Agents Completion


POST
 /v1/agents/completions


Request Body
application/json

agent_id
*
string

The ID of the agent to use for this completion.

frequency_penalty
number

Default Value: 0

The frequency_penalty penalizes the repetition of words based on their frequency in the generated text. A higher frequency penalty discourages the model from repeating words that have already appeared frequently in the output, promoting diversity and reducing repetition.

max_tokens
integer|null

The maximum number of tokens to generate in the completion. The token count of your prompt plus max_tokens cannot exceed the model's context length.


messages
*
array<SystemMessage|UserMessage|AssistantMessage|ToolMessage>

The prompt(s) to generate completions for, encoded as a list of dict with role and content.

n
integer|null

Number of completions to return for each request, input tokens are only billed once.

parallel_tool_calls
boolean

Default Value: true


prediction
Prediction|null

Enable users to specify an expected completion, optimizing response times by leveraging known or predictable content.

presence_penalty
number

Default Value: 0

The presence_penalty determines how much the model penalizes the repetition of words or phrases. A higher presence penalty encourages the model to use a wider variety of words and phrases, making the output more diverse and creative.

prompt_mode
"reasoning"

Allows toggling between the reasoning mode and no system prompt. When set to reasoning the system prompt for reasoning models will be used.

random_seed
integer|null

The seed to use for random sampling. If set, different calls will generate deterministic results.


response_format
ResponseFormat|null

Specify the format that the model must output. By default it will use \{ "type": "text" \}. Setting to \{ "type": "json_object" \} enables JSON mode, which guarantees the message the model generates is in JSON. When using JSON mode you MUST also instruct the model to produce JSON yourself with a system or a user message. Setting to \{ "type": "json_schema" \} enables JSON schema mode, which guarantees the message the model generates is in JSON and follows the schema you provide.

stop
string|array<string>

Stop generation if this token is detected. Or if one of these tokens is detected when providing an array

stream
boolean

Default Value: false

Whether to stream back partial progress. If set, tokens will be sent as data-only server-side events as they become available, with the stream terminated by a data: [DONE] message. Otherwise, the server will hold the request open until the timeout or until completion, with the response containing the full result as JSON.


tool_choice
ToolChoice|"auto"|"none"|"any"|"required"


tools
array<Tool>|null

A list of tools the model may call. Use this to provide a list of functions the model may generate JSON inputs for.

200

Successful Response


choices
*
array<ChatCompletionChoice>


created
*
integer


id
*
string


model
*
string


object
*
string


usage
*
UsageInfo


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.agents.complete(messages=[
        {
            "content": "Who is the best French painter? Answer in one short sentence.",
            "role": "user",
        },
    ], agent_id="<id>", stream=False)

    # Handle response
    print(res)

200


{
  "id": "cf79f7daaee244b1a0ae5c7b1444424a",
  "object": "chat.completion",
  "model": "mistral-medium-latest",
  "usage": {
    "prompt_tokens": 24,
    "completion_tokens": 27,
    "total_tokens": 51,
    "prompt_audio_seconds": {},
    "__pydantic_extra__": {}
  },
  "created": 1759500534,
  "choices": [
    {
      "index": 0,
      "message": {
        "content": "Arrr, the scallywag Claude Monet be the finest French painter to ever splash colors on a canvas, savvy?",
        "tool_calls": null,
        "prefix": false,
        "role": "assistant"
      },
      "finish_reason": "stop"
    }
  ]
}