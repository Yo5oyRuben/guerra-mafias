# High-N strong asymmetry

Pregunta:
Explorar casos grandes y muy dispares, N1:N2 = 1:3 y 3:1, para comprobar como se comportan los puntos fijos analiticos.

Fuente:
- Manifest original: c_paper/out/logs/initial_plane_queue_highNAsym_20260503_184314.tsv
- Copiado el: 2026-05-03 19:33:25

Contenido:
- manifest.tsv: indice del lote.
- raw/: ficheros unidos de cada simulacion.
- parts/: parciales de la ejecucion paralela.
- plots/: figuras generadas con gnuplot.
- logs/: log de ejecucion de la cola.

Notas:
Lote con N=(200,600) y (600,200), ndiv=8, reps=3. Parametros p12 pequenos para mantener los puntos fijos dentro del cuadrado.

## highNAsymLarge aÃ±adido 2026-05-05 17:16:11

Se aÃ±aden mapas initial_plane con N mayores y asimetrÃ­a fuerte:
- N1/N2 = 400/1200 y 1200/400: escala 1:3 del caso original 200/600.
- N1/N2 = 300/1500 y 1500/300: asimetrÃ­a 1:5 para forzar diferencia de tamaÃ±os.
- En ambos casos se repiten los dos regÃ­menes previos: (P12,B)=(0.02,1.06) y (0.03,1.10).
- NDiv=8, NReps=3, Jobs=12.
- Manifest de la tanda: C:\Users\rbndz\Movistar Cloud\Ruben\3_FISICA\2_Cuatrimestre\Caos_y_SDNL\guerra-mafias\c_paper\out\logs\initial_plane_queue_highNAsymLarge_20260505_102858.tsv
