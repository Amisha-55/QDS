from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator


# Create a circuit with 2 qubits and 2 classical bits
qc = QuantumCircuit(2, 2)

# Step 1: Put qubit 0 into superposition
qc.h(0)

# Step 2: Entangle qubit 0 and qubit 1
qc.cx(0, 1)

# Step 3: Measure both qubits
qc.measure([0, 1], [0, 1])

# Display the circuit
print("Quantum Circuit:")
print(qc)

# Run the circuit on a quantum simulator
simulator = AerSimulator()

result = simulator.run(qc, shots=1000).result()

# Get measurement results
counts = result.get_counts()

print("\nMeasurement Results:")
print(counts)