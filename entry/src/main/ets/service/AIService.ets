import http from '@ohos.net.http'
import { SecureKeyManager } from './SecureKeyManager'

export class ChatMessage {
  role: string = ''
  content: string = ''

  constructor(role: string, content: string) {
    this.role = role
    this.content = content
  }
}

export class ChatRequest {
  model: string = ''
  messages: ChatMessage[] = []
  stream: boolean = false

  constructor(model: string, messages: ChatMessage[], stream: boolean = false) {
    this.model = model
    this.messages = messages
    this.stream = stream
  }
}

export class ChatResponse {
  id: string = ''
  choices: ChatChoice[] = []

  constructor() {
    this.choices = []
  }
}

export class ChatChoice {
  index: number = 0
  message: ChatMessage = new ChatMessage('', '')
  finish_reason: string = ''

  constructor() {
    this.message = new ChatMessage('', '')
  }
}

export class APIConfig {
  apiKey: string = ''
  baseUrl: string = ''
  model: string = ''

  constructor(apiKey: string, baseUrl: string, model: string) {
    this.apiKey = apiKey
    this.baseUrl = baseUrl
    this.model = model
  }
}

export class HttpHeader {
  contentType: string = ''
  authorization: string = ''

  constructor(contentType: string, authorization: string) {
    this.contentType = contentType
    this.authorization = authorization
  }
}

export class RequestPayload {
  model: string = ''
  messages: MessageItem[] = []
  stream: boolean = false

  constructor(model: string, messages: MessageItem[], stream: boolean) {
    this.model = model
    this.messages = messages
    this.stream = stream
  }
}

export class MessageItem {
  role: string = ''
  content: string = ''

  constructor(role: string, content: string) {
    this.role = role
    this.content = content
  }
}

const DEFAULT_BASE_URL: string = 'https://api.minimaxi.com/v1'
const DEFAULT_MODEL: string = 'MiniMax-M2.7'
const INITIAL_API_KEY: string = 'sk-cp-mEnE_KvyPejkFl_cQDkupuPHY9DmRyo-zDooC7HtlXpphaDgyH_MsZbxZJAdE9usZnPZ8_5cw5tN0oBK0s-bRt9mS78R1nh94hQhcyT0OxI07Ue4en27EZA'

export class AIService {
  private static instance: AIService = new AIService()
  private config: APIConfig
  private keyInitialized: boolean = false

  private constructor() {
    this.config = new APIConfig('', DEFAULT_BASE_URL, DEFAULT_MODEL)
  }

  static getInstance(): AIService {
    return AIService.instance
  }

  private convertToMessageItems(messages: ChatMessage[]): MessageItem[] {
    const items: MessageItem[] = []
    for (let i = 0; i < messages.length; i++) {
      const msg = messages[i]
      items.push(new MessageItem(msg.role, msg.content))
    }
    return items
  }

  private removeThinkingProcess(content: string): string {
    let result = content.replace(/<note>[\s\S]*?<\/note>/g, '')
    result = result.replace(/<tool_call>[\s\S]*?<\/think>/g, '')
    return result.trim()
  }

  async initializeSecureKey(): Promise<void> {
    if (this.keyInitialized) return

    try {
      if (!SecureKeyManager.hasStoredKey()) {
        const success = await SecureKeyManager.storeEncryptedApiKey(INITIAL_API_KEY)
        if (!success) {
          console.error('[AIService] Failed to store encrypted API key, using fallback')
          this.config.apiKey = INITIAL_API_KEY
        }
      }
      this.keyInitialized = true
    } catch (e) {
      console.error('[AIService] SecureKey init error:', JSON.stringify(e))
      this.config.apiKey = INITIAL_API_KEY
      this.keyInitialized = true
    }
  }

  private async getDecryptedApiKey(): Promise<string> {
    if (this.config.apiKey.length > 0) {
      return this.config.apiKey
    }

    try {
      const apiKey = await SecureKeyManager.retrieveApiKey()
      if (apiKey.length > 0) {
        this.config.apiKey = apiKey
        return apiKey
      }
    } catch (e) {
      console.error('[AIService] Decrypt API key failed:', JSON.stringify(e))
    }

    console.warn('[AIService] Using fallback API key')
    this.config.apiKey = INITIAL_API_KEY
    return INITIAL_API_KEY
  }

  async chat(messages: ChatMessage[]): Promise<string> {
    await this.initializeSecureKey()
    const apiKey = await this.getDecryptedApiKey()

    return new Promise<string>((resolve, reject) => {
      const httpRequest = http.createHttp()
      const url: string = this.config.baseUrl + '/chat/completions'

      const messageItems = this.convertToMessageItems(messages)
      const requestPayload = new RequestPayload(this.config.model, messageItems, false)

      const header = new HttpHeader('application/json', 'Bearer ' + apiKey)

      try {
        httpRequest.request(url, {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': header.contentType,
            'Authorization': header.authorization
          },
          extraData: JSON.stringify(requestPayload),
          connectTimeout: 30000,
          readTimeout: 30000,
          expectDataType: http.HttpDataType.STRING
        }, (err, data) => {
          if (err) {
            console.error('[AIService] HTTPS request failed:', err.message)
            reject(new Error('HTTPS请求失败: ' + err.message))
            return
          }

          if (data.responseCode === 200) {
            try {
              const result = JSON.parse(data.result as string) as Record<string, Object>
              const choices = result['choices'] as Array<Record<string, Object>>
              if (choices && choices.length > 0) {
                const firstChoice = choices[0]
                const message = firstChoice['message'] as Record<string, Object>
                const content = message['content'] as string
                const cleanContent = this.removeThinkingProcess(content)
                resolve(cleanContent)
              } else {
                reject(new Error('响应格式错误'))
              }
            } catch (parseErr) {
              console.error('[AIService] Parse response failed:', parseErr)
              reject(new Error('解析响应失败'))
            }
          } else {
            console.error('[AIService] HTTP error:', data.responseCode)
            reject(new Error('HTTP错误: ' + data.responseCode))
          }
        })
      } catch (e) {
        console.error('[AIService] Exception:', e)
        reject(new Error('AI服务异常: ' + e))
      }
    })
  }

  async smartHomeChat(userMessage: string, chatHistory: ChatMessage[] = []): Promise<string> {
    const systemPrompt = new ChatMessage('system',
      '你是一个智能家居助手，名叫"鸿蒙智家AI助手"。你的职责是：\n' +
      '1. 回答用户关于智能家居设备控制的问题\n' +
      '2. 帮助用户控制设备（如灯光、空调、窗帘等）\n' +
      '3. 提供智能家居使用建议\n' +
      '4. 当用户提到控制设备时，你可以回复类似"已为您打开空调"、"已关闭灯光"等确认信息\n\n' +
      '请用友好、简洁的方式回答。如果用户询问设备控制，直接给出操作确认。')

    const history = chatHistory.slice()
    const allMessages: ChatMessage[] = [systemPrompt]
    for (let i = 0; i < history.length; i++) {
      allMessages.push(history[i])
    }
    allMessages.push(new ChatMessage('user', userMessage))

    return this.chat(allMessages)
  }
}
