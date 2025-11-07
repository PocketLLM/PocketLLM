const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL ?? "https://pocket-llm-api.vercel.app/v1"

type WaitlistPayload = {
  name: string
  email: string
  source?: string
}

export async function joinWaitlist(payload: WaitlistPayload) {
  const response = await fetch(`${API_BASE_URL}/waitlist`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify(payload),
  })

  if (!response.ok) {
    const message = (await response.text()).trim()
    throw new Error(message.length > 0 ? message : "Failed to join waitlist")
  }

  return response.json()
}
