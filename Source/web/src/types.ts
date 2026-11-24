export interface SettlementRow {
  pid: number
  seq: number
  wallMs: number
  diedAt: string
  victim: number
  victimCode: string
  victimName: string
  victimOwner: number
  kind: string
  instanceIndex: number
  totalDamage: number
  hits: number
  maxHit: number
  peak1s: number
  dps: number
  lifetimeSeconds: number
  combatSeconds: number
  fatalSource: number
  fatalSourceCode: string
  fatalSourceName: string
  fatalDamage: number
  firstTick: number
  lastTick: number
}

export interface SettlementPage {
  schemaVersion: number
  type: 'settlement-page'
  requestId: number
  sessionId: string
  page: number
  pageSize: number
  total: number
  error: string
  rows: SettlementRow[]
}

export interface DamageEventRow {
  seq: number
  wallMs: number
  time: string
  victim: number
  victimCode: string
  victimName: string
  victimOwner: number
  victimIllusion: boolean
  victimHero: boolean
  source: number
  sourceCode: string
  sourceName: string
  sourceOwner: number
  sourceIllusion: boolean
  sourceHero: boolean
  amount: number
  engine: number
  final: number
  actual: number
  engineValid: boolean
  finalFlags: number
  finalValid: boolean
  effective: number
  effectiveValid: boolean
  rate: number
  hpBefore: number
  hpAfter: number
  hpValid: boolean
  attackType: number
  damageMask: number
  damageType: number
  isPhysical: boolean
  isAttack: boolean
  isRanged: boolean
  depth: number
  unitFlags: number
}

export interface UnitRow {
  addr: number
  typeCode: string
  name: string
  title: string
  ownerSlot: number
  attackRange: number
  damageMin: number
  damageMax: number
  attackInterval: number
  attackSpeed: number
  armor: number
  moveSpeed: number
  sightDay: number
  sightNight: number
  acquireRange: number
  strength: number
  agility: number
  intelligence: number
  hero: boolean
  illusion: boolean
  locust: boolean
  dead: boolean
}

export interface Snapshot {
  schemaVersion: number
  generatedAt: string
  pid: number
  sessionId: string
  mapName: string
  sessionUpdatedAt: string
  sessionRevision: number
  databasePath: string
  backend: string
  message: string
  eventRevision: number
  counts: {
    settlements: number
    events: number
    units: number
  }
  settlements: SettlementRow[]
  events: DamageEventRow[]
  units: UnitRow[]
  desktop?: DesktopState
}

export interface DesktopState {
  mode: 'live' | 'history'
  appVersion: string
  buildTime: string
  connected: boolean
  ready: boolean
  autoAttach: boolean
  pid: number
  sessionId: string
  gameVersion: string
  status: string
  hookStatus: string
  hookAttached: boolean
  selfIntegrity: string
  gameIntegrity: string
  scanCount: number
  databasePath: string
  sourceLabel: string
}

export interface HistoryItem {
  sessionId: string
  mapName: string
  startedAt: string
  endedAt: string
  totalDamage: number
  settlementCount: number
  eventCount: number
  unitCount: number
}

export interface BreakdownRow {
  source: string
  isAttack: string
  isRanged: string
  attackType: string
  damageType: string
  count: number
  raw: number
  engine: number
  engineValid: boolean
  effective: number
  effectiveValid: boolean
  net: number
  netValid: boolean
  percent: number
  summary: boolean
}

export interface EventPage {
  schemaVersion: number
  type: 'event-page'
  requestId: number
  sessionId: string
  page: number
  pageSize: number
  total: number
  eventRevision: number
  error: string
  rows: DamageEventRow[]
}

export interface SettlementDetail {
  schemaVersion: number
  type: 'settlement-detail'
  requestId: number
  sessionId: string
  seq: number
  victim: number
  eventCount: number
  error: string
  rows: BreakdownRow[]
}

export interface EventUnitFilter {
  typeCode: string
  illusion: boolean
  label: string
}
