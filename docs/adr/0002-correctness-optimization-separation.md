# ADR-0002: Separate Correctness from Synchronization Optimization

**Status:** Accepted
**Date:** 2026-08-28
**Decision owners:** SynapseFS contributors

## Context

SynapseFS has two distinct engineering objectives.

The first is distributed correctness: independent replicas must eventually represent the same logical state after supported concurrent operations, disconnections, retries, duplicate delivery, reordering, crashes, and reconnection.

The second is synchronization efficiency: replicas should exchange state using strategies appropriate to network conditions, workload, divergence, and peer availability.

Combining these responsibilities would make the system difficult to validate.

For example, an adaptive policy that determines which concurrent version wins would make logical state dependent on network conditions or learned-policy behavior. That would violate the intended architecture and make controlled comparisons between synchronization policies invalid.

The project therefore requires a strict separation between correctness and optimization.

## Decision

SynapseFS will implement a **correctness plane** and an **optimization plane** with an explicit correctness firewall between them.

## Correctness Plane Responsibilities

The correctness plane owns all decisions that affect final logical replica state.

These responsibilities include:

### Identity

* peer identity
* workspace identity
* file identity
* operation identity
* version identity

### Causality

* logical clocks
* causal dots
* version contexts
* causal ordering relationships

### Replicated Data Types

The correctness plane will define and implement replicated semantics such as:

* observed-remove sets
* observed-remove maps
* last-writer-wins registers where explicitly appropriate
* multi-value registers
* sequence CRDT behavior for supported text synchronization

### Version History

The correctness plane owns the immutable causal version DAG.

Versions and parent relationships cannot be discarded merely because an optimization strategy considers them inconvenient or expensive.

### Conflict Semantics

Conflicts must have explicit deterministic semantics.

In particular, arbitrary concurrent binary modifications must not be silently collapsed through last-writer behavior.

Where semantic merging is unavailable, conflicting binary versions remain represented explicitly.

### Persistence and Recovery

Accepted logical operations and versions must survive supported crash/restart scenarios according to the documented persistence model.

### Materialization

The correctness plane determines what logical state should be represented in the local filesystem.

Filesystem materialization is a projection of replicated state, not an independent conflict-resolution authority.

## Optimization Plane Responsibilities

The optimization plane may select among synchronization actions that are already valid under the correctness model.

Examples include:

### Peer Selection

Choose which available peers should be contacted.

### Gossip Fan-out

Choose how many peers should receive immediate dissemination.

### Batching

Choose how long valid updates may be buffered before transmission within configured safety bounds.

### Reconciliation

Choose among supported methods such as:

* explicit identifier exchange
* delta synchronization
* chunk reconciliation
* fixed IBLT
* Rateless IBLT
* snapshot/full-state synchronization

### Transfer Scheduling

Choose which missing chunks or operations should be transferred first.

### Topology

Change neighbor selection and replacement policies.

## Correctness Firewall

An optimizer action is valid only if changing that action cannot change the final logical state after all required information has eventually been exchanged.

For a logical history `H` and two valid optimization policies `P1` and `P2`, the required property is:

```text
LogicalState(H, P1) = LogicalState(H, P2)
```

after the system reaches quiescence under the supported fault model.

Performance characteristics may differ:

```text
ConvergenceTime(H, P1) != ConvergenceTime(H, P2)

NetworkBytes(H, P1) != NetworkBytes(H, P2)

CPUCost(H, P1) != CPUCost(H, P2)
```

Those differences are precisely what SynapseFS intends to measure.

## Optimizer Inputs

The optimization layer may observe:

* RTT
* jitter
* throughput
* transfer retry/error information
* peer availability
* replica divergence
* synchronization backlog
* churn
* topology
* workload characteristics

These observations must not become causal truth.

A measured RTT, for example, may alter peer preference but cannot change whether a version exists.

## Optimizer Outputs

Optimizer output must be constrained to an explicit action space.

Examples include:

```text
peer = P7

fanout = 3

batch_interval_ms = 100

reconciliation = RIBLESS

transfer_priority = [...]
```

The optimizer must not emit decisions such as:

```text
discard_version = V42

ignore_conflict = true

rewrite_operation = OP9

prefer_replica_state = P3
```

because those decisions would alter correctness semantics.

## Failure Behavior

If optimization fails, SynapseFS should degrade to a valid baseline synchronization policy.

Examples include:

* static gossip fan-out
* deterministic peer ordering
* fixed batching
* explicit hash-list reconciliation
* fixed synchronization mode

Optimizer failure must not prevent the correctness plane from interpreting already-received valid state.

## Machine-Learned Policies

Machine learning is not part of the initial correctness foundation.

Adaptive or learned policies will only be introduced after:

* CRDT semantics are deterministic
* persistence is trustworthy
* binary conflict behavior is defined
* synchronization baselines exist
* P2P communication works
* reconciliation mechanisms are independently benchmarkable

A learned policy will therefore optimize synchronization decisions rather than learn replica semantics.

## Testing Requirement

The project must eventually execute identical logical histories under different synchronization policies and verify that canonical logical-state digests are identical after quiescence.

Conceptually:

```text
Digest(S_static)
    =
Digest(S_heuristic)
    =
Digest(S_learned)
```

for the same logical history.

Any optimizer configuration that changes final logical state is a correctness defect.

## Consequences

### Positive

* adaptive policies can be evaluated without weakening convergence claims
* failures in optimization can fall back to deterministic baselines
* research comparisons can isolate performance effects
* CRDT and conflict semantics remain inspectable
* learned policies cannot silently redefine user data

### Negative

* optimization opportunities that require semantic shortcuts are intentionally disallowed
* additional validation is required at subsystem boundaries
* some globally efficient behaviors may be rejected if they cannot preserve correctness guarantees

## Revisit Conditions

This decision may be revisited only if a proposed feature demonstrates that synchronization efficiency fundamentally requires additional correctness-plane metadata.

Such a change must be introduced explicitly into the correctness model rather than smuggled through the optimizer.
