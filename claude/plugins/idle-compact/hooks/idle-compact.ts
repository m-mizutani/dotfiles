import type { EngineInterface, Register, Timer } from 'claude-code'

// Compact once after the main conversation has been idle for 50 minutes, while
// the 1h prompt cache is still warm. At most one timer; nothing is re-armed after it.
export const IDLE_MS = 50 * 60 * 1000
// A timer firing later than this (e.g. the machine slept) may find the cache cold;
// compacting would then re-cache the whole context, so it does nothing.
export const LATEST_MS = 58 * 60 * 1000

type Pending = {
  generation: number
  timer: Timer
  sessionId: string
  armedAt: number
}

type State = {
  // Bumped on every cancel so that callbacks of older timers become no-ops.
  generation: number
  pending: Pending | null
  // The main turn seen at turn.start; only its matching turn.complete arms.
  turnId: string | null
  compacting: boolean
}

async function debug($: EngineInterface, text: string) {
  try {
    await $.ui.log(`idle-compact: ${text}`, { to: 'debug' })
  } catch {}
}

// Shown in the conversation and kept in the transcript, never sent to the model.
async function notice($: EngineInterface, text: string) {
  try {
    await $.ui.log(`idle-compact: ${text}`, { to: 'transcript' })
  } catch {}
}

export function formatClock(ms: number): string {
  const d = new Date(ms)
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
}

type Usage = {
  input_tokens?: number
  cache_read_input_tokens?: number
  cache_creation_input_tokens?: number
}

// Share of the summary call's input served from the prompt cache; null without usage.
export function cacheHitSummary(result: unknown): string | null {
  const usage = (result as { usage?: Usage } | undefined)?.usage
  if (usage === undefined) return null
  const read = usage.cache_read_input_tokens ?? 0
  const written = usage.cache_creation_input_tokens ?? 0
  const uncached = usage.input_tokens ?? 0
  const total = read + written + uncached
  if (total === 0) return null
  // Integer math: (29 / 50) * 100 in floating point floors to 57.
  const percent = Math.floor((read * 100) / total)
  const n = (x: number) => x.toLocaleString('en-US')
  return `compacted with a ${percent}% cache hit (${n(read)} read, ${n(written)} written, ${n(uncached)} uncached)`
}

function cancel(state: State) {
  state.generation++
  state.pending?.timer.cancel()
  state.pending = null
}

async function arm($: EngineInterface, state: State) {
  cancel(state)
  const generation = state.generation
  const armedAt = await $.clock.now()
  const sessionId = await $.session.id()
  // A turn that started during the awaits above wins.
  if (state.generation !== generation) return
  const timer = $.clock.after(IDLE_MS, () => void fire($, state, generation))
  state.pending = { generation, timer, sessionId, armedAt }
  await notice($, `compacts at ${formatClock(armedAt + IDLE_MS)} if nothing happens before then`)
  await debug($, `armed at ${new Date(armedAt).toISOString()}`)
}

async function fire($: EngineInterface, state: State, generation: number) {
  const pending = state.pending
  if (pending === null || pending.generation !== generation || state.compacting) return
  state.pending = null
  try {
    const elapsed = (await $.clock.now()) - pending.armedAt
    const minutes = (elapsed / 60000).toFixed(1)
    if (elapsed < IDLE_MS || elapsed >= LATEST_MS) {
      await debug($, `fired after ${minutes} min: outside the window, skipped`)
      return
    }
    if ((await $.session.id()) !== pending.sessionId) {
      await debug($, `fired after ${minutes} min: session changed, skipped`)
      return
    }
    // Checked after the last await: a turn may have started in the meantime.
    if (state.generation !== generation) return
    state.compacting = true
    await debug($, `fired after ${minutes} min: compacting`)
    const result = await $.session.compact()
    await debug($, 'compaction finished')
    const summary = cacheHitSummary(result)
    if (summary !== null) await notice($, summary)
  } catch (error) {
    // A running turn, DISABLE_COMPACT or a headless host: never retried, by design.
    await debug($, `compaction failed: ${error instanceof Error ? error.message : String(error)}`)
  } finally {
    state.compacting = false
  }
}

export const register: Register = (on) => {
  const state: State = { generation: 0, pending: null, turnId: null, compacting: false }

  on('turn.start', ($, e, next) => {
    cancel(state)
    state.turnId = e.turnId
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    // Skip subagent runs (agentId), aborted or failed turns, completions raised by our
    // own compaction, and completions without a matching turn.start.
    if (e.agentId !== undefined || e.reason !== 'answer' || state.compacting) return result
    if (e.turnId !== state.turnId) return result
    state.turnId = null
    await arm($, state)
    return result
  })

  // A manual /compact or an auto compaction is activity too: the pending timer would
  // only compact the fresh summary again.
  on('session.compact', ($, e, next) => {
    if (e.agentId === undefined && (e.trigger === 'manual' || e.trigger === 'auto')) cancel(state)
    return next(e)
  })

  on('session.end', ($, e, next) => {
    cancel(state)
    state.turnId = null
    return next(e)
  })
}
