import numpy as np

# Create two 16x16 matrices
a = np.arange(1, 257).reshape(16, 16)
b = np.arange(1, 257).reshape(16, 16)

# Perform matrix multiplication
result = np.dot(a, b)

# Display the result
print("Matrix A:\n", a)
print("\nMatrix B:\n", b)
print("\nResult of A x B:\n", result)
