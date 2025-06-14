import os
import pymysql


def main():
    host = os.environ.get('MYSQL_HOST', '127.0.0.1')
    user = os.environ.get('MYSQL_USER', 'root')
    password = os.environ.get('MYSQL_PASSWORD', '')
    conn = pymysql.connect(host=host, user=user, password=password)
    with conn.cursor() as cur:
        cur.execute('SELECT 1 + 1')
        result = cur.fetchone()[0]
        print('DB result:', result)
    conn.close()


if __name__ == '__main__':
    main()
