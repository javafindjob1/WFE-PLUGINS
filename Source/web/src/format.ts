import type { DamageEventRow, SettlementRow, Snapshot } from './types'

export const emptySnapshot: Snapshot = {
  schemaVersion: 1,
  generatedAt: new Date().toISOString(),
  pid: 0,
  sessionId: '',
  mapName: '',
  sessionUpdatedAt: '',
  sessionRevision: 0,
  databasePath: '',
  backend: 'SQLite',
  message: '正在读取 SQLite…',
  eventRevision: 0,
  counts: { settlements: 0, events: 0, units: 0 },
  settlements: [],
  events: [],
  units: [],
}

export function formatNumber(value: number, digits = 1): string {
  if (!Number.isFinite(value)) return '?'
  return value.toLocaleString('zh-CN', {
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  })
}

export function formatFixed(value: number, digits = 2): string {
  return Number.isFinite(value) ? value.toFixed(digits) : '?'
}

export function formatCompact(value: number): string {
  if (!Number.isFinite(value)) return '?'
  return Number(value.toFixed(2)).toString()
}

export function compactNumber(value: number): string {
  const abs = Math.abs(value)
  if (abs >= 1_000_000) return `${formatNumber(value / 1_000_000, 2)}m`
  if (abs >= 10_000) return `${formatNumber(value / 1_000, 1)}k`
  return formatNumber(value, Math.abs(value) >= 100 ? 0 : 1)
}

export function formatAddr(addr: number): string {
  return `0x${(addr >>> 0).toString(16).padStart(8, '0').toUpperCase()}`
}

export function playerText(slot: number): string {
  return slot >= 0 ? `Player ${slot + 1}` : '?'
}

export function unitLabel(name: string, code: string, addr: number): string {
  if (name) return `${name}${code ? ` (${code})` : ''}`
  return code || formatAddr(addr)
}

export function unitIdentity(name: string, title: string, code: string, illusion = false): string {
  const cleanName = name || code
  const cleanTitle = title && title !== name ? title : ''
  let text = cleanTitle ? `${cleanTitle}\n${cleanName}` : cleanName
  if (illusion && !text.includes('镜像')) text += '（镜像）'
  return text
}

export function attackTypeText(value: number): string {
  return String(value)
}

export function damageTypeText(event: Pick<DamageEventRow, 'damageType' | 'damageMask'>): string {
  if (event.damageType < 0) return '?'
  const single = event.damageMask !== 0 && (event.damageMask & (event.damageMask - 1)) === 0
  return single
    ? String(event.damageType)
    : `${event.damageType}(多类型0x${event.damageMask.toString(16).toUpperCase()})`
}

export function settlementDps(row: SettlementRow): number {
  return row.dps
}

export function matchesSettlement(row: SettlementRow, query: string): boolean {
  const term = query.trim().toLocaleLowerCase()
  if (!term) return true
  return [row.victimName, row.victimCode, row.fatalSourceName, formatAddr(row.victim)]
    .some(value => value.toLocaleLowerCase().includes(term))
}

export function matchesEvent(row: DamageEventRow, query: string): boolean {
  const term = query.trim().toLocaleLowerCase()
  if (!term) return true
  return [
    row.victimName,
    row.victimCode,
    row.sourceName,
    row.sourceCode,
    formatAddr(row.victim),
    formatAddr(row.source),
  ].some(value => value.toLocaleLowerCase().includes(term))
}
