# Curated Experiments

Esta carpeta contiene lotes de simulaciones ya organizados por pregunta fisica.

Los ficheros originales siguen existiendo en `c_paper/out/raw/initial_plane`,
`c_paper/out/raw/initial_plane/parts`, `c_paper/out/plots/initial_plane` y
`c_paper/out/logs`. Aqui hay copias curadas para analisis.

## 2026-05-03_symmetric_N_scaling

Pregunta: comparar el limite bien mezclado y los puntos fijos analiticos al
aumentar `N1=N2`.

Contenido: 12 simulaciones.

Uso principal: referencia simetrica antes de estudiar efectos de asimetria.

## 2026-05-03_lowN_asymmetry_corrected

Pregunta: ver efectos de tamano finito y asimetria moderada `N1 != N2` sobre
la prediccion analitica.

Contenido: 12 simulaciones.

Uso principal: estudiar el limite termodinamico con tamanos pequenos y medianos.

Nota importante: este es el lote corregido tras arreglar las formulas de `B'` y
`E` para `N1 != N2`. Para analisis final, ignorar los lotes `lowNAsym` anteriores
a `20260503_181656`.

## 2026-05-03_highN_strong_asymmetry

Pregunta: explorar casos grandes y muy dispares, `N1:N2 = 1:3` y `3:1`.

Contenido: 4 simulaciones.

Uso principal: comparar con el lote de baja N y comprobar si la prediccion
analitica mejora al subir el tamano aunque haya asimetria fuerte.

## Estructura interna

Cada experimento tiene:

- `manifest.tsv`: parametros y rutas de cada simulacion.
- `notes.md`: descripcion breve del proposito del lote.
- `raw/`: ficheros unidos `initial_plane__*.txt`.
- `parts/`: parciales de ejecucion paralela.
- `plots/`: imagenes generadas con gnuplot.
- `logs/`: log de ejecucion de la cola.
