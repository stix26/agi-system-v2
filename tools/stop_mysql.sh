#!/bin/bash
# Stop MySQL server started with start_mysql.sh
set -e
DATA_DIR=${MYSQL_DATA_DIR:-/tmp/mysql-data}
if [ -f "$DATA_DIR/mysqld.pid" ]; then
    kill $(cat "$DATA_DIR/mysqld.pid")
    rm -f "$DATA_DIR/mysqld.pid"
fi

