import * as fs from 'node:fs'
import * as path from 'node:path'
import * as os from 'node:os'

type TestResult = {
  file: string
  passed: boolean
  output: string
  timestamp: number
}

type SessionState = {
  sessionId: string
  editedFiles: string[]
  testResults: TestResult[]
  lastTestRun: number | null
}

const getStateFilePath = (sessionId: string): string =>
  path.join(os.tmpdir(), `tdd-agent-${sessionId}.json`)

const createEmptyState = (sessionId: string): SessionState => ({
  sessionId,
  editedFiles: [],
  testResults: [],
  lastTestRun: null,
})

export const loadState = (sessionId: string): SessionState => {
  const filePath = getStateFilePath(sessionId)

  if (!fs.existsSync(filePath)) {
    return createEmptyState(sessionId)
  }

  try {
    const content = fs.readFileSync(filePath, 'utf-8')
    return JSON.parse(content) as SessionState
  } catch {
    return createEmptyState(sessionId)
  }
}

export const saveState = (state: SessionState): void => {
  const filePath = getStateFilePath(state.sessionId)
  fs.writeFileSync(filePath, JSON.stringify(state, null, 2))
}

export const recordEditedFile = (sessionId: string, filePath: string): SessionState => {
  const state = loadState(sessionId)
  const normalizedPath = path.resolve(filePath)

  if (!state.editedFiles.includes(normalizedPath)) {
    state.editedFiles.push(normalizedPath)
  }

  saveState(state)
  return state
}

export const recordTestResult = (
  sessionId: string,
  file: string,
  passed: boolean,
  output: string
): SessionState => {
  const state = loadState(sessionId)

  const existingIndex = state.testResults.findIndex(r => r.file === file)
  const result: TestResult = {
    file,
    passed,
    output,
    timestamp: Date.now(),
  }

  if (existingIndex >= 0) {
    state.testResults[existingIndex] = result
  } else {
    state.testResults.push(result)
  }

  state.lastTestRun = Date.now()
  saveState(state)
  return state
}

export const getFailingTests = (sessionId: string): TestResult[] => {
  const state = loadState(sessionId)
  return state.testResults.filter(r => !r.passed)
}

export const getAllEditedFiles = (sessionId: string): string[] => {
  const state = loadState(sessionId)
  return state.editedFiles
}

export const clearState = (sessionId: string): void => {
  const filePath = getStateFilePath(sessionId)
  if (fs.existsSync(filePath)) {
    fs.unlinkSync(filePath)
  }
}
