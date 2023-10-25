For any user with M1/M2 chip set, docker may not be able to identify your platform, so you have to run the following code to ensure superset codebase will be able to run

```
export DOCKER_DEFAULT_PLATFORM=linux/x86_64
```