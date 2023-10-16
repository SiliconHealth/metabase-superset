# Metabase and Superset
<!--Introduction -->
This repository is the repository for a guideline in using `metabase` and `superset` to generate the dashboard. This guideline is divided into five main points to be considered upon using either one of `metabase` or `superset`.

<!-- Table of contents -->
- [Chart generation](#chart-generation)
- [Dashboard generation](#dashboard-generation)

# Installation
Both `metabase` and `superset` can be installed as a running docker container via simple CLI commands.  
- Metabase
```
docker pull metabase/metabase:latest
docker run -d -p 3000:3000 --name metabase metabase/metabase
```
- Superset
```
git clone https://github.com/apache/superset.git
cd superset
docker compose up
```

**Platform must be** *manually*  **specified in M1/M2 Mac chipsets since, in most cases, docker would not be able to identify the platform itself** The command to do so is `export DOCKER_DEFAULT_PLATFORM=linux/x86_64`

# Authentication/Access control
Both *metabase* and *superset* are equipped with username/password authentication with its own user database. The admin user can be generated using CLI in container instance.  

For example, in supserset the admin user is created by following set of commands.

```
docker exec -it SUIPERSET_CONTATINERNAME superset fab create-admin \
              --username USERNAME \
              --firstname ADMIN_FIRSTNAME \
              --lastname ADMIN_LASTNAME \
              --email WHATEVER@superset.com \
              --password ADMIN_PASSOWRD
```
```
docker exec -it superset superset db upgrade
docker exec -it superset superset init
```
The first command is to generate the transaction to database to create an admin user. The second command set is for database migration (commit the transaction).

After create the user admin, admin user can create roles and users. Permission is set in the role descriptions. User permission is set upon creation by assigned roles and can be edited later.  

**Row-level security** can be implemented as well via admin account.

# Data curation
To curate data from the known database, we need to establish connection to the sources inside the each of the programs. The process of describing the source is rather simple in both application using common things such as *Hostname, Port, Databasename, Authentication schemes and credentials.* which are all easy to find out.
## Database access

Most known database is compatible for `metabase`[^1]and `superset`[^2]

Lastly, I will give out and example to establish the connection to Postgresql database inside the same docker *bridge-network*.

<!-- Add picture --> 
## Query
Both applications provide simple data curation from each database table after successfully establishing database connection. In case that needs transformation operation such as join, type casting, calculation, user can use **SQL** to directly read off the database.  
**Note that** *unsafe operations such as insert, update is prohibited by default and can be enabled via admin console*

<!-- Add picture example for superset --> 

# Chart generation
In this section, we go through the details in which `superset` and `metabase` chart generation process is implemented. 

<!-- Add picture example for superset --> 

# Dashboard generation
<!-- Superset example --> 

# Footneotes
[^1]: [Superset supported database](https://superset.apache.org/docs/databases/installing-database-drivers)  
[^2]: [Managing Metabase database](https://www.metabase.com/docs/latest/databases/connecting)
