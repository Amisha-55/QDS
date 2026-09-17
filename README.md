# Quantum-Inspired Cyber Threat Detection for Digital Signature Security (QDS)

A hybrid quantum-classical security prototype combining **Quantum Digital Signature (QDS) simulation** and **Ed25519 digital-signature authentication** with an asynchronous **FastAPI WebSocket Gateway**, a production **Flutter mobile application** (Sender X / Receiver Y), an external adversarial **Python Attack Console**, an interactive **Streamlit Research Dashboard**, and automated **empirical benchmark pipelines**.

---

## 1. Project Overview & Research Objectives

Digital signatures provide authentication, integrity, and non-repudiation in modern communication networks. As quantum computing advances, classical asymmetric schemes face long-term challenges, motivating research into Quantum Digital Signatures (QDS) and hybrid quantum-classical cryptographic architectures.

This project implements an end-to-end prototype addressing the problem statement:

> **Quantum-Inspired Cyber Threat Detection for Digital Signature Security**

The framework explores multi-layer cyber and quantum channel threat detection:
1. **Classical Cryptographic Layer**: Ed25519 digital signatures and SHA-256 message digests ensure packet authenticity and canonical payload integrity.
2. **Quantum-Inspired Layer**: Qiskit and Qiskit Aer simulate quantum state preparation (Pauli $Z$, $X$, and $Y$ eigenstates), EPR-pair quantum teleportation circuits, and projective conjugate measurements evaluated against noise-aware thresholds.
3. **Statistical Threat Engine**: Non-AI statistical classification combining Neyman-Pearson Likelihood Ratio Tests (LRT), Hoeffding statistical confidence intervals (99% CI), quantum state fidelity, and trace distance bounds.
4. **Three-Party Arbiter Dispute Resolution**: A Charlie non-repudiation arbitration protocol using dual-threshold adjudication to resolve Alice-Bob verification disputes.
5. **Session Replay Protection**: In-memory nonce and signature-identifier tracking detect packet reuse across active sessions.
6. **Network Gateway**: An asynchronous FastAPI/Uvicorn WebSocket service mediating full-duplex communication and dispatching payloads to the security engine.
7. **Production Mobile Client**: A single-APK Flutter mobile application supporting both Sender (X) and Receiver (Y) roles with live cryptographic telemetry and security alerts.
8. **Live Attack Console**: A standalone Python CLI simulating real-world cyber-attacks (forgery, impersonation, replay, and channel disturbance) directly against the network gateway.
9. **Research Operations Dashboard**: A 6-tab Streamlit dashboard providing empirical benchmark visualization, state vector analysis, and attack simulations.

> **Research Prototype Notice:** The quantum signature component is a **QDS-inspired simulation** executed via Qiskit Aer. It does not claim formal unconditional quantum security or physical hardware quantum key distribution. Classical authenticity is provided by Ed25519.

---

## 2. System Architecture

```text
                      ┌────────────────────────────────────────┐
                      │              mobile_app/               │
                      │        (Flutter Mobile Client)         │
                      │  - Single APK (Role X & Role Y)        │
                      │  - Real-time Verification Telemetry    │
                      │  - Security Center & Threat Alerts     │
                      └──────────────────┬─────────────────────┘
                                         │
                                         ▼ WebSocket Protocol
                      ┌────────────────────────────────────────┐
                      │                server/                 │
                      │       (FastAPI WebSocket Gateway)      │
                      │  - Full-duplex connection registry     │
                      │  - Typed envelope serialization        │
                      └──────────────┬───────────────────▲─────┘
                                     │                   │
                                     ▼                   │ WebSocket
                      ┌────────────────────────┐         │ Attack Packets
                      │  QDS RESEARCH/SECURITY │         │
                      │         CORE           │         │
                      │        (src/)          │         │
                      └────────────────────────┘         │
                                     ▲                   │
                                     │                   │
                      ┌──────────────┴─────────┐         │
                      │    attack_console/     │─────────┘
                      │ (Python Adversary CLI) │
                      │ - Signature Forgery    │
                      │ - Identity Spoofing    │
                      │ - Nonce Replay         │
                      │ - Channel Noise        │
                      └────────────────────────┘

    [ backend/qds/ acts as the higher-level Python service facade ]
    [ dashboard/ & benchmarks/ act as research & presentation tooling ]
```

