import { createApp } from 'vue'
import App from './App.vue'
import './styles.css'

window.__ddhClick = (x, y) => {
  const suppressUntil = (window as typeof window & { __ddhSuppressClickUntil?: number })
    .__ddhSuppressClickUntil ?? 0
  if (Date.now() < suppressUntil) return
  const target = document.elementFromPoint(x, y)
  if (!(target instanceof Element)) return
  const options: MouseEventInit = {
    bubbles: true,
    cancelable: true,
    clientX: x,
    clientY: y,
    button: 0,
    buttons: 1,
  }
  target.dispatchEvent(new PointerEvent('pointerdown', { ...options, pointerId: 1, isPrimary: true }))
  target.dispatchEvent(new MouseEvent('mousedown', options))
  target.dispatchEvent(new PointerEvent('pointerup', { ...options, buttons: 0, pointerId: 1, isPrimary: true }))
  target.dispatchEvent(new MouseEvent('mouseup', { ...options, buttons: 0 }))
  target.dispatchEvent(new MouseEvent('click', { ...options, buttons: 0 }))
  const editable = target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement
    ? target
    : target.closest<HTMLElement>('input, textarea')
  if (editable) editable.focus()
  else if (document.activeElement instanceof HTMLInputElement ||
           document.activeElement instanceof HTMLTextAreaElement)
    document.activeElement.blur()
}

function notifyTextFocus(focused: boolean) {
  window.chrome?.webview?.postMessage({ type: 'ddh-focus', focused })
}

document.addEventListener('focusin', event => {
  if (event.target instanceof HTMLInputElement || event.target instanceof HTMLTextAreaElement)
    notifyTextFocus(true)
})

document.addEventListener('focusout', event => {
  if (event.target instanceof HTMLInputElement || event.target instanceof HTMLTextAreaElement)
    notifyTextFocus(false)
})

window.__ddhText = code => {
  const element = document.activeElement
  if (!(element instanceof HTMLInputElement) && !(element instanceof HTMLTextAreaElement)) return

  const start = element.selectionStart ?? element.value.length
  const end = element.selectionEnd ?? start
  if (code === 8) {
    if (start === end && start > 0) {
      element.setRangeText('', start - 1, end, 'end')
    } else {
      element.setRangeText('', start, end, 'end')
    }
  } else if (code === 13 || code === 27) {
    element.blur()
    return
  } else if (code >= 32) {
    element.setRangeText(String.fromCharCode(code), start, end, 'end')
  }
  element.dispatchEvent(new Event('input', { bubbles: true }))
}

window.__ddhWheel = (x, y, delta) => {
  let node = document.elementFromPoint(x, y)
  while (node instanceof HTMLElement) {
    const style = getComputedStyle(node)
    const canScrollY =
      /(auto|scroll)/.test(style.overflowY) && node.scrollHeight > node.clientHeight + 1
    if (canScrollY) {
      node.scrollTop += delta > 0 ? -120 : 120
      return
    }
    node = node.parentElement
  }
  window.scrollBy({ top: delta > 0 ? -120 : 120 })
}

interface ScrollDrag {
  element: HTMLElement
  axis: 'y' | 'x'
  rect: DOMRect
  trackSize: number
  thumbSize: number
}

let scrollDrag: ScrollDrag | null = null
let pointerButtons = 0

function scrollableAt(x: number, y: number): HTMLElement | null {
  let node = document.elementFromPoint(x, y)
  while (node instanceof HTMLElement) {
    const style = getComputedStyle(node)
    const vertical = /(auto|scroll)/.test(style.overflowY) && node.scrollHeight > node.clientHeight + 1
    const horizontal = /(auto|scroll)/.test(style.overflowX) && node.scrollWidth > node.clientWidth + 1
    if (vertical || horizontal) return node
    node = node.parentElement
  }
  return null
}

window.__ddhPointer = (x, y, buttons) => {
  pointerButtons = buttons

  if (!buttons) {
    scrollDrag = null
    return
  }
  if (scrollDrag) {
    const { element, axis, rect, trackSize, thumbSize } = scrollDrag
    if (axis === 'y') {
      const ratio = Math.min(1, Math.max(0, (y - rect.top - thumbSize / 2) / trackSize))
      element.scrollTop = ratio * (element.scrollHeight - element.clientHeight)
    } else {
      const ratio = Math.min(1, Math.max(0, (x - rect.left - thumbSize / 2) / trackSize))
      element.scrollLeft = ratio * (element.scrollWidth - element.clientWidth)
    }
    return
  }
  const element = scrollableAt(x, y)
  if (!element) return
  const rect = element.getBoundingClientRect()
  if (x >= rect.right - 12 && element.scrollHeight > element.clientHeight + 1) {
    const thumbSize = Math.max(18, rect.height * element.clientHeight / element.scrollHeight)
    scrollDrag = {
      element,
      axis: 'y',
      rect,
      trackSize: Math.max(1, rect.height - thumbSize),
      thumbSize,
    }
  } else if (y >= rect.bottom - 12 && element.scrollWidth > element.clientWidth + 1) {
    const thumbSize = Math.max(18, rect.width * element.clientWidth / element.scrollWidth)
    scrollDrag = {
      element,
      axis: 'x',
      rect,
      trackSize: Math.max(1, rect.width - thumbSize),
      thumbSize,
    }
  }
}

createApp(App).mount('#app')
