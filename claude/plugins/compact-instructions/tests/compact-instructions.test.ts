import { describe, expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'
import { INSTRUCTIONS } from '../hooks/compact-instructions.ts'

const SUMMARY = [{ role: 'user' as const, text: 'summary', toolUses: [] }]

// The engine beneath the plugin: records what the summarizer would be told.
function host(on: On) {
  const seen: (string | undefined)[] = []
  on('session.compact', ($, e) => {
    seen.push(e.instructions)
    return { messages: SUMMARY }
  })
  return seen
}

describe('compact-instructions', () => {
  for (const trigger of ['manual', 'auto', 'plugin', 'precompute'] as const) {
    test(`a ${trigger} compaction without instructions gets the plugin's instructions`, async ($, on) => {
      const seen = host(on)
      await $.session.compact({ trigger, messages: SUMMARY })
      expect(seen).toEqual([INSTRUCTIONS])
    })
  }

  test('instructions typed after /compact come first and are kept', async ($, on) => {
    const seen = host(on)
    await $.session.compact({ trigger: 'manual', messages: SUMMARY, instructions: 'focus on the API changes' })
    expect(seen).toEqual([`focus on the API changes\n\n${INSTRUCTIONS}`])
  })

  test('blank typed instructions are replaced by the plugin instructions alone', async ($, on) => {
    const seen = host(on)
    await $.session.compact({ trigger: 'manual', messages: SUMMARY, instructions: '  ' })
    expect(seen).toEqual([INSTRUCTIONS])
  })

  test("a subagent's compaction gets the instructions too", async ($, on) => {
    const seen = host(on)
    await $.session.compact({ trigger: 'auto', messages: SUMMARY, agentId: 'agent-1' })
    expect(seen).toEqual([INSTRUCTIONS])
  })

  test('the compaction result reaches the caller unchanged', async ($, on) => {
    host(on)
    const result = await $.session.compact({ trigger: 'manual', messages: SUMMARY })
    expect(result.messages).toEqual(SUMMARY)
  })
})
