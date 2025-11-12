Fim Endpoints
Fill-in-the-middle API.

Toggle themeWall AssetsCat FrameLampCat ToyLamp LightDeskChairOrange Cat IdleLamp LightScreenScreen LightLamp Light Large
Examples
Real world code examples

Fim Completion


POST
 /v1/fim/completions

FIM completion.


Request Body
application/json

max_tokens
integer|null

The maximum number of tokens to generate in the completion. The token count of your prompt plus max_tokens cannot exceed the model's context length.

min_tokens
integer|null

The minimum number of tokens to generate in the completion.


model
string

Default Value: "codestral-2404"

ID of the model with FIM to use.


prompt
*
string

The text/code to complete.

random_seed
integer|null

The seed to use for random sampling. If set, different calls will generate deterministic results.

stop
string|array<string>

Stop generation if this token is detected. Or if one of these tokens is detected when providing an array

stream
boolean

Default Value: false

Whether to stream back partial progress. If set, tokens will be sent as data-only server-side events as they become available, with the stream terminated by a data: [DONE] message. Otherwise, the server will hold the request open until the timeout or until completion, with the response containing the full result as JSON.


suffix
string|null

Optional text/code that adds more context for the model. When given a prompt and a suffix the model will fill what is between them. When suffix is not provided, the model will simply execute completion starting with prompt.

Example:


return a+b
temperature
number|null

What sampling temperature to use, we recommend between 0.0 and 0.7. Higher values like 0.7 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or top_p but not both. The default value varies depending on the model you are targeting. Call the /models endpoint to retrieve the appropriate value.

top_p
number

Default Value: 1

Nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. We generally recommend altering this or temperature but not both.

200 (application/json)

200 (text/event-stream)

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

    res = mistral.fim.complete(model="codestral-2405", prompt="def", top_p=1, stream=False, suffix="return a+b")

    # Handle response
    print(res)

200 (application/json)

200 (text/event-stream)


{
  "id": "447e3e0d457e42e98248b5d2ef52a2a3",
  "object": "chat.completion",
  "model": "codestral-2508",
  "usage": {
    "prompt_tokens": 8,
    "completion_tokens": 91,
    "total_tokens": 99
  },
  "created": 1759496862,
  "choices": [
    {
      "index": 0,
      "message": {
        "content": "add_numbers(a: int, b: int) -> int:\n    \"\"\"\n    You are given two integers `a` and `b`. Your task is to write a function that\n    returns the sum of these two integers. The function should be implemented in a\n    way that it can handle very large integers (up to 10^18). As a reminder, your\n    code has to be in python\n    \"\"\"\n",
        "tool_calls": null,
        "prefix": false,
        "role": "assistant"
      },
      "finish_reason": "stop"
    }
  ]
}



Nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. We generally recommend altering this or temperature but not both.

200 (application/json)

200 (text/event-stream)

Response Type
event-stream<CompletionEvent>
Successful Response


CompletionEvent
{object}

data
*
CompletionChunk


CompletionChunk
{object}

choices
*
array<CompletionResponseStreamChoice>


CompletionResponseStreamChoice
{object}

delta
*
DeltaMessage


DeltaMessage
{object}

content
string|array<TextChunk|ImageURLChunk|DocumentURLChunk|ReferenceChunk|FileChunk|ThinkChunk|AudioChunk>|null


TextChunk
{object}
text
*
string

type
"text"

Default Value: "text"


ImageURLChunk
{object}
{"type":"image_url","image_url":{"url":"data
/png;base64,iVBORw0


image_url
*
ImageURL|string

type
"image_url"

Default Value: "image_url"


DocumentURLChunk
{object}

document_name
string|null

document_url
*
string

type
"document_url"

Default Value: "document_url"


ReferenceChunk
{object}
reference_ids
*
array<integer>

type
"reference"

Default Value: "reference"


FileChunk
{object}
file_id
*
string

type
string

Default Value: "file"


ThinkChunk
{object}

closed
boolean

Default Value: true


thinking
*
array<ReferenceChunk|TextChunk>

type
"thinking"

Default Value: "thinking"


AudioChunk
{object}
input_audio
*
string

type
"input_audio"

Default Value: "input_audio"

role
string|null


tool_calls
array<ToolCall>|null

finish_reason
*
"stop"|"length"|"error"|"tool_calls"

index
*
integer

created
integer

id
*
string

model
*
string

object
string


usage
UsageInfo


UsageInfo
{object}
completion_tokens
integer

Default Value: 0

prompt_audio_seconds
integer|null

prompt_tokens
integer

Default Value: 0

total_tokens
integer

Default Value: 0