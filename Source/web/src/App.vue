<script setup lang="ts">
import { computed, ref } from 'vue'
import DeathPanel from './components/DeathPanel.vue'
import EventsPanel from './components/EventsPanel.vue'
import UnitsPanel from './components/UnitsPanel.vue'
import { useSnapshot } from './useSnapshot'
import type { EventUnitFilter } from './types'

type TabId = 'deaths' | 'events' | 'units'

const tabs: Array<{ id: TabId; label: string; hint: string }> = [
  { id: 'deaths', label: '死亡结算', hint: 'SETTLEMENT' },
  { id: 'events', label: '伤害事件', hint: 'EVENTS' },
  { id: 'units', label: '战场单位', hint: 'UNITS' },
]

const {
  snapshot,
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
} = useSnapshot()
const activeTab = ref<TabId>('deaths')
const query = ref('')
const victimFilter = ref<EventUnitFilter | null>(null)
const sourceFilter = ref<EventUnitFilter | null>(null)
const historyOpen = ref(false)

const desktop = computed(() => snapshot.value.desktop)
const connectionText = computed(() => {
  if (!desktop.value) return ''
  if (desktop.value.ready) return `已连接 PID ${desktop.value.pid}`
  if (desktop.value.connected) return `等待进入地图 · PID ${desktop.value.pid}`
  return '等待魔兽进程'
})

function openHistory() {
  historyOpen.value = true
  requestHistory()
}

function selectHistory(sessionId: string) {
  loadHistory(sessionId)
  historyOpen.value = false
}

function backToLive() {
  resumeLive()
}

function loadEventPage(request: { page: number; pageSize: number }) {
  requestEventPage({
    sessionId: snapshot.value.sessionId,
    query: query.value,
    page: request.page,
    pageSize: request.pageSize,
    victimFilter: victimFilter.value,
    sourceFilter: sourceFilter.value,
  })
}

function loadSettlementPage(request: {
  page: number
  pageSize: number
  victimFilter: EventUnitFilter | null
}) {
  requestSettlementPage({
    sessionId: snapshot.value.sessionId,
    query: query.value,
    page: request.page,
    pageSize: request.pageSize,
    victimFilter: request.victimFilter,
  })
}
</script>

<template>
  <main class="app-shell" :class="{ 'desktop-app': desktop }">
    <header v-if="desktop" class="desktop-bar">
      <div class="brand">
        <span class="brand-mark">D</span>
        <div>
          <strong>魔兽死亡结算</strong>
          <small>WAR3 DEATH SETTLEMENT · v{{ desktop.appVersion }}</small>
        </div>
      </div>

      <div class="desktop-actions">
        <span class="connection-pill" :class="{ online: desktop.connected, ready: desktop.ready }">
          <i />
          {{ connectionText }}
        </span>
        <button :disabled="busy" @click="command('find-game')">查找游戏</button>
        <button @click="openHistory">历史</button>
        <button v-if="desktop.mode === 'history'" class="accent-button" @click="backToLive">
          回到实时
        </button>
        <button @click="command('open-logs')">日志</button>
        <button @click="command('open-settings')">设置</button>
      </div>
    </header>

    <section class="controlbar">
      <nav class="tabs" aria-label="结算内容">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          :class="{ active: activeTab === tab.id }"
          @click="activeTab = tab.id"
        >
          <span>{{ tab.label }}</span>
          <small>{{ tab.hint }}</small>
        </button>
      </nav>

      <label v-if="desktop" class="search-box">
        <span>筛选</span>
        <input v-model="query" type="search" placeholder="单位、类型码、来源或地址" />
        <button v-if="query" aria-label="清空筛选" @click="query = ''">×</button>
      </label>
    </section>

    <section class="content">
      <DeathPanel
        v-if="activeTab === 'deaths'"
        :key="snapshot.sessionId"
        :settlement-page="settlementPage"
        :loading="settlementPageLoading"
        :error="settlementPageError"
        :session-id="snapshot.sessionId"
        :settlement-revision="snapshot.counts.settlements"
        :query="query"
        :detail="settlementDetail"
        :detail-loading="settlementDetailLoading"
        :detail-error="settlementDetailError"
        @page-request="loadSettlementPage"
        @select-settlement="requestSettlementDetail"
      />
      <EventsPanel
        v-else-if="activeTab === 'events'"
        :event-page="eventPage"
        :loading="eventPageLoading"
        :error="eventPageError"
        :session-id="snapshot.sessionId"
        :event-revision="snapshot.eventRevision"
        :query="query"
        :victim-filter="victimFilter"
        :source-filter="sourceFilter"
        @update:victim-filter="victimFilter = $event"
        @update:source-filter="sourceFilter = $event"
        @page-request="loadEventPage"
      />
      <UnitsPanel
        v-else
        :units="snapshot.units"
        :query="query"
      />
    </section>

    <footer v-if="desktop" class="desktop-status">
      <span class="status-dot" :class="{ online: desktop.connected }" />
      <span>{{ desktop.status || snapshot.message }}</span>
      <span class="status-separator" />
      <span>{{ desktop.sourceLabel }}</span>
      <span v-if="desktop.sessionId" class="mono">会话 {{ desktop.sessionId }}</span>
      <span v-if="desktop.selfIntegrity" class="status-right">
        本程序 {{ desktop.selfIntegrity }}
        <template v-if="desktop.gameIntegrity"> / 游戏 {{ desktop.gameIntegrity }}</template>
      </span>
    </footer>

    <aside v-if="historyOpen" class="history-drawer">
      <div class="drawer-heading">
        <div>
          <span class="eyebrow">MATCH HISTORY</span>
          <h2>对局历史</h2>
        </div>
        <button aria-label="关闭历史" @click="historyOpen = false">×</button>
      </div>
      <p v-if="historyError" class="drawer-error">{{ historyError }}</p>
      <div class="history-list">
        <button
          v-for="item in historyItems"
          :key="item.sessionId"
          class="history-item"
          @click="selectHistory(item.sessionId)"
        >
          <span class="history-map">{{ item.mapName || '未命名地图' }}</span>
          <span class="history-session mono">{{ item.sessionId }}</span>
          <span class="history-metrics">
            结算 {{ item.settlementCount }} · 事件 {{ item.eventCount }} · 单位 {{ item.unitCount }}
          </span>
          <span class="history-damage">{{ item.totalDamage.toFixed(0) }}</span>
        </button>
        <div v-if="historyItems.length === 0" class="history-empty">
          当前数据库还没有可查看的对局。
        </div>
      </div>
    </aside>
    <button
      v-if="historyOpen"
      class="drawer-backdrop"
      aria-label="关闭历史"
      @click="historyOpen = false"
    />
  </main>
</template>
