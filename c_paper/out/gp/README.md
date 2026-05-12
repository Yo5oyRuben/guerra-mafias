# Scripts de gnuplot

Esta carpeta contiene los scripts usados para regenerar las figuras principales a partir de los datos guardados.

- `plot_initial_plane.gp`: grafica planos de condiciones iniciales.
- `prepare_initial_plane_plot.ps1`: prepara los datos auxiliares usados por `plot_initial_plane.gp`.
- `plot_fig3_fig4_side_by_side.gp`: figura comparativa tipo Fig. 3/Fig. 4.
- `plot_fig3_horizontal.gp`: reconstruccion horizontal de la Fig. 3.
- `prepare_fig3_horizontal.ps1`: prepara datos auxiliares para `plot_fig3_horizontal.gp`.
- `plot_copy_probability_fig4_pp.gp`: comparacion de reglas de copia para la Fig. 4.
- `plot_critical_transition_p12_curves.gp`: curvas de transicion critica frente a `p11=p22`.
- `plot_symmetric_n_scaling_distance.gp`: escalado finito en `1/N`.

Los archivos temporales generados por gnuplot o por scripts auxiliares no forman parte del repositorio.
