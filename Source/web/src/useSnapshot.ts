import { onBeforeUnmount, onMounted, ref } from 'vue'
import { emptySnapshot } from './format'
import type {
  EventPage,
  EventUnitFilter,
  HistoryItem,
  SettlementDetail,
  SettlementPage,
  Snapshot,
} from './types'

interface EventPageRequest {
  sessionId: string
  query: string
  page: number
  pageSize: number
  victimFilter: EventUnitFilter | null
  sourceFilter: EventUnitFilter | null
}

interface SettlementPageRequest {
  sessionId: string
  query: string
  page: number
  pageSize: number
  victimFilter: EventUnitFilter | null
}

const emptySettlementPage: SettlementPage = {
  schemaVersion: 1,
  type: 'settlement-page',
  requestId: 0,
  sessionId: '',
  page: 0,
  pageSize: 200,
  total: 0,
  error: '',
  rows: [],
}

const emptyEventPage: EventPage = {
  schemaVersion: 1,
  type: 'event-page',
  requestId: 0,
  sessionId: '',
  page: 0,
  pageSize: 500,
  total: 0,
  eventRevision: 0,
  error: '',
  rows: [],
}

export function useSnapshot() {
  const snapshot = ref<Snapshot>(emptySnapshot)
  const connected = ref(false)
  const lastMessageAt = ref('')
  const historyItems = ref<HistoryItem[]>([])
  const historyError = ref('')
  const busy = ref(false)
  const settlementPage = ref<SettlementPage>(emptySettlementPage)
  const settlementPageLoading = ref(false)
  const settlementPageError = ref('')
  const eventPage = ref<EventPage>(emptyEventPage)
  const eventPageLoading = ref(false)
  const eventPageError = ref('')
  const settlementDetail = ref<SettlementDetail | null>(null)
  const settlementDetailLoading = ref(false)
  const settlementDetailError = ref('')

  let nextSettlementRequestId = 0
  let nextEventRequestId = 0
  let nextDetailRequestId = 0

  const post = (message: unknown) => {
    window.chrome?.webview?.postMessage(message)
  }

  const onMessage = (event: MessageEvent) => {
    const value = event.data as Partial<Snapshot> & {
      type?: string
      requestId?: number
      items?: HistoryItem[]
      error?: string
      busy?: boolean
    } | null
    if (!value) return

    if (value.type === 'history-list') {
      historyItems.value = value.items ?? []
      historyError.value = value.error ?? ''
      return
    }
    if (value.type === 'command-result') {
      busy.value = Boolean(value.busy)
      if (value.error) historyError.value = value.error
      return
    }
    if (value.type === 'settlement-page') {
      if (value.requestId !== nextSettlementRequestId) return
      settlementPage.value = value as SettlementPage
      settlementPageError.value = value.error ?? ''
      settlementPageLoading.value = false
      return
    }
    if (value.type === 'event-page') {
      if (value.requestId !== nextEventRequestId) return
      eventPage.value = value as EventPage
      eventPageError.value = value.error ?? ''
      eventPageLoading.value = false
      return
    }
    if (value.type === 'settlement-detail') {
      if (value.requestId !== nextDetailRequestId) return
      settlementDetail.value = value as SettlementDetail
      settlementDetailError.value = value.error ?? ''
      settlementDetailLoading.value = false
      return
    }
    if (value.schemaVersion !== 1) return

    snapshot.value = value as Snapshot
    connected.value = true
    lastMessageAt.value = new Date().toLocaleTimeString('zh-CN', { hour12: false })
  }

  onMounted(() => {
    window.chrome?.webview?.addEventListener('message', onMessage)
    post({ type: 'dss-ready' })
    if (!window.chrome?.webview) {
      import('./demo').then(({ demoSnapshot }) => {
        snapshot.value = demoSnapshot
        connected.value = true
        lastMessageAt.value = '预览模式'
        settlementPage.value = {
          ...emptySettlementPage,
          sessionId: demoSnapshot.sessionId,
          total: demoSnapshot.settlements.length,
          rows: demoSnapshot.settlements,
        }
      })
    }
  })

  onBeforeUnmount(() => {
    window.chrome?.webview?.removeEventListener('message', onMessage)
  })

  const command = (action: string, payload: Record<string, unknown> = {}) => {
    busy.value = true
    historyError.value = ''
    post({ type: 'dss-command', action, ...payload })
  }

  const requestEventPage = (request: EventPageRequest) => {
    const requestId = ++nextEventRequestId
    eventPageLoading.value = true
    eventPageError.value = ''
    post({
      type: 'dss-command',
      action: 'event-page',
      requestId,
      sessionId: request.sessionId,
      query: request.query,
      page: request.page,
      pageSize: request.pageSize,
      victimCode: request.victimFilter?.typeCode ?? '',
      victimIllusion: request.victimFilter?.illusion ?? false,
      sourceCode: request.sourceFilter?.typeCode ?? '',
      sourceIllusion: request.sourceFilter?.illusion ?? false,
    })
  }

  const requestSettlementPage = (request: SettlementPageRequest) => {
    const requestId = ++nextSettlementRequestId
    settlementPageLoading.value = true
    settlementPageError.value = ''
    post({
      type: 'dss-command',
      action: 'settlement-page',
      requestId,
      sessionId: request.sessionId,
      query: request.query,
      page: request.page,
      pageSize: request.pageSize,
      victimCode: request.victimFilter?.typeCode ?? '',
    })
  }

  const requestSettlementDetail = (seq: number) => {
    const requestId = ++nextDetailRequestId
    settlementDetailLoading.value = true
    settlementDetailError.value = ''
    post({
      type: 'dss-command',
      action: 'settlement-detail',
      requestId,
      sessionId: snapshot.value.sessionId,
      seq,
    })
  }

  const requestHistory = () => command('history-list')
  const loadHistory = (sessionId: string) => command('history-load', { sessionId })
  const resumeLive = () => command('resume-live')

  return {
    snapshot,
    connected,
    lastMessageAt,
    historyItems,
    historyError,
    busy,
    settlementPage,
    settlementPageLoading,
    settlementPageError,
    eventPage,
    eventPageLoading,
    eventPageError,
    settlementDetail,
    settlementDetailLoading,
    settlementDetailError,
    command,
    requestSettlementPage,
    requestEventPage,
    requestSettlementDetail,
    requestHistory,
    loadHistory,
    resumeLive,
  }
}
