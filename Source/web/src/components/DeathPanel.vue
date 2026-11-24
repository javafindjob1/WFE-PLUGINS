<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import {
  formatAddr,
  formatFixed,
  playerText,
  unitLabel,
} from '../format'
import type {
  EventUnitFilter,
  SettlementDetail,
  SettlementPage,
  SettlementRow,
} from '../types'

const props = defineProps<{
  settlementPage: SettlementPage
  loading: boolean
  error: string
  sessionId: string
  settlementRevision: number
  query: string
  detail: SettlementDetail | null
  detailLoading: boolean
  detailError: string
}>()
const emit = defineEmits<{
  'page-request': [value: {
    page: number
    pageSize: number
    victimFilter: EventUnitFilter | null
  }]
  'select-settlement': [seq: number]
}>()

const pageSize = 200
const page = ref(0)
const selectedSeq = ref<number | null>(null)
const victimFilter = ref<EventUnitFilter | null>(null)
const scrollElement = ref<HTMLElement | null>(null)
let requestTimer: ReturnType<typeof setTimeout> | undefined

const pageCount = computed(() =>
  Math.max(1, Math.ceil(props.settlementPage.total / pageSize)),
)
const rows = computed(() => props.settlementPage.rows)

function sendPage(reset: boolean, delay = 0) {
  if (reset) {
    page.value = 0
    if (scrollElement.value) scrollElement.value.scrollTop = 0
  }
  if (requestTimer) clearTimeout(requestTimer)
  requestTimer = setTimeout(() => {
    emit('page-request', {
      page: page.value,
      pageSize,
      victimFilter: victimFilter.value,
    })
  }, delay)
}

function changePage(delta: number) {
  page.value = Math.max(0, Math.min(pageCount.value - 1, page.value + delta))
  sendPage(false)
}

watch(
  rows,
  rows => {
    if (selectedSeq.value !== null && rows.some(row => row.seq === selectedSeq.value)) return
    selectedSeq.value = rows[0]?.seq ?? null
  },
  { immediate: true },
)

const selected = computed(() =>
  rows.value.find(row => row.seq === selectedSeq.value)
  ?? rows.value[0]
  ?? null,
)

const breakdownRows = computed(() => {
  return props.detail && props.detail.seq === selected.value?.seq ? props.detail.rows : []
})

watch(
  () => selected.value?.seq ?? null,
  seq => {
    if (seq !== null) emit('select-settlement', seq)
  },
  { immediate: true },
)

function selectRow(row: SettlementRow) {
  selectedSeq.value = row.seq
}

function filterByVictim(row: SettlementRow) {
  selectedSeq.value = row.seq
  victimFilter.value = {
    typeCode: row.victimCode,
    illusion: false,
    label: row.victimName || row.victimCode || formatAddr(row.victim),
  }
}

function clearVictimFilter() {
  victimFilter.value = null
}

watch(
  [
    () => props.sessionId,
    () => props.query,
    () => victimFilter.value?.typeCode,
    () => victimFilter.value?.illusion,
  ],
  () => sendPage(true, 180),
  { immediate: true },
)

watch(
  () => props.settlementRevision,
  value => {
    if (!value || page.value !== 0) return
    if ((scrollElement.value?.scrollTop ?? 0) < 50) sendPage(false, 250)
  },
)

watch(
  () => props.settlementPage.page,
  value => {
    if (!props.loading) page.value = value
  },
)

onBeforeUnmount(() => {
  if (requestTimer) clearTimeout(requestTimer)
})
</script>

