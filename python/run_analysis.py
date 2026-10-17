"""Run from any directory: python python/run_analysis.py. Outputs are rebuilt locally."""
from pathlib import Path
import sqlite3
import pandas as pd
ROOT = Path(__file__).resolve().parents[1]
TABLE = 'orders'
frame = pd.read_csv(ROOT / 'data' / (TABLE + '.csv'))
assert not frame.isna().any().any(), 'Missing values'
assert frame.order_id.is_unique
assert frame.discount_pct.between(0,1).all()
assert (frame.quantity > 0).all()
assert (frame.unit_price >= 0).all()
assert set(frame.status) <= {'Completed', 'Returned', 'Cancelled'}
out = ROOT / 'reports' / 'query_results'
out.mkdir(parents=True, exist_ok=True)
with sqlite3.connect(':memory:') as conn:
    frame.to_sql(TABLE, conn, index=False)
    script = (ROOT / 'sql' / 'analysis_sqlite.sql').read_text()
    statements = [s.strip() for s in script.split(';') if s.strip()]
    query = 0
    for statement in statements:
        cursor = conn.execute(statement)
        if cursor.description:
            query += 1
            result = pd.DataFrame(cursor.fetchall(), columns=[c[0] for c in cursor.description])
            result.to_csv(out / f'query_{query:02}.csv', index=False)
    sql_total = conn.execute("SELECT SUM(quantity*unit_price*(1-discount_pct)) FROM orders WHERE status='Completed'").fetchone()[0]
    python_total = frame.loc[frame.status.eq('Completed')].eval('quantity * unit_price * (1-discount_pct)').sum()
    assert abs(sql_total - python_total) < 0.01, 'SQL / Python reconciliation failed'
print(f'Passed data checks and SQL/Python total reconciliation; wrote {query} query results.')
