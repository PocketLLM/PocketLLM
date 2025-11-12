# Get Cost Report - Claude Docs> Source: https://docs.claude.com/en/api/admin-api/usage-cost/get-cost-reportAgent Skills are now available! [Learn more about extending Claude's capabilities with Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview).
[Claude Docs home page![light logo](https://mintcdn.com/anthropic-claude-docs/DcI2Ybid7ZEnFaf0/logo/light.svg?fit=max&auto=format&n=DcI2Ybid7ZEnFaf0&q=85&s=c877c45432515ee69194cb19e9f983a2)![dark logo](https://mintcdn.com/anthropic-claude-docs/DcI2Ybid7ZEnFaf0/logo/dark.svg?fit=max&auto=format&n=DcI2Ybid7ZEnFaf0&q=85&s=f5bb877be0cb3cba86cf6d7c88185216)](https://docs.claude.com/)
![US](https://d3gk2c5xim1je2.cloudfront.net/flags/US.svg)
English
Search...
Ctrl K
  * [Console](https://console.anthropic.com/login)
  * [Support](https://support.claude.com/)
  * [Discord](https://www.anthropic.com/discord)
  * [Sign up](https://console.anthropic.com/login)
  * [Sign up](https://console.anthropic.com/login)


Search...
Navigation
Usage and Cost
Get Cost Report
[Home](https://docs.claude.com/en/home)[Developer Guide](https://docs.claude.com/en/docs/intro)[API Reference](https://docs.claude.com/en/api/overview)[Model Context Protocol (MCP)](https://docs.claude.com/en/docs/mcp)[Resources](https://docs.claude.com/en/resources/overview)[Release Notes](https://docs.claude.com/en/release-notes/overview)
##### Using the API
  * [Features overview](https://docs.claude.com/en/api/overview)
  * [Client SDKs](https://docs.claude.com/en/api/client-sdks)
  * [Beta headers](https://docs.claude.com/en/api/beta-headers)
  * [Errors](https://docs.claude.com/en/api/errors)


##### Messages
  * [POSTMessages](https://docs.claude.com/en/api/messages)
  * [POSTCount Message tokens](https://docs.claude.com/en/api/messages-count-tokens)


##### Models
  * [GETList Models](https://docs.claude.com/en/api/models-list)
  * [GETGet a Model](https://docs.claude.com/en/api/models)


##### Message Batches
  * [POSTCreate a Message Batch](https://docs.claude.com/en/api/creating-message-batches)
  * [GETRetrieve a Message Batch](https://docs.claude.com/en/api/retrieving-message-batches)
  * [GETRetrieve Message Batch Results](https://docs.claude.com/en/api/retrieving-message-batch-results)
  * [GETList Message Batches](https://docs.claude.com/en/api/listing-message-batches)
  * [POSTCancel a Message Batch](https://docs.claude.com/en/api/canceling-message-batches)
  * [DELDelete a Message Batch](https://docs.claude.com/en/api/deleting-message-batches)


##### Files
  * [POSTCreate a File](https://docs.claude.com/en/api/files-create)
  * [GETList Files](https://docs.claude.com/en/api/files-list)
  * [GETGet File Metadata](https://docs.claude.com/en/api/files-metadata)
  * [GETDownload a File](https://docs.claude.com/en/api/files-content)
  * [DELDelete a File](https://docs.claude.com/en/api/files-delete)


##### Skills
  * Skill Management
  * Skill Versions


##### Admin API
  * Organization Info
  * Organization Member Management
  * Organization Invites
  * Workspace Management
  * Workspace Member Management
  * API Keys
  * Usage and Cost
    * [GETGet Usage Report for the Messages API](https://docs.claude.com/en/api/admin-api/usage-cost/get-messages-usage-report)
    * [GETGet Cost Report](https://docs.claude.com/en/api/admin-api/usage-cost/get-cost-report)
    * [GETGet Claude Code Usage Report](https://docs.claude.com/en/api/admin-api/claude-code/get-claude-code-usage-report)


##### Experimental APIs
  * Prompt tools


##### Text Completions (Legacy)
  * [Migrating from Text Completions](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages)


##### Support & configuration
  * [Rate limits](https://docs.claude.com/en/api/rate-limits)
  * [Service tiers](https://docs.claude.com/en/api/service-tiers)
  * [Versions](https://docs.claude.com/en/api/versioning)
  * [IP addresses](https://docs.claude.com/en/api/ip-addresses)
  * [Supported regions](https://docs.claude.com/en/api/supported-regions)
  * [OpenAI SDK compatibility](https://docs.claude.com/en/api/openai-sdk)


cURL
cURL
Copy
```
curl "https://api.anthropic.com/v1/organizations/cost_report\
?starting_at=2025-08-01T00:00:00Z\
&group_by[]=workspace_id\
&group_by[]=description\
&limit=1" \
  --header "anthropic-version: 2023-06-01" \
  --header "content-type: application/json" \
  --header "x-api-key: $ANTHROPIC_ADMIN_KEY"
```

200
4XX
Copy
```
{
  "data": [
    {
      "starting_at": "2025-08-01T00:00:00Z",
      "ending_at": "2025-08-02T00:00:00Z",
      "results": [
        {
          "currency": "USD",
          "amount": "123.78912",
          "workspace_id": "wrkspc_01JwQvzr7rXLA5AGx3HKfFUJ",
          "description": "Claude Sonnet 4 Usage - Input Tokens",
          "cost_type": "tokens",
          "context_window": "0-200k",
          "model": "claude-sonnet-4-20250514",
          "service_tier": "standard",
          "token_type": "uncached_input_tokens"
        }
      ]
    }
  ],
  "has_more": true,
  "next_page": "page_MjAyNS0wNS0xNFQwMDowMDowMFo="
}
```

Usage and Cost
# Get Cost Report
Copy page
Copy page
GET
/
v1
/
organizations
/
cost_report
cURL
cURL
Copy
```
curl "https://api.anthropic.com/v1/organizations/cost_report\
?starting_at=2025-08-01T00:00:00Z\
&group_by[]=workspace_id\
&group_by[]=description\
&limit=1" \
  --header "anthropic-version: 2023-06-01" \
  --header "content-type: application/json" \
  --header "x-api-key: $ANTHROPIC_ADMIN_KEY"
```

200
4XX
Copy
```
{
  "data": [
    {
      "starting_at": "2025-08-01T00:00:00Z",
      "ending_at": "2025-08-02T00:00:00Z",
      "results": [
        {
          "currency": "USD",
          "amount": "123.78912",
          "workspace_id": "wrkspc_01JwQvzr7rXLA5AGx3HKfFUJ",
          "description": "Claude Sonnet 4 Usage - Input Tokens",
          "cost_type": "tokens",
          "context_window": "0-200k",
          "model": "claude-sonnet-4-20250514",
          "service_tier": "standard",
          "token_type": "uncached_input_tokens"
        }
      ]
    }
  ],
  "has_more": true,
  "next_page": "page_MjAyNS0wNS0xNFQwMDowMDowMFo="
}
```

**The Admin API is unavailable for individual accounts.** To collaborate with teammates and add members, set up your organization in **Console → Settings → Organization**.
#### Headers
[​](https://docs.claude.com/en/api/admin-api/usage-cost/get-cost-report#parameter-x-api-key)
x-api-key
string
required
Your unique Admin API key for authentication.
This key is required in the header of all Admin API requests, to authenticate your account and access Anthropic's services. Get your Admin API key through the [Console](https://console.anthropic.com/settings/admin-keys).
[​](https://docs.claude.com/en/api/admin-api/usage-cost/get-cost-report#parameter-anthropic-version)
anthropic-version
string
required
The version of the Claude API you want to use.
Read more about versioning and our version history [here](https://docs.claude.com/en/docs/build-with-claude/versioning).
#### Query Parameters
[​](https://docs.claude.com/en/api/admin-api/usage-cost/get-cost-report#parameter-limit)
limit
integer
default:7
Maximum number of time buckets to return in the response.
Required range: `1 <= x <= 31`
Examples:
`7`
[​](https://docs.claude.com/en/api/admin-api/usage-cost/get-cost-report#parameter-page)
page
string<date-time> | null
Optionally set to the `next_page` token from the previous response.
Examples:
`"page_MjAyNS0wNS0xNFQwMDowMDowMFo="`
`null`
[​](https://docs.claude.com/en/api/admin-api/usage-cost/get-cost-report#parameter-starting-at)
starting_at
string<date-time>
required
Time buckets that start on or after this RFC 3339 timestamp will be returned. Each time bucket will be snapped to the start of the minute/hour/day in UTC.
Examples:
`"2024-10-30T23:58:27.427722Z"`
[​](https://docs.claude.com/en/api/admin-api/usage-cost/get-cost-report#parameter-ending-at)
ending_at
string<date-time> | null
Time buckets that end before this RFC 3339 timestamp will be returned.
Examples:
`"2024-10-30T23:58:27.427722Z"`
[​](https://docs.claude.com/en/api/admin-api/usage-cost/get-cost-report#parameter-group-by)
group_by[]
enum<string>[] | null
Group by any subset of the available options.
Show child attributes
Examples:
`"workspace_id"`
`"description"`
[​](https://docs.claude.com/en/api/admin-api/usage-cost/get-cost-report#parameter-bucket-width)
bucket_width
enum<string>
Time granularity of the response data.
Available options: Title | Const  
---|---  
CostReportTimeBucketWidth | `1d`  
#### Response
200
application/json
Successful Response
[​](https://docs.claude.com/en/api/admin-api/usage-cost/get-cost-report#response-data)
data
CostReportTimeBucket · object[]
required
Show child attributes
[​](https://docs.claude.com/en/api/admin-api/usage-cost/get-cost-report#response-has-more)
has_more
boolean
required
Indicates if there are more results.
[​](https://docs.claude.com/en/api/admin-api/usage-cost/get-cost-report#response-next-page)
next_page
string<date-time> | null
required
Token to provide in as `page` in the subsequent request to retrieve the next page of data.
Examples:
`"page_MjAyNS0wNS0xNFQwMDowMDowMFo="`
`null`
Was this page helpful?
YesNo
[Get Usage Report for the Messages API](https://docs.claude.com/en/api/admin-api/usage-cost/get-messages-usage-report)[Get Claude Code Usage Report](https://docs.claude.com/en/api/admin-api/claude-code/get-claude-code-usage-report)
Assistant
Responses are generated using AI and may contain mistakes.
[Claude Docs home page![light logo](https://mintcdn.com/anthropic-claude-docs/DcI2Ybid7ZEnFaf0/logo/light.svg?fit=max&auto=format&n=DcI2Ybid7ZEnFaf0&q=85&s=c877c45432515ee69194cb19e9f983a2)![dark logo](https://mintcdn.com/anthropic-claude-docs/DcI2Ybid7ZEnFaf0/logo/dark.svg?fit=max&auto=format&n=DcI2Ybid7ZEnFaf0&q=85&s=f5bb877be0cb3cba86cf6d7c88185216)](https://docs.claude.com/)
[x](https://x.com/AnthropicAI)[linkedin](https://www.linkedin.com/company/anthropicresearch)
Company
[Anthropic](https://www.anthropic.com/company)[Careers](https://www.anthropic.com/careers)[Economic Futures](https://www.anthropic.com/economic-futures)[Research](https://www.anthropic.com/research)[News](https://www.anthropic.com/news)[Trust center](https://trust.anthropic.com/)[Transparency](https://www.anthropic.com/transparency)
Help and security
[Availability](https://www.anthropic.com/supported-countries)[Status](https://status.anthropic.com/)[Support center](https://support.claude.com/)
Learn
[Courses](https://www.anthropic.com/learn)[MCP connectors](https://claude.com/partners/mcp)[Customer stories](https://www.claude.com/customers)[Engineering blog](https://www.anthropic.com/engineering)[Events](https://www.anthropic.com/events)[Powered by Claude](https://claude.com/partners/powered-by-claude)[Service partners](https://claude.com/partners/services)[Startups program](https://claude.com/programs/startups)
Terms and policies
[Privacy policy](https://www.anthropic.com/legal/privacy)[Disclosure policy](https://www.anthropic.com/responsible-disclosure-policy)[Usage policy](https://www.anthropic.com/legal/aup)[Commercial terms](https://www.anthropic.com/legal/commercial-terms)[Consumer terms](https://www.anthropic.com/legal/consumer-terms)
