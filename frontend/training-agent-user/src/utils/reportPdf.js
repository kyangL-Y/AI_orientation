let pdfLibPromise = null
const DEFAULT_PAGE_BREAK_SELECTORS = [
  'section',
  '.metrics-grid',
  '.analysis-grid',
  '.growth-story-strip',
  '.growth-goals',
  '.report-paper > *',
  '.paper-body > *',
  '.paper-chapter',
  '.content-card',
]

function ensurePdfExtension(filename) {
  const rawName = (filename || 'report').replace(/[\\/:*?"<>|]/g, '_').trim().replace(/[.\s]+$/, '')
  const safeName = rawName || 'report'
  return safeName.toLowerCase().endsWith('.pdf') ? safeName : `${safeName}.pdf`
}

function waitForImages(element) {
  const images = Array.from(element.querySelectorAll('img'))
  if (!images.length) return Promise.resolve()

  return Promise.all(
    images.map((img) => {
      if (img.complete) return Promise.resolve()
      return new Promise((resolve) => {
        const done = () => {
          img.removeEventListener('load', done)
          img.removeEventListener('error', done)
          resolve()
        }
        img.addEventListener('load', done, { once: true })
        img.addEventListener('error', done, { once: true })
      })
    })
  )
}

async function waitForElementReady(element) {
  if (document.fonts?.ready) {
    try {
      await document.fonts.ready
    } catch {
      // ignore font readiness failures and continue export
    }
  }

  await waitForImages(element)
  await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
}

async function ensurePdfLibs() {
  if (!pdfLibPromise) {
    pdfLibPromise = Promise.all([import('html2canvas'), import('jspdf')]).then(([canvasModule, pdfModule]) => ({
      html2canvas: canvasModule.default,
      jsPDF: pdfModule.default,
    }))
  }
  return pdfLibPromise
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max)
}

function uniqueSorted(values) {
  return [...new Set(values)].sort((a, b) => a - b)
}

function collectPageBreakpoints(element, canvasHeight, pageHeightPx, selectors) {
  const rootHeight = Math.max(element.scrollHeight, element.offsetHeight, 1)
  const rootRect = element.getBoundingClientRect()
  const domToCanvasRatio = canvasHeight / rootHeight
  const pageHeightDom = pageHeightPx / domToCanvasRatio
  const minPageContentDom = Math.max(180, pageHeightDom * 0.45)
  const candidates = [0, rootHeight]

  selectors.forEach((selector) => {
    element.querySelectorAll(selector).forEach((node) => {
      if (!(node instanceof HTMLElement) || node === element) return
      const rect = node.getBoundingClientRect()
      const top = clamp(Math.round(rect.top - rootRect.top), 0, rootHeight)
      const bottom = clamp(Math.round(rect.bottom - rootRect.top), 0, rootHeight)
      if (bottom - top < 24) return
      candidates.push(top, bottom)
    })
  })

  const sortedCandidates = uniqueSorted(candidates)
  const breakpoints = [0]
  let current = 0

  while (current < rootHeight) {
    const target = Math.min(current + pageHeightDom, rootHeight)
    if (target >= rootHeight) {
      breakpoints.push(rootHeight)
      break
    }

    const preferred = sortedCandidates.filter((point) => point > current + minPageContentDom && point < target - 8)
    const nextBreak = preferred.length ? preferred[preferred.length - 1] : target

    if (nextBreak <= current) {
      breakpoints.push(rootHeight)
      break
    }

    breakpoints.push(nextBreak)
    current = nextBreak
  }

  return uniqueSorted(breakpoints.map((point) => clamp(Math.round(point * domToCanvasRatio), 0, canvasHeight)))
}

export async function exportElementToPdf({
  element,
  filename = 'report.pdf',
  backgroundColor = '#ffffff',
  margin = 10,
  scale = Math.min(Math.max(window.devicePixelRatio || 1, 2.5), 3),
  pageBreakSelectors = DEFAULT_PAGE_BREAK_SELECTORS,
}) {
  if (!element) {
    throw new Error('未找到要导出的内容')
  }

  await waitForElementReady(element)
  const { html2canvas, jsPDF } = await ensurePdfLibs()

  const canvas = await html2canvas(element, {
    backgroundColor,
    scale,
    useCORS: true,
    logging: false,
    imageTimeout: 0,
    scrollX: 0,
    scrollY: -window.scrollY,
    width: element.scrollWidth,
    height: element.scrollHeight,
    windowWidth: Math.max(document.documentElement.clientWidth, element.scrollWidth),
    windowHeight: Math.max(document.documentElement.clientHeight, element.scrollHeight),
  })

  const pdf = new jsPDF({
    orientation: 'p',
    unit: 'mm',
    format: 'a4',
    compress: true,
  })

  const pageWidth = pdf.internal.pageSize.getWidth()
  const pageHeight = pdf.internal.pageSize.getHeight()
  const usableWidth = pageWidth - margin * 2
  const usableHeight = pageHeight - margin * 2
  const renderRatio = usableWidth / canvas.width
  const sliceHeightPx = Math.max(1, Math.floor(usableHeight / renderRatio))
  const breakpoints = collectPageBreakpoints(element, canvas.height, sliceHeightPx, pageBreakSelectors)

  for (let pageIndex = 0; pageIndex < breakpoints.length - 1; pageIndex += 1) {
    const offsetY = breakpoints[pageIndex]
    const currentSliceHeight = Math.min(sliceHeightPx, breakpoints[pageIndex + 1] - offsetY)

    const pageCanvas = document.createElement('canvas')
    pageCanvas.width = canvas.width
    pageCanvas.height = currentSliceHeight

    const context = pageCanvas.getContext('2d')
    if (!context) {
      throw new Error('PDF画布初始化失败')
    }

    context.imageSmoothingEnabled = true
    context.imageSmoothingQuality = 'high'
    context.fillStyle = backgroundColor
    context.fillRect(0, 0, pageCanvas.width, pageCanvas.height)
    context.drawImage(
      canvas,
      0,
      offsetY,
      canvas.width,
      currentSliceHeight,
      0,
      0,
      canvas.width,
      currentSliceHeight
    )

    if (pageIndex > 0) {
      pdf.addPage()
    }

    pdf.addImage(
      pageCanvas.toDataURL('image/png'),
      'PNG',
      margin,
      margin,
      usableWidth,
      currentSliceHeight * renderRatio
    )
  }

  pdf.save(ensurePdfExtension(filename))
}
