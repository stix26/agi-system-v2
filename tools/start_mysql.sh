#!/bin/bash
# Initialize and launch a local MySQL server for testing
set -e
DATA_DIR=${MYSQL_DATA_DIR:-/tmp/mysql-data}
if [ ! -d "$DATA_DIR/mysql" ]; then
    mysqld --initialize-insecure --datadir="$DATA_DIR" --basedir=/usr
fi
mysqld --datadir="$DATA_DIR" --user=root --bind-address=127.0.0.1 --skip-networking=0 --socket=/tmp/mysql.sock &
MYSQL_PID=$!
echo $MYSQL_PID > "$DATA_DIR/mysqld.pid"
# Wait briefly for server startup
sleep 5

