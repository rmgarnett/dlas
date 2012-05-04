close all;

make_gp_plot(train_x(:, 1), continuum_mean, continuum_variance, train_x(:, 1), train_y, ...
             [min(train_x(:, 1)) max(train_x(:, 1)) -5 12.5], 9, 'wavelength', ...
             'flux', 'northeast', 40, 15);

% [~, sorted_ind] = sort(log_likelihoods, 'descend');

% num_samples = 100;

% lls = zeros(1, num_samples);
% means = zeros(num_points, num_samples);
% variances = zeros(num_points, num_samples);

% dla_means = means;
% dla_variances = variances;

% for i = 1:num_samples
%   sample = samples(sorted_ind(i), :);

%   hyperparameters.mean(2) = sample(1);
%   hyperparameters.mean(3) = sample(2);
%   hyperparameters.mean(4) = sample(3);
%   hyperparameters.cov(3) = sample(2);
%   hyperparameters.cov(4) = sample(3);

%   [~, ~, means(:, i), variances(:, i), ~, lls(i)] = ...
%       gp_test(hyperparameters, inference_method, mean_function, ...
%               covariance_function, likelihood, train_x, train_y, test_x);

%   dla_covariance = feval(b_covariance_function{:}, ...
%                          hyperparameters.cov(3:end), train_x);

%   dla_variances(:, i) = diag(dla_covariance);

%   ind = (dla_variances(:, i) > 0);

%   dla_means(:, i) = means(:, i);
%   means(:, i) = means(:, i) - feval(b_mean_function{:}, ...
%           hyperparameters.mean(2:end), train_x);
% end

% lls = -lls;
% lls = lls - max(lls);

% weights = exp(lls);
% weights = weights / sum(weights);

% make_gp_plot(train_x, latent_mean, latent_variance, train_x, train_y, ...
%               [min(train_x) max(train_x) -5 12.5], 9, 'wavelength', ...
%               'flux', 'northeast', 17, 10);
% matlabfrag(['spectrum-' filename]);

% make_gp_plot(train_x(ind), dla_mean(ind), dla_variance(ind), ...
%              train_x, train_y, [min(train_x) max(train_x) -5 12.5], ...
%              9, 'wavelength', 'flux', 'northeast', 17, 10);
% matlabfrag(['dla-' filename]);
