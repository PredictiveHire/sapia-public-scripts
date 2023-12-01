


## ECR Scripts

### Publish ECR without Stage
```sh
chmod +x ./image.publish.sh && ./image.publish.sh \
 -n phapi-core-idp-nest \ # the container name, just a name, won't affect real process
 -i "${BUILDKITE_BUILD_NUMBER}" \ # buildkite number passed from env vars
 -u 174623324848.dkr.ecr.ap-southeast-2.amazonaws.com/phapi/idp-nest # ecr uri
```

### Publish ECR with Stage
```sh
chmod +x image.stage.publish.sh && image.stage.publish.sh \
-s qa \ # stage: qa,sandbox,product
-n phapi/idp-nest \ # ecr url suffix, could be found in ecr service
-i "${BUILDKITE_BUILD_NUMBER}" # buildkite number passed from env vars
```