// AI 服务 - 调用 MiniMax API 实现智能问答
import http from '@ohos.net.http'

// 聊天消息结构
@Observed
export class ChatMessage {
  role: string = ''
  content: string = ''

  constructor(role: string, content: string) {
    this.role = role
    this.content = content
  }
}

// API 请求结构
@Observed
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

// API 响应结构
@Observed
export class ChatResponse {
  id: string = ''
  choices: ChatChoice[] = []

  constructor() {
    this.choices = []
  }
}

@Observed
export class ChatChoice {
  index: number = 0
  message: ChatMessage = new ChatMessage('', '')
  finish_reason: string = ''

  constructor() {
    this.message = new ChatMessage('', '')
  }
}

// API 配置信息
@Observed
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

// HTTP 头部结构
@Observed
export class HttpHeader {
  contentType: string = ''
  authorization: string = ''

  constructor(contentType: string, authorization: string) {
    this.contentType = contentType
    this.authorization = authorization
  }
}

// 请求载荷结构
@Observed
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

// 消息项结构
@Observed
export class MessageItem {
  role: string = ''
  content: string = ''

  constructor(role: string, content: string) {
    this.role = role
    this.content = content
  }
}

export class AIService {
  private static instance: AIService = new AIService()
  private config: APIConfig

  private constructor() {
    this.config = new APIConfig(
      'sk-cp-mEnE_KvyPejkFl_cQDkupuPHY9DmRyo-zDooC7HtlXpphaDgyH_MsZbxZJAdE9usZnPZ8_5cw5tN0oBK0s-bRt9mS78R1nh94hQhcyT0OxI07Ue4en27EZA',
      'https://api.minimaxi.com/v1',
      'MiniMax-M2.7'
    )
  }

  static getInstance(): AIService {
    return AIService.instance
  }

  // 将 ChatMessage 数组转换为 MessageItem 数组
  private convertToMessageItems(messages: ChatMessage[]): MessageItem[] {
    const items: MessageItem[] = []
    for (let i = 0; i < messages.length; i++) {
      const msg = messages[i]
      items.push(new MessageItem(msg.role, msg.content))
    }
    return items
  }

  // 移除思考过程标记
  private removeThinkingProcess(content: string): string {
    // 移除 <note>...</note> 标签对
    let result = content.replace(/<note>[\s\S]*?<\/note>/g, '')
    // 移除 <think>...</think> 标签对
    result = result.replace(/<think>[\s\S]*?<\/think>/g, '')
    return result.trim()
  }

  // 发送对话请求
  async chat(messages: ChatMessage[]): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      const httpRequest = http.createHttp()
      const url = `${this.config.baseUrl}/chat/completions`

      // 构建消息数组
      const messageItems = this.convertToMessageItems(messages)
      const requestPayload = new RequestPayload(this.config.model, messageItems, false)

      // 构建 HTTP 头部
      const header = new HttpHeader('application/json', `Bearer ${this.config.apiKey}`)

      try {
        httpRequest.request(url, {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': header.contentType,
            'Authorization': header.authorization
          },
          extraData: JSON.stringify(requestPayload),
          connectTimeout: 30000,
          readTimeout: 30000
        }, (err, data) => {
          if (err) {
            console.error('AI请求失败:', err.message)
            reject(new Error(`请求失败: ${err.message}`))
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
              console.error('解析响应失败:', parseErr)
              reject(new Error('解析响应失败'))
            }
          } else {
            console.error('HTTP错误:', data.responseCode)
            reject(new Error(`HTTP错误: ${data.responseCode}`))
          }
        })
      } catch (e) {
        console.error('AI服务异常:', e)
        reject(new Error(`AI服务异常: ${e}`))
      }
    })
  }

  // 带系统提示的对话（用于智能家居场景）
  async smartHomeChat(userMessage: string, chatHistory: ChatMessage[] = []): Promise<string> {
    const systemPrompt = new ChatMessage('system',
      `你是一个智能家居助手，名叫"鸿蒙智家AI助手"。你的职责是：
1. 回答用户关于智能家居设备控制的问题
2. 帮助用户控制设备（如灯光、空调、窗帘等）
3. 提供智能家居使用建议
4. 当用户提到控制设备时，你可以回复类似"已为您打开空调"、"已关闭灯光"等确认信息

请用友好、简洁的方式回答。如果用户询问设备控制，直接给出操作确认。`)

    const history = chatHistory.slice()
    const allMessages: ChatMessage[] = [systemPrompt]
    for (let i = 0; i < history.length; i++) {
      allMessages.push(history[i])
    }
    allMessages.push(new ChatMessage('user', userMessage))

    return this.chat(allMessages)
  }
}