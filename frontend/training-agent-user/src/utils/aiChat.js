import { escapeHtml } from './security'

const normalizeText = (value) => {
  if (value === null || value === undefined) {
    return ''
  }
  return String(value).replace(/\r\n/g, '\n').replace(/\r/g, '\n').trim()
}

const SENTENCE_ENDING_REGEX = /(?<=[。！？!?；;])\s*/g
const STRUCTURED_SECTION_REGEX = /([。！？!?；;])\s*((?:\d+[.、]|[一二三四五六七八九十]+[、：:]|首先|其次|再次|另外|此外|同时|然后|最后))/g
const STRUCTURED_REPLY_PARAGRAPH_REGEX = /^(?:步骤[一二三四五六七八九十]|第[一二三四五六七八九十]步|[一二三四五六七八九十][、：:]|首先|其次|再次|另外|此外|同时|然后|最后|先接住感受|别急着解释|当场要做什么|再补一句偏好确认|可以这样回复客人|SOP闭环动作)/
const MAX_PARAGRAPH_LENGTH = 88
const MAX_SENTENCES_PER_PARAGRAPH = 2
const CODE_FENCE_REGEX = /^```([\w-]+)?\s*$/
const HEADING_REGEX = /^(#{1,3})\s+(.*)$/
const BLOCKQUOTE_REGEX = /^>\s?(.*)$/
const UNORDERED_LIST_REGEX = /^[-*+]\s+(.*)$/
const ORDERED_LIST_REGEX = /^\d+[.)]\s+(.*)$/

const applyInlineFormatting = (text) => escapeHtml(text).replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')

const isSpecialBlockStart = (line) => {
  const trimmedLine = line.trim()
  return (
    CODE_FENCE_REGEX.test(trimmedLine) ||
    HEADING_REGEX.test(trimmedLine) ||
    BLOCKQUOTE_REGEX.test(trimmedLine) ||
    UNORDERED_LIST_REGEX.test(trimmedLine) ||
    ORDERED_LIST_REGEX.test(trimmedLine)
  )
}

const splitLongChunkBySentences = (chunk) => {
  const normalizedChunk = chunk.trim()
  if (!normalizedChunk || normalizedChunk.length <= MAX_PARAGRAPH_LENGTH) {
    return normalizedChunk ? [normalizedChunk] : []
  }

  if (STRUCTURED_REPLY_PARAGRAPH_REGEX.test(normalizedChunk)) {
    return [normalizedChunk]
  }

  const sentences = normalizedChunk
    .split(SENTENCE_ENDING_REGEX)
    .map((sentence) => sentence.trim())
    .filter(Boolean)

  if (sentences.length <= 1) {
    return [normalizedChunk]
  }

  const paragraphs = []
  let currentParagraph = ''
  let sentenceCount = 0

  sentences.forEach((sentence, index) => {
    const nextParagraph = currentParagraph ? `${currentParagraph}${sentence}` : sentence
    const exceedsLength = nextParagraph.length > MAX_PARAGRAPH_LENGTH
    const exceedsSentenceLimit = sentenceCount >= MAX_SENTENCES_PER_PARAGRAPH

    if (currentParagraph && (exceedsLength || exceedsSentenceLimit)) {
      paragraphs.push(currentParagraph.trim())
      currentParagraph = sentence
      sentenceCount = 1
      return
    }

    currentParagraph = nextParagraph
    sentenceCount += 1

    if (index === sentences.length - 1 && currentParagraph.trim()) {
      paragraphs.push(currentParagraph.trim())
    }
  })

  return paragraphs.length > 0 ? paragraphs : [normalizedChunk]
}

const splitParagraphs = (text) => {
  const paragraphs = text
    .split(/\n{2,}/)
    .map((paragraph) => paragraph.trim())
    .filter(Boolean)

  return paragraphs.flatMap((paragraph) => {
    if (paragraph.includes('\n')) {
      return [paragraph]
    }

    const structuredParagraph = paragraph.replace(STRUCTURED_SECTION_REGEX, '$1\n$2')
    const sections = structuredParagraph
      .split('\n')
      .map((section) => section.trim())
      .filter(Boolean)

    return sections.flatMap((section) => splitLongChunkBySentences(section))
  })
}

const renderParagraphBlock = (content) => {
  const paragraphs = splitParagraphs(content)

  return paragraphs
    .map((paragraph) => `<p>${applyInlineFormatting(paragraph).replace(/\n/g, '<br>')}</p>`)
    .join('')
}

const parseBlocks = (text) => {
  const lines = text.split('\n')
  const blocks = []
  let index = 0

  while (index < lines.length) {
    const currentLine = lines[index]
    const trimmedLine = currentLine.trim()

    if (!trimmedLine) {
      index += 1
      continue
    }

    const codeFenceMatch = trimmedLine.match(CODE_FENCE_REGEX)
    if (codeFenceMatch) {
      const language = codeFenceMatch[1] || ''
      const codeLines = []
      index += 1

      while (index < lines.length && !CODE_FENCE_REGEX.test(lines[index].trim())) {
        codeLines.push(lines[index])
        index += 1
      }

      if (index < lines.length) {
        index += 1
      }

      blocks.push({
        type: 'code',
        language,
        content: codeLines.join('\n').trimEnd()
      })
      continue
    }

    const headingMatch = trimmedLine.match(HEADING_REGEX)
    if (headingMatch) {
      blocks.push({
        type: 'heading',
        level: Math.min(headingMatch[1].length, 3),
        content: headingMatch[2].trim()
      })
      index += 1
      continue
    }

    if (BLOCKQUOTE_REGEX.test(trimmedLine)) {
      const quoteLines = []

      while (index < lines.length && BLOCKQUOTE_REGEX.test(lines[index].trim())) {
        quoteLines.push(lines[index].trim().replace(BLOCKQUOTE_REGEX, '$1'))
        index += 1
      }

      blocks.push({
        type: 'blockquote',
        content: quoteLines.join('\n')
      })
      continue
    }

    if (UNORDERED_LIST_REGEX.test(trimmedLine) || ORDERED_LIST_REGEX.test(trimmedLine)) {
      const isOrderedList = ORDERED_LIST_REGEX.test(trimmedLine)
      const listRegex = isOrderedList ? ORDERED_LIST_REGEX : UNORDERED_LIST_REGEX
      const items = []

      while (index < lines.length && listRegex.test(lines[index].trim())) {
        const itemMatch = lines[index].trim().match(listRegex)
        if (itemMatch) {
          items.push(itemMatch[1].trim())
        }
        index += 1
      }

      blocks.push({
        type: isOrderedList ? 'ol' : 'ul',
        items
      })
      continue
    }

    const paragraphLines = [currentLine]
    index += 1

    while (index < lines.length) {
      const nextLine = lines[index]
      if (!nextLine.trim() || isSpecialBlockStart(nextLine)) {
        break
      }
      paragraphLines.push(nextLine)
      index += 1
    }

    blocks.push({
      type: 'paragraph',
      content: paragraphLines.join('\n')
    })
  }

  return blocks
}

export const formatAiMessageContent = (content) => {
  const normalized = normalizeText(content)
  if (!normalized) {
    return ''
  }

  return parseBlocks(normalized)
    .map((block) => {
      if (block.type === 'heading') {
        const tagName = `h${block.level}`
        return `<${tagName}>${applyInlineFormatting(block.content)}</${tagName}>`
      }

      if (block.type === 'blockquote') {
        return `<blockquote>${renderParagraphBlock(block.content)}</blockquote>`
      }

      if (block.type === 'ul' || block.type === 'ol') {
        return `<${block.type}>${block.items.map((item) => `<li>${applyInlineFormatting(item)}</li>`).join('')}</${block.type}>`
      }

      if (block.type === 'code') {
        const languageClass = block.language ? ` class="language-${escapeHtml(block.language)}"` : ''
        return `<pre><code${languageClass}>${escapeHtml(block.content)}</code></pre>`
      }

      return renderParagraphBlock(block.content)
    })
    .join('')
}

const dispatchSseEvent = (block, callbacks, state = {}) => {
  const lines = block.split('\n')
  let eventName = 'message'
  const dataLines = []
  let hasStructuredFields = false

  for (const rawLine of lines) {
    const line = rawLine.trimEnd()
    if (line.startsWith('event:')) {
      eventName = line.substring(6).trim() || 'message'
      hasStructuredFields = true
      continue
    }
    if (line.startsWith('data:')) {
      dataLines.push(line.substring(5).trimStart())
      hasStructuredFields = true
    }
  }

  if (!hasStructuredFields) {
    if (state.lastEventName === 'message') {
      callbacks.onMessage?.(`\n\n${block}`)
      return 'message'
    }
    return null
  }

  if (dataLines.length === 0) {
    return null
  }

  const data = dataLines.join('\n')
  if (eventName === 'done' || data === '[DONE]') {
    callbacks.onDone?.()
    return 'done'
  }

  if (eventName === 'thinking') {
    callbacks.onThinking?.(data)
    return 'thinking'
  }

  if (eventName === 'error') {
    callbacks.onError?.(new Error(data || 'SSE 请求失败'))
    return 'error'
  }

  if (eventName === 'sources') {
    try {
      callbacks.onSources?.(JSON.parse(data))
    } catch (error) {}
    return 'sources'
  }

  callbacks.onMessage?.(data)
  return 'message'
}

export const createSseEventParser = (callbacks = {}) => {
  let buffer = ''
  let lastEventName = null

  return {
    consume(chunk, { flush = false } = {}) {
      if (chunk) {
        buffer += String(chunk).replace(/\r\n/g, '\n').replace(/\r/g, '\n')
      }

      let separatorIndex = buffer.indexOf('\n\n')
      while (separatorIndex !== -1) {
        const block = buffer.slice(0, separatorIndex)
        buffer = buffer.slice(separatorIndex + 2)
        if (block.trim()) {
          const eventName = dispatchSseEvent(block, callbacks, { lastEventName })
          if (eventName) {
            lastEventName = eventName
          }
        }
        separatorIndex = buffer.indexOf('\n\n')
      }

      if (flush) {
        const tail = buffer.trim()
        buffer = ''
        if (tail) {
          const eventName = dispatchSseEvent(tail, callbacks, { lastEventName })
          if (eventName) {
            lastEventName = eventName
          }
        }
      }
    },
    getPendingBuffer() {
      return buffer
    }
  }
}
