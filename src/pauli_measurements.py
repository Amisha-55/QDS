from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator


def measure_state(basis, state=0, shots=1000):

    qc = QuantumCircuit(1, 1)

    if state == 1:
        qc.x(0)

    if basis == "X":
        qc.h(0)

    elif basis == "Y":
        qc.sdg(0)
        qc.h(0)

    elif basis == "Z":
        pass

    else:
        raise ValueError("Basis must be X, Y, or Z")

    qc.measure(0, 0)

    simulator = AerSimulator()
    result = simulator.run(qc, shots=shots).result()
    counts = result.get_counts()

    return counts


print("========================================")
print("     PAULI EIGENSTATE MEASUREMENTS")
print("========================================")

for basis in ["X", "Y", "Z"]:

    counts = measure_state(basis, state=0)

    print(f"\n{basis}-BASIS MEASUREMENT")
    print("State: |0>")
    print("Measurement Results:")
    print(counts)

    total = sum(counts.values())
    probability_0 = counts.get("0", 0) / total
    probability_1 = counts.get("1", 0) / total

    print(f"P(0): {probability_0:.3f}")
    print(f"P(1): {probability_1:.3f}")