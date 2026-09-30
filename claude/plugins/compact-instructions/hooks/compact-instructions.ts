import type { Register } from 'claude-code'

// The engine's own compaction prompt keeps the recent work but lets earlier user
// decisions, the sources they came from and the content of pasted material fade,
// most of all when a summary is summarized again.
export const INSTRUCTIONS = `In addition to the usual summary, keep the following. Nothing listed here may be shortened because it is older; when the conversation begins with the summary of an earlier compaction, carry every item of that summary forward unless the conversation since then replaced it.

1. Decisions and constraints: every decision, constraint and scope limit the user stated or approved, quoting the user's own words, with the reason when one was given. Include options that were rejected and why.
2. Corrections: every correction the user made to the assistant, and what the assistant then accepted as correct.
3. Supplied material: the content of every email, error message, screenshot, document excerpt or other material the user pasted or attached, not only the fact that it was supplied. Write the text a screenshot shows when it matters to the work.
4. Sources to re-read: every document, file, artifact, pull request and page the work depends on, with its location (path, URL or ID) and the decisions or facts taken from it. Say that it must be re-read before proposing a change to anything it covers.
5. Where each fact came from: separate what the user said in this conversation from what the assistant inferred from files, commits or other sessions.

End the summary with this note to the assistant that continues: before saying that something was not shared, not decided or is unknown, search the full transcript and the sources to re-read; if it is still not found, say where you searched and that it was not found there, and do not say that it does not exist.`

export const register: Register = (on) => {
  on('session.compact', ($, e, next) => {
    const instructions = e.instructions === undefined || e.instructions.trim() === ''
      ? INSTRUCTIONS
      : `${e.instructions}\n\n${INSTRUCTIONS}`
    return next({ ...e, instructions })
  })
}
