# ADR-0003: Define Research Questions and Project Non-Goals

**Status:** Accepted
**Date:** 2026-08-28
**Decision owners:** SynapseFS contributors

## Context

SynapseFS combines established distributed-systems mechanisms with an experimental synchronization controller.

The research contribution should therefore be based on measurable behavior rather than the claim that combining CRDTs, peer-to-peer networking, content-defined chunking, and reconciliation is itself novel.

The project requires explicit research questions and non-goals so implementation effort remains aligned with measurable hypotheses.

## Decision

SynapseFS will center its research evaluation on synchronization efficiency under a correctness-preserving architecture.

Four primary research hypotheses will guide later experiments.

## Research Question 1: Adaptive Gossip

### Question

Can network-aware gossip reduce convergence time relative to a fixed gossip strategy under heterogeneous network conditions?

### Hypothesis

```text
T_adaptive-gossip < T_static-gossip
```

under selected combinations of:

* latency
* packet loss
* bandwidth constraints
* peer availability
* churn
* topology

### Required Baseline

Adaptive gossip must be compared against a deterministic or fixed random-gossip policy on matched workloads and predetermined seeds.

### Measurements

Candidate metrics include:

* global convergence time
* update propagation latency
* number of gossip messages
* duplicate suppression rate
* bytes transferred
* peer fan-out

No improvement is assumed before measurement.

## Research Question 2: Dynamic Synchronization Mode

### Question

Can selecting the synchronization mechanism from current replica and network conditions reduce communication cost compared with using one fixed method?

### Hypothesis

```text
B_dynamic-mode < B_fixed-mode
```

for selected mixed-divergence and file-update workloads.

Candidate synchronization modes include:

* full-state or snapshot synchronization
* delta synchronization
* content/chunk synchronization
* explicit set-difference exchange
* IBLT-based reconciliation
* Rateless IBLT reconciliation

### Measurements

Candidate metrics include:

* application bytes transferred
* wire bytes transferred
* convergence time
* reconciliation CPU
* retries
* memory usage

Each mechanism must first be measurable independently.

## Research Question 3: Rateless Reconciliation

### Question

Under what conditions does rateless reconciliation reduce reconciliation traffic relative to explicit identifier exchange and fixed-size reconciliation structures?

### Hypothesis

For sufficiently large and initially unknown set differences:

```text
B_rateless < B_explicit-hash-list
```

### Required Comparisons

At minimum:

```text
explicit hash/identifier exchange
fixed IBLT
Rateless IBLT
```

must be separately benchmarkable.

Rateless reconciliation will not be assumed superior for every set size or network condition.

## Research Question 4: Content-Defined Chunking

### Question

How much transfer can content-defined chunking avoid when localized changes occur inside large binary files?

### Hypothesis

For suitable workloads:

```text
B_CDC << B_whole-file
```

### Measurements

Candidate measurements include:

* bytes transferred
* reused chunks
* new chunks
* chunking throughput
* chunk-size distribution
* CPU cost
* storage deduplication ratio

The comparison must include a whole-file transfer baseline.

## Experimental Principle

These statements are hypotheses, not promised results.

Negative or mixed results remain valid research outcomes if experiments are reproducible and methodology is sound.

SynapseFS must report its own measurements rather than importing performance claims from external systems or papers.

## Required Baseline Decomposition

The intended research progression is:

```text
B0  Full-state / snapshot reconciliation
B1  Fixed delta synchronization
B2  Fixed random gossip
B3  CDC + explicit hash-list reconciliation
B4  CDC + fixed IBLT

P1  CDC + Rateless IBLT
P2  Deterministic network-aware heuristic
P3  Learned / contextual-bandit policy
```

Mechanisms must be benchmarked incrementally.

A result from a combined system must not be attributed to the adaptive planner if Rateless IBLT, CDC, or another mechanism could independently explain the improvement.

## Primary Non-Goals

### 1. Semantic Merge for Arbitrary Binary Files

SynapseFS will not claim that arbitrary concurrent binary payloads can always be merged meaningfully.

