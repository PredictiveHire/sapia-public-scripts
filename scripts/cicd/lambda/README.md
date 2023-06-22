

## Lambda

### Lambda Publish
```sh
npx zx lambda-publish.mjs --s3BucketName ph-lambda-registry --s3BucketKey phapi-core-idp-proxy --packageTag v1.0.0

npx zx lambda-publish.mjs --s3BucketName ph-lambda-registry --s3BucketKey phapi-core-idp-proxy --packageTag v1.0.$BUILDKITE_BUILD_NUMBER
```


### Lambda Deployment
```sh
npx zx lambda-deploy.mjs --s3BucketName ph-lambda-registry --s3BucketKey phapi-core-idp-proxy --lambdaNameAbbr idp --stage qa --versionTag v1.0.0

npx zx lambda-deploy.mjs --s3BucketName ph-lambda-registry --s3BucketKey phapi-core-idp-proxy --lambdaNameAbbr idp --stage qa --versionTag v1.0.$BUILDKITE_BUILD_NUMBER
```