from fpdf import FPDF

class PDF(FPDF):
    def header(self):
        self.set_font("Arial", "B", 14)
        self.cell(0, 10, "Cloud Data Warehouse Comparison: ACID & Analytics", ln=True, align="C")
        self.ln(5)

    def chapter_title(self, title):
        self.set_font("Arial", "B", 12)
        self.cell(0, 10, title, ln=True)
        self.ln(2)

    def chapter_body(self, text):
        self.set_font("Arial", "", 10)
        self.multi_cell(0, 6, text)
        self.ln()

# Initialize PDF
pdf = PDF()
pdf.add_page()

# Section: Introduction
intro = """
This document compares leading cloud data warehouse platforms (BigQuery, Snowflake, Redshift, Databricks) 
with a focus on ACID compliance, analytics performance, concurrency, and transaction handling.
"""

# Section: Comparison Table (ASCII only)
comparison_table = """
| Feature / Platform         | BigQuery              | Snowflake             | Redshift               | Databricks Delta Lake     |
|---------------------------|-----------------------|------------------------|------------------------|----------------------------|
| ACID Transactions         | Partial (single stmt) | Full (multi-stmt)     | Partial (with caveats) | Full (via Delta Lake)      |
| Optimized For             | Analytics             | Analytics             | Analytics              | Analytics + ML             |
| Storage Architecture      | Columnar, Serverless  | Micro-partitioned     | Columnar               | Parquet + Delta Format     |
| Multi-statement Txns      | [X] Not supported      | [OK] Supported         | [!] Limited rollback    | [OK] Supported              |
| Concurrency Handling      | High (auto-scaling)   | High (multi-cluster)  | Medium (scaling)       | High (with autoscaling)    |
| Real-time Data Support    | Limited               | Moderate              | Limited                | [OK] Excellent             |
| Frequent Updates/Deletes  | [X] Not ideal          | [OK] Efficient         | [!] Slower on deletes   | [OK] Excellent              |
| ML Integration            | Basic (BQML)          | Via integrations      | SageMaker (AWS)        | [OK] Built-in (MLflow)     |
| Pricing Model             | Query-based           | Per-second + storage  | Node-hour              | Compute + storage separate |
"""

# Section: Summary
summary = """
[OK] = Recommended / supported well
[X]  = Not supported
[!]  = Limited or partially supported

Recommendations:
- Use BigQuery for fast, cost-effective analytics and dashboards.
- Use Snowflake for full ACID support and ease of use.
- Use Redshift if you're in AWS and okay with manual tuning.
- Use Databricks for unified analytics + ML with strong ACID support.
"""

# Write content
pdf.chapter_title("Overview")
pdf.chapter_body(intro)

pdf.chapter_title("Comparison Matrix")
pdf.chapter_body(comparison_table)

pdf.chapter_title("Summary & Recommendations")
pdf.chapter_body(summary)

# Save the PDF
pdf.output("cloud_dw_comparison_ascii_safe.pdf")
