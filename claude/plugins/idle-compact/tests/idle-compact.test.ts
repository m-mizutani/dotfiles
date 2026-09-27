import { describe, expect, mock, test } from 'claude-code/testing'
import type { On } from 'claude-code'
import type { Engine } from 'claude-code/testing'
import { formatClock } from '../hooks/idle-compact.ts'

const MIN = 60 * 1000
const T0 = 1_700_000_000_000
const SUMMARY = [{ role: 'user' as const, text: 'summary', toolUses: [] }]

type Host = {
  compacts: number
  sessionId: string
  usage?: Record<string, number>
  onCompact?: () => unknown
  onSessionId?: () => unknown
  transcript: string[]
}

// The host beneath the plugin: answers every event the plugin raises or calls.
function host(on: On): Host {
  const h: Host = { compacts: 0, sessionId: 'session-a', transcript: [] }
  on('turn.start', ($, e) => ({ turnId: e.turnId }))
  on('turn.complete', () => ({ text: '' }))
  on('session.end', ($, e) => ({ sessionId: e.sessionId }))
  on('session.id', async () => {
    await h.onSessionId?.()
    return { value: h.sessionId }
  })
  on('session.compact', async () => {
    h.compacts++
    await h.onCompact?.()
    return h.usage === undefined ? { messages: SUMMARY } : { messages: SUMMARY, usage: h.usage }
  })
  on('ui.log', ($, e) => {
    if (e.to === 'transcript') h.transcript.push(e.text)
    return { value: undefined }
  })
  return h
}

let seq = 0
async function turn($: Engine, extra: Record<string, unknown> = {}) {
  const turnId = `turn-${++seq}`
  await $.turn.start({ text: 'hi', turnId })
  await $.turn.complete({ answer: 'ok', durationMs: 1, isAborted: false, turnId, reason: 'answer', ...extra })
  return turnId
}

