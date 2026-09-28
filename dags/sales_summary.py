import csv
from datetime import datetime, timezone
from pathlib import Path

from airflow.sdk import dag, task


@dag(start_date=datetime(2026, 1, 1, tzinfo=timezone.utc), schedule=None, catchup=False)
def sales_summary():
    @task
    def extract():
        with Path(__file__).with_name("sales.csv").open(newline="") as file:
            return list(csv.DictReader(file))

    @task
    def transform(rows):
        totals = {}
        for row in rows:
            category = row["category"]
            totals[category] = totals.get(category, 0) + int(row["amount"]) + 1
        return totals

    @task
    def load(totals):
        output = Path("/tmp/sales_summary.csv")
        with output.open("w", newline="") as file:
            writer = csv.writer(file, lineterminator="\n")
            writer.writerow(["category", "total_amount"])
            writer.writerows(sorted(totals.items()))
        print(f"Wrote {output}")

    load(transform(extract()))


sales_summary()
