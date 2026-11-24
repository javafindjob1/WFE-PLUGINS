<script setup lang="ts">
import { computed } from 'vue'
import { formatAddr, formatCompact, playerText, unitIdentity } from '../format'
import type { UnitRow } from '../types'

const ATTACK_SPEED_FREQUENCY_CAP = 5

const props = defineProps<{
  units: UnitRow[]
  query: string
}>()

const filtered = computed(() => {
  const term = props.query.trim().toLocaleLowerCase()
  const illusionCodes = new Set(
    props.units.filter(row => row.illusion).map(row => row.typeCode.toUpperCase()),
  )
  return props.units
    .filter(row => !(row.ownerSlot >= 12))
    .filter(row => row.illusion || !row.locust || illusionCodes.has(row.typeCode.toUpperCase()))
    .filter(row => {
      if (!term) return true
      return [row.name, row.title, row.typeCode, formatAddr(row.addr)]
        .some(value => value.toLocaleLowerCase().includes(term))
    })
})

function positive(value: number): string {
  return value > 0 ? formatCompact(value) : '?'
}

function damageValue(row: UnitRow, value: number): string {
  return row.damageMin > 0 || row.damageMax > 0 ? formatCompact(value) : '?'
}

function frequency(row: UnitRow): string {
  if (row.attackSpeed <= 0 || row.attackInterval <= 0) return '?'
  const cappedAttackSpeed = Math.min(row.attackSpeed, ATTACK_SPEED_FREQUENCY_CAP)
  return formatCompact(cappedAttackSpeed / row.attackInterval)
}
</script>

<template>
  <section class="units-panel">
    <div class="table-card fill-card units-card">
      <div class="table-viewport">
        <div class="table-scroll units-scroll">
          <table class="data-table units-table">
          <thead>
            <tr>
              <th>类型码</th>
              <th>单位名称（称谓）</th>
              <th>最小攻击力</th>
              <th>最大攻击力</th>
              <th>攻击范围</th>
              <th>护甲</th>
              <th>攻击速度</th>
              <th>攻击间隔</th>
              <th>攻击频率</th>
              <th>蝗虫</th>
              <th>镜像</th>
              <th>玩家</th>
              <th>地址</th>
            </tr>
          </thead>
          <colgroup>
            <col v-for="index in 13" :key="index" />
          </colgroup>
          <tbody>
            <tr v-for="row in filtered" :key="`${row.addr}-${row.typeCode}`">
              <td class="mono accent">{{ row.typeCode }}</td>
              <td class="identity-cell">{{ unitIdentity(row.name, row.title, row.typeCode, row.illusion) }}</td>
              <td class="number">{{ damageValue(row, row.damageMin) }}</td>
              <td class="number">{{ damageValue(row, row.damageMax) }}</td>
              <td class="number">{{ positive(row.attackRange) }}</td>
              <td class="number">{{ formatCompact(row.armor) }}</td>
              <td class="number">{{ positive(row.attackSpeed) }}</td>
              <td class="number">{{ positive(row.attackInterval) }}</td>
              <td class="number">{{ frequency(row) }}</td>
              <td>{{ row.locust ? '是' : '否' }}</td>
              <td>{{ row.illusion ? '是' : '否' }}</td>
              <td>{{ playerText(row.ownerSlot) }}</td>
              <td class="mono muted">{{ formatAddr(row.addr) }}</td>
            </tr>
          </tbody>
          </table>
        </div>
        <div v-if="filtered.length === 0" class="table-empty-overlay">
          <div class="table-empty-message">
            <strong>暂无战场单位</strong>
            <span>单位属性由 ddh 写入 SQLite 后会显示在这里。</span>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
