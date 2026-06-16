import logger from '@/utils/logger';
import { api } from '@/utils/api'
import { getTenantId } from '@/utils/tenantContext'
import { createSseEventParser } from '@/utils/aiChat'

/**
 * AI指导相关API - 使用本地存储管理对话，只调用后端AI接口
 */

// 发送消息到AI
export const sendMessageToAI = (message, sessionId) => {
  return api.post('/train/ai/sendMessage', {
    message: message,
    sessionId: sessionId || 'default_session'
  })
}

/**
 * 发送消息到AI（SSE 流式）
 * 返回一个对象 { close() } 用于中断连接
 * @param {string} message 用户消息
 * @param {string} sessionId 会话ID
 * @param {object} callbacks { onMessage, onThinking, onDone, onError }
 */
export const sendMessageToAIStream = (message, sessionId, callbacks = {}) => {
  const token = localStorage.getItem('authToken') || localStorage.getItem('admin_token') || ''
  const tenantId = getTenantId()

  const controller = new AbortController()
  let finished = false
  const finish = () => {
    if (finished) {
      return
    }
    finished = true
    if (callbacks.onDone) callbacks.onDone()
  }
  const fail = (error) => {
    if (finished) {
      return
    }
    finished = true
    if (callbacks.onError) callbacks.onError(error)
  }
  const parser = createSseEventParser({
    onMessage: callbacks.onMessage,
    onThinking: callbacks.onThinking,
    onSources: callbacks.onSources,
    onDone: finish,
    onError: fail
  })

  // 使用 fetch 发送 POST SSE 请求（EventSource 只支持 GET）
  fetch('/train/ai/chat/stream', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + token,
      'Tenant-Id': tenantId
    },
    body: JSON.stringify({ message, sessionId: sessionId || 'default_session' }),
    signal: controller.signal
  }).then(response => {
    if (!response.ok) {
      throw new Error('SSE请求失败: ' + response.status)
    }
    const reader = response.body.getReader()
    const decoder = new TextDecoder()

    function processChunk() {
      reader.read().then(({ done, value }) => {
        if (done) {
          parser.consume(decoder.decode(), { flush: true })
          finish()
          return
        }
        parser.consume(decoder.decode(value, { stream: true }))
        if (finished) {
          return
        }
        processChunk()
      }).catch(err => {
        if (err.name !== 'AbortError') {
          fail(err)
        }
      })
    }
    processChunk()
  }).catch(err => {
    if (err.name !== 'AbortError') {
      fail(err)
    }
  })

  return {
    close: () => {
      finished = true
      controller.abort()
    }
  }
}

// 清除指定会话的对话历史
export const clearChatHistory = (sessionId) => {
  return api.delete(`/train/ai/clearHistory/${sessionId}`)
}

// 从后端获取指定会话的对话历史
export const getChatHistoryFromServer = (sessionId, limit = 100) => {
  return api.get(`/train/ai/history/${sessionId}`, { params: { limit } })
}

// 从后端获取用户的所有会话列表
export const getSessionListFromServer = () => {
  return api.get('/train/ai/sessions')
}

// 本地存储相关函数
const createMessageId = (conversationId, message, index) => {
  const rawTimestamp = message?.timestamp || message?.time || message?.createTime || message?.create_time
  const timestamp = rawTimestamp ? new Date(rawTimestamp).getTime() : Date.now()
  const safeTimestamp = Number.isNaN(timestamp) ? Date.now() : timestamp
  return message?.id || `${conversationId}-${safeTimestamp}-${index}`
}

const normalizeConversationMessage = (message = {}, conversationId = 'default_session', index = 0) => {
  const timestamp = message.timestamp || message.time || message.createTime || message.create_time || new Date().toISOString()

  return {
    ...message,
    id: createMessageId(conversationId, message, index),
    timestamp,
    time: message.time || timestamp,
    sources: Array.isArray(message.sources) ? message.sources : [],
    searchMeta: message.searchMeta || null
  }
}

export const getConversationList = () => {
  try {
    const conversations = localStorage.getItem('ai_conversations')
    return conversations ? JSON.parse(conversations) : []
  } catch (error) {
    logger.error('获取对话列表失败:', error)
    return []
  }
}

