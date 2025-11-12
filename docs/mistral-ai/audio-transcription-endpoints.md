Audio Transcriptions Endpoints
API for audio transcription.

Toggle themeWall AssetsCat FrameLampCat ToyLamp LightDeskChairOrange Cat IdleLamp LightScreenScreen LightLamp Light Large
Examples
Real world code examples

Create Transcription


POST
 /v1/audio/transcriptions


Request Body
application/json


file
File

The File object (not file name) to be uploaded. To upload a file and specify a custom file name you should format your request as such:


file=@path/to/your/file.jsonl;filename=custom_name.jsonl
Otherwise, you can just keep the original file name:


file=@path/to/your/file.jsonl

File
{object}
The File object (not file name) to be uploaded. To upload a file and specify a custom file name you should format your request as such:


file=@path/to/your/file.jsonl;filename=custom_name.jsonl
Otherwise, you can just keep the original file name:


file=@path/to/your/file.jsonl
content
*
binary

fileName
*
string

file_id
string|null

ID of a file uploaded to /v1/files

file_url
string|null

Url of a file to be transcribed

language
string|null

Language of the audio, e.g. 'en'. Providing the language can boost accuracy.


model
*
string

ID of the model to be used.

Examples:


voxtral-mini-latest

voxtral-mini-2507
stream
boolean

Default Value: false

temperature
number|null

timestamp_granularities
array<"segment">

Granularities of timestamps to include in the response.

200

Successful Response

language
*
string|null

model
*
string


segments
array<TranscriptionSegmentChunk>


TranscriptionSegmentChunk
{object}
end
*
number

start
*
number

text
*
string

type
"transcription_segment"

Default Value: "transcription_segment"

text
*
string


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

    res = mistral.audio.transcriptions.complete(model="Model X")

    # Handle response
    print(res)

200


{
  "model": "voxtral-mini-2507",
  "text": "This week, I traveled to Chicago to deliver my final farewell address to the nation, following in the tradition of presidents before me. It was an opportunity to say thank you. Whether we've seen eye to eye or rarely agreed at all, my conversations with you, the American people, in living rooms, in schools, at farms and on factory floors, at diners and on distant military outposts, All these conversations are what have kept me honest, kept me inspired, and kept me going. Every day, I learned from you. You made me a better President, and you made me a better man.\nOver the course of these eight years, I've seen the goodness, the resilience, and the hope of the American people. I've seen neighbors looking out for each other as we rescued our economy from the worst crisis of our lifetimes. I've hugged cancer survivors who finally know the security of affordable health care. I've seen communities like Joplin rebuild from disaster, and cities like Boston show the world that no terrorist will ever break the American spirit. I've seen the hopeful faces of young graduates and our newest military officers. I've mourned with grieving families searching for answers. And I found grace in a Charleston church. I've seen our scientists help a paralyzed man regain his sense of touch, and our wounded warriors walk again. I've seen our doctors and volunteers rebuild after earthquakes and stop pandemics in their tracks. I've learned from students who are building robots and curing diseases, and who will change the world in ways we can't even imagine. I've seen the youngest of children remind us of our obligations to care for our refugees, to work in peace, and above all, to look out for each other.\nThat's what's possible when we come together in the slow, hard, sometimes frustrating, but always vital work of self-government. But we can't take our democracy for granted. All of us, regardless of party, should throw ourselves into the work of citizenship. Not just when there is an election. Not just when our own narrow interest is at stake. But over the full span of a lifetime. If you're tired of arguing with strangers on the Internet, try to talk with one in real life. If something needs fixing, lace up your shoes and do some organizing. If you're disappointed by your elected officials, then grab a clipboard, get some signatures, and run for office yourself.\nOur success depends on our participation, regardless of which way the pendulum of power swings. It falls on each of us to be guardians of our democracy, to embrace the joyous task we've been given to continually try to improve this great nation of ours. Because for all our outward differences, we all share the same proud title – citizen.\nIt has been the honor of my life to serve you as President. Eight years later, I am even more optimistic about our country's promise. And I look forward to working along your side as a citizen for all my days that remain.\nThanks, everybody. God bless you. And God bless the United States of America.\n",
  "language": "en",
  "segments": [],
  "usage": {
    "prompt_audio_seconds": 203,
    "prompt_tokens": 4,
    "total_tokens": 3264,
    "completion_tokens": 635
  }
}
Create Streaming Transcription (SSE)


POST
 /v1/audio/transcriptions#stream


Request Body
application/json


file
File

The File object (not file name) to be uploaded. To upload a file and specify a custom file name you should format your request as such:


file=@path/to/your/file.jsonl;filename=custom_name.jsonl
Otherwise, you can just keep the original file name:


file=@path/to/your/file.jsonl
file_id
string|null

ID of a file uploaded to /v1/files

file_url
string|null

Url of a file to be transcribed

language
string|null

Language of the audio, e.g. 'en'. Providing the language can boost accuracy.

model
*
string

stream
boolean

Default Value: true

temperature
number|null

timestamp_granularities
array<"segment">

Granularities of timestamps to include in the response.

200

Response Type
event-stream<TranscriptionStreamEvents>
Stream of transcription events


TranscriptionStreamEvents
{object}

data
*
TranscriptionStreamTextDelta|TranscriptionStreamLanguage|TranscriptionStreamSegmentDelta|TranscriptionStreamDone


TranscriptionStreamTextDelta
{object}
text
*
string

type
"transcription.text.delta"

Default Value: "transcription.text.delta"


TranscriptionStreamLanguage
{object}
audio_language
*
string

type
"transcription.language"

Default Value: "transcription.language"


TranscriptionStreamSegmentDelta
{object}
end
*
number

start
*
number

text
*
string

type
"transcription.segment"

Default Value: "transcription.segment"


TranscriptionStreamDone
{object}
language
*
string|null

model
*
string


segments
array<TranscriptionSegmentChunk>


TranscriptionSegmentChunk
{object}
end
*
number

start
*
number

text
*
string

type
"transcription_segment"

Default Value: "transcription_segment"

text
*
string

type
"transcription.done"

Default Value: "transcription.done"


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

event
*
"transcription.language"|"transcription.segment"|"transcription.text.delta"|"transcription.done"


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.audio.transcriptions.stream(model="Camry")

    with res as event_stream:
        for event in event_stream:
            # handle event
            print(event, flush=True)

200


null