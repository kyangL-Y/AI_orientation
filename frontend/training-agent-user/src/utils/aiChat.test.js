import { describe, expect, it, vi } from 'vitest'
import { createSseEventParser, formatAiMessageContent } from './aiChat'

describe('formatAiMessageContent', () => {
  it('renders paragraphs and line breaks', () => {
    const content = '第一段第一行\n第一段第二行\n\n第二段内容'

    expect(formatAiMessageContent(content)).toBe(
      '<p>第一段第一行<br>第一段第二行</p><p>第二段内容</p>'
    )
  })

  it('escapes html before formatting', () => {
    const content = '<script>alert(1)</script>\n\n**重点**'

    expect(formatAiMessageContent(content)).toBe(
      '<p>&lt;script&gt;alert(1)&lt;/script&gt;</p><p><strong>重点</strong></p>'
    )
  })

  it('splits long single-block answers into shorter paragraphs', () => {
    const content = '好的，我们来模拟一次酒店前台常见的客人投诉处理场景。假设客人因预订房间未保留，抵达后被告知无房而情绪激动，提出退订并索赔。一：立即致歉并共情。不要急于解释原因，先说非常抱歉给您带来不便。二：立即核验并给出方案。请同事同步查询房态与后台。三：跟进与闭环。登记客户联系方式，在24小时内回访。'

    expect(formatAiMessageContent(content)).toBe(
      '<p>好的，我们来模拟一次酒店前台常见的客人投诉处理场景。假设客人因预订房间未保留，抵达后被告知无房而情绪激动，提出退订并索赔。</p><p>一：立即致歉并共情。不要急于解释原因，先说非常抱歉给您带来不便。</p><p>二：立即核验并给出方案。请同事同步查询房态与后台。</p><p>三：跟进与闭环。登记客户联系方式，在24小时内回访。</p>'
    )
  })

  it('keeps structured reply paragraphs intact instead of splitting each sentence', () => {
    const content = '先接住感受。第一反应不是解释，而是明确表达“我们已经听见并重视这条反馈”。可以先感谢客人愿意直说，再说明你会马上跟进，先把情绪稳住。\n\n当场要做什么。可以明确告诉客人，你会马上把意见同步给餐饮主管，并协助核查当餐出品、补货状态、口味搭配和现场可选项。'

    expect(formatAiMessageContent(content)).toBe(
      '<p>先接住感受。第一反应不是解释，而是明确表达“我们已经听见并重视这条反馈”。可以先感谢客人愿意直说，再说明你会马上跟进，先把情绪稳住。</p><p>当场要做什么。可以明确告诉客人，你会马上把意见同步给餐饮主管，并协助核查当餐出品、补货状态、口味搭配和现场可选项。</p>'
    )
  })
})

describe('createSseEventParser', () => {
  it('parses complete SSE event blocks', () => {
    const onMessage = vi.fn()
    const onThinking = vi.fn()
    const parser = createSseEventParser({ onMessage, onThinking })

    parser.consume('event: thinking\ndata: 正在整理\n\nevent: message\ndata: 第一段\n\n')

    expect(onThinking).toHaveBeenCalledWith('正在整理')
    expect(onMessage).toHaveBeenCalledWith('第一段')
  })

  it('flushes the trailing buffer when stream ends without blank line', () => {
    const onMessage = vi.fn()
    const parser = createSseEventParser({ onMessage })

    parser.consume('event: message\ndata: 最后一段')
    parser.consume('', { flush: true })

    expect(onMessage).toHaveBeenCalledWith('最后一段')
    expect(parser.getPendingBuffer()).toBe('')
  })

  it('keeps malformed multiline message blocks emitted by spring sse', () => {
    const onMessage = vi.fn()
    const parser = createSseEventParser({ onMessage })

    parser.consume(
      'event: message\n' +
      'data: 首先，感谢您提出的这个非常实际的服务场景。\n\n' +
      '步骤一：快速响应，表达重视。\n\n' +
      '步骤二：共情优先，不辩解不否定。\n\n' +
      'event: done\n' +
      'data: [DONE]\n\n'
    )

    expect(onMessage).toHaveBeenNthCalledWith(1, '首先，感谢您提出的这个非常实际的服务场景。')
    expect(onMessage).toHaveBeenNthCalledWith(2, '\n\n步骤一：快速响应，表达重视。')
    expect(onMessage).toHaveBeenNthCalledWith(3, '\n\n步骤二：共情优先，不辩解不否定。')
  })
})