### Architectural Responsibilities:
- **`src/` (Research & Security Core)**: Contains the quantum teleportation circuits, projective measurements, Ed25519 cryptography, threat detector, mathematical bounds, and Charlie arbiter protocol.
- **`backend/qds/` (Service Facade)**: A higher-level Python service layer (`QDSService`, `KeyManager`, dataclass models) wrapping `src/` for clean programmatic integration.
- **`server/` (Network Gateway)**: An asynchronous FastAPI/Uvicorn server managing live WebSocket connections and dispatching payloads for verification.
- **`mobile_app/` (Flutter Client)**: A single-APK Flutter mobile app implementing both Sender (X) and Receiver (Y) roles with real-time telemetry inspection and threat notifications.
- **`attack_console/` (Adversarial CLI)**: A dedicated Python CLI tool generating and transmitting real attack payloads over WebSockets against the live gateway.
- **`dashboard/` & `benchmarks/`**: Streamlit operational dashboard and empirical benchmark runners for jury evaluations and academic presentations.

---

## 3. Empirical Benchmark Evaluation Summary

Measured across automated trials (`data/sih_benchmark_results.csv`):

| Evaluation Metric | Measured Value | Standard Required | Verdict |
| :--- | :--- | :--- | :--- |
| **Overall Accuracy** | **100.00%** | $\ge 95\%$ | Optimal |
| **True Positive Rate (Recall)** | **100.00%** | $\ge 95\%$ | Optimal |
| **False Positive Rate (FPR)** | **0.00%** | $\le 2\%$ | Optimal |
| **Precision** | **100.00%** | $\ge 95\%$ | Optimal |
| **$F_1$ Score** | **1.0000** | $\ge 0.95$ | Optimal |
| **Verification Complexity** | **$O(N)$ Linear** | Low latency | Optimal |
| **Average Detection Latency** | **~6.5 ms (Channel) / ~900 ms (Full Packet)** | $< 3\text{ sec}$ | Real-time |

---

## 4. Repository Structure

