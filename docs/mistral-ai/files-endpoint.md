Files Endpoints
Files API

Toggle themeWall AssetsCat FrameLampCat ToyLamp LightDeskChairOrange Cat IdleLamp LightScreenScreen LightLamp Light Large
Examples
Real world code examples

List Files


GET
 /v1/files

Returns a list of files that belong to the user's organization.

200

OK


data
*
array<FileSchema>

object
*
string

total
*
integer


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.files.list(page=0, page_size=100)

    # Handle response
    print(res)

200


{
  "data": [
    {
      "id": "<your_file_id>",
      "object": "file",
      "bytes": null,
      "created_at": 1759491994,
      "filename": "<your_file_name>",
      "purpose": "batch",
      "sample_type": "batch_result",
      "source": "mistral",
      "num_lines": 2,
      "mimetype": "application/jsonl",
      "signature": null
    },
    {
      "id": "<your_file_id>",
      "object": "file",
      "bytes": null,
      "created_at": 1759491994,
      "filename": "<your_file_name>",
      "purpose": "batch",
      "sample_type": "batch_result",
      "source": "mistral",
      "num_lines": 2,
      "mimetype": "application/jsonl",
      "signature": null
    }
  ],
  "object": "list",
  "total": 2
}
Upload File


POST
 /v1/files

Upload a file that can be used across various endpoints.

The size of individual files can be a maximum of 512 MB. The Fine-tuning API only supports .jsonl files.

Please contact us if you need to increase these storage limits.


Request Body
application/json


file
*
File

The File object (not file name) to be uploaded. To upload a file and specify a custom file name you should format your request as such:


file=@path/to/your/file.jsonl;filename=custom_name.jsonl
Otherwise, you can just keep the original file name:


file=@path/to/your/file.jsonl
purpose
"fine-tune"|"batch"|"ocr"

200

OK


bytes
*
integer

The size of the file, in bytes.


created_at
*
integer

The UNIX timestamp (in seconds) of the event.


filename
*
string

The name of the uploaded file.


id
*
string

The unique identifier of the file.

mimetype
string|null

num_lines
integer|null


object
*
string

The object type, which is always "file".

purpose
*
"fine-tune"|"batch"|"ocr"

sample_type
*
"pretrain"|"instruct"|"batch_request"|"batch_result"|"batch_error"

signature
string|null

source
*
"upload"|"repository"|"mistral"


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.files.upload(file={
        "file_name": "example.file",
        "content": open("example.file", "rb"),
    })

    # Handle response
    print(res)

200


{
  "id": "e85980c9-409e-4a46-9304-36588f6292b0",
  "object": "file",
  "bytes": null,
  "created_at": 1759500189,
  "filename": "example.file.jsonl",
  "purpose": "fine-tune",
  "sample_type": "instruct",
  "source": "upload",
  "num_lines": 2,
  "mimetype": "application/jsonl",
  "signature": "d4821d2de1917341"
}
Retrieve File


GET
 /v1/files/{file_id}

Returns information about a specific file.


Parameters
application/json

file_id
*
string

200

OK


bytes
*
integer

The size of the file, in bytes.


created_at
*
integer

The UNIX timestamp (in seconds) of the event.

deleted
*
boolean


filename
*
string

The name of the uploaded file.


id
*
string

The unique identifier of the file.

mimetype
string|null

num_lines
integer|null


object
*
string

The object type, which is always "file".

purpose
*
"fine-tune"|"batch"|"ocr"

sample_type
*
"pretrain"|"instruct"|"batch_request"|"batch_result"|"batch_error"

signature
string|null

source
*
"upload"|"repository"|"mistral"


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.files.retrieve(file_id="f2a27685-ca4e-4dc2-9f2b-88c422c3e0f6")

    # Handle response
    print(res)

200


{
  "id": "e85980c9-409e-4a46-9304-36588f6292b0",
  "object": "file",
  "bytes": null,
  "created_at": 1759500189,
  "filename": "example.file.jsonl",
  "purpose": "fine-tune",
  "sample_type": "instruct",
  "source": "upload",
  "deleted": false,
  "num_lines": 2,
  "mimetype": "application/jsonl",
  "signature": "d4821d2de1917341"
}
Delete File


DELETE
 /v1/files/{file_id}

Delete a file.


Parameters
application/json

file_id
*
string

200

OK


deleted
*
boolean

The deletion status.


id
*
string

The ID of the deleted file.


object
*
string

The object type that was deleted


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.files.delete(file_id="3b6d45eb-e30b-416f-8019-f47e2e93d930")

    # Handle response
    print(res)

200


{
  "id": "e85980c9-409e-4a46-9304-36588f6292b0",
  "object": "file",
  "deleted": true
}
Download File


GET
 /v1/files/{file_id}/content

Download a file


Parameters
application/json

file_id
*
string

200

Response Type
binary
OK


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.files.download(file_id="f8919994-a4a1-46b2-8b5b-06335a4300ce")

    # Handle response
    print(res)

200


"ipsum eiusmod"
Get Signed Url


GET
 /v1/files/{file_id}/url


Parameters
application/json

file_id
*
string

expiry
integer

Number of hours before the url becomes invalid. Defaults to 24h

200

OK

url
*
string


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.files.get_signed_url(file_id="06a020ab-355c-49a6-b19d-304b7c01699f", expiry=24)

    # Handle response
    print(res)

200


{
  "url": "https://mistralaifilesapiprodswe.blob.core.windows.net/fine-tune/.../.../e85980c9409e4a46930436588f6292b0.jsonl?se=2025-10-04T14%3A16%3A17Z&sp=r&sv=2025-01-05&sr=b&sig=..."
}