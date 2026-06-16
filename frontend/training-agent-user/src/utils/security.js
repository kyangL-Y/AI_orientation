const FORBIDDEN_TAGS = new Set([
  'script',
  'iframe',
  'object',
  'embed',
  'link',
  'style',
  'meta',
  'base',
  'form',
  'input',
  'button',
  'textarea',
  'select',
  'svg',
  'math',
  'noscript',
  'template'
])

const URL_ATTRS = new Set(['href', 'src', 'xlink:href', 'formaction'])

function isDangerousUrl(value) {
  if (!value) return false
  const normalized = String(value).trim().toLowerCase()
  return (
    normalized.startsWith('javascript:') ||
    normalized.startsWith('data:text/html') ||
    normalized.startsWith('data:image/svg+xml') ||
    normalized.startsWith('vbscript:')
  )
}

export function escapeHtml(value) {
  if (value === null || value === undefined) return ''
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

export function sanitizeHtml(value) {
  if (!value) return ''
  if (typeof window === 'undefined' || typeof DOMParser === 'undefined') {
    return escapeHtml(value)
  }

  const parser = new DOMParser()
  const doc = parser.parseFromString(String(value), 'text/html')

  doc.querySelectorAll('*').forEach((node) => {
    const tagName = node.tagName.toLowerCase()
    if (FORBIDDEN_TAGS.has(tagName)) {
      node.remove()
      return
    }

    Array.from(node.attributes).forEach((attr) => {
      const name = attr.name.toLowerCase()
      const attrValue = attr.value

      if (name.startsWith('on') || name === 'srcdoc') {
        node.removeAttribute(attr.name)
        return
      }

      if (URL_ATTRS.has(name) && isDangerousUrl(attrValue)) {
        node.removeAttribute(attr.name)
      }
    })
  })

  return doc.body.innerHTML
}
