# Mathematical & Theoretical Security Formulation

## 1. Introduction & Security Paradigm
In post-quantum cryptography, computational hardness assumptions (e.g., discrete logarithm, integer factorization) are vulnerable to polynomial-time quantum algorithms like Shor's Algorithm. **Quantum Digital Signatures (QDS)** provide **Information-Theoretic Security (ITS)** rooted in the fundamental laws of quantum physics:
- **No-Cloning Theorem**: Unknown quantum states cannot be cloned with unit fidelity ($\mathcal{F} < 1$).
- **Heisenberg Uncertainty Principle**: Measurement in non-commuting mutually unbiased bases (MUBs) creates unavoidable disturbance.
- **Quantum Teleportation**: Exact state transmission via EPR entanglement and classical feed-forward correction.

---

## 2. Quantum Teleportation Protocol Formulation

Let the state to be signed and teleported by Alice be an arbitrary Pauli eigenstate $|\psi\rangle \in \mathcal{H}_2$:
$$|\psi\rangle = \alpha |0\rangle + \beta |1\rangle$$
where $|\alpha|^2 + |\beta|^2 = 1$.

### Step 2.1: Entanglement Generation (EPR Pair)
Alice and Bob share a maximally entangled Bell pair $|\Phi^+\rangle_{12}$ generated via Hadamard and CNOT gates:
$$|\Phi^+\rangle_{12} = \frac{1}{\sqrt{2}} \left( |00\rangle_{12} + |11\rangle_{12} \right)$$

The joint state of the 3-qubit composite system $|\Psi\rangle_{012} \in \mathcal{H}_0 \otimes \mathcal{H}_1 \otimes \mathcal{H}_2$ is:
$$|\Psi\rangle_{012} = |\psi\rangle_0 \otimes |\Phi^+\rangle_{12} = \frac{1}{\sqrt{2}} (\alpha |0\rangle + \beta |1\rangle) \otimes (|00\rangle + |11\rangle)$$

Expanding into the Bell basis for Alice's qubits $(0, 1)$:
$$|\Psi\rangle_{012} = \frac{1}{2} \Big[ |\Phi^+\rangle_{01} (\alpha |0\rangle + \beta |1\rangle)_2 + |\Phi^-\rangle_{01} (\alpha |0\rangle - \beta |1\rangle)_2 + |\Psi^+\rangle_{01} (\beta |0\rangle + \alpha |1\rangle)_2 + |\Psi^-\rangle_{01} (-\beta |0\rangle + \alpha |1\rangle)_2 \Big]$$

### Step 2.2: Bell State Measurement (BSM) & Classical Feed-Forward
Alice applies $\text{CNOT}_{0 \to 1}$ followed by $H_0$ and measures classical outcomes $c_0, c_1 \in \{0, 1\}$. Depending on $(c_1, c_0)$, Bob's qubit 2 collapses to:
$$\rho_2 = \sigma_z^{c_0} \sigma_x^{c_1} |\psi\rangle \langle\psi| \sigma_x^{c_1} \sigma_z^{c_0}$$

Bob recovers the exact state $|\psi\rangle$ by applying the unitary Pauli correction:
$$U_{\text{corr}} = X^{c_1} Z^{c_0}$$
yielding an ideal fidelity:
$$\mathcal{F} = \langle\psi| U_{\text{corr}} \rho_2 U_{\text{corr}}^\dagger |\psi\rangle = 1.0$$

---

## 3. Information-Theoretic Forgery Bound

Let $N$ denote the number of signature qubits. Each bit is encoded into one of three mutually unbiased bases (MUBs):
$$\mathcal{B}_Z = \{|0\rangle, |1\rangle\}, \quad \mathcal{B}_X = \{|+\rangle, |-\rangle\}, \quad \mathcal{B}_Y = \{|+i\rangle, |-i\rangle\}$$

Where for any two distinct bases $\mathcal{B}_j, \mathcal{B}_k$:
$$|\langle \phi_j | \phi_k \rangle|^2 = \frac{1}{2}, \quad \forall j \ne k$$