export const saveConversationList = (conversations) => {
  try {
    localStorage.setItem('ai_conversations', JSON.stringify(conversations))
  } catch (error) {
    logger.error('保存对话列表失败:', error)
  }
}

export const getConversationHistory = (conversationId) => {
  try {
    const history = localStorage.getItem(`ai_conversation_${conversationId}`)
    if (!history) {
      return []
    }

    return JSON.parse(history).map((message, index) => normalizeConversationMessage(message, conversationId, index))
  } catch (error) {
    logger.error('获取对话历史失败:', error)
    return []
  }
}

export const saveConversationHistory = (conversationId, messages) => {
  try {
    const normalizedMessages = Array.isArray(messages)
      ? messages.map((message, index) => normalizeConversationMessage(message, conversationId, index))
      : []
    localStorage.setItem(`ai_conversation_${conversationId}`, JSON.stringify(normalizedMessages))
  } catch (error) {
    logger.error('保存对话历史失败:', error)
  }
}

export const createNewConversation = (title) => {
  const conversation = {
    id: Date.now().toString(),
    title: title || '新对话',
    createTime: new Date().toISOString(),
    updateTime: new Date().toISOString()
  }
  
  const conversations = getConversationList()
  conversations.unshift(conversation)
  saveConversationList(conversations)
  
  // 初始化空的消息历史
  saveConversationHistory(conversation.id, [])
  
  return conversation
}

export const deleteConversation = (conversationId) => {
  try {
    // 从对话列表中删除
    const conversations = getConversationList()
    const filtered = conversations.filter(conv => conv.id !== conversationId)
    saveConversationList(filtered)
    
    // 删除对话历史
    localStorage.removeItem(`ai_conversation_${conversationId}`)
    
    return true
  } catch (error) {
    logger.error('删除对话失败:', error)
    return false
  }
}

export const updateConversationTitle = (conversationId, title) => {
  try {
    const conversations = getConversationList()
    const conversation = conversations.find(conv => conv.id === conversationId)
    if (conversation) {
      conversation.title = title
      conversation.updateTime = new Date().toISOString()
      saveConversationList(conversations)
      return true
    }
    return false
  } catch (error) {
    logger.error('更新对话标题失败:', error)
    return false
  }
}

/**
 * 从服务器同步聊天历史到本地
 * 用于用户登录后恢复历史记录
 */
export const syncHistoryFromServer = async () => {
  try {
    // 1. 获取服务器上的会话列表
    const sessionsRes = await getSessionListFromServer()
    if (sessionsRes.data.code !== 200 || !sessionsRes.data.data) {
      return { success: true, synced: 0 }
    }

    const serverSessions = sessionsRes.data.data

    if (serverSessions.length === 0) {
      return { success: true, synced: 0 }
    }

    // 2. 获取本地会话列表
    const localConversations = getConversationList()
    const localSessionIds = new Set(localConversations.map(c => c.id))

    let syncedCount = 0

    // 3. 遍历服务器会话，同步到本地
    for (const session of serverSessions) {
      const sessionId = session.session_id

      // 检查本地是否已有此会话
      if (!localSessionIds.has(sessionId)) {
        // 本地没有，从服务器获取历史并创建
        const historyRes = await getChatHistoryFromServer(sessionId, 100)
        if (historyRes.data.code === 200 && historyRes.data.data) {
          const serverMessages = historyRes.data.data

          // 转换消息格式
          const messages = serverMessages.map((msg, index) => normalizeConversationMessage({
            role: msg.role,
            content: msg.content,
            time: msg.create_time
          }, sessionId, index))

          // 创建本地会话记录
          const title = session.first_message
            ? (session.first_message.substring(0, 20) + (session.first_message.length > 20 ? '...' : ''))
            : '历史对话'

          const conversation = {
            id: sessionId,
            title: title,
            createTime: session.start_time,
            updateTime: session.last_time
          }

          localConversations.push(conversation)
          saveConversationHistory(sessionId, messages)
          syncedCount++
        }
      }
    }

    // 4. 保存更新后的会话列表（按更新时间排序）
    localConversations.sort((a, b) => new Date(b.updateTime) - new Date(a.updateTime))
    saveConversationList(localConversations)

    return { success: true, synced: syncedCount }
  } catch (error) {
    logger.error('❌ 同步聊天历史失败:', error)
    return { success: false, error: error.message }
  }
}

