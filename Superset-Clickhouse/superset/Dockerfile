FROM apache/superset

# Switching to root to install the required packages
USER root

# Metadata database drivers
RUN pip install psycopg2-binary
RUN pip install mysqlclient

RUN pip install clickhouse-connect
# Switching back to using the `superset` user
USER superset