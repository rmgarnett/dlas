close('all');

figure_directory = '~/work/papers/dlas/figures/';

plot_width  = 15;
plot_height = 6;

plot_min_z = 1;
plot_max_z = 5.5;
plot_min_p = 0;
plot_max_p = max(dla_redshift_prior_p) * 1.2;

make_function_plot(dla_redshift_prior_x, dla_redshift_prior_p, ...
                   [plot_min_z, plot_max_z, plot_min_p, plot_max_p], ...
                   'redshift ($z$)', '$p(z)$', ...
                   'northeast', plot_width, plot_height);
matlabfrag([figure_directory 'dla_redshift_prior']);

plot_min_z = convert_z(plot_min_z);
plot_max_z = convert_z(plot_max_z);
plot_max_p = plot_max_p / transition_wavelength;

make_function_plot(central_wavelength_prior_x, central_wavelength_prior_p, ...
                   [plot_min_z, plot_max_z, plot_min_p, plot_max_p], ...
                   'wavelength (\AA)', '$p(\text{central})$', ...
                   'northeast', plot_width, plot_height);
matlabfrag([figure_directory 'central_wavelength_prior']);

make_function_plot(minimum_value_prior_x, minimum_value_prior_p, ...
                   [-2, 2, 0, max(minimum_value_prior_p) * 1.2], ...
                   'flux (\fluxunits)', 'p(\text{minimum})', ...
                   'northeast', plot_width, plot_height);
matlabfrag([figure_directory 'minimum_value_prior']);