<template>
  <section class="death-panel">
    <div class="table-card settlement-table-card">
      <div class="table-viewport">
        <div ref="scrollElement" class="table-scroll settlement-scroll">
          <table class="data-table settlement-table">
          <thead>
            <tr>
              <th>时间</th>
              <th class="table-filter-head">
                <span>触发单位</span>
                <span v-if="victimFilter" class="column-filter">
                  <span :title="victimFilter.label">{{ victimFilter.label }}</span>
                  <button aria-label="关闭触发单位筛选" @click="clearVictimFilter">×</button>
                </span>
              </th>
              <th>类型码</th>
              <th>实例ID</th>
              <th>玩家</th>
              <th>结局</th>
              <th>实例</th>
              <th>受击</th>
              <th>总伤害</th>
              <th>最大单次</th>
              <th>最惨1秒</th>
              <th>秒伤</th>
              <th>存活s</th>
              <th>战斗s</th>
            </tr>
          </thead>
          <colgroup>
            <col v-for="index in 14" :key="index" />
          </colgroup>
          <tbody>
            <tr
              v-for="row in rows"
              :key="row.seq"
              :class="{ selected: selected?.seq === row.seq }"
              @click="selectRow(row)"
            >
              <td class="mono muted">{{ row.diedAt }}</td>
              <td class="name-cell">
                <button type="button" class="unit-filter-link" title="点击按该单位筛选"
                        @click.stop="filterByVictim(row)">
                  {{ row.victimName || row.victimCode }}
                </button>
              </td>
              <td class="mono accent">{{ row.victimCode }}</td>
              <td class="mono muted">{{ formatAddr(row.victim) }}</td>
              <td>{{ playerText(row.victimOwner) }}</td>
              <td>{{ row.kind }}</td>
              <td>{{ row.instanceIndex }}</td>
              <td>{{ row.hits }}</td>
              <td class="number strong">{{ formatFixed(row.totalDamage, 2) }}</td>
              <td class="number">{{ formatFixed(row.maxHit, 2) }}</td>
              <td class="number">{{ formatFixed(row.peak1s, 2) }}</td>
              <td class="number">{{ formatFixed(row.dps, 2) }}</td>
              <td class="number">{{ formatFixed(row.lifetimeSeconds, 1) }}</td>
              <td class="number">{{ formatFixed(row.combatSeconds, 1) }}</td>
            </tr>
          </tbody>
          </table>
        </div>
        <div v-if="rows.length === 0" class="table-empty-overlay">
          <div class="table-empty-message">
            <strong>{{ loading ? '正在读取死亡结算…' : '暂无阵亡结算' }}</strong>
            <span>{{ error || '进入地图并发生死亡后，WebHost 会按当前页从 SQLite 读取结算。' }}</span>
          </div>
        </div>
      </div>
      <footer class="table-footer">
        <span :title="error">
          {{ loading
            ? '正在刷新当前页…'
            : `共 ${settlementPage.total} 条 · 每页最多 ${pageSize} 条` }}
        </span>
        <div class="pager">
          <button :disabled="page <= 0" @click="changePage(-1)">上一页</button>
          <span>{{ page + 1 }} / {{ pageCount }}</span>
          <button :disabled="page >= pageCount - 1" @click="changePage(1)">下一页</button>
        </div>
      </footer>
    </div>

    <div class="detail-grid">
      <div class="table-card breakdown-card">
        <div class="section-heading compact-heading">
          <div>
            <span class="eyebrow">DAMAGE BREAKDOWN</span>
            <h2>伤害构成</h2>
          </div>
          <span class="selection-label" v-if="selected">
            {{ unitLabel(selected.victimName, selected.victimCode, selected.victim) }}
          </span>
          <span class="selection-label" v-else>本局全部事件</span>
        </div>

        <div class="breakdown-body">
          <div class="table-viewport">
            <div class="table-scroll source-table-wrap">
              <table class="data-table breakdown-table">
              <thead>
                <tr>
                  <th>伤害来源</th>
                  <th>是否攻击</th>
                  <th>是否远程</th>
                  <th>攻击类型</th>
                  <th>伤害类型</th>
                  <th>笔数</th>
                  <th>原始伤害</th>
                  <th>引擎伤害</th>
                  <th>地图伤害</th>
                  <th>净掉血</th>
                  <th>占比</th>
                </tr>
              </thead>
              <colgroup>
                <col v-for="index in 11" :key="index" />
              </colgroup>
              <tbody>
                <tr
                  v-for="(row, index) in breakdownRows"
                  :key="`${row.source}-${row.isAttack}-${row.attackType}-${row.damageType}-${index}`"
                  :class="{ 'summary-row': row.summary }"
                >
                  <td class="name-cell">{{ row.source }}</td>
                  <td>{{ row.isAttack }}</td>
                  <td>{{ row.isRanged }}</td>
                  <td>{{ row.attackType }}</td>
                  <td>{{ row.damageType }}</td>
                  <td class="number">{{ row.count }}</td>
                  <td class="number">{{ row.count > 0 ? formatFixed(row.raw, 2) : '?' }}</td>
                  <td class="number">{{ row.engineValid ? formatFixed(row.engine, 2) : '?' }}</td>
                  <td class="number">{{ row.effectiveValid ? formatFixed(row.effective, 2) : '?' }}</td>
                  <td class="number strong">{{ row.netValid ? formatFixed(row.net, 2) : '?' }}</td>
                  <td class="number percent-cell">{{ formatFixed(row.percent, 1) }}%</td>
                </tr>
              </tbody>
              </table>
            </div>
            <div v-if="breakdownRows.length === 0" class="table-empty-overlay compact">
              <div class="table-empty-message">
                <span>{{ detailLoading ? '正在由 WebHost 汇总伤害构成…' : detailError || '当前死亡记录没有可聚合的伤害事件' }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
