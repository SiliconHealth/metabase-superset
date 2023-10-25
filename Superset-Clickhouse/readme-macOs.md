For any user with M1/M2 chip set, docker may not be able to identify your platform, so you have to run the following code to ensure superset codebase will be able to run

```
export DOCKER_DEFAULT_PLATFORM=linux/arm64/v8 
```

The `install.sh` is, by default, modified based on `linux/arm64` platform for M1/M2 deployment.  
`.env` file is for production environment configuration outside clickhouse.  
Any desire to configure `clickhouse` should consult [clickhouse-config-documentation](https://clickhouse.com/docs/en/operations/configuration-files).  
