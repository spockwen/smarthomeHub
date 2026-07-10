import { huks } from '@kit.UniversalKeystoreKit'
import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { util } from '@kit.ArkTS'

const HUKS_KEY_ALIAS: string = 'smarthome_ai_aes256_key'
const ENCRYPTED_KEY_STORAGE: string = 'encrypted_api_key'

function stringToUint8Array(str: string): Uint8Array {
  const arr: number[] = []
  for (let i = 0; i < str.length; i++) {
    arr.push(str.charCodeAt(i))
  }
  return new Uint8Array(arr)
}

function uint8ArrayToString(data: Uint8Array): string {
  let result: string = ''
  for (let i = 0; i < data.length; i++) {
    result += String.fromCharCode(data[i])
  }
  return result
}

function base64Encode(data: Uint8Array): string {
  const helper = new util.Base64Helper()
  const result = helper.encodeToStringSync(data)
  return result
}

function base64Decode(str: string): Uint8Array {
  const helper = new util.Base64Helper()
  return helper.decodeSync(str)
}

export class SecureKeyManager {
  private static isKeyInitialized: boolean = false

  static getHuksKeyAlias(): string {
    return HUKS_KEY_ALIAS
  }

  private static getGenerateProperties(): huks.HuksParam[] {
    return [
      {
        tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
        value: huks.HuksKeyAlg.HUKS_ALG_AES
      },
      {
        tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
        value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
      },
      {
        tag: huks.HuksTag.HUKS_TAG_PURPOSE,
        value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT |
          huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
      },
      {
        tag: huks.HuksTag.HUKS_TAG_PADDING,
        value: huks.HuksKeyPadding.HUKS_PADDING_NONE
      },
      {
        tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
        value: huks.HuksCipherMode.HUKS_MODE_GCM
      }
    ]
  }

  private static getEncryptProperties(nonce: Uint8Array, aad: Uint8Array): huks.HuksParam[] {
    return [
      {
        tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
        value: huks.HuksKeyAlg.HUKS_ALG_AES
      },
      {
        tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
        value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
      },
      {
        tag: huks.HuksTag.HUKS_TAG_PURPOSE,
        value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT
      },
      {
        tag: huks.HuksTag.HUKS_TAG_PADDING,
        value: huks.HuksKeyPadding.HUKS_PADDING_NONE
      },
      {
        tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
        value: huks.HuksCipherMode.HUKS_MODE_GCM
      },
      {
        tag: huks.HuksTag.HUKS_TAG_NONCE,
        value: nonce
      },
      {
        tag: huks.HuksTag.HUKS_TAG_ASSOCIATED_DATA,
        value: aad
      }
    ]
  }

  private static getDecryptProperties(nonce: Uint8Array, aad: Uint8Array): huks.HuksParam[] {
    return [
      {
        tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
        value: huks.HuksKeyAlg.HUKS_ALG_AES
      },
      {
        tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
        value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
      },
      {
        tag: huks.HuksTag.HUKS_TAG_PURPOSE,
        value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
      },
      {
        tag: huks.HuksTag.HUKS_TAG_PADDING,
        value: huks.HuksKeyPadding.HUKS_PADDING_NONE
      },
      {
        tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
        value: huks.HuksCipherMode.HUKS_MODE_GCM
      },
      {
        tag: huks.HuksTag.HUKS_TAG_NONCE,
        value: nonce
      },
      {
        tag: huks.HuksTag.HUKS_TAG_ASSOCIATED_DATA,
        value: aad
      }
    ]
  }

  static async isKeyExist(): Promise<boolean> {
    try {
      const result = await huks.isKeyItemExist(HUKS_KEY_ALIAS, { properties: [] })
      return result
    } catch (e) {
      return false
    }
  }

  static async generateAesKey(): Promise<boolean> {
    const exist = await SecureKeyManager.isKeyExist()
    if (exist) {
      SecureKeyManager.isKeyInitialized = true
      return true
    }
    try {
      const properties = SecureKeyManager.getGenerateProperties()
      const options: huks.HuksOptions = { properties: properties }
      await huks.generateKeyItem(HUKS_KEY_ALIAS, options)
      SecureKeyManager.isKeyInitialized = true
      console.info('[SecureKeyManager] AES-256-GCM key generated via HUKS')
      return true
    } catch (e) {
      console.error('[SecureKeyManager] generateKeyItem failed:', JSON.stringify(e))
      return false
    }
  }

  static async generateNonce(): Promise<Uint8Array> {
    const random = cryptoFramework.createRandom()
    const randomData = await random.generateRandom(12)
    return randomData.data
  }

