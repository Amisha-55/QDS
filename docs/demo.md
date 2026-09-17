# QDS End-to-End Demonstration Guide

This guide provides a reproducible, step-by-step procedure for demonstrating the **Quantum-Inspired Digital Signature (QDS) Cyber Threat Detection System** during college presentations, faculty reviews, or live evaluations.

---

## 1. System Architecture Overview

```
                      ┌────────────────────────────────────────┐
                      │             ATTACK CONSOLE             │
                      │         (Python CLI Interface)         │
                      └──────────────────┬─────────────────────┘
                                         │ Raw Packet / Attacks
                                         ▼
┌──────────────────┐               ┌───────────┐               ┌──────────────────┐
│   X CLIENT       │  WebSocket    │    QDS    │  WebSocket    │    Y CLIENT      │
│ (Sender Device)  │ ◄───────────► │  GATEWAY  │ ◄───────────► │ (Receiver Device)│
│  Flutter APK     │  Registration │  (FastAPI)│  Registration │  Flutter APK     │
└──────────────────┘  & Messages   └─────┬─────┘  & Telemetry  └──────────────────┘
                                         │
                                         ▼
                      ┌────────────────────────────────────────┐
                      │          RESEARCH CORE (src/)          │
                      │  - Ed25519 Classical Verification      │
                      │  - Quantum Swap-Test Teleportation     │
                      │  - In-Memory Replay Nonce Cache        │
                      │  - Multi-Layer Threat Classification   │
                      └────────────────────────────────────────┘
```

Both clients run the **exact same Flutter APK/codebase**. Roles (**Sender X** vs **Receiver Y**) are selected at runtime during initial profile setup.

---

## 2. Prerequisites & Environment Setup

### A. Python Environment
- Python 3.10+ (tested on Python 3.14)
- Dependencies installed from `requirements.txt`:
```bash
pip install -r requirements.txt
```
*(FastAPI, Uvicorn, WebSockets, PyCryptodome / Cryptography, Pytest)*

### B. Flutter Environment
- Flutter SDK (3.x stable)
- Android SDK & ADB (for physical Android device or emulator)

### C. Network Configuration
Find the host computer's local IP address on Wi-Fi/LAN:
- **Windows**: `ipconfig` (Look for `IPv4 Address`, e.g., `<LAPTOP_IP>`)
- **macOS / Linux**: `ifconfig` or `ip a`

---

## 3. Step-by-Step Demonstration Workflow

