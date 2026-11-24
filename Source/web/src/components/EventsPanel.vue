<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import {
  damageTypeText,
  formatAddr,
  formatCompact,
  formatFixed,
  playerText,
} from '../format'
import type { EventPage, EventUnitFilter } from '../types'

const props = defineProps<{
  eventPage: EventPage
  loading: boolean
  error: string
  sessionId: string
  eventRevision: number
  query: string
  victimFilter: EventUnitFilter | null
  sourceFilter: EventUnitFilter | null
}>()
const emit = defineEmits<{
  'update:victim-filter': [value: EventUnitFilter | null]
  'update:source-filter': [value: EventUnitFilter | null]
  'page-request': [value: { page: number; pageSize: number }]
}>()

const pageSize = 500
const page = ref(0)
const selectedSeq = ref<number | null>(null)
const scrollElement = ref<HTMLElement | null>(null)
let requestTimer: ReturnType<typeof setTimeout> | undefined
let stopColumnResize: (() => void) | null = null

const defaultColumnWidths: Record<number, number> = {
  3: 170,
  4: 160,
  5: 30,
  11: 210,
}
const minColumnWidths: Record<number, number> = { 3: 110, 11: 140 }
const columnWidthStorageKey = 'ddh-events-column-widths-v3'
const columnWidths = ref<Record<number, number>>({ ...defaultColumnWidths })

try {
  const saved = JSON.parse(localStorage.getItem(columnWidthStorageKey) || '{}') as
    Record<string, number>
  for (const index of [3, 11]) {
    const width = Number(saved[index])
    if (Number.isFinite(width) && width >= minColumnWidths[index])
      columnWidths.value[index] = Math.min(width, 600)
  }
} catch {
  // 本地存储不可用时只保留本次会话的默认宽度。
}

const pageCount = computed(() =>
  Math.max(1, Math.ceil(props.eventPage.total / pageSize)),
)
const rows = computed(() => props.eventPage.rows)

function sendPage(reset: boolean, delay = 0) {
  if (reset) {
    page.value = 0
    if (scrollElement.value) scrollElement.value.scrollTop = 0
  }
  if (requestTimer) clearTimeout(requestTimer)
  requestTimer = setTimeout(() => {
    emit('page-request', { page: page.value, pageSize })
  }, delay)
}

function changePage(delta: number) {
  page.value = Math.max(0, Math.min(pageCount.value - 1, page.value + delta))
  sendPage(false)
}

function selectRow(seq: number) {
  selectedSeq.value = seq
}

function columnStyle(index: number) {
  const width = columnWidths.value[index]
  return width ? { width: `${width}px` } : undefined
}

function startColumnResize(index: number, event: PointerEvent) {
  stopColumnResize?.()
  const header = (event.currentTarget as HTMLElement).closest('th')
  if (!header) return

  event.preventDefault()
  const startX = event.clientX
  const startWidth = columnWidths.value[index]
    ?? header.getBoundingClientRect().width

  const move = (moveEvent: PointerEvent) => {
    const width = Math.max(
      minColumnWidths[index],
      Math.min(600, startWidth + moveEvent.clientX - startX),
    )
    columnWidths.value = { ...columnWidths.value, [index]: width }
  }
  const end = () => {
    window.removeEventListener('pointermove', move)
    window.removeEventListener('pointerup', end)
    window.removeEventListener('pointercancel', end)
    ;(window as typeof window & { __ddhSuppressClickUntil?: number })
      .__ddhSuppressClickUntil = Date.now() + 120
    try {
      localStorage.setItem(columnWidthStorageKey, JSON.stringify(columnWidths.value))
    } catch {
      // 宽度仍保留到当前页面关闭。
    }
    stopColumnResize = null
  }

  window.addEventListener('pointermove', move)
  window.addEventListener('pointerup', end)
  window.addEventListener('pointercancel', end)
  stopColumnResize = end
}

function filterByUnit(field: 'victim' | 'source', filter: EventUnitFilter) {
  if (field === 'victim') emit('update:victim-filter', filter)
  else emit('update:source-filter', filter)
}

function clearUnitFilter(field: 'victim' | 'source') {
  if (field === 'victim') emit('update:victim-filter', null)
  else emit('update:source-filter', null)
}

watch(
  [() => props.sessionId, () => props.query,
    () => props.victimFilter?.typeCode, () => props.victimFilter?.illusion,
    () => props.sourceFilter?.typeCode, () => props.sourceFilter?.illusion],
  () => sendPage(true, 180),
  { immediate: true },
)

watch(
  () => props.eventRevision,
  value => {
    if (!value || page.value !== 0) return
    if ((scrollElement.value?.scrollTop ?? 0) < 50) sendPage(false, 250)
  },
)

watch(
  () => props.eventPage.page,
  value => {
    if (!props.loading) page.value = value
  },
)

onBeforeUnmount(() => {
  if (requestTimer) clearTimeout(requestTimer)
  stopColumnResize?.()
})
</script>

