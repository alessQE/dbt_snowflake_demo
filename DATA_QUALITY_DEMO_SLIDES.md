# Data Quality with dbt + Snowflake
## 15-20 Minute Demo Deck

Presenter: Your Name  
Project: dbt_data_quality

---

## Slide 1: What Is Snowflake?

Snowflake is a cloud-native data platform for storage, compute, and analytics.

Why teams use it:
- Separates storage and compute so teams can scale query power without copying data or replatforming pipelines.
- Supports multiple workloads on the same governed data platform, including BI dashboards, ELT jobs, data science exploration, and application-facing use cases.
- Includes built-in performance capabilities such as automatic micro-partitioning, result caching, and optimization behaviors that reduce manual tuning.
- Provides enterprise-grade security and governance features like role-based access, masking policies, and secure data sharing across teams.
- Runs across major clouds, which helps organizations align analytics architecture with broader cloud strategy and vendor requirements.

In this demo:
- Source data comes from Snowflake's SNOWFLAKE_SAMPLE_DATA so we can focus on modeling and quality patterns instead of ingestion setup.
- We build a medallion-style pipeline into BRONZE, SILVER, and GOLD databases to show how quality expectations evolve across layers.

Speaker notes:
- Position Snowflake as the execution engine and dbt as the transformation framework.

---

## Slide 2: What Is dbt?

dbt (data build tool) is a transformation framework that turns SQL into modular, tested, version-controlled pipelines.

Core uses:
- Build transformation layers as reusable SQL models, so business logic is modular and easier to maintain over time.
- Manage dependencies with ref and source, letting dbt compile objects in the correct order and preserve lineage automatically.
- Add tests and documentation directly next to model code, which keeps quality rules close to the transformations they validate.
- Bring software engineering practices into analytics workflows, including pull requests, CI checks, version control, and impact analysis.

Small Jinja example:

```sql
select
  customer_key,
  sum(total_price) as total_order_value
from {{ ref('silver_orders') }}
group by 1
```

Why this matters:
- ref automatically resolves object names by environment and determines dependency order, reducing brittle hardcoded table references.
- Jinja removes repeated SQL patterns and enables reusable macros, which improves consistency and cuts development time for common transformations.

---

## Slide 3: dbt Packages in This Project

Configured in packages.yml:
- dbt_utils for common utility macros that reduce custom boilerplate SQL.
- elementary for observability, quality monitoring context, and richer operational visibility.
- dbt_expectations for expressive, expectation-style tests that expand validation coverage quickly.

How they help with quality and speed:
- dbt_utils provides standardized helper macros for recurring modeling needs, so teams write less one-off SQL and get more consistency.
- dbt_expectations provides rich tests similar to Great Expectations patterns, making it easy to express data quality rules beyond basic null and uniqueness checks.
- elementary improves observability by organizing run information and quality signals, which helps teams troubleshoot issues faster.

Time savings:
- Avoid writing custom SQL tests for every column and rule by using reusable package-level assertions.
- Reuse proven macros and tests across many models, which improves delivery speed and reduces quality drift between teams.
- Standardize quality checks quickly across Bronze, Silver, and Gold layers so governance scales with model count.

Project example:
- The gold_customer_value_behaviour model uses dbt_expectations tests for score ranges and value constraints, demonstrating practical rule enforcement in analytics-ready outputs.

---

## Slide 4: Types of Testing You Can Add in dbt

1. Generic tests (schema.yml)
- not_null to enforce required fields that downstream consumers rely on.
- unique to validate key integrity and prevent duplicate business entities.
- relationships to ensure foreign-key style consistency between related models.
- accepted_values to constrain categorical fields to expected business-defined sets.

2. Package-based quality tests
- dbt_expectations.expect_column_values_to_be_between for numeric thresholds and sanity bounds.
- Many additional expectation-style tests are available without writing custom SQL, which accelerates policy rollout.

3. Singular tests (custom SQL test files)
- Arbitrary assertions return only failing rows, giving precise evidence for what violated the rule.
- Useful for business-specific logic and macro behavior validation where generic tests are not expressive enough.

4. Source tests
- Validate freshness, nullability, and structural assumptions at ingestion boundaries before transformation layers amplify bad data.

Practical strategy:
- Use generic and expectation tests first for broad, scalable coverage across most models.
- Add singular tests for edge cases and domain-specific logic that require precise custom assertions.

---

## Slide 5: dbt Testing in CI/CD

How dbt integrates into delivery pipelines:
- Run tests automatically on pull requests so quality is evaluated before code reaches shared environments.
- Block merges when quality gates fail, preventing known bad transformations from being promoted.
- Publish artifacts like manifest and run_results for lineage traceability, debugging, and auditability.

Typical CI flow:
1. Install dependencies
2. Run dbt deps
3. Run targeted build/test for changed models
4. Run full build/test in main branch pipeline

Example quality gate policy:
- Any failing ERROR-level test blocks deployment because it indicates a policy violation with high downstream risk.
- WARN-level tests surface potential risk signals without blocking release, allowing teams to phase in stricter controls.

Outcome:
- Data quality checks become an automated part of release engineering rather than a manual, after-the-fact QA activity.

---

## Slide 6: Warnings vs Errors in dbt

What they mean:
- ERROR means the failing condition is severe enough to stop a build, deployment, or pull request merge.
- WARN means the condition is important and should be reviewed, but may be allowed to pass temporarily by policy.

Why both are useful:
- ERROR should be used for critical integrity rules where incorrect data would break trust or functionality.
- WARN is useful for softer thresholds, drift indicators, and early anomaly signals that need monitoring before hard enforcement.

Common examples:
- ERROR example: primary key uniqueness is violated, creating ambiguous records for reporting and joins.
- ERROR example: relationship integrity is broken, indicating orphaned records across model boundaries.
- WARN example: a metric is outside an expected range but still analytically usable while teams investigate root cause.

Recommendation:
- Start strict on structural tests like not_null, unique, and relationships because these protect core model integrity.
- Start new business thresholds as WARN, then promote to ERROR once behavior stabilizes and false positives are understood.

---

## Slide 7: Demo Walkthrough (Suggested)

1. Show medallion layers in the repo
- Bronze: raw, minimally transformed source-aligned data for traceability.
- Silver: cleaned and conformed data where quality rules and standardization macros are applied.
- Gold: analytics-ready marts designed for reporting, KPI tracking, and business consumption.

2. Show quality logic near models
- Schema tests in model yml files to show declarative, version-controlled quality rules.
- Macro-based standardization in the Silver layer to show reusable cleansing logic at scale.

3. Show one rich gold model
- gold_customer_value_behaviour as a customer 360 example with richer lineage and business context.
- Call out tests that enforce value ranges and not-null constraints to demonstrate quality controls on final outputs.

4. Show one custom singular test
- Show the custom singular macro behavior test that validates explicit input/output scenarios and expected text normalization behavior.

---

## Slide 8: Key Takeaways

- Snowflake provides scalable, governed analytics infrastructure that supports shared enterprise data workloads.
- dbt makes transformations modular, testable, and CI/CD friendly, bringing engineering discipline to analytics.
- The package ecosystem accelerates delivery while improving consistency and reducing repetitive custom SQL.
- Effective testing combines structural tests, expectation-style tests, and custom singular tests for full coverage.
- Warning and error severities provide flexible quality gates that can evolve with team maturity.

Call to action:
- Treat data quality as code by enforcing tests in every pull request and promoting rules from warn to error as your platform matures.
