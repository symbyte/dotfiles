#!/usr/bin/env npx tsx

import { getAllEditedFiles, getFailingTests, loadState } from '../lib/session-state.js'
import { findProjectRoot, runTests, detectTestRunner, isSourceFile, isTestFile } from '../lib/test-runner.js'

type StopHookInput = {
  hook_event_name: 'Stop'
  session_id: string
  stop_hook_active: boolean
}

type StopHookOutput = {
  decision: 'allow' | 'block'
  reason?: string
}

const readStdin = async (): Promise<string> => {
  const chunks: Buffer[] = []
  for await (const chunk of process.stdin) {
    chunks.push(chunk)
  }
  return Buffer.concat(chunks).toString('utf-8')
}

const groupFilesByProject = (files: string[]): Map<string, string[]> => {
  const projectFiles = new Map<string, string[]>()

  for (const file of files) {
    const projectRoot = findProjectRoot(file)
    if (!projectRoot) continue

    const existing = projectFiles.get(projectRoot) ?? []
    existing.push(file)
    projectFiles.set(projectRoot, existing)
  }

  return projectFiles
}

const main = async (): Promise<void> => {
  const input = await readStdin()

  let hookInput: StopHookInput
  try {
    hookInput = JSON.parse(input) as StopHookInput
  } catch {
    console.log(JSON.stringify({ decision: 'allow' } satisfies StopHookOutput))
    return
  }

  const { session_id } = hookInput

  const state = loadState(session_id)
  const editedFiles = getAllEditedFiles(session_id)

  const sourceOrTestFiles = editedFiles.filter(f => isSourceFile(f) || isTestFile(f))

  if (sourceOrTestFiles.length === 0) {
    console.log(JSON.stringify({ decision: 'allow' } satisfies StopHookOutput))
    return
  }

  const failingTests = getFailingTests(session_id)
  if (failingTests.length > 0) {
    const failedFiles = failingTests.map(t => t.file).join(', ')
    console.log(JSON.stringify({
      decision: 'block',
      reason: `[TDD Agent] Cannot complete: tests are failing for: ${failedFiles}. Fix the failing tests before completing.`,
    } satisfies StopHookOutput))
    return
  }

  const projectFiles = groupFilesByProject(sourceOrTestFiles)

  const failures: string[] = []

  for (const [projectRoot, files] of projectFiles) {
    const runner = detectTestRunner(projectRoot)

    if (runner.name === 'unknown') {
      continue
    }

    const result = runTests(projectRoot, files)

    if (!result.passed) {
      failures.push(`Tests failed in ${projectRoot}:\n${result.output.slice(-500)}`)
    }
  }

  if (failures.length > 0) {
    console.log(JSON.stringify({
      decision: 'block',
      reason: `[TDD Agent] Cannot complete: final test verification failed.\n\n${failures.join('\n\n')}`,
    } satisfies StopHookOutput))
    return
  }

  console.log(JSON.stringify({
    decision: 'allow',
    reason: '[TDD Agent] All tests passing. Completion allowed.',
  } satisfies StopHookOutput))
}

main().catch((error) => {
  console.log(JSON.stringify({
    decision: 'allow',
    reason: `[TDD Agent] Hook error, allowing stop: ${error instanceof Error ? error.message : String(error)}`,
  } satisfies StopHookOutput))
})
