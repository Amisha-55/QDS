# System Architecture & Technical Specifications

## 1. Architectural Topology
```
[ Sender: Alice ]
       │
       ├── 1. Message Bit Decomposition (M -> {b_i})
       ├── 2. Pauli State Preparation: |ψ_i⟩ ∈ {|0⟩,|1⟩,|+⟩,|-⟩,|+i⟩,|-i⟩}
       ├── 3. EPR Pair Entanglement (|Φ⁺⟩ = (|00⟩+|11⟩)/√2)
       ├── 4. Bell State Measurement (BSM) -> Classical Bits (c0, c1)
       └── 5. Authentication Envelope (SHA-256 + Ed25519 + Nonce + Timestamp)
                 │
                 ▼
[ Quantum & Classical Communication Channels ]
       ├── Quantum Channel: Teleportation of Qubit States
       ├── Classical Channel: Authenticated Packet Metadata
       └── Adversarial Ingestion Layer:
             ├── Signature Forgery (Payload corruption)
             ├── Signer Impersonation (Key spoofing)
             ├── Cryptographic Replay (Nonce reuse)
             └── Quantum Channel Manipulation (Bit/Phase flip, Depolarizing)
                 │
                 ▼
[ Receiver: Bob & Non-AI Threat Detection Engine ]
       ├── 1. Feed-Forward Pauli Correction: U_corr = X^{c1} Z^{c0}
       ├── 2. Projective Measurement in Conjugate Bases (X, Y, Z)
       ├── 3. Classical Authentication & Replay Filter (Cache Deduplication)
       ├── 4. Statistical Threat Detection:
       │     ├── Neyman-Pearson Likelihood Ratio Test (LRT)
       │     ├── Hoeffding Statistical Confidence Bounds (99% CI)
       │     └── State Fidelity & Trace Distance Analysis
       └── 5. Deterministic Decision Gate (Accept if error <= s_v)
                 │
                 ▼ (In Case of Dispute)
[ Arbiter: Charlie (Non-Repudiation Resolution) ]
       └── Dual-Threshold Adjudication (Accept if error <= s_a, s_v < s_a < 0.50)
```

## 2. Directory Layout & Module Responsibilities

```
QDS/
├── run_demo.py               # Standalone interactive CLI demonstration for judges
├── run_dashboard.bat         # 1-Click launcher for Streamlit web dashboard
├── run_all.bat               # 1-Click test suite + benchmark + CLI demo runner
├── requirements.txt          # Production dependencies (qiskit, streamlit, pytest, etc.)
│
├── dashboard/
│   └── app.py                # Modern 6-tab Streamlit Security Operations Center
│
├── src/
│   ├── math_model.py         # Analytical bounds, Hoeffding inequality, LRT engine
│   ├── teleportation.py      # Qiskit 3-qubit teleportation circuit & corrections
│   ├── qds_signature.py      # QDS signature creation & Pauli state assembly
│   ├── qds_verify.py         # Multi-qubit projective verification engine
│   ├── threat_detector.py    # Non-AI statistical threat classification
│   ├── attack_suite.py       # 4-pronged attack simulation orchestrator
│   ├── arbiter_protocol.py   # 3-party Alice-Bob-Charlie dispute resolver
│   ├── secure_packet.py      # Dual-layer quantum + classical authentication packet
│   ├── classical_signature.py# Ed25519 asymmetric cryptography layer
│   ├── noisy_channel.py      # Quantum channel decoherence & noise simulators
│   └── config.py             # System thresholds, shot counts, and constants
│
├── benchmarks/
│   ├── run_benchmarks.py     # Automated benchmark runner (calculates TPR, FPR, F1)
│   └── generate_plots.py     # Publication-grade figure generator
│
├── tests/
│   ├── test_circuits.py      # Quantum circuit & teleportation fidelity unit tests
│   ├── test_detection.py     # Non-AI statistical engine unit tests
│   ├── test_attacks.py       # Integration tests for 4 attack vectors
│   └── test_arbiter.py       # 3-party dispute resolution tests
│
├── data/
│   ├── sih_benchmark_results.csv   # Empirical benchmark dataset (30 trials, 100% accuracy)
│   └── pipeline_security_dataset.csv
│
└── docs/
    ├── figures/              # Generated high-resolution figures
    ├── mathematical_formulation.md
    ├── SIH_PITCH_GUIDE.md
    └── ARCHITECTURE.md
```
