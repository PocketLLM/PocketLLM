Embeddings Endpoints
Embeddings API.

Toggle themeWall AssetsCat FrameLampCat ToyLamp LightDeskChairOrange Cat IdleLamp LightScreenScreen LightLamp Light Large
Examples
Real world code examples

Embeddings


POST
 /v1/embeddings

Embeddings


Request Body
application/json

encoding_format
"float"|"base64"

input
*
string|array<string>

The text content to be embedded, can be a string or an array of strings for fast processing in bulk.


model
*
string

The ID of the model to be used for embedding.

Example:


mistral-embed
output_dimension
integer|null

The dimension of the output embeddings when feature available. If not provided, a default output dimension will be used.

output_dtype
"float"|"int8"|"uint8"|"binary"|"ubinary"

200

Successful Response


data
*
array<EmbeddingResponseData>


EmbeddingResponseData
{object}
embedding
array<number>


index
integer

Example:


0

object
string

Example:


embedding

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

    res = mistral.embeddings.create(model="mistral-embed", inputs=[
        "Embed this sentence.",
        "As well as this one.",
    ])

    # Handle response
    print(res)

200


{
  "data": [
    {
      "embedding": [
        -0.016632080078125,
        0.0701904296875,
        0.03143310546875,
        0.01309967041015625,
        0.0202789306640625
      ],
      "index": 0,
      "object": "embedding"
    },
    {
      "embedding": [
        -0.0230560302734375,
        0.039337158203125,
        0.0521240234375,
        -0.0184783935546875,
        0.034271240234375
      ],
      "index": 1,
      "object": "embedding"
    }
  ],
  "model": "mistral-embed",
  "object": "list",
  "usage": {
    "prompt_tokens": 15,
    "completion_tokens": 0,
    "total_tokens": 15,
    "prompt_audio_seconds": null
  }
}