<template>
  <section class="events-panel">
    <div class="table-card fill-card events-card">
      <div class="table-viewport">
        <div ref="scrollElement" class="table-scroll events-scroll">
          <table class="data-table events-table">
          <thead>
            <tr>
              <th>时间</th>
              <th class="table-filter-head resizable-head">
                <span>触发单位</span>
                <span v-if="victimFilter" class="column-filter">
                  <span :title="victimFilter.label">{{ victimFilter.label }}</span>
                  <button aria-label="关闭触发单位筛选" @click="clearUnitFilter('victim')">×</button>
                </span>
              </th>
              <th class="table-filter-head">
                <span>伤害来源</span>
                <span v-if="sourceFilter" class="column-filter">
                  <span :title="sourceFilter.label">{{ sourceFilter.label }}</span>
                  <button aria-label="关闭伤害来源筛选" @click="clearUnitFilter('source')">×</button>
                </span>
                <span class="column-resizer" title="拖动调整伤害来源列宽"
                      @pointerdown="startColumnResize(3, $event)" />
              </th>
              <th title="攻击 / 远程 / 攻击类型 / 伤害类型">攻击 / 远程 / 攻击类型 / 伤害类型</th>
              <th class="depth-column">层</th>
              <th>原始伤害</th>
              <th>引擎伤害</th>
              <th>地图伤害</th>
              <th>净掉血</th>
              <th>倍数</th>
              <th class="resizable-head" title="拖动右边缘调整列宽">
                本层前血→后血
                <span class="column-resizer" @pointerdown="startColumnResize(11, $event)" />
              </th>
              <th>实例ID</th>
              <th>触发玩家</th>
              <th>实例ID</th>
              <th>来源玩家</th>
            </tr>
          </thead>
          <colgroup>
            <col v-for="index in 15" :key="index" :style="columnStyle(index)" />
          </colgroup>
          <tbody>
            <tr
              v-for="row in rows"
              :key="row.seq"
              :class="{ selected: selectedSeq === row.seq }"
              @click="selectRow(row.seq)"
            >
              <td class="mono muted">{{ row.time }}</td>
              <td class="name-cell">
                <button type="button" class="unit-filter-link" title="点击按该单位筛选"
                        @click.stop="filterByUnit('victim', {
                          typeCode: row.victimCode,
                          illusion: row.victimIllusion,
                          label: row.victimName || row.victimCode || formatAddr(row.victim),
                        })">
                  {{ row.victimName || row.victimCode }}
                </button>
              </td>
              <td class="name-cell">
                <button type="button" class="unit-filter-link" title="点击按该单位筛选"
                        @click.stop="filterByUnit('source', {
                          typeCode: row.sourceCode,
                          illusion: row.sourceIllusion,
                          label: row.sourceName || row.sourceCode || formatAddr(row.source),
                        })">
                  {{ row.sourceName || row.sourceCode }}
                </button>
              </td>
              <td class="composition-cell">
                {{ row.isAttack ? '1' : '0' }} / {{ row.isRanged ? '1' : '0' }} /
                {{ row.attackType }} / {{ damageTypeText(row) }}
              </td>
              <td class="number depth-column">{{ row.depth > 1 ? row.depth : 1 }}</td>
              <td class="number">{{ formatFixed(row.amount, 2) }}</td>
              <td class="number">{{ row.engineValid ? formatFixed(row.engine, 2) : '?' }}</td>
              <td class="number">{{ row.effectiveValid ? formatFixed(row.effective, 2) : '?' }}</td>
              <td class="number strong">{{ row.hpValid ? formatFixed(row.actual, 2) : '?' }}</td>
              <td class="number">{{ row.rate > 0 ? `${formatCompact(row.rate)}×` : '' }}</td>
              <td class="mono">{{ row.hpValid ? `${formatFixed(row.hpBefore, 2)}→${formatFixed(row.hpAfter, 2)}` : '' }}</td>
              <td class="mono muted">{{ formatAddr(row.victim) }}</td>
              <td>{{ playerText(row.victimOwner) }}</td>
              <td class="mono muted">{{ formatAddr(row.source) }}</td>
              <td>{{ playerText(row.sourceOwner) }}</td>
            </tr>
          </tbody>
          </table>
        </div>
        <div v-if="rows.length === 0" class="table-empty-overlay">
          <div class="table-empty-message">
            <strong>{{ loading ? '正在读取事件…' : '暂无伤害事件' }}</strong>
            <span>{{ error || '进入地图并发生战斗后，WebHost 会按当前页从 SQLite 读取事件。' }}</span>
          </div>
        </div>
      </div>

      <footer class="table-footer">
        <span>
          {{ loading ? '正在刷新当前页…' : `共 ${eventPage.total} 条 · 每页最多 ${pageSize} 条` }}
        </span>
        <div class="pager">
          <button :disabled="page <= 0" @click="changePage(-1)">上一页</button>
          <span>{{ page + 1 }} / {{ pageCount }}</span>
          <button :disabled="page >= pageCount - 1" @click="changePage(1)">下一页</button>
        </div>
      </footer>
    </div>
  </section>
</template>
