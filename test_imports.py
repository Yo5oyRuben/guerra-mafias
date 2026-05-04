#!/usr/bin/env python
import sys
import traceback

print("Python version:", sys.version)
print("=" * 72)

try:
    print("Importing numpy...", end=" ", flush=True)
    import numpy as np
    print("OK")
except Exception as e:
    print("FAILED")
    traceback.print_exc()
    sys.exit(1)

try:
    print("Importing matplotlib...", end=" ", flush=True)
    import matplotlib
    matplotlib.use('Agg')  # Use non-interactive backend
    import matplotlib.pyplot as plt
    print("OK")
except Exception as e:
    print("FAILED")
    traceback.print_exc()
    sys.exit(1)

try:
    print("Importing scipy.optimize...", end=" ", flush=True)
    from scipy.optimize import root
    print("OK")
except Exception as e:
    print("FAILED")
    traceback.print_exc()
    sys.exit(1)

try:
    print("Importing scipy.integrate...", end=" ", flush=True)
    from scipy.integrate import solve_ivp
    print("OK")
except Exception as e:
    print("FAILED")
    traceback.print_exc()
    sys.exit(1)

print("=" * 72)
print("All imports successful!")