Concurrent incompatible binary changes will be represented as explicit versions or conflicts.

### 2. Novel Cryptography

SynapseFS will not invent cryptographic primitives.

The project will rely on established, reviewed primitives and libraries for identity, key establishment, and authenticated encryption.

The research contribution is synchronization policy, not cryptographic design.

### 3. Byzantine Fault Tolerance

The initial system does not attempt to tolerate fully malicious authorized replicas through a Byzantine consensus protocol.

Authentication and integrity checks are in scope.

General Byzantine replication is not.

### 4. Centralized Authoritative File Storage

Signaling and TURN services may assist connectivity.

They must not become the authoritative synchronized filesystem or a required centralized data store for replica correctness.

### 5. Premature Machine Learning

The project will not introduce learned synchronization policy before deterministic correctness and synchronization baselines exist.

Adaptive/ML work is intentionally postponed until the later research phase.

### 6. Premature Rust Rewrite

Python remains the primary implementation language.

Rust acceleration may be considered only after profiling identifies a stable hotspot whose cost materially limits experiments or product behavior.

### 7. Production-Grade QUIC as a Release Requirement

QUIC may be investigated as an optional comparative transport.

A complete QUIC production path must not delay the correctness, WebRTC, reconciliation, or experimental objectives.

### 8. Distributed Database Replacement

SynapseFS is a file synchronization system.

It is not intended to become a general distributed transactional database.

### 9. Universal Operating-System Equivalence

Cross-platform support is desirable, but experimental network tooling may depend on Linux facilities such as network namespaces, `tc netem`, or Mininet.

Windows development support does not imply that every later network experiment must execute natively on Windows.

## Scope Priorities

The project uses the following priority model.

### P0 — Essential Correctness and Experimental Foundation

* causal metadata
* CRDT correctness
* version DAG
* persistence and recovery
* filesystem semantics
* CDC/CAS
* reconciliation baselines
* WebRTC/ICE/STUN/TURN
* authenticated encryption
* gossip
* experiment harness
* reproducible measurements

### P1 — Primary Research Contribution

* Rateless IBLT integration
* telemetry
* deterministic adaptive heuristic
* controlled comparison against baselines

### P2 — Research Extension

* contextual-bandit or learned synchronization controller
* policy ablations

### P3 — Productization

* polished CLI
* background daemon integration
* dashboard
* VS Code extension
* distributable artifacts

### P4 — Stretch Work

* production-grade QUIC path
* Rust acceleration
* additional advanced optimization mechanisms

When schedule pressure occurs, lower-priority work must be reduced before correctness, reproducibility, or baseline measurements are sacrificed.

## Research Validity Rules

The project will follow these rules.

1. Baseline implementations must exist before proposed adaptive mechanisms are evaluated.

2. Experimental scenarios must record configuration and random seeds.

3. Measurements must identify the software revision used.

4. Learned-policy training data and final evaluation data should remain distinguishable.

5. Primary hypotheses and metrics should be frozen before the main experimental campaign.

6. Performance claims must include uncertainty or repeated-run evidence where appropriate.

7. A result that improves performance but changes final replica state is invalid.

## Success Criterion

The intended research claim is narrow:

SynapseFS evaluates whether synchronization strategy can adapt to measured network and replica conditions in a peer-to-peer CRDT-based file synchronization system while preserving the same logical convergence semantics as fixed synchronization policies.

## Consequences

### Positive

* implementation priorities align with measurable research questions
* negative findings remain publishable and meaningful
* scope creep can be rejected against explicit non-goals
* baseline comparisons are built into the architecture from the beginning
* performance claims can later be traced to explicit hypotheses

### Negative

* attractive but unrelated features may be postponed
* some systems capabilities will intentionally remain incomplete
* experimental discipline may delay optimization work

## Revisit Conditions

Research questions may be refined before the experiment-freeze milestone if pilot implementation reveals that a hypothesis cannot be measured meaningfully.

Primary hypotheses must not be retroactively rewritten to match final experimental results.
