# ADR-0001: Define SynapseFS System Boundaries

**Status:** Accepted
**Date:** 2026-08-28
**Decision owners:** SynapseFS contributors

## Context

SynapseFS is a peer-to-peer file synchronization system and a distributed-systems research platform.

The project combines several areas:

* filesystem observation and materialization
* causal metadata
* CRDT-based replicated state
* immutable version history
* content-addressed storage
* peer-to-peer synchronization
* reconciliation
* secure transport
* telemetry
* adaptive synchronization
* user-facing CLI, dashboard, and editor integration

Without explicit architectural boundaries, responsibilities such as convergence, transport, storage, and optimization can become coupled. That would make correctness harder to reason about and would weaken experimental claims about adaptive synchronization.

The project therefore requires stable system boundaries before implementation begins.

## Decision

SynapseFS will be organized conceptually into the following major subsystems.

### 1. User Surfaces

User-facing components include:

* command-line interface
* VS Code extension
* web dashboard

These components interact with SynapseFS through the daemon control interface.

They do not independently implement synchronization semantics.

Closing a user interface must not terminate synchronization performed by the background daemon.

### 2. Local Daemon

A long-running SynapseFS daemon coordinates local system activity.

Its responsibilities will include supervising:

* filesystem observation
* persistent state
* synchronization
* peer connectivity
* gossip
* telemetry
* materialization
* local control APIs

The daemon is the runtime owner of a local SynapseFS replica.

### 3. Filesystem Boundary

Filesystem-specific components translate operating-system events into canonical SynapseFS operations.

Supported operation categories are expected to include:

* create
* modify
* delete
* rename
* move
* directory creation
* directory removal

Filesystem events are inputs to the replicated model.

Raw operating-system watcher events are not themselves the distributed protocol.

Likewise, remote replica state must be materialized through controlled filesystem operations rather than allowing network code to mutate files directly.

### 4. Correctness Plane

The correctness plane owns the logical meaning of replica state.

It includes:

* peer, workspace, file, version, and operation identities
* logical clocks
* causal context
* CRDT semantics
* conflict representation
* immutable version relationships
* persistent logical state
* operation replay
* content identity
* deterministic materialization rules
* replica convergence invariants

The correctness plane determines **what state is valid**.

### 5. Synchronization Plane

The synchronization plane moves valid state between replicas.

It includes:

* operation dissemination
* anti-entropy
* reconciliation
* chunk exchange
* acknowledgements
* gossip
* peer membership and liveness information

The synchronization plane may change how quickly state propagates, but it must not redefine the logical meaning of operations.

### 6. Optimization Plane

The optimization plane observes runtime conditions and chooses among valid synchronization strategies.

Its inputs may include:

* latency
* jitter
* throughput
* loss or retry indicators
* replica divergence
* peer availability
* churn
* synchronization backlog

Its outputs may influence:

* peer selection
* gossip fan-out
* batching
* synchronization timing
* reconciliation method
* chunk-transfer scheduling

Optimization decisions affect cost and latency, not correctness.

### 7. Secure P2P Transport

Transport components provide authenticated communication between replicas.

The anticipated primary path is WebRTC DataChannels with ICE/STUN/TURN support.

Application-level security will protect SynapseFS objects independently of whether traffic travels directly or through a relay.

Transport establishes communication.

It does not define replica merge semantics.

### 8. Persistent Storage

Persistent state will be divided according to data characteristics.

SQLite is expected to hold structured metadata such as:

* causal state
* operation records
* version records
* peer/workspace metadata
* synchronization bookkeeping

Large immutable file chunks will live in a filesystem-backed content-addressed store rather than ordinary relational rows.

Storage implementations must preserve the semantics defined by the correctness plane.

### 9. Experiment Infrastructure

Experiments are separate from production semantics.

Experiment components may:

* create workloads
* control topology
* inject network impairment
* crash or restart peers
* collect telemetry
* replay deterministic scenarios
* analyze results

Experiment tooling must not require special correctness behavior unavailable in normal SynapseFS operation.

## Dependency Direction

The intended high-level dependency direction is:

```text
User surfaces
      |
      v
Local daemon
      |
      +----------------------+
      |                      |
      v                      v
Filesystem              Telemetry
      |                      |
      v                      v
Correctness plane <--- Optimization plane
      |
      v
Synchronization plane
      |
      v
Secure P2P transport
```

This diagram represents conceptual responsibility rather than final Python import structure.

## Architectural Invariants

The following boundaries are mandatory.

1. Transport code must not decide CRDT conflict semantics.

2. Optimizer code must not create, delete, rewrite, or reinterpret logical replica state.

3. User-interface code must not become an independent synchronization engine.

4. Filesystem watcher events must be normalized before becoming replicated operations.

5. Remote network messages must pass validation before affecting durable replica state.

6. Persistent storage must not become the source of undocumented logical semantics.

7. Experimental instrumentation may observe and perturb environmental conditions but must not change correctness rules.

## Initial Deployment Boundary

SynapseFS is peer-to-peer for synchronization but may use supporting infrastructure for connectivity.

A signaling/rendezvous service may exchange connection bootstrap metadata.

A TURN server may relay encrypted traffic when direct communication is unavailable.

These services must not become authoritative storage for the user's synchronized filesystem.

## Consequences

### Positive

* correctness can be reasoned about independently from networking optimizations
* alternative synchronization strategies can be benchmarked fairly
* transport implementations can later be replaced without rewriting CRDT semantics
* CLI, dashboard, and VS Code can share one synchronization daemon
* experimental code can be isolated from production semantics

### Negative

* explicit interfaces will be required between subsystems
* some information must cross several layers
* early development may appear slower because boundaries are documented before implementation

## Revisit Conditions

This ADR should be revisited if:

* a new subsystem needs authority over logical replica state
* a transport-specific behavior becomes necessary for correctness
* the daemon/user-surface relationship changes
* persistent storage responsibilities materially change
* experimental tooling requires behavior not available through normal system interfaces
