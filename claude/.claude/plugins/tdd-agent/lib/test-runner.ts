import * as fs from 'node:fs'
import * as path from 'node:path'
import { execSync, type ExecSyncOptions } from 'node:child_process'

type TestRunnerName = 'vitest' | 'jest' | 'mocha' | 'bun' | 'unknown'

type TestRunner = {
  name: TestRunnerName
  packageManager: 'pnpm' | 'yarn' | 'npm' | 'bun'
  runCommand: string
  relatedCommand: (files: string[]) => string
}

type TestRunResult = {
  passed: boolean
  output: string
  exitCode: number
}

const detectPackageManager = (projectDir: string): TestRunner['packageManager'] => {
  if (fs.existsSync(path.join(projectDir, 'pnpm-lock.yaml'))) return 'pnpm'
  if (fs.existsSync(path.join(projectDir, 'yarn.lock'))) return 'yarn'
  if (fs.existsSync(path.join(projectDir, 'bun.lockb'))) return 'bun'
  return 'npm'
}

const hasDependency = (packageJson: Record<string, unknown>, dep: string): boolean => {
  const deps = packageJson.dependencies as Record<string, string> | undefined
  const devDeps = packageJson.devDependencies as Record<string, string> | undefined
  return Boolean(deps?.[dep] || devDeps?.[dep])
}

export const detectTestRunner = (projectDir: string): TestRunner => {
  const packageJsonPath = path.join(projectDir, 'package.json')
  const packageManager = detectPackageManager(projectDir)

  if (!fs.existsSync(packageJsonPath)) {
    return {
      name: 'unknown',
      packageManager,
      runCommand: `${packageManager} test`,
      relatedCommand: () => `${packageManager} test`,
    }
  }

  const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf-8')) as Record<string, unknown>

  if (hasDependency(packageJson, 'vitest')) {
    return {
      name: 'vitest',
      packageManager,
      runCommand: `${packageManager} test`,
      relatedCommand: (files) => `${packageManager} test --related ${files.join(' ')}`,
    }
  }

  if (hasDependency(packageJson, 'jest')) {
    return {
      name: 'jest',
      packageManager,
      runCommand: `${packageManager} test`,
      relatedCommand: (files) => `${packageManager} test --findRelatedTests ${files.join(' ')}`,
    }
  }

  if (hasDependency(packageJson, 'mocha')) {
    return {
      name: 'mocha',
      packageManager,
      runCommand: `${packageManager} test`,
      relatedCommand: () => `${packageManager} test`,
    }
  }

  if (packageManager === 'bun') {
    return {
      name: 'bun',
      packageManager,
      runCommand: 'bun test',
      relatedCommand: (files) => `bun test ${files.join(' ')}`,
    }
  }

  return {
    name: 'unknown',
    packageManager,
    runCommand: `${packageManager} test`,
    relatedCommand: () => `${packageManager} test`,
  }
}

export const findProjectRoot = (filePath: string): string | null => {
  let currentDir = path.dirname(filePath)

  while (currentDir !== path.dirname(currentDir)) {
    if (fs.existsSync(path.join(currentDir, 'package.json'))) {
      return currentDir
    }
    currentDir = path.dirname(currentDir)
  }

  return null
}

export const runTests = (
  projectDir: string,
  files: string[],
  timeout = 120000
): TestRunResult => {
  const runner = detectTestRunner(projectDir)
  const command = files.length > 0
    ? runner.relatedCommand(files)
    : runner.runCommand

  const execOptions: ExecSyncOptions = {
    cwd: projectDir,
    timeout,
    encoding: 'utf-8',
    stdio: ['pipe', 'pipe', 'pipe'],
    env: {
      ...process.env,
      CI: 'true',
      FORCE_COLOR: '0',
    },
  }

  try {
    const output = execSync(command, execOptions) as string
    return {
      passed: true,
      output: output.slice(-5000),
      exitCode: 0,
    }
  } catch (error) {
    const execError = error as { status?: number; stdout?: string; stderr?: string }
    const stdout = execError.stdout ?? ''
    const stderr = execError.stderr ?? ''
    const combinedOutput = `${stdout}\n${stderr}`.slice(-5000)

    return {
      passed: false,
      output: combinedOutput,
      exitCode: execError.status ?? 1,
    }
  }
}

export const isSourceFile = (filePath: string): boolean => {
  const ext = path.extname(filePath).toLowerCase()
  const sourceExtensions = ['.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs']

  if (!sourceExtensions.includes(ext)) return false

  const basename = path.basename(filePath)
  const skipPatterns = [
    /\.test\.[jt]sx?$/,
    /\.spec\.[jt]sx?$/,
    /\.config\.[jt]s$/,
    /\.d\.ts$/,
  ]

  return !skipPatterns.some(pattern => pattern.test(basename))
}

export const isTestFile = (filePath: string): boolean => {
  const basename = path.basename(filePath)
  const testPatterns = [
    /\.test\.[jt]sx?$/,
    /\.spec\.[jt]sx?$/,
    /__tests__\//,
  ]

  return testPatterns.some(pattern => pattern.test(basename) || pattern.test(filePath))
}
