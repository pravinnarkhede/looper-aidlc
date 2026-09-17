# Requirements Verification — tax-inclusive-inventory (CCD-20)

## Context

The functional and non-functional requirements for this feature are already fully defined in:
`tax-inclusive-inventory\golfler_asp_2\docs\requirements\PRD-020-tax-inclusive-inventory.md`

This document contains only the **extension opt-in questions** that require a decision before requirements.md can be finalized.

Please answer each question by filling in the letter choice after the `[Answer]:` tag.

---

## Question 1: Security Extensions

Should security extension rules be enforced for this project?

A) Yes — enforce all SECURITY rules as blocking constraints (recommended for production-grade applications)

B) No — skip all SECURITY rules (suitable for PoCs, prototypes, and experimental projects)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 2: Property-Based Testing Extension

Should property-based testing (PBT) rules be enforced for this project?

A) Yes — enforce all PBT rules as blocking constraints (recommended for projects with business logic, data transformations, serialization, or stateful components)

B) Partial — enforce PBT rules only for pure functions and serialization round-trips (suitable for projects with limited algorithmic complexity)

C) No — skip all PBT rules (suitable for simple CRUD applications, UI-only projects, or thin integration layers with no significant business logic)

X) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Question 3: Resiliency Extensions

Should the resiliency baseline be applied to this project?

**What this extension is.** Enabling it applies a set of directional, design-time best practices for building resilient systems, derived from the AWS Well-Architected Framework (Reliability Pillar). It steers requirements, design, and code toward fault tolerance, high availability, observability, and recoverability.

**What this extension is NOT.** It does not make your workload production-ready, nor does it certify any availability, RTO, or RPO target. It is a starting point.

A) Yes — apply the resiliency baseline as directional best practices and design-time guidance (recommended for business-critical workloads)

B) No — skip the resiliency baseline (suitable for PoCs, prototypes, and experimental projects)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

*When done, let me know and I will generate the full requirements.md and proceed to Workflow Planning, Application Design, and Units Generation.*