### STEP 1: Launch the QDS Network Gateway
Open Terminal 1 in the repository root directory:
```bash
python -m server.main
```
Expected output:
```text
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

Verify gateway health in a browser or curl:
```bash
curl http://localhost:8000/health
# {"status":"healthy"}
```

---

### STEP 2: Launch Client X (Sender)
Option A: On Desktop / Second Emulator:
```bash
cd mobile_app
flutter run -d windows --dart-define=QDS_GATEWAY_HOST=127.0.0.1
```
Option B: On Physical Android Device (e.g., Samsung Galaxy S24):
```bash
cd mobile_app
flutter run -d <DEVICE_ID> --dart-define=QDS_GATEWAY_HOST=<HOST_LAN_IP>
```
**Setup Flow for Client X:**
1. Progress through the 3-step Onboarding.
2. In Role Selection, choose **Sender (X)**.
3. Enter Display Name: `Alice (X)` and tap **Continue**.
4. The Home screen opens; the Gateway status indicator turns green (**Connected**).

---

### STEP 3: Launch Client Y (Receiver)
Option A: In Android Emulator:
```bash
cd mobile_app
flutter run -d emulator-5554 --dart-define=QDS_GATEWAY_HOST=10.0.2.2
```
Option B: On Physical Device (when gateway is on LAN):
```bash
cd mobile_app
flutter run -d <DEVICE_ID_Y> --dart-define=QDS_GATEWAY_HOST=<HOST_LAN_IP>
```
**Setup Flow for Client Y:**
1. Progress through the 3-step Onboarding.
2. In Role Selection, choose **Receiver (Y)**.
3. Enter Display Name: `Bob (Y)` and tap **Continue**.
4. The Home screen opens; the Gateway status indicator turns green (**Connected**).

---

### STEP 4: Demonstrate Legitimate Messaging & Verification
1. On **Client X**: Tap **Start Conversation with Receiver Y**.
2. Type: `"Quantum key distribution test 101"` and tap **Send**.
3. **Observe Client X:**
   - Message initially shows sending status.
   - Message updates to `delivered` upon receiving gateway acknowledgment (`ACK`).
   - Message displays compact `✓ Verified` badge.
4. **Observe Client Y:**
   - Message appears immediately with `✓ Verified` indicator.
   - Tap the message or verification badge to open **Verification Summary Sheet**.
   - Tap **View Full Verification Details** to see:
     - Final Decision: `TRUSTED`
     - Classical Signature: `Valid`
     - Quantum Verification: `Valid`
     - Replay Check: `Passed`
     - Quantum Swap-Test Accuracy: `~98% - 99%`
5. **Observe Security Center:**
   - Navigate to the **Security** tab on either device.
   - Global status shows **Trusted** with the verified audit log entry.

---

### STEP 5: Demonstrate Reverse Messaging (Role Independence)
1. On **Client Y**: Type reply `"Transmission received and quantum fidelity confirmed."` and tap **Send**.
2. **Observe Client X:**
   - Message appears cleanly without duplication.
   - Verified status and telemetry are attached.
   - Proves the single codebase functions symmetrically regardless of user role.

---

### STEP 6: Demonstrate Attack #1 — Classical Forgery Attack
Open Terminal 2 in the repository root directory:
```bash
python -m attack_console --target ws://127.0.0.1:8000/ws --attack forgery
```
*(Use `--host <HOST_LAN_IP>` if running across LAN).*

**Observable Behavior:**
1. **Attack Console Terminal:**
   ```text
   Attack:                    Forgery
   Final Decision:            INVALID / SUSPICIOUS
   Detected Type:             FORGERY_OR_IMPERSONATION
   Classical Signature Valid: False
   ```
2. **Client Y (Receiver UI):**
   - A non-intrusive **Threat Alert Banner** slides in at the top of the screen:
     - Headline: `Signature Forgery Detected`
     - Factual description: `Classical digital signature failed validation.`
   - In Chat: The incoming forged message is styled with an amber/red threat border and a `⚠ Security warning` chip.
   - Tap **View Details**:
     - Status: `THREAT DETECTED`
     - Classification: `Forgery / Impersonation`
     - Classical Signature: `Invalid`

---

### STEP 7: Demonstrate Attack #2 — Impersonation Attack
In Terminal 2:
```bash
python -m attack_console --target ws://127.0.0.1:8000/ws --attack impersonation
```
**Observable Behavior:**
- Attacker Eve signs a packet claiming to be Alice (X).
- Classical verification against Alice's registered public key fails.
- Client Y displays `Signature Forgery Detected` / `Impersonation Detected`.
- Security Center records an audit event under the **Threats** filter.

---

### STEP 8: Demonstrate Attack #3 — Replay Attack
In Terminal 2:
```bash
python -m attack_console --target ws://127.0.0.1:8000/ws --attack replay
```
**Observable Behavior:**
1. First packet is accepted as legitimate.
2. Second packet (replayed with identical `signature_id`) is caught by the research core's `ReplayDetector`.
3. **Attack Console Terminal:**
   ```text
   Attack:                    Replay
   Final Decision:            INVALID / SUSPICIOUS
   Detected Type:             REPLAY
   Replay Detected:           True
   ```
4. **Client Y (Receiver UI):**
   - Threat Alert Banner: `Replay Detected`.
   - Message Bubble: Marked as `Verification failed`.
   - Tap details: Dedicated `ThreatDetectionCard` highlights:
     - `Replay detection: Detected`
     - Evidence explains the nonce or hash was previously recorded in the session registry.

---

### STEP 9: Demonstrate Attack #4 — Quantum Channel Manipulation
In Terminal 2:
```bash
python -m attack_console --target ws://127.0.0.1:8000/ws --attack channel
```
**Observable Behavior:**
1. The packet retains a valid classical Ed25519 signature, but its quantum state measurements have been disturbed by Pauli channel noise.
2. **Attack Console Terminal:**
   ```text
   Attack:                    Channel Manipulation
   Final Decision:            INVALID / SUSPICIOUS
   Detected Type:             CHANNEL_ATTACK
   Classical Signature Valid: True
   QDS Verification Valid:    False
   Verification Accuracy:     ~60% - 65% (below threshold)
   ```
3. **Client Y (Receiver UI):**
   - Status: `SUSPICIOUS`.
   - Threat Alert Banner: `Channel Manipulation Detected`.
   - Verification Details shows:
     - Classical Signature: `Valid` (distinguishing classical crypto from quantum telemetry)
     - QDS Quantum Verification: `Invalid`
     - Swap fidelity below 0.95 threshold.

---

### STEP 10: Demonstrate Resilience & Recovery
1. **Dismiss Threat Alert**: Tap the close (`×`) icon on the banner; notice the banner dismisses and does not repeatedly popup on page rebuilds.
2. **Role Reset / Switch**: Navigate to **Profile** $\to$ **Reset Identity**. Switch from Sender X to Receiver Y. Notice stored credentials update and the socket re-registers without restarting the app.
3. **Gateway Disconnection**: Stop the gateway (`Ctrl+C` in Terminal 1).
   - Flutter app reflects disconnected/reconnecting state gracefully.
   - No app crashes or unhandled exceptions occur.
   - Outgoing messages transition to failed delivery state.
   - Restarting the gateway automatically re-establishes connectivity and registers the participant session.

---

## 4. Troubleshooting

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| Gateway shows offline on Android emulator | Android emulator localhost loopback | Connect using `10.0.2.2:8000` via `--dart-define=QDS_GATEWAY_HOST=10.0.2.2`. |
| Physical phone cannot connect to gateway | Firewall or wrong IP | 1. Ensure phone and PC are on the same Wi-Fi network.<br>2. Run `ipconfig` to obtain the correct IPv4 address.<br>3. Allow port 8000 in Windows Defender Firewall.<br>4. Pass `--dart-define=QDS_GATEWAY_HOST=<HOST_LAN_IP>`. |
| Port 8000 already in use | Previous gateway process running | Terminate old Python process: `taskkill /F /IM python.exe` (Windows) or use a different port `--port 8080`. |
| Message shows "Sending" indefinitely | WebSocket disconnected | Check gateway terminal log to confirm client registration was received. |
