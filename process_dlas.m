data_directory = '~/work/data/astronomy/quasars/processed/';
load([data_directory 'quasars.mat']);

train_x = wavelengths(:);
[num_points, d] = size(train_x);

train_y = data(end, :);
train_y = train_y(:);

test_x = train_x;

fault_shape = linspace(-1, 1).^2 - 1;

likelihood = @likLaplace;
mean_function = {@meanSum, {@meanConst, {@meanScale, {@meanDrift, fault_shape}}}};
covariance_function = ...
    {@covSum, { ...
        {@covMaterniso, 3}, ...
        {@covDrift, {@covMaterniso, 3}} ...
              }
     };
inference_method = @infLaplace;

latent_prior_mean_prior_mean = mean(train_y);
latent_prior_mean_prior_variance = 1;

fault_scaling_prior_mean = 15;
fault_scaling_prior_variance = 2;

fault_width_prior_mean = log(15);
fault_width_prior_variance = (1 / 2)^2;

length_scale_prior_mean = log(15);
length_scale_prior_variance = 1;

output_scale_prior_mean = log(1);
output_scale_prior_variance = 1;

fault_length_scale_prior_mean = log(15);
fault_length_scale_prior_variance = 1;

fault_output_scale_prior_mean = log(1 / 2);
fault_output_scale_prior_variance = (1 / 2)^2;

noise_scale_prior_mean = log(1);
noise_scale_prior_variance = (1 / 2)^2;

hypersamples.prior_means = ...
    [latent_prior_mean_prior_mean ...
     fault_scaling_prior_mean ...
     fault_width_prior_mean ...
     length_scale_prior_mean ...
     output_scale_prior_mean ...
     fault_length_scale_prior_mean ...
     fault_output_scale_prior_mean ...
     noise_scale_prior_mean ...
    ];

hypersamples.prior_variances = ...
    [latent_prior_mean_prior_variance ...
     fault_scaling_prior_variance ...
     fault_width_prior_variance ...
     length_scale_prior_variance ...
     output_scale_prior_variance ...
     fault_length_scale_prior_variance ...
     fault_output_scale_prior_variance ...
     noise_scale_prior_variance ...
    ];

values = find_ccd_points(hypersamples.prior_means, ...
                         hypersamples.prior_variances);
num_hypersamples = size(values, 1);

hypersamples.likelihood_ind = 9;
hypersamples.mean_ind = 1:4;
hypersamples.covariance_ind = [5:6 3:4 7:8];
hypersamples.marginal_ind = [1:2 4:9];

hyperparameters.lik = NaN;
hyperparameters.mean = nan(4, 1);
hyperparameters.cov = nan(6, 1);

[~, inference_method, mean_function, covariance_function, likelihood] ...
    = check_gp_arguments(hyperparameters, inference_method, ...
                         mean_function, covariance_function, likelihood, ...
                         data, responses);

best_means = zeros(num_points, num_points);
best_variances = zeros(num_points, num_points);
best_log_likelihoods = zeros(num_points, 1);
start_times = zeros(num_points, 1);
widths = zeros(num_points, 1);

for fault_start_ind = 316:num_points

  fault_start_times = wavelengths(fault_start_ind) * ones(num_hypersamples, 1);

  hypersamples.values = ...
      [values(:, 1:2) ...
       fault_start_times ...
       values(:, 3:end) ...
      ];

  [latent_means, latent_variances, hypersample_weights, log_likelihoods] = ...
      estimate_latent_posterior(train_x, train_y, test_x, inference_method, ...
                                mean_function, covariance_function, ...
                                likelihood, hypersamples);

  b_function = {@meanScale, {@meanDrift, fault_shape}};

  for i = 1:num_hypersamples
    latent_means(i, :) = latent_means(i, :) - ...
        feval(b_function{:}, hypersamples.values(i, 2:4), test_x)';
  end

  [~, best_hypersample] = max(hypersample_weights);

  best_means(ind, :) = latent_means(best_hypersample, :);
  best_variances(ind, :) = latent_variances(best_hypersample, :);
  best_log_likelihoods(ind) = log_likelihoods(best_hypersample);
  start_times(ind) = hypersamples.values(best_hypersample, 3);
  widths(ind) = exp(hypersamples.values(best_hypersample, 4));

  fault_start_ind
end
