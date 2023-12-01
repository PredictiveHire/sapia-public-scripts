

## Deploy ECR to ECS
```sh
- curl -o ./.buildkite/ecs-deploy https://raw.githubusercontent.com/PredictiveHire/sapia-public-scripts/main/scripts/cicd/ecs/deploy.sh
- curl -o ./.buildkite/deploy https://raw.githubusercontent.com/PredictiveHire/sapia-public-scripts/main/scripts/cicd/ecs/trigger.deploy.sh
- chmod +x ./.buildkite/deploy && ./.buildkite/deploy \
-n idp-nest \ # ecs name prefix, could be found in ecs service
-t qa \ # stage
-u 174623324848.dkr.ecr.ap-southeast-2.amazonaws.com/phapi/idp-nest # ecr uri
```