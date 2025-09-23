import CryptoJS from 'crypto-js'

const ENCRYPTION_KEY = Deno.env.get('ENCRYPTION_KEY')

if (!ENCRYPTION_KEY || ENCRYPTION_KEY.length < 32) {
  throw new Error('A 32-byte ENCRYPTION_KEY is not set in environment variables.')
}

/**
 * Encrypts a string using AES.
 * @param text The plain text string to encrypt.
 * @returns The encrypted string (ciphertext).
 */
export function encrypt(text: string): string {
  return CryptoJS.AES.encrypt(text, ENCRYPTION_KEY).toString()
}

/**
 * Decrypts an AES-encrypted string.
 * @param ciphertext The encrypted string to decrypt.
 * @returns The original plain text string.
 */
export function decrypt(ciphertext: string): string {
  const bytes = CryptoJS.AES.decrypt(ciphertext, ENCRYPTION_KEY)
  const originalText = bytes.toString(CryptoJS.enc.Utf8)
  if (!originalText) {
    throw new Error('Decryption failed. The key may be incorrect or the ciphertext corrupted.')
  }
  return originalText
}