```text
QDS/
├── src/                        # Core quantum simulation & security implementation
│   ├── classical_signature.py  # Ed25519 key generation, signing & verification
│   ├── qds_signature.py        # Quantum state preparation & teleportation
│   ├── qds_verify.py           # Projective measurement & verification
│   ├── secure_packet.py        # Envelope structure & serialization
│   ├── trusted_keys.py         # Registry of trusted public keys
│   ├── security_pipeline.py    # Multi-layer evaluation & threat classification
│   ├── math_model.py           # Analytical bounds, Hoeffding bounds & LRT
│   ├── arbiter_protocol.py     # 3-party dispute resolution (Alice-Bob-Charlie)
│   ├── attack_suite.py         # Offline benchmarking attack suite
│   ├── replay_attack.py        # Replay attack simulation & session nonce tracking
│   ├── forgery_attack.py       # Message tampering & signature forgery simulation
│   ├── impersonation_attack.py # Unregistered key impersonation simulation
│   ├── channel_manipulation.py # Pauli noise & quantum channel perturbation
│   ├── threat_detector.py      # Noise-calibrated threshold detection
│   └── config.py               # Constants, shot counts & threshold settings
│
├── backend/                    # High-level QDS service facade
│   └── qds/
│       ├── __init__.py         # Package entry points
│       ├── service.py          # QDSService high-level orchestration
│       ├── key_manager.py      # Session key lifecycle management
│       ├── models.py           # Dataclass models & verification results
│       └── exceptions.py       # Custom exception hierarchy
│
├── dashboard/                  # Streamlit Web Research Operations Center
│   └── app.py                  # 6-tab interactive demonstration dashboard
│
├── benchmarks/                 # Automated performance & benchmark scripts
│   ├── run_benchmarks.py       # Automated benchmark runner (TPR, FPR, F1)
│   └── generate_plots.py       # Publication-grade plot generator
│
├── server/                     # FastAPI WebSocket network gateway
│   ├── main.py                 # Application entry point & lifecycle
│   ├── websocket_manager.py    # Active participant connection registry
│   ├── handlers.py             # Pipeline dispatch & key provisioning
│   └── protocol.py             # Typed wire-protocol envelopes
│
├── attack_console/             # Live WebSocket adversarial CLI tool
│   ├── __main__.py             # Executable module entry point
│   ├── main.py                 # CLI parser & attack dispatcher
│   ├── client.py               # WebSocket client for gateway interaction
│   └── attacks/                # Live attack payload generators
│
├── mobile_app/                 # Flutter mobile client (single APK)
│   ├── lib/
│   │   ├── app/                # Themes, routing, application shell
│   │   ├── core/               # Models, services, storage, telemetry parser
│   │   └── features/           # Onboarding, Identity, Messaging, Security Center
│   ├── test/                   # Automated unit, widget, and integration tests
│   └── android/                # Native Android build & manifest configuration
│
├── tests/                      # Python automated test suite
│   ├── test_circuits.py        # Quantum teleportation circuit unit tests
│   ├── test_detection.py       # Non-AI statistical engine unit tests
│   ├── test_attacks.py         # Research attack suite unit tests
│   ├── test_arbiter.py         # 3-party dispute arbitration tests
│   ├── test_qds_service.py     # QDSService integration tests
│   ├── test_gateway.py         # FastAPI WebSocket & REST tests
│   ├── test_attack_console.py  # Attack CLI & payload integration tests
│   └── test_e2e_integration.py # Full multi-client end-to-end integration tests
│
├── data/                       # Experimental & benchmark datasets
│   ├── sih_benchmark_results.csv
│   └── pipeline_security_dataset.csv
│
├── docs/                       # Technical specifications & presentation guides
│   ├── ARCHITECTURE.md         # Detailed architectural documentation
│   ├── SIH_PITCH_GUIDE.md      # Hackathon defense & jury pitch guide
│   ├── mathematical_formulation.md # Formal security proofs & mathematical bounds
│   └── demo.md                 # Live demonstration runbook
│
├── run_demo.py                 # Standalone interactive CLI demo for judges
├── run_dashboard.bat           # 1-Click launcher for Streamlit dashboard
├── run_all.bat                 # 1-Click test suite + benchmarks + demo runner
├── requirements.txt            # Python dependencies (Qiskit, FastAPI, Streamlit, etc.)
└── README.md                   # Unified project documentation
```

---

## 5. Requirements & Setup

### Environment Prerequisites
- **Python**: 3.10+ (tested on Python 3.10, 3.11, 3.12, 3.13, 3.14)
- **Flutter**: Flutter SDK 3.x stable with Dart 3.x
- **Android SDK & ADB**: For physical Android phone testing or Android emulator

### Python Setup
```bash
# 1. Create and activate a virtual environment
python -m venv .venv

# Windows PowerShell:
.venv\Scripts\activate

# Linux / macOS:
source .venv/bin/activate

# 2. Install unified dependencies:
pip install -r requirements.txt
```

### Flutter Setup
```bash
cd mobile_app
flutter pub get
flutter analyze
flutter test
cd ..
```

---

## 6. Running the System

### Mode 1: Research Platform & Benchmarks

#### Interactive CLI Demonstration
```bash
python run_demo.py
```

#### Streamlit Security Operations Dashboard
```bash
streamlit run dashboard/app.py
# Or run launcher on Windows:
run_dashboard.bat
```

#### Run Benchmarks & Generate Plots
```bash
python benchmarks/run_benchmarks.py
python benchmarks/generate_plots.py
```

---

### Mode 2: Mobile Application & Live Attack Gateway

#### Step 1: Start the QDS Gateway Server
From the repository root:
```bash
python -m uvicorn server.main:app --host 0.0.0.0 --port 8000
```
Verify gateway health via curl or browser:
```bash
curl http://localhost:8000/health
# Output: {"status":"healthy"}
```

#### Step 2: Run the Flutter Mobile App
- **Desktop (Windows/macOS/Linux):**
  ```bash
  cd mobile_app
  flutter run -d windows --dart-define=QDS_GATEWAY_HOST=127.0.0.1
  ```
