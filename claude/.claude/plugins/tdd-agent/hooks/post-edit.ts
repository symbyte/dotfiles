#!/usr/bin/env npx tsx

import { recordEditedFile, recordTestResult } from '../lib/session-state.js'
import { detectTestRunner, findProjectRoot, runTests, isSourceFile, isTestFile } from '../lib/test-runner.js'

type ToolInput = {
  file_path: string
  [key: string]: unknown
}

type HookInput = {
  hook_event_name: 'PostToolUse'
  tool_name: 'Edit' | 'Write'
  tool_input: ToolInput
  tool_result: { success?: boolean }
  session_id: string
}

type HookOutput = {
  systemMessage?: string
}

const readStdin = async (): Promise<string> => {
  const chunks: Buffer[] = []
  for await (const chunk of process.stdin) {
    chunks.push(chunk)
  }
  return Buffer.concat(chunks).toString('utf-8')
}

const formatTestOutput = (
  passed: boolean,
  output: string,
  filePath: string,
  runnerName: string
): string => {
  const status = passed ? '✅ TESTS PASSED' : '❌ TESTS FAILED'
  const truncatedOutput = output.length > 2000
    ? output.slice(-2000) + '\n...(truncated)'
    : output

  return `
[TDD Agent] ${status}
Runner: ${runnerName}
Related to: ${filePath}

${truncatedOutput}
`.trim()
}

const main = async (): Promise<void> => {
  const input = await readStdin()

  let hookInput: HookInput
  try {
    hookInput = JSON.parse(input) as HookInput
  } catch {
    console.error(JSON.stringify({ error: 'Failed to parse hook input' }))
    process.exit(0)
  }

  const { tool_input, session_id } = hookInput
  const filePath = tool_input.file_path

  if (!filePath) {
    console.log(JSON.stringify({}))
    return
  }

  const shouldRunTests = isSourceFile(filePath) || isTestFile(filePath)
  if (!shouldRunTests) {
    console.log(JSON.stringify({}))
    return
  }

  recordEditedFile(session_id, filePath)

  const projectRoot = findProjectRoot(filePath)
  if (!projectRoot) {
    console.log(JSON.stringify({
      systemMessage: `[TDD Agent] No package.json found for ${filePath}, skipping tests`,
    } satisfies HookOutput))
    return
  }

  const runner = detectTestRunner(projectRoot)

  if (runner.name === 'unknown') {
    console.log(JSON.stringify({
      systemMessage: `[TDD Agent] No recognized test runner found in ${projectRoot}`,
    } satisfies HookOutput))
    return
  }

  const testResult = runTests(projectRoot, [filePath])

  recordTestResult(session_id, filePath, testResult.passed, testResult.output)

  const output: HookOutput = {
    systemMessage: formatTestOutput(
      testResult.passed,
      testResult.output,
      filePath,
      runner.name
    ),
  }

  console.log(JSON.stringify(output))
}

main().catch((error) => {
  console.error(JSON.stringify({
    error: `Hook failed: ${error instanceof Error ? error.message : String(error)}`,
  }))
  process.exit(0)
})
