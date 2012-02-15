data_directory = '~/work/data/astronomy/quasars/processed/';
load([data_directory 'quasars.mat']);

train_x = wavelengths(:);
d = size(train_x, 2);

train_y = data(end, :);
train_y = train_y(:);

test_x = train_x;

length_scale = log(20);
output_scale = log(2.5);

noise_scale = log(1);

fault_shape        = linspace(-1, 1).^2 - 1;
fault_length_scale = log(20);
fault_output_scale = log(2.5);
fault_start_time   = 1220;
fault_end_time     = 1235;
fault_scaling      = 20;

inference_method = @infExactFault;
mean_function = @meanConst;
covariance_function = {@covMaterniso, 3};
fault_covariance_function = {@covDrift, {@covSEiso}};
likelihood = @likGauss;

a_function = @meanOne;
b_function = {@meanScale, {@meanDrift, fault_shape}};

hyperparameters.mean = mean(train_y);
hyperparameters.cov = [length_scale; output_scale];
hyperparameters.lik = noise_scale;

hyperparameters.a = [];
hyperparameters.b = [fault_scaling; fault_start_time; fault_end_time];
hyperparameters.fault_covariance_function =...
    [fault_start_time; fault_end_time; fault_length_scale; fault_output_scale];

[hyperparameters inference_method mean_function covariance_function ...
 likelihood a_function b_function] = ...
    check_gp_fault_arguments(hyperparameters, inference_method, ...
                             mean_function, covariance_function, ...
                             likelihood, a_function, b_function, ...
                             fault_covariance_function, train_x);

[output_means output_variances ...
 latent_means latent_variances ...
 fault_means fault_variances] = ...
    gp_fault(hyperparameters, inference_method, mean_function, ...
             covariance_function, likelihood, a_function, b_function, ...
             fault_covariance_function, ...
             train_x, train_y, test_x);

close('all');

make_gp_plot(test_x, latent_means, sqrt(latent_variances), train_x, ...
             train_y, [min(wavelengths) max(wavelengths) 0 35], 7, ...
             'wavelength', 'energy', 'SouthWest', 45, 12);
title('latent function -- good');

make_gp_plot(test_x, output_means, sqrt(output_variances), train_x, ...
             train_y, [min(wavelengths) max(wavelengths) 0 35], 7, ...
             'wavelength', 'energy', 'SouthWest', 45, 12);
title('outputs');

make_gp_plot(test_x, fault_means + mean(train_y), sqrt(fault_variances), train_x, ...
             train_y, [min(wavelengths) max(wavelengths) 0 35], 7, ...
             'wavelength', 'energy', 'SouthWest', 45, 12);
title('fault contribution');

negative_log_likelihood = ...
    gp_fault(hyperparameters, inference_method, mean_function, ...
             covariance_function, likelihood, a_function, b_function, ...
             fault_covariance_function, train_x, train_y);

disp(['likelihood: ' num2str(-negative_log_likelihood)]);

fault_scaling_ind = 1;
fault_start_ind = 2;
fault_end_ind = 3;
length_scale_ind = 4;
output_scale_ind = 5;
%fault_length_scale_ind = 6;
%fault_output_scale_ind = 7;
%noise_ind = 8;
%mean_ind = 9;
noise_ind = 6;
mean_ind = 7;

transform_inds = [1 2 3 4 5 2 3 4 5 6 7];

prior = @(sample) ...
        normlike([10 5], sample(fault_scaling_ind)) + ...
        normlike([3 0.1], sample(length_scale_ind)) + ...
        normlike([0 1], sample(output_scale_ind)) + ...
        normlike([0 1], sample(noise_ind));

% normlike([3 0.1], sample(fault_length_scale_ind)) + ...
% normlike([0 1], sample(fault_output_scale_ind)) + ...

likelihood_function = @(sample) ...
    -prior(sample) + ...
    -gp_fault(rewrap(hyperparameters, ...
                     sample(transform_inds)'), ...
             inference_method, mean_function, ...
             covariance_function, likelihood, a_function, b_function, ...
             fault_covariance_function, train_x, train_y);

initial = unwrap(hyperparameters)';
initial = initial([1:5 8:end]);
width = [0.1 1 1 0.1 0.1 0.1 0.1 0.1 0.1];
num_samples = 500;
burn_in = 100;

samples = slicesample(initial, num_samples, 'logpdf', likelihood_function, ...
                      'width', width, 'burnin', burn_in);

mean_sample = mean(samples);

hyperparameters_sampled = rewrap(hyperparameters, ...
        mean_sample(transform_inds)');

[output_means output_variances ...
 latent_means latent_variances ...
 fault_means fault_variances] = ...
    gp_fault(hyperparameters_sampled, inference_method, mean_function, ...
             covariance_function, likelihood, a_function, b_function, ...
             fault_covariance_function, ...
             train_x, train_y, test_x);

make_gp_plot(test_x, latent_means, sqrt(latent_variances), train_x, ...
             train_y, [min(wavelengths) max(wavelengths) 0 35], 7, ...
             'wavelength', 'energy', 'SouthWest', 45, 12);
title('latent function -- good');

make_gp_plot(test_x, output_means, sqrt(output_variances), train_x, ...
             train_y, [min(wavelengths) max(wavelengths) 0 35], 7, ...
             'wavelength', 'energy', 'SouthWest', 45, 12);
title('outputs');

make_gp_plot(test_x, fault_means + mean(train_y), sqrt(fault_variances), train_x, ...
             train_y, [min(wavelengths) max(wavelengths) 0 35], 7, ...
             'wavelength', 'energy', 'SouthWest', 45, 12);
title('fault contribution');

negative_log_likelihood = ...
    gp_fault(hyperparameters_sampled, inference_method, mean_function, ...
             covariance_function, likelihood, a_function, b_function, ...
             fault_covariance_function, train_x, train_y);

disp(['likelihood: ' num2str(-negative_log_likelihood)]);

% latent_means     = zeros(num_samples, d);
% latent_variances = zeros(num_samples, d);
% output_means     = zeros(num_samples, d);
% output_variances = zeros(num_samples, d);
% fault_means      = zeros(num_samples, d);
% faukt_variances  = zeros(num_samples, d);

% for i = 1:num_samples
%   hyperparameter_sample = rewrap(hyperparameters, ...
%         [samples(i, 1:5)'; samples(i, 2:3)'; samples(i, 6:end)']);

%   [latent_means(:, i), latent_variances(:, i), ...
%    output_means(:, i), output_variances(:, i), ...
%    fault_means(:, i),  fault_variances(:, i)] = ...
%   gp_fault(hyperparameter_sample, inference_method, mean_function, ...
%            covariance_function, likelihood, a_function, b_function, ...
%            fault_covariance_function, ...
%            train_x, train_y, test_x);
% end