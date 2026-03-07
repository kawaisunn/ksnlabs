"""
ITD_AggDB database connection layer.
Connects to IGS-Intrusion\\SQLEXPRESS via pyodbc (Windows Auth).
"""
import pyodbc
from contextlib import contextmanager

SERVER = r"IGS-Intrusion\SQLEXPRESS"
DATABASE = "ITD_AggDB"
CONN_STR = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    f"Trusted_Connection=yes;"
    f"Connection Timeout=5;"
)

def get_connection():
    return pyodbc.connect(CONN_STR)

@contextmanager
def get_cursor():
    conn = get_connection()
    try:
        cursor = conn.cursor()
        yield cursor
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

def fetch_all(query: str, params=None) -> list[dict]:
    """Execute query and return list of dicts."""
    with get_cursor() as cur:
        cur.execute(query, params or [])
        cols = [col[0] for col in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]

def fetch_one(query: str, params=None) -> dict | None:
    """Execute query and return single dict or None."""
    with get_cursor() as cur:
        cur.execute(query, params or [])
        row = cur.fetchone()
        if row is None:
            return None
        cols = [col[0] for col in cur.description]
        return dict(zip(cols, row))

def execute(query: str, params=None):
    """Execute non-SELECT statement."""
    with get_cursor() as cur:
        cur.execute(query, params or [])
        return cur.rowcount

def execute_returning_id(query: str, params=None) -> int:
    """Execute INSERT and return the identity value."""
    with get_cursor() as cur:
        cur.execute(query, params or [])
        cur.execute("SELECT SCOPE_IDENTITY()")
        row = cur.fetchone()
        return int(row[0]) if row and row[0] else 0

def next_id(table: str, column: str) -> int:
    """Get next available integer ID for a table's PK column."""
    row = fetch_one(f"SELECT ISNULL(MAX([{column}]), 0) + 1 AS next_id FROM [{table}]")
    return row["next_id"] if row else 1


def health_check() -> dict:
    """Quick DB connectivity check."""
    row = fetch_one(
        "SELECT DB_NAME() AS [database], @@SERVERNAME AS server, "
        "SUSER_SNAME() AS db_user, CONVERT(varchar, GETDATE(), 120) AS db_time"
    )
    return row or {}
