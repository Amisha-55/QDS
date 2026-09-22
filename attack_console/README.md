# QDS Attack Console

A command-line tool for demonstrating quantum-inspired digital signature attacks against the QDS Network Gateway. The console wraps the existing research algorithms under `src/` to simulate and dispatch attacks across WebSocket connections.

> **Note**: This is an academic research demonstration simulation, not a production exploitation framework.

---

## 1. How to Start the QDS Gateway

Before running the attack console, start the gateway server in a separate terminal:

```bash
python -m uvicorn server.main:app --host 0.0.0.0 --port 8000
```

The gateway listens on `ws://0.0.0.0:8000/ws` and provides real-time verification and routing.

---

## 2. How to Start the Attack Console

In a new terminal window, run:

```bash
python -m attack_console
```

Or target a remote or custom host:

```bash
python -m attack_console --host 127.0.0.1 --port 8000
# or via environment variable:
export QDS_GATEWAY_WS=ws://<LAPTOP_IP>:8000/ws
python -m attack_console
```

For automated testing or batch runs, use non-interactive mode:

```bash
python -m attack_console --attack forgery
python -m attack_console --attack impersonation
python -m attack_console --attack replay
python -m attack_console --attack channel
python -m attack_console --attack all
```

---

## 3. How to Select an Attack

When running interactively, the console presents the menu:

```
=====================================
         QDS ATTACK CONSOLE
=====================================
Target: ws://127.0.0.1:8000/ws

1. Forgery Attack
2. Impersonation Attack
3. Replay Attack
4. Channel Manipulation
5. Exit

Select attack (1-5):
```

---

## 4. How Attacks Reach the Existing QDS Pipeline

The attack console does not duplicate security algorithms. It directly invokes the existing research functions from `src/`:

1. **Forgery Attack** (`src/forgery_attack.py`):
   - Invokes `simulate_forgery(packet)`.
   - Modifies the plaintext message inside the packet without recomputing the Ed25519 signature.
   - The gateway validates Ed25519 classical authenticity $\rightarrow$ fails $\rightarrow$ classified as `FORGERY_OR_IMPERSONATION`.

2. **Impersonation Attack** (`src/impersonation_attack.py`):
   - Invokes `simulate_impersonation(message, claimed_signer_id)`.
   - Generates an unauthorized rogue keypair and signs the packet while claiming legitimate identity (`X`).
   - The gateway verifies against the sender's registered public key in `trusted_keys.py` $\rightarrow$ fails $\rightarrow$ classified as `FORGERY_OR_IMPERSONATION`.

3. **Replay Attack** (`src/replay_attack.py`):
   - Dispatches a legitimate packet once (accepted as `TRUSTED`).
   - Invokes `simulate_replay(packet)` to duplicate the exact same packet with identical `signature_id`.
   - The gateway's `check_replay()` flags the repeated UUID $\rightarrow$ classified as `REPLAY`.

4. **Channel Manipulation** (`src/channel_manipulation.py`):
   - Invokes `run_experiment(basis, attack="bit_flip")` on the quantum teleportation circuit.
   - Measures Pauli eigenstates under simulated bit-flip perturbation, dropping verification accuracy to 0.0.
   - Classical Ed25519 signature remains valid, but quantum integrity fails $\rightarrow$ classified as `CHANNEL_ATTACK`.

---

## 5. What Result the Console Displays

After each attack packet is evaluated by the QDS Gateway, the console displays the real cryptographic outputs returned by the research pipeline:

```
=====================================
          ATTACK RESULT
=====================================
Attack:                    Replay
Final Decision:            INVALID / SUSPICIOUS
Detected Type:             REPLAY
Classical Signature Valid: True
QDS Verification Valid:    True
Replay Detected:           True
Verification Accuracy:     0.9900
Error Rate:                0.0100
Quantum Shots Measured:    8000
=====================================
```
