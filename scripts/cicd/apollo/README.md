

## Publish GraphQL Schema to Apollo Registry
```sh
chmod +x ./schema.publish.sh && ./schema.publish.sh \
    -t qa \ # stage
    -s phapi-core-idp-nest \ # service name showed in apollo studio
    -p ph-phapi-idp-nest-internal # service url prefix, can be found in route53
```