  static async encryptData(plainText: string, nonce: Uint8Array): Promise<Uint8Array> {
    const aad: Uint8Array = stringToUint8Array('SmartHomeAIHub')
    const properties = SecureKeyManager.getEncryptProperties(nonce, aad)
    const inData: Uint8Array = stringToUint8Array(plainText)
    const options: huks.HuksOptions = {
      properties: properties,
      inData: inData
    }

    let handle: number = 0
    try {
      const initResult = await huks.initSession(HUKS_KEY_ALIAS, options)
      handle = initResult.handle
    } catch (e) {
      const errMsg = e instanceof Error ? e.message : JSON.stringify(e)
      console.error('[SecureKeyManager] encrypt initSession failed:', errMsg)
      throw new Error('Encrypt init failed: ' + errMsg)
    }

    try {
      const finishResult = await huks.finishSession(handle, options)
      const outData = finishResult.outData
      if (outData === undefined || outData === null) {
        throw new Error('Encrypt outData is undefined')
      }
      const cipherOut = outData as Uint8Array
      console.info('[SecureKeyManager] encrypt success, cipher length:', cipherOut.length)
      return cipherOut
    } catch (e) {
      const errMsg = e instanceof Error ? e.message : JSON.stringify(e)
      console.error('[SecureKeyManager] encrypt finishSession failed:', errMsg)
      throw new Error('Encrypt finish failed: ' + errMsg)
    }
  }

  static async decryptData(cipherData: Uint8Array, nonce: Uint8Array): Promise<string> {
    const aad: Uint8Array = stringToUint8Array('SmartHomeAIHub')
    const properties = SecureKeyManager.getDecryptProperties(nonce, aad)
    const options: huks.HuksOptions = {
      properties: properties,
      inData: cipherData
    }

    let handle: number = 0
    try {
      const initResult = await huks.initSession(HUKS_KEY_ALIAS, options)
      handle = initResult.handle
    } catch (e) {
      const errMsg = e instanceof Error ? e.message : JSON.stringify(e)
      console.error('[SecureKeyManager] decrypt initSession failed:', errMsg)
      throw new Error('Decrypt init failed: ' + errMsg)
    }

    try {
      const finishResult = await huks.finishSession(handle, options)
      const outData = finishResult.outData
      if (outData === undefined || outData === null) {
        throw new Error('Decrypt outData is undefined')
      }
      const plainText = uint8ArrayToString(outData as Uint8Array)
      console.info('[SecureKeyManager] decrypt success')
      return plainText
    } catch (e) {
      const errMsg = e instanceof Error ? e.message : JSON.stringify(e)
      console.error('[SecureKeyManager] decrypt finishSession failed:', errMsg)
      throw new Error('Decrypt finish failed: ' + errMsg)
    }
  }

  static async storeEncryptedApiKey(apiKey: string): Promise<boolean> {
    try {
      const keyReady = await SecureKeyManager.generateAesKey()
      if (!keyReady) {
        console.error('[SecureKeyManager] key not ready')
        return false
      }

      const nonce = await SecureKeyManager.generateNonce()
      const cipherData = await SecureKeyManager.encryptData(apiKey, nonce)

      const nonceBase64: string = base64Encode(nonce)
      const cipherBase64: string = base64Encode(cipherData)
      const storageValue: string = nonceBase64 + ':' + cipherBase64

      AppStorage.setOrCreate(ENCRYPTED_KEY_STORAGE, storageValue)
      console.info('[SecureKeyManager] API key encrypted and stored')
      return true
    } catch (e) {
      console.error('[SecureKeyManager] storeEncryptedApiKey failed:', JSON.stringify(e))
      return false
    }
  }

  static async retrieveApiKey(): Promise<string> {
    const stored: string = AppStorage.get<string>(ENCRYPTED_KEY_STORAGE) || ''
    if (stored.length === 0) {
      return ''
    }

    const parts: string[] = stored.split(':')
    if (parts.length !== 2) {
      console.error('[SecureKeyManager] invalid stored format')
      return ''
    }

    try {
      const keyReady = await SecureKeyManager.generateAesKey()
      if (!keyReady) {
        console.error('[SecureKeyManager] key not ready for decrypt')
        return ''
      }

      const nonce: Uint8Array = base64Decode(parts[0])
      const cipherData: Uint8Array = base64Decode(parts[1])
      const plainText: string = await SecureKeyManager.decryptData(cipherData, nonce)
      return plainText
    } catch (e) {
      console.error('[SecureKeyManager] retrieveApiKey failed:', JSON.stringify(e))
      return ''
    }
  }

  static hasStoredKey(): boolean {
    const stored: string = AppStorage.get<string>(ENCRYPTED_KEY_STORAGE) || ''
    return stored.length > 0
  }

  static async deleteKey(): Promise<void> {
    try {
      const exist = await SecureKeyManager.isKeyExist()
      if (exist) {
        await huks.deleteKeyItem(HUKS_KEY_ALIAS, { properties: [] })
        console.info('[SecureKeyManager] HUKS key deleted')
      }
    } catch (e) {
      console.error('[SecureKeyManager] deleteKey failed:', JSON.stringify(e))
    }
    AppStorage.setOrCreate(ENCRYPTED_KEY_STORAGE, '')
    SecureKeyManager.isKeyInitialized = false
  }
}
