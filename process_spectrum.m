setup_dlas_common;

[wavelengths, flux, noise_variance] = ...
    read_fits_data(filename(plate, mjd, fiber));

test_x = wavelengths;

skip = 5;

wavelengths    = wavelengths(1:skip:end);
flux           = flux(1:skip:end);
noise_variance = noise_variance(1:skip:end);

num_points = numel(wavelengths);

train_x = wavelengths;
train_y = flux;

likelihood          =  @likLaplace;
mean_function       = {@meanConst};
covariance_function = {@covMaterniso, 3};
inference_method    =  @infEP;

hyperparameters.lik  = nan;
hyperparameters.mean = nan(1);
hyperparameters.cov  = nan(2, 1);

[~, inference_method, mean_function, covariance_function, likelihood] ...
    = check_gp_arguments(hyperparameters, inference_method, ...
                         mean_function, covariance_function, likelihood, ...
                         train_x, train_y);

hyperparamters.mean = median(train_y);
hyperparamters.lik  = log(median(sqrt(noise_variance)));
hyperparamters.cov  = [log(1000); log(3)];

tic;
[~, ~, latent_mean, latent_variance] = ...
    gp_test(hyperparamters, inference_method, mean_function, ...
            covariance_function, likelihood, train_x, train_y, test_x);
toc;

% % spectrum mean
% prior_mean_mean       = mean(train_y);
% prior_mean_variance   = (prctile(train_y, 55) - ...
%                          prctile(train_y, 45))^2;

% % spectrum covariance
% length_scale_mean     = log(200);
% length_scale_variance = (1 / 4)^2;
% output_scale_mean     = log(1 / 2);
% output_scale_variance = (1 / 4)^2;

% % spectrum likelihood
% noise_mean            = log(1 / 4);
% noise_variance        = (1 / 4)^2;

% hypersamples.prior_means = ...
%     [prior_mean_mean, ...
%      length_scale_mean, ...
%      output_scale_mean, ...
%      noise_mean];

% hypersamples.prior_variances = ...
%     [prior_mean_variance, ...
%      length_scale_variance, ...
%      output_scale_variance, ...
%      noise_variance];

% hypersamples.values = ...
%     find_ccd_points(hypersamples.prior_means, ...
%                     hypersamples.prior_variances);

% num_hypersamples = size(hypersamples.values, 1);

% hypersamples.likelihood_ind = 4;
% hypersamples.mean_ind = 1;
% hypersamples.covariance_ind = 2:3;

% hypersamples.marginal_ind = 1:4;

% [latent_means, latent_variances, hypersample_weights, log_likelihoods] ...
%     = estimate_latent_posterior(train_x, flux, test_x, inference_method, ...
%         mean_function, covariance_function, likelihood, hypersamples);

% posterior_mean     = hypersample_weights' * latent_means;
% posterior_variance = hypersample_weights' * (latent_variances + latent_means.^2) - ...
%     posterior_mean.^2;

make_gp_plot(test_x, latent_mean, latent_variance, train_x, train_y, ...
             [min(wavelengths) max(wavelengths) -5 15], 9, 'wavelength', ...
             'flux', 'northeast', 40, 10);