describe('idle-compact', () => {
  test('does not compact before 50 minutes', async ($, on) => {
    const clock = mock.clock(on, { now: T0 })
    const h = host(on)
    await turn($)
    await clock.advance(50 * MIN - 1)
    expect(h.compacts).toBe(0)
  })

  test('compacts once at 50 minutes and does not re-arm', async ($, on) => {
    const clock = mock.clock(on, { now: T0 })
    const h = host(on)
    await turn($)
    await clock.advance(50 * MIN)
    expect(h.compacts).toBe(1)
    await clock.advance(6 * 60 * MIN)
    expect(h.compacts).toBe(1)
  })

  test('a new turn cancels the timer and the idle period restarts at its completion', async ($, on) => {
    const clock = mock.clock(on, { now: T0 })
    const h = host(on)
    await turn($)
    await clock.advance(40 * MIN)
    await $.turn.start({ text: 'again', turnId: 'long' })
    await clock.advance(20 * MIN)
    expect(h.compacts).toBe(0)
    await $.turn.complete({ answer: 'ok', durationMs: 1, isAborted: false, turnId: 'long', reason: 'answer' })
    await clock.advance(50 * MIN - 1)
    expect(h.compacts).toBe(0)
    await clock.advance(1)
    expect(h.compacts).toBe(1)
  })

  test('a subagent completion does not arm', async ($, on) => {
    const clock = mock.clock(on, { now: T0 })
    const h = host(on)
    await $.turn.complete({
      answer: 'ok', durationMs: 1, isAborted: false, turnId: 'sub', reason: 'answer', agentId: 'agent-1',
    })
    await clock.advance(2 * 60 * MIN)
    expect(h.compacts).toBe(0)
  })

  test('an aborted or failed turn does not arm', async ($, on) => {
    const clock = mock.clock(on, { now: T0 })
    const h = host(on)
    await $.turn.start({ text: 'hi', turnId: 'a' })
    await $.turn.complete({ answer: '', durationMs: 1, isAborted: true, turnId: 'a', reason: 'aborted' })
    await $.turn.start({ text: 'hi', turnId: 'b' })
    await $.turn.complete({ answer: '', durationMs: 1, isAborted: false, turnId: 'b', reason: 'error' })
    await clock.advance(2 * 60 * MIN)
    expect(h.compacts).toBe(0)
  })

  test('session.end cancels the pending timer', async ($, on) => {
    const clock = mock.clock(on, { now: T0 })
    const h = host(on)
    await turn($)
    await $.session.end({ reason: 'clear', sessionId: 'session-a', resume: { id: 'session-a' } })
    await clock.advance(2 * 60 * MIN)
    expect(h.compacts).toBe(0)
  })

  test('a manual /compact cancels the pending timer', async ($, on) => {
    const clock = mock.clock(on, { now: T0 })
    const h = host(on)
    await turn($)
    await $.session.compact({ trigger: 'manual', messages: SUMMARY })
    expect(h.compacts).toBe(1)
    await clock.advance(2 * 60 * MIN)
    expect(h.compacts).toBe(1)
  })

  test('does not compact when the session changed before the timer fired', async ($, on) => {
    const clock = mock.clock(on, { now: T0 })
    const h = host(on)
    await turn($)
    h.sessionId = 'session-b'
    await clock.advance(50 * MIN)
    expect(h.compacts).toBe(0)
  })

  test('a completion raised by the compaction itself does not re-arm', async ($, on) => {
    const clock = mock.clock(on, { now: T0 })
    const h = host(on)
    h.onCompact = async () => {
      await $.turn.start({ text: '', turnId: 'inner' })
      await $.turn.complete({ answer: '', durationMs: 1, isAborted: false, turnId: 'inner', reason: 'answer' })
    }
    await turn($)
    await clock.advance(50 * MIN)
    await clock.advance(6 * 60 * MIN)
    expect(h.compacts).toBe(1)
  })

  test('a failed compaction is not retried', async ($, on) => {
    const clock = mock.clock(on, { now: T0 })
    const h = host(on)
    h.onCompact = () => {
      throw new Error('DISABLE_COMPACT')
    }
    await turn($)
    await clock.advance(50 * MIN)
    await clock.advance(6 * 60 * MIN)
    expect(h.compacts).toBe(1)
  })

  test('repeated completions keep a single timer', async ($, on) => {
    const clock = mock.clock(on, { now: T0 })
    const h = host(on)
    await turn($)
    await clock.advance(10 * MIN)
    const last = await turn($)
    // A duplicate completion of the same turn does not arm a second timer.
    await $.turn.complete({ answer: 'ok', durationMs: 1, isAborted: false, turnId: last, reason: 'answer' })
    await clock.advance(6 * 60 * MIN)
    expect(h.compacts).toBe(1)
  })

  test('a turn starting while the fire callback runs prevents the compaction', async ($, on) => {
    const clock = mock.clock(on, { now: T0 })
    const h = host(on)
    let release = () => {}
    const gate = new Promise<void>((resolve) => { release = resolve })
    let lookups = 0
    // The first lookup is the arm's, the second the fire callback's: hold only the latter.
    h.onSessionId = async () => {
      if (++lookups === 2) await gate
    }
    await turn($)
    await clock.advance(50 * MIN)
    expect(lookups).toBe(2)
    await $.turn.start({ text: 'back', turnId: 'late' })
    release()
    await clock.settle()
    expect(h.compacts).toBe(0)
  })

  test('shows the compaction time when armed and the cache hit after compacting', async ($, on) => {
    const clock = mock.clock(on, { now: T0 })
    const h = host(on)
    h.usage = { input_tokens: 0, output_tokens: 1, cache_read_input_tokens: 29, cache_creation_input_tokens: 21 }
    await turn($)
    expect(h.transcript).toEqual([`idle-compact: compacts at ${formatClock(T0 + 50 * MIN)} if nothing happens before then`])
    await clock.advance(50 * MIN)
    expect(h.transcript.slice(1)).toEqual([
      'idle-compact: compacted with a 58% cache hit (29 read, 21 written, 0 uncached)',
    ])
  })

  test('shows no cache hit line when the compaction reports no usage', async ($, on) => {
    const clock = mock.clock(on, { now: T0 })
    const h = host(on)
    await turn($)
    await clock.advance(50 * MIN)
    expect(h.compacts).toBe(1)
    expect(h.transcript.length).toBe(1)
  })
})

// A timer that fires late against the wall clock (the machine slept through it).
function lateClock(on: On) {
  const c = { now: T0, fire: () => {}, onNow: () => {} }
  on('clock.now', () => {
    c.onNow()
    return { value: c.now }
  })
  on('clock.after', () => new Promise((resolve) => { c.fire = () => resolve({ value: undefined }) }))
  return c
}

async function fireAt($: Engine, c: ReturnType<typeof lateClock>, elapsed: number) {
  c.now = T0 + elapsed
  const seen = new Promise<void>((resolve) => { c.onNow = resolve })
  c.fire()
  await seen
  // A few engine round trips through an ignored event let the callback finish.
  for (let i = 0; i < 5; i++) {
    await $.turn.complete({ answer: '', durationMs: 1, isAborted: false, turnId: 's', reason: 'answer', agentId: 's' })
  }
}

describe('idle-compact against the wall clock', () => {
  for (const [minutes, expected] of [[50, 1], [57, 1], [58, 0], [90, 0]] as const) {
    test(`a callback running at ${minutes} minutes compacts ${expected} time(s)`, async ($, on) => {
      const c = lateClock(on)
      const h = host(on)
      await turn($)
      await fireAt($, c, minutes * MIN)
      expect(h.compacts).toBe(expected)
    })
  }
})
