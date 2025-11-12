Chat Endpoints
Chat Completion API.

Toggle themeWall AssetsCat FrameLampCat ToyLamp LightDeskChairOrange Cat IdleLamp LightScreenScreen LightLamp Light Large
Examples
Real world code examples

Chat Completion


POST
 /v1/chat/completions


Request Body
application/json

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


SystemMessage
{object}

content
*
string|array<TextChunk|ThinkChunk>


TextChunk
{object}
text
*
string

type
"text"

Default Value: "text"


ThinkChunk
{object}

closed
boolean

Default Value: true

Whether the thinking chunk is closed or not. Currently only used for prefixing.


thinking
*
array<ReferenceChunk|TextChunk>


ReferenceChunk
{object}
reference_ids
*
array<integer>

type
"reference"

Default Value: "reference"


TextChunk
{object}
text
*
string

type
"text"

Default Value: "text"

type
"thinking"

Default Value: "thinking"

role
"system"

Default Value: "system"


UserMessage
{object}

content
*
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


ImageURL
{object}
detail
string|null

url
*
string

type
"image_url"

Default Value: "image_url"


DocumentURLChunk
{object}

document_name
string|null

The filename of the document

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

Whether the thinking chunk is closed or not. Currently only used for prefixing.


thinking
*
array<ReferenceChunk|TextChunk>


ReferenceChunk
{object}
reference_ids
*
array<integer>

type
"reference"

Default Value: "reference"


TextChunk
{object}
text
*
string

type
"text"

Default Value: "text"

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
"user"

Default Value: "user"


AssistantMessage
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


ImageURL
{object}
detail
string|null

url
*
string

type
"image_url"

Default Value: "image_url"


DocumentURLChunk
{object}

document_name
string|null

The filename of the document

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

Whether the thinking chunk is closed or not. Currently only used for prefixing.


thinking
*
array<ReferenceChunk|TextChunk>


ReferenceChunk
{object}
reference_ids
*
array<integer>

type
"reference"

Default Value: "reference"


TextChunk
{object}
text
*
string

type
"text"

Default Value: "text"

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


prefix
boolean

Default Value: false

Set this to true when adding an assistant message as prefix to condition the model response. The role of the prefix message is to force the model to start its answer by the content of the message.

role
"assistant"

Default Value: "assistant"


tool_calls
array<ToolCall>|null


ToolCall
{object}

function
*
FunctionCall


FunctionCall
{object}
arguments
*
map<any>|string

name
*
string

id
string

Default Value: "null"

index
integer

Default Value: 0

type
"function"


ToolMessage
{object}

model
*
string

ID of the model to use. You can use the List Available Models API to see all of your available models, or see our Model overview for model descriptions.

Example:


mistral-large-latest
n
integer|null

Number of completions to return for each request, input tokens are only billed once.

parallel_tool_calls
boolean

Default Value: true

Whether to enable parallel function calling during tool use, when enabled the model can call multiple tools in parallel.


prediction
Prediction|null

Enable users to specify an expected completion, optimizing response times by leveraging known or predictable content.


Prediction
{object}
Enable users to specify an expected completion, optimizing response times by leveraging known or predictable content.

content
string

Default Value: ""

type
string

Default Value: "content"

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


ResponseFormat
{object}
Specify the format that the model must output. By default it will use \{ "type": "text" \}. Setting to \{ "type": "json_object" \} enables JSON mode, which guarantees the message the model generates is in JSON. When using JSON mode you MUST also instruct the model to produce JSON yourself with a system or a user message. Setting to \{ "type": "json_schema" \} enables JSON schema mode, which guarantees the message the model generates is in JSON and follows the schema you provide.


json_schema
JsonSchema|null


JsonSchema
{object}
description
string|null

name
*
string

schema_definition
*
map<any>

strict
boolean

Default Value: false

type
"text"|"json_object"|"json_schema"

safe_prompt
boolean

Default Value: false

Whether to inject a safety prompt before all conversations.

stop
string|array<string>

Stop generation if this token is detected. Or if one of these tokens is detected when providing an array

stream
boolean

Default Value: false

Whether to stream back partial progress. If set, tokens will be sent as data-only server-side events as they become available, with the stream terminated by a data: [DONE] message. Otherwise, the server will hold the request open until the timeout or until completion, with the response containing the full result as JSON.

temperature
number|null

What sampling temperature to use, we recommend between 0.0 and 0.7. Higher values like 0.7 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or top_p but not both. The default value varies depending on the model you are targeting. Call the /models endpoint to retrieve the appropriate value.


tool_choice
ToolChoice|"auto"|"none"|"any"|"required"

Controls which (if any) tool is called by the model. none means the model will not call any tool and instead generates a message. auto means the model can pick between generating a message or calling one or more tools. any or required means the model must call one or more tools. Specifying a particular tool via \{"type": "function", "function": \{"name": "my_function"\}\} forces the model to call that tool.


ToolChoice
{object}
ToolChoice is either a ToolChoiceEnum or a ToolChoice


function
*
FunctionName

this restriction of Function is used to select a specific function to call


FunctionName
{object}
this restriction of Function is used to select a specific function to call

name
*
string

type
"function"


tools
array<Tool>|null

A list of tools the model may call. Use this to provide a list of functions the model may generate JSON inputs for.


Tool
{object}

function
*
Function


Function
{object}
description
string

Default Value: ""

name
*
string

parameters
*
map<any>

strict
boolean

Default Value: false

type
"function"

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


ChatCompletionChoice
{object}

finish_reason
*
"stop"|"length"|"model_length"|"error"|"tool_calls"

Example:


stop

index
*
integer

Example:


0

message
*
AssistantMessage


AssistantMessage
{object}

content
string|array<TextChunk|ImageURLChunk|DocumentURLChunk|ReferenceChunk|FileChunk|ThinkChunk|AudioChunk>|null


TextChunk
{object}

ImageURLChunk
{object}

DocumentURLChunk
{object}

ReferenceChunk
{object}

FileChunk
{object}

ThinkChunk
{object}

AudioChunk
{object}

prefix
boolean

Default Value: false

Set this to true when adding an assistant message as prefix to condition the model response. The role of the prefix message is to force the model to start its answer by the content of the message.

role
"assistant"

Default Value: "assistant"


tool_calls
array<ToolCall>|null


ToolCall
{object}

function
*
FunctionCall


FunctionCall
{object}
arguments
*
map<any>|string

name
*
string

id
string

Default Value: "null"

index
integer

Default Value: 0

type
"function"


created
*
integer

Example:


1702256327

id
*
string

Example:


cmpl-e5cc70bb28c444948073e77776eb30ef

model
*
string

Example:


mistral-small-latest

object
*
string

Example:


chat.completion

usage
*
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


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.chat.complete(model="mistral-small-latest", messages=[
        {
            "content": "Who is the best French painter? Answer in one short sentence.",
            "role": "user",
        },
    ], stream=False)

    # Handle response
    print(res)

200 (application/json)

200 (text/event-stream)


{
  "choices": [
    {
      "finish_reason": "stop",
      "index": "0",
      "message": {}
    }
  ],
  "created": "1702256327",
  "id": "cmpl-e5cc70bb28c444948073e77776eb30ef",
  "model": "mistral-small-latest",
  "object": "chat.completion",
  "usage": {}
}