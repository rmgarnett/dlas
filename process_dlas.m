data_directory = '~/work/data/astronomy/quasars/processed/';
load([data_directory 'quasars.mat']);

train_x = wavelengths(:);
[num_points, d] = size(train_x);

train_y = data(end, :);
train_y = train_y(:);
train_y = train_y - min(train_y);
train_y = train_y / max(train_y);

test_x = train_x;

fault_shape = linspace(-1, 1).^2 - 1;

likelihood = @likLaplace;
mean_function = ...
    {@meanSum, { ...
        @meanConst, ...
        {@meanScale, ...
            {@meanDrift, fault_shape} ...
        }
               }
    };
covariance_function = ...
    {@covSum, { ...
        {@covMaterniso, 3}, ...
        {@covDrift, {@covMaterniso, 3}} ...
              }
     };
inference_method = @infLaplace;
b_function = {@meanScale, {@meanDrift, fault_shape}};

hyperparameters.lik = nan;
hyperparameters.mean = nan(4, 1);
hyperparameters.cov = nan(6, 1);

[~, inference_method, mean_function, covariance_function, likelihood] ...
    = check_gp_arguments(hyperparameters, inference_method, ...
                         mean_function, covariance_function, likelihood, ...
                         data, responses);

prior_mean_mean              = median(train_y);
prior_mean_variance          = (1 / 20)^2;
fault_width_mean             = log(15);
fault_width_variance         = (1 / 4)^2;
fault_scaling_mean           = 0.5;
fault_scaling_variance       = (1 / 20)^2;
noise_scale_mean             = log(1 / 50);
noise_scale_variance         = (1 / 4)^2;
length_scale_mean            = log(15);
length_scale_variance        = (1 / 4)^2;
output_scale_mean            = log(1 / 20);
output_scale_variance        = (1 / 4)^2;
fault_length_scale_mean      = log(15);
fault_length_scale_variance  = (1 / 4)^2;
fault_output_scale_mean      = log(1 / 40);
fault_output_scale_variance  = (1 / 4)^2;

hypersamples.prior_means = ...
    [prior_mean_mean, ...
     fault_scaling_mean, ...
     fault_width_mean, ...
     noise_scale_mean, ...
     length_scale_mean, ...
     output_scale_mean, ...
     fault_length_scale_mean, ...
     fault_output_scale_mean];

hypersamples.prior_variances = ...
    [prior_mean_variance, ...
     fault_scaling_variance, ...
     fault_width_variance, ...
     noise_scale_variance, ...
     length_scale_variance, ...
     output_scale_variance, ...
     fault_length_scale_variance, ...
     fault_output_scale_variance];

ccd_hypersamples = ...
    find_ccd_points(hypersamples.prior_means, ...
                    hypersamples.prior_variances);

num_hypersamples = size(ccd_hypersamples, 1);

hypersamples.mean_ind = 1:4;
hypersamples.likelihood_ind = 9;
hypersamples.covariance_ind = [5:6 3:4 7:8];
hypersamples.marginal_ind = [1 5:9];

fault_start_times = wavelengths;
num_start_times = numel(fault_start_times);

all_latent_means = zeros(num_hypersamples, num_points, num_start_times);
all_latent_variances = zeros(num_hypersamples, num_points, num_start_times);
all_log_likelihoods = zeros(num_hypersamples, num_start_times);

for i = 1:num_start_times
  hypersamples.values = ...
      [ccd_hypersamples(:, 1:2) ...
       fault_start_times(i) * ones(num_hypersamples, 1) ...
       ccd_hypersamples(:, 3:end)];
  
  [latent_means, latent_variances, hypersample_weights, log_likelihoods] = ...
      estimate_latent_posterior(train_x, train_y, test_x, inference_method, ...
                                mean_function, covariance_function, ...
                                likelihood, hypersamples);

  for j = 1:num_hypersamples
    latent_means(j, :) = latent_means(j, :) - ...
        feval(b_function{:}, hypersamples.values(j, 2:4), ...
              test_x)';
  end

  all_latent_means(:, :, i)     = latent_means;
  all_latent_variances(:, :, i) = latent_variances;
  all_log_likelihoods(:, i)     = log_likelihoods;
  
  fprintf('time %4.2f: likelihood: %4.2f\n', fault_start_times(i), ...
          max(log_likelihoods));
end