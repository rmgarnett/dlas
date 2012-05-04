num_samples_per_quasar = 1;

setup_dlas_common;

load([processed_directory 'file_list']);
num_quasars = size(file_list, 1);

num_samples = num_quasars * num_samples_per_quasar;

data = zeros(num_samples, 2);
flux = zeros(num_samples, 1);

for i = 1:num_quasars
  start = tic;
  
  plate              = file_list(i, 1);
  mjd                = file_list(i, 2);
  fiber              = file_list(i, 3);
  [wavelengths, this_flux, ~, redshift] = ...
      read_fits_data(filename(plate, mjd, fiber));
  
  this_flux = this_flux / sum(max(this_flux, 0));
  
  num_points = numel(wavelengths);
  r = randperm(num_points);
  samples = r(1:num_samples_per_quasar);
  
  range = (1 + (i - 1) * num_samples_per_quasar):(i * num_samples_per_quasar);
  
  data(range, :) = [wavelengths(samples), ...
                    redshift * ones(num_samples_per_quasar, 1)];
  flux(range)    = this_flux(samples);
  
  elapsed = toc(start);
  fprintf('%i of %i done, took %0.3fs.\n', i, num_quasars, elapsed);
end