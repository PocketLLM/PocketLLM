import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as CryptoJS from 'crypto-js';

@Injectable()
export class EncryptionService {
  private readonly encryptionKey: string;

  constructor(private configService: ConfigService) {
    this.encryptionKey = this.configService.get<string>('ENCRYPTION_KEY');
    
    if (!this.encryptionKey || this.encryptionKey.length < 32) {
      throw new Error('A 32-byte ENCRYPTION_KEY is not set in environment variables.');
    }
  }

  /**
   * Encrypts a string using AES.
   * @param text The plain text string to encrypt.
   * @returns The encrypted string (ciphertext).
   */
  encrypt(text: string): string {
    return CryptoJS.AES.encrypt(text, this.encryptionKey).toString();
  }

  /**
   * Decrypts an AES-encrypted string.
   * @param ciphertext The encrypted string to decrypt.
   * @returns The original plain text string.
   */
  decrypt(ciphertext: string): string {
    const bytes = CryptoJS.AES.decrypt(ciphertext, this.encryptionKey);
    const originalText = bytes.toString(CryptoJS.enc.Utf8);
    
    if (!originalText) {
      throw new Error('Decryption failed. The key may be incorrect or the ciphertext corrupted.');
    }
    
    return originalText;
  }
}
