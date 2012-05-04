setup_dlas_common;

[wavelengths, flux, noise_variance, redshift] = ...
    read_fits_data(filename(plate, mjd, fiber));

num_points = numel(wavelengths);

train_x = wavelengths;
train_y = flux;

skip = 5;
train_x = train_x(1:skip:end);
train_y = train_y(1:skip:end);
noise_variance = noise_variance(1:skip:end);

train_x = [train_x (1:numel(train_x))'];
test_x  = train_x;

spectrum_mean_function = {@meanConst};

spectrum_continuum_covariance_function = {@covMaterniso, 3};
spectrum_noise_covariance_function = {@covConstMatrix, 0 * diag(noise_variance)};
spectrum_covariance_function = ...
    {@covSum, ...
     {{@covMask, {1, spectrum_continuum_covariance_function}}, ...
      {@covMask, {2, spectrum_noise_covariance_function}}}};

likelihood       = @likGauss;
inference_method = @infExact;

hyperparameters.lik  = log(1 / 4); %[log(3); log(1 / 4)];
hyperparameters.mean = median(flux);
hyperparameters.cov  = [log(500); log(1)];

learned = minimize(hyperparameters, @gp_likelihood, -70, inference_method, ...
                   spectrum_mean_function, spectrum_covariance_function, ...
                   likelihood, train_x, train_y);

[~, ~, continuum_mean, continuum_variance, ~, continuum_negativelog_likelihood] = ...
    gp_test(learned, inference_method, spectrum_mean_function, ...
            spectrum_covariance_function, likelihood, train_x, train_y, ...
            test_x);

b_mean_function = {@meanScale, {@meanDrift, {@meanVoightProfile}}};
mean_function = ...
    {@meanSum, ...
     {f_mean_function, b_mean_function} ...
    };

b_covariance_function = {@covDrift, {@covMaterniso, 3}};
covariance_function = {@covSum, ...
                       {f_covariance_function, b_covariance_function} ...
                      };

% hyperparameters.lik        = learned.lik;
% hyperparameters.mean(1)    = learned.mean(1);
% hyperparameters.cov([1 5]) = learned.cov(1);
% hyperparameters.cov(2) = learned.cov(2);
% hyperparameters.cov(6) = log(1 / 4);

% ll = @(sample) log_likelihood_helper(hyperparameters, inference_method, ...
%         mean_function, covariance_function, likelihood, train_x, ...
%         train_y, sample(1), sample(2), sample(3));

% start_times = linspace(wavelengths(floor(end / 10)), wavelengths(floor(end / 2)), 50);
% widths = log(linspace(300, 1200, 10));
% depths = linspace(1, 5, 10);

% log_likelihoods = [];
% samples = [];

% best = -no_dla_log_likelihood;

% for start_time = start_times
%   for width = widths
%     for depth = depths
%       sample =  [depth start_time width];
%       samples = [samples; sample];

%       log_likelihood = ll(sample);
%       log_likelihoods = [log_likelihoods; log_likelihood];

%       if (log_likelihood > best)
%         best = log_likelihood;
%         [start_time exp(width) depth log_likelihood]
%       end
%     end
%   end
% end