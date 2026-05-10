# Torre boundary robustness checks at B=1.15, TMAX400k

Pregunta:
Are selected near-boundary signals stable with higher replication?

Fuente:
- Manifest original: C:\simulaciones\guerra-mafias\c_paper\out\logs\initial_plane_queue_torreCriticalBoundaryRobustT400k_20260509_171711.tsv
- Copiado el: 2026-05-09 22:14:53

Contenido:
- manifest.tsv: indice del lote.
- raw/: ficheros unidos de cada simulacion.
- parts/: parciales de la ejecucion paralela.
- plots/: figuras generadas con gnuplot.
- logs/: log de ejecucion de la cola.

Notas:
T_MAX = 400000
N1 = N2 = 500
B = 1.15
R = 0
E = -0.4
NDiv = 8
NReps = 5
Points:
- P12 = 0.21, P11 = P22 = 0.80
- P12 = 0.22, P11 = P22 = 0.80
- P12 = 0.22, P11 = P22 = 0.82
- P12 = 0.23, P11 = P22 = 0.86
Purpose: higher-statistics checks near the inferred boundary.
