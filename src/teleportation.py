from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator

# 3 qubits:
# q0 = state to teleport
# q1, q2 = entangled Bell pair
qc = QuantumCircuit(3, 3)

# ------------------------------------------------
# 1. Prepare the state to be teleported
# ------------------------------------------------
qc.x(0)

# ------------------------------------------------
# 2. Create Bell pair between q1 and q2
# ------------------------------------------------
qc.h(1)
qc.cx(1, 2)

# ------------------------------------------------
# 3. Alice entangles q0 with q1
# ------------------------------------------------
qc.cx(0, 1)
qc.h(0)

# ------------------------------------------------
# 4. Measure Alice's two qubits
# ------------------------------------------------
qc.measure(0, 0)
qc.measure(1, 1)

# ------------------------------------------------
# 5. Bob applies Pauli corrections
# ------------------------------------------------
with qc.if_test((qc.clbits[1], 1)):
    qc.x(2)

with qc.if_test((qc.clbits[0], 1)):
    qc.z(2)

# ------------------------------------------------
# 6. Measure Bob's qubit
# ------------------------------------------------
qc.measure(2, 2)

print("Quantum Teleportation Circuit:")
print(qc)

# Run simulation
simulator = AerSimulator()
result = simulator.run(qc, shots=1000).result()

counts = result.get_counts()

print("\nMeasurement Results:")
print(counts)