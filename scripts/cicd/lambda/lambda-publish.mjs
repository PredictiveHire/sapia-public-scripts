#!/usr/bin/env zx

import { existsSync } from "fs"

/**
 *
 * @param compiler tsc or ncc
 */
const compileWithYarn = async (compiler) => {
  const useTSC = compiler === "tsc"
  const useNCC = compiler === "ncc"
  // clean deps
  await $`rm -rf node_modules || :`

  // need to compile ts
  await $`yarn install`

  // need to exclude node_modules in tsconfig.json
  useTSC && (await $`yarn build`)
  useNCC && (await $`yarn build-ncc`)

  // clean deps
  useTSC && (await $`rm -rf node_modules || :`)

  // only install package in deps
  useTSC && (await $`yarn install --prod`)

  // clean package
  await $`rm deployment_package.zip || :`

  // zip package
  // zip -q -r deployment_package.zip dist -x 'dist/*.mem'
  useNCC && (await $`zip -q -r deployment_package.zip dist -x 'dist/*.mem'`)
  useTSC && (await $`zip -q -r deployment_package.zip node_modules dist -x 'dist/*.map'`)
}

const compileWithNpm = async (compiler) => {
  const useTSC = compiler === "tsc"
  const useNCC = compiler === "ncc"
  // clean deps
  await $`rm -rf node_modules || :`

  // need to compile ts
  await $`npm ci --legacy-peer-deps`

  // need to exclude node_modules in tsconfig.json
  useTSC && (await $`npm run build`)
  useNCC && (await $`npm run build-ncc`)

  // clean deps
  useTSC && (await $`rm -rf node_modules || :`)

  // only install package in deps
  useTSC && (await $`npm ci --legacy-peer-deps --omit=dev`)

  // clean package
  await $`rm deployment_package.zip || :`

  // zip package
  // zip -q -r deployment_package.zip dist -x 'dist/*.mem'
  useNCC && (await $`zip -q -r deployment_package.zip dist -x 'dist/*.mem'`)
  useTSC && (await $`zip -q -r deployment_package.zip node_modules dist -x 'dist/*.map'`)
}

const compileWithPnpm = async (compiler) => {
  const useTSC = compiler === "tsc"
  const useNCC = compiler === "ncc"
  // clean deps
  await $`rm -rf node_modules || :`

  // need to compile ts
  await $`pnpm install --frozen-lockfile`

  // need to exclude node_modules in tsconfig.json
  useTSC && (await $`npm run build`)
  useNCC && (await $`npm run build-ncc`)

  // clean deps
  useTSC && (await $`rm -rf node_modules || :`)

  // only install package in deps
  useTSC && (await $`pnpm install --frozen-lockfile --prod`)

  // clean package
  await $`rm deployment_package.zip || :`

  // zip package
  // zip -q -r deployment_package.zip dist -x 'dist/*.mem'
  useNCC && (await $`zip -q -r deployment_package.zip dist -x 'dist/*.mem'`)
  useTSC && (await $`zip -q -r deployment_package.zip node_modules dist -x 'dist/*.map'`)
}

/**
 *
 * @param s3BucketName the s3 bucket name
 * @param s3BucketKey  the s3 bucket key
 * @param compiler    tsc or ncc
 */
const publish = async (s3BucketName, s3BucketKey, packageTag, compiler, pm) => {
  const s3BucketKeyVersion = `${s3BucketKey}/${packageTag}`
  // ! deprecated tag: latest, it won't used in deploy stage anymore
  const s3BucketKeyLatest = `${s3BucketKey}/latest`

  if (pm === "yarn") {
    await compileWithYarn(compiler)
  }

  if (pm === "npm") {
    await compileWithNpm(compiler)
  }

  if (pm === "pnpm") {
    await compileWithPnpm(compiler)
  }

  // upload to lambda registry s3 at qa sydney region(fixed)
  await Promise.all([
    $`aws s3 cp deployment_package.zip s3://${s3BucketName}/${s3BucketKeyVersion} --content-type application/zip --profile=infra-qa --region ap-southeast-2`,
    // ! deprecated tag: latest, it won't used in deploy stage anymore
    $`aws s3 cp deployment_package.zip s3://${s3BucketName}/${s3BucketKeyLatest} --content-type application/zip --profile=infra-qa --region ap-southeast-2`
  ])
}

const s3BucketName = argv.s3BucketName
const s3BucketKey = argv.s3BucketKey
const packageTag = argv.packageTag

let compiler = "tsc"
try {
  compiler = String(await $`buildkite-agent meta-data get "compiler"`)
} catch (error) {
  console.error(error)
}

let pm = ""
if (existsSync("yarn.lock")) {
  pm = "yarn"
}
if (existsSync("package-lock.json")) {
  pm = "npm"
}
if (existsSync("pnpm-lock.yaml")) {
  pm = "pnpm"
}

if (pm === "") {
  throw new Error("no package manager found")
}

await publish(s3BucketName, s3BucketKey, packageTag, compiler, pm)