### 3.1 Adversary Basis Uncertainty
An eavesdropper or forging recipient (Eve/Bob) possesses zero information regarding the basis sequence chosen by Alice. If Eve intercepts or attempts to forge without the basis:
1. She chooses the correct basis with probability $P_{\text{correct}} = \frac{1}{3}$.
2. She chooses a mismatched basis with probability $P_{\text{wrong}} = \frac{2}{3}$.
3. In a mismatched basis, measurement outcome is completely random ($p = 0.5$).

Thus, the minimum expected error rate introduced by an unauthorized observer is:
$$\mathbb{E}[e_{\text{attack}}] = \frac{1}{3}(0) + \frac{2}{3}\left(\frac{1}{2}\right) = \frac{1}{3} \approx 33.33\%$$
Under an active intercept-resend attack across all bases, the average error rate escalates to $\approx 50\%$.

### 3.2 Hoeffding Inequality for Forgery Probability
Under the verification threshold $\tau$ with physical channel error $p_{\text{channel}} < \tau$, let $X_i \in \{0, 1\}$ be the independent error indicator for qubit $i$.
By Hoeffding's Inequality:
$$P\left( \frac{1}{N} \sum_{i=1}^N X_i \ge \tau \right) \le \exp\left( -2 N (\tau - p_{\text{channel}})^2 \right)$$

Hence, the probability of an unauthorized signature passing verification decays exponentially:
$$P_{\text{forgery}} \le \exp\left( -2 N \Delta^2 \right) = 2^{-\alpha N}$$
where $\Delta = \tau - p_{\text{channel}}$ is the calibrated security margin.

---

## 4. Likelihood Ratio Hypothesis Testing (Non-AI/ML Threat Identification)

To rigorously separate physical channel decoherence from malicious cyber tampering without heuristic AI, we implement a **Neyman-Pearson optimal Likelihood Ratio Test (LRT)**:

- **Null Hypothesis $\mathcal{H}_0$ (Benign Physical Noise):**
  $$P(k \mid \mathcal{H}_0) = \binom{S}{k} p_0^k (1 - p_0)^{S - k}, \quad p_0 \le 0.02$$
- **Alternative Hypothesis $\mathcal{H}_1$ (Adversarial Intervention):**
  $$P(k \mid \mathcal{H}_1) = \binom{S}{k} p_1^k (1 - p_1)^{S - k}, \quad p_1 \ge 0.50$$

The Log-Likelihood Ratio (LLR) over $S$ measurement shots is:
$$\Lambda = \ln \left( \frac{P(k \mid \mathcal{H}_1)}{P(k \mid \mathcal{H}_0)} \right) = k \ln\left(\frac{p_1}{p_0}\right) + (S - k) \ln\left(\frac{1 - p_1}{1 - p_0}\right)$$

### Decision Boundary:
- If $\Lambda > 0 \implies$ Reject $\mathcal{H}_0$, declare **CYBER THREAT (Tampering / Intercept-Resend)**.
- If $\Lambda \le 0 \implies$ Accept $\mathcal{H}_0$, declare **BENIGN CHANNEL / LEGITIMATE**.

---

## 5. Non-Repudiation Dual-Threshold Proof (Arbiter Charlie)

In a 3-party protocol (Alice, Bob, Arbiter Charlie):
- Bob verifies using threshold $s_v$.
- Charlie adjudicates using threshold $s_a$.

**Condition for Non-Repudiation Security:**
$$p_{\text{channel}} < s_v < s_a < 0.50$$

If Bob accepts a signature, the error rate $e_B \le s_v$. For Alice to successfully repudiate to Charlie, she would need Bob's forwarded measurement tokens to exhibit an error rate $e_C > s_a$ when evaluated by Charlie.

By the quantum symmetrization bound:
$$P_{\text{repudiate}} = P(e_B \le s_v \land e_C > s_a) \le \exp\left( -2 N (s_a - s_v)^2 \right)$$

Since $s_a - s_v > 0$, this repudiation probability is bounded by $O(2^{-N})$, providing **unconditional non-repudiation**.
