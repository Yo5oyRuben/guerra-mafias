import sys
print("Starting test...", file=sys.stderr)
try:
    import numpy
    print("Numpy imported successfully", file=sys.stderr)
except Exception as e:
    import traceback
    print("Error importing numpy:", file=sys.stderr)
    traceback.print_exc(file=sys.stderr)
