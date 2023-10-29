# Apple Silicon M1/M2 Chip problem
For any user with M1/M2 chip set, docker may not be able to identify your platform, so you have to specify the platform for `superset` docker image in docker compose file. The procedures are implemented in `install.sh` so you can just implement it.

# Inside `install.sh`
The installation script `install.sh` do the following:  
    1. Detect OS and then specify image if detect M1/M2 apple silicon
    2. Create `network`s and `volume`s for composing superset-clickhouse
    3. Ask for admin user creation via provided credentials

