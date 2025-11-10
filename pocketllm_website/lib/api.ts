const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL ?? ""

type WaitlistPayload = {
  name: string
  email: string
  source?: string
  metadata?: Record<string, any>
}

export async function joinWaitlist(payload: WaitlistPayload) {
  try {
    // Use the Next.js API route as a proxy to avoid CORS issues
    const response = await fetch('/api/waitlist', {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify(payload),
    })

    if (!response.ok) {
      const errorData = await response.json()
      throw new Error(errorData.error || "Failed to join waitlist")
    }

    return response.json()
  } catch (error) {
    console.error('Waitlist API error:', error)
    throw error
  }
}