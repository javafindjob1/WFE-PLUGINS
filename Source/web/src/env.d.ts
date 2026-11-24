/// <reference types="vite/client" />

interface DdhWebMessageEvent extends MessageEvent {
  data: unknown
}

interface Window {
  __ddhClick?: (x: number, y: number) => void
  __ddhWheel?: (x: number, y: number, delta: number) => void
  __ddhPointer?: (x: number, y: number, buttons: number) => void
  __ddhText?: (code: number) => void
  chrome?: {
    webview?: {
      postMessage: (message: unknown) => void
      addEventListener: (
        type: 'message',
        listener: (event: DdhWebMessageEvent) => void,
      ) => void
      removeEventListener: (
        type: 'message',
        listener: (event: DdhWebMessageEvent) => void,
      ) => void
    }
  }
}
