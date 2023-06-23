#!/usr/bin/env zx

/**
 *
 * @param {*} region aws regions
 * @param {*} awsRegions region long name - short name mappings
 * @param {*} stage qa,sandbox, product
 * @param {*} lambdaNameAbbr e.g. idp, org
 * @param {*} live whether provisioned with live alias
 */
const deployByRegion = async (region, awsRegions, stage, lambdaNameAbbr, live) => {
  console.log(`========================== deploy to ${region} started ==========================`)
  const regionShort = awsRegions[region]
  const funcName = `${stage}-${regionShort}-${lambdaNameAbbr}`

  console.log(`update lambda function code`)
  await $`aws lambda update-function-code --function-name ${funcName} --zip-file fileb://code.zip --region=${region} --profile=infra-${stage}`

  // Poller: solve aws cli async response issue
  let functionUpdateCompleted = false
  while (!functionUpdateCompleted) {
    const res =
      await $`aws lambda get-function --function-name ${funcName} --query 'Configuration.[State, LastUpdateStatus]' --region=${region} --profile=infra-${stage}`
    const state = JSON.parse(res)[0]
    const lastUpdate = JSON.parse(res)[1]
    console.log(state)
    console.log(lastUpdate)
    functionUpdateCompleted = state === "Active" && lastUpdate === "Successful" ? true : false
    await sleep(2000)
  }

  if (live === "true") {
    console.log(`publish a new version`)
    const publishRes =
      await $`aws lambda publish-version --function-name ${funcName} --region=${region} --profile=infra-${stage}`
    const publishObj = JSON.parse(publishRes)
    const latestVersion = publishObj.Version

    // assign the live alias to the latest version
    console.log(`update live alias`)
    await $`aws lambda update-alias --function-name ${funcName}  --function-version ${latestVersion} --name live --region=${region} --profile=infra-${stage}`
    console.log(`========================== deploy to ${region} successfully ==========================`)
  }
}

/**
 *
 * @param s3BucketName the s3 bucket name
 * @param s3BucketKey  the s3 bucket key
 * @param lambdaNameAbbr  the lambda function service name abbreviation, e.g. idp
 */
const deploy = async (s3BucketName, s3BucketKey, lambdaNameAbbr, stage, versionTag = "latest", live = "false") => {
  let awsRegions = {}

  const resp = await fetch(
    "https://gist.githubusercontent.com/predictivehirebuild/8422a1911476effb0c745f06aeb90494/raw/awsRegions.json"
  )

  if (resp.ok) {
    awsRegions = await resp.json()
  } else {
    throw new Error("cannot fetch aws region mappings")
  }

  const s3BucketKeyVersion = `${s3BucketKey}/${versionTag}`

  let buildKiteRegions = []
  try {
    buildKiteRegions = String(await $`buildkite-agent meta-data get "deploy-regions-${stage}"`).split("\n")
  } catch (error) {
    console.log(error)
  }

  // qa/sandbox/product code stored in qa s3
  await $`aws s3api get-object --bucket ${s3BucketName} --key ${s3BucketKeyVersion} code.zip --region ap-southeast-2 --profile infra-qa`

  for (const region of buildKiteRegions) {
    await deployByRegion(region, awsRegions, stage, lambdaNameAbbr, live)
  }
}

const s3BucketName = argv.s3BucketName
const s3BucketKey = argv.s3BucketKey
const lambdaAbbr = argv.lambdaNameAbbr
const stage = argv.stage
const versionTag = argv.versionTag ? argv.versionTag : "latest"
const live = argv.live ? argv.live : "false"

if (!s3BucketName) {
  console.error("s3BucketName is required. e.g. --s3BucketName ph-lambda-registry")
  process.exit(1)
}

if (!s3BucketKey) {
  console.error("s3BucketKey is required. e.g. --s3BucketKey phapi-core-idp-proxy")
  process.exit(1)
}

if (!lambdaAbbr) {
  console.error("lambdaNameAbbr is required. e.g. --lambdaNameAbbr idp")
  process.exit(1)
}

if (!stage) {
  console.error("stage is required. e.g. --stage qa")
  process.exit(1)
}

await deploy(s3BucketName, s3BucketKey, lambdaAbbr, stage, versionTag, live)