- **Android Emulator:**
  ```bash
  cd mobile_app
  flutter run -d emulator-5554 --dart-define=QDS_GATEWAY_HOST=10.0.2.2
  ```
- **Physical Android Phone (Local Wi-Fi Network):**
  1. Connect your phone and PC to the same Wi-Fi network.
  2. Find your PC's local IP using `ipconfig` (Windows) or `ip a` (Linux/macOS).
  3. Ensure inbound port `8000` is permitted through your firewall.
  4. Launch the app pointing to your PC:
     ```bash
     cd mobile_app
     flutter run -d <DEVICE_ID> --dart-define=QDS_GATEWAY_HOST=<LAPTOP_IP>
     ```

#### Step 3: Build Debug APK for Android
```bash
cd mobile_app
flutter build apk --debug
```
Output location: `mobile_app/build/app/outputs/flutter-apk/app-debug.apk`

---

### Mode 3: Live Adversarial Attack Demonstrations

Execute live attacks using the external Python CLI console while the mobile app is active on the Receiver (Y) screen:

#### 1. Classical Signature Forgery
Simulates payload tampering in transit:
```bash
python -m attack_console --target ws://127.0.0.1:8000/ws --attack forgery
```
* **Attack Console:** Reports `Classical Signature Valid: False`, `Final Decision: INVALID / SUSPICIOUS`.
* **Flutter UI:** Displays a high-visibility `Threat Alert Banner` (`Signature Forgery Detected`) and marks message with `⚠ Security warning`.

#### 2. Identity Impersonation
Simulates an unauthorized third party claiming Alice's identity using an unauthenticated key:
```bash
python -m attack_console --target ws://127.0.0.1:8000/ws --attack impersonation
```
* **Flutter UI:** Classical verification against trusted key registry fails; logged in Security Center under **Threats**.

#### 3. Nonce Replay Attack
Resends a previously legitimate signed packet:
```bash
python -m attack_console --target ws://127.0.0.1:8000/ws --attack replay
```
* **Flutter UI:** First transmission succeeds; replayed transmission is flagged by the session replay detector (`Replay detected: True`).

#### 4. Quantum Channel Manipulation
Introduces depolarizing Pauli channel disturbance:
```bash
python -m attack_console --target ws://127.0.0.1:8000/ws --attack channel
```
* **Flutter UI:** Classical Ed25519 signature remains `Valid`, but quantum measurement accuracy falls below threshold (`~60%`). Status surfaces as `SUSPICIOUS` with detailed quantum state error metrics.

---

## 7. Automated Test Verification

Execute all verification suites:

```bash
# 1. Run Python test suites (Research Core, QDSService, Gateway, Attack Console, E2E)
python -m pytest tests/ -q

# 2. Run Flutter static analysis
cd mobile_app
flutter analyze

# 3. Run Flutter unit, widget, and integration tests
flutter test

# 4. Build Android APK
flutter build apk --debug
```

---

## 8. Technical Documentation Directory

- [System Architecture Specification](docs/ARCHITECTURE.md)
- [Mathematical Formulation & Security Proofs](docs/mathematical_formulation.md)
- [SIH Presentation & Jury Defense Guide](docs/SIH_PITCH_GUIDE.md)
- [Live Demonstration Runbook](docs/demo.md)

---

## 9. Limitations & Research Notes

1. **Quantum Simulation:** Quantum circuits are simulated using Qiskit Aer statevectors and shot-based measurement models; physical quantum key distribution hardware or quantum repeaters are not used.
2. **Replay Registry Scope:** The current replay detection registry operates in-memory for active gateway sessions. Enterprise deployment would require distributed persistent storage.
3. **Key Distribution:** The trusted-key registry uses a prototype local mapping file (`keys/public_keys.json`) rather than a full hierarchical Public Key Infrastructure (PKI).
4. **Local Network Demonstration:** The gateway is configured for local LAN evaluation and development; production deployment requires TLS termination (`wss://`) and firewall access controls.

---

## 10. License

Developed for academic research, cryptographic evaluation, and project presentation.
