#!/usr/bin/env zx

/**
 *
 * @param {*} region aws regions
 * @param {*} awsRegions region long name - short name mappings
 * @param {*} stage dev, qa,sandbox, product
 * @param {*} lambdaNameAbbr e.g. idp, org
 * @param {*} imageURI the uri of ecr image
 */
const deployByRegion = async (region, awsRegions, stage, lambdaNameAbbr, imageURI) => {
    console.log(`========================== deploy to ${region} started ==========================`)
    const regionShort = awsRegions[region]
    const funcName = `${stage}-${regionShort}-${lambdaNameAbbr}`

    // regional image uri
    // discussion: https://sapiaai.slack.com/archives/C06UF7PNK39/p1714545862723799
    const updatedImageURI = `${imageURI.replace("ap-southeast-2", region)}:${stage}`
  
    console.log(`update lambda function code`)
    await $`aws lambda update-function-code --function-name ${funcName} --image-uri ${updatedImageURI} --region=${region} --profile=infra-${stage} --no-cli-pager`
  
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
    console.log(`========================== deploy to ${region} successfully ==========================`)
  }
  
/**
 * @param imageURI the uri of ecr image
 * @param lambdaNameAbbr  the lambda function service name abbreviation, e.g. idp
 * @param stage dev, qa, sandbox, product
 */
const deploy = async (imageURI, lambdaNameAbbr, stage) => {
    // get region and region short mappings
    let awsRegions = {}
    const resp = await fetch(
        "https://gist.githubusercontent.com/predictivehirebuild/8422a1911476effb0c745f06aeb90494/raw/awsRegions.json"
    )
    if (resp.ok) {
        awsRegions = await resp.json()
    } else {
        throw new Error("cannot fetch aws region mappings")
    }

    // get region selection from buildkite
    let buildKiteRegions = []
    try {
        buildKiteRegions = String(await $`buildkite-agent meta-data get "deploy-regions-${stage}"`).split("\n")
    } catch (error) {
        console.log(error)
    }

    for (const region of buildKiteRegions) {
        await deployByRegion(region, awsRegions, stage, lambdaNameAbbr, imageURI)
    }
}

const imageURI = argv.imageURI
const lambdaAbbr = argv.lambdaNameAbbr
const stage = argv.stage

if (!imageURI) {
    console.error("imageURI is required. e.g. --imageURI xxx.dkr.ecr.ap-southeast-2.amazonaws.com/my-repo:latest")
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

await deploy(imageURI, lambdaAbbr, stage)