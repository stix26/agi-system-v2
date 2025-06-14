import os
import time
import subprocess
import shutil
import pymysql

DATA_DIR = '/tmp/mysql-data-test'


def ensure_server():
    if shutil.which('mysqld') is None:
        print('mysqld not found, skipping test')
        return None
    if not os.path.isdir(os.path.join(DATA_DIR, 'mysql')):
        subprocess.run([
            'mysqld',
            '--initialize-insecure',
            f'--datadir={DATA_DIR}',
            '--basedir=/usr'
        ], check=True)
    proc = subprocess.Popen([
        'mysqld',
        f'--datadir={DATA_DIR}',
        '--user=root',
        '--bind-address=127.0.0.1',
        '--skip-networking=0',
        '--socket=/tmp/mysql.sock'
    ])
    # wait for server to be ready
    for _ in range(10):
        try:
            conn = pymysql.connect(host='127.0.0.1', user='root', connect_timeout=1)
            conn.close()
            return proc
        except Exception:
            time.sleep(1)
    raise RuntimeError('MySQL server failed to start')


def main():
    proc = ensure_server()
    if proc is None:
        return
    conn = pymysql.connect(host='127.0.0.1', user='root')
    cur = conn.cursor()
    cur.execute('SELECT 1 + 1')
    result = cur.fetchone()[0]
    assert result == 2
    print('SQL test passed.')
    conn.close()
    proc.terminate()
    proc.wait(timeout=10)


if __name__ == '__main__':
    main()
