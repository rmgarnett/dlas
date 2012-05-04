setup_dlas_common;

num_density_points = 1000;

load([processed_directory 'concordance']);
num_quasars = size(concordance, 1);

[dla_redshift_prior_p, dla_redshift_prior_x] = ...
    ksdensity(concordance(:, 7), 'npoints', num_density_points);

central_wavelength_prior_x = convert_z(dla_redshift_prior_x);
central_wavelength_prior_p = dla_redshift_prior_p / transition_wavelength;

minimum_values = zeros(num_quasars, 1);
for i = 1:num_quasars
  plate              = concordance(i, 1);
  mjd                = concordance(i, 2);
  fiber              = concordance(i, 3);
  central_wavelength = convert_z(concordance(i, 7));

  [wavelengths, flux, noise_variance] = ...
      read_fits_data(filename(plate, mjd, fiber));

  [~, closest_ind] = min(abs(wavelengths - central_wavelength));
  minimum_values(i) = mean(flux(max(1, (closest_ind - 1)):(closest_ind + 1)));
end

[minimum_value_prior_p, minimum_value_prior_x] = ...
    ksdensity(minimum_values, 'npoints', num_density_points);

save([results_directory 'priors'], ...
     'dla_redshift_prior_x',       'dla_redshift_prior_p', ...
     'central_wavelength_prior_x', 'central_wavelength_prior_p', ...
     'minimum_value_prior_x',      'minimum_value_prior_p');