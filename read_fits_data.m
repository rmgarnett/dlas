function [wavelengths, flux, noise_variance, redshift] = ...
      read_fits_data(filename)

  measurements = fitsread(filename, 'binarytable', 1);

  wavelengths    = 10.^measurements{2};
  flux           = measurements{1};
  noise_variance = 1 ./ measurements{3};
  noise_variance(isinf(noise_variance)) = eps;
  
  measurements = fitsread(filename, 'binarytable', 2);

  redshift = measurements{20};
  
end