clear, clc
% let's generate some fake data for a simple correlation analysis
x = randn(100,1);
y = 0.3*x+randn(100,1);

% x = randn(100,4); % x could have more than one column 
% y = 0.2*x(:,1)+0.4*x(:,2)-0.1*x(:,3)+1.2*x(:,4)+randn(100,1);

ndata = length(y);
nfolds = 5; 
cv = balanced_cv(y, nfolds); % 5-fold balanced cross-validation (p>0.95 or highest in 10000 iters)
% cv = balanced_cv(y, nfolds, 1); % highest p in 10000 iters
% p_balance = anova1(y, cv); % p value of the main effect on group (fold) 


predicted_y = zeros(ndata,1);
for i = 1:nfolds
    training_x = x(cv~=i,:);
    training_y = y(cv~=i,:);
    ntraining = length(training_y);
    design = [ones(ntraining,1), training_x];
    b = pinv(design)*training_y;
%     b = glmfit(training_x,training_y,'normal');
    test_x = x(cv==i,:);
    predicted_y(cv==i) = b(1)+test_x*b(2:end);
end

r_true_predicted = corr(y, predicted_y); % correlation between predicted and true y
r_x_y = corr(x, y); % for comparison

%% permutation test
nperm = 1000;
r_perm_predicted = zeros(nperm, 1);
for perm = 1:nperm
    idx = randperm(ndata);
    y_perm = y(idx);
    cv_perm = cv(idx);
    predicted_y_perm = zeros(ndata,1);
    for i = 1:nfolds
        training_x = x(cv_perm~=i,:);
        training_y = y_perm(cv_perm~=i,:);
        ntraining = length(training_y);
        design = [ones(ntraining,1), training_x];
        b = pinv(design)*training_y;
%         b = glmfit(training_x,training_y,'normal');
        test_x = x(cv_perm==i,:);
        predicted_y_perm(cv_perm==i) = b(1)+test_x*b(2:end);
    end  
    r_perm_predicted(perm, 1) = corr(y_perm, predicted_y_perm);
end

p = sum(r_perm_predicted>=r_true_predicted)/nperm;