# SynapseFS

SynapseFS is an experimental peer-to-peer file synchronization system built around CRDT-based replica convergence, causal versioning, content-addressed storage, peer-to-peer networking, and adaptive synchronization.

> Status: Pre-alpha research prototype.

## Project Goal

SynapseFS investigates whether synchronization decisions can be adapted to network and replica conditions without changing distributed correctness semantics.

The architecture is conceptually separated into two planes.

### Correctness Plane

Responsible for:

- causal history
- CRDT semantics
- versioning
- conflict representation
- persistent metadata
- content identity
- filesystem materialization
- replica convergence

### Optimization Plane

May influence:

- peer selection
- gossip fan-out
- batching
- reconciliation strategy
- chunk-transfer strategy
- synchronization scheduling

The optimization plane must never change the final logical result of synchronization.

## Research Areas

The project will investigate:

- CRDT-based filesystem metadata
- causal version histories
- text CRDTs
- explicit binary-file conflicts
- content-defined chunking
- content-addressed storage
- set reconciliation
- rateless reconciliation
- gossip synchronization
- WebRTC / ICE / STUN / TURN networking
- authenticated encryption
- synchronization telemetry
- adaptive synchronization strategies

## Current Status

Day 1 — repository bootstrap.

Currently available:

- Git repository
- Python package skeleton
- packaging metadata
- project structure
- project charter

Distributed synchronization is not implemented yet.

## Requirements

- Python 3.13+
- Git

Development is cross-platform, with Windows supported for development and Linux used extensively for later networking and systems experiments.

## Development Setup

Clone the repository:

```bash
git clone https://github.com/sannx4/synapsefs.git
cd synapsefs