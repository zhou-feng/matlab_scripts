function cv = balanced_cv(y, nfolds, pthresh, niter)
% this function is based on the constraint that the mean label value does not differ across folds according to a one-way ANOVA
% see Cohen et al., 2010.
% by default this script will break if p value>0.95 (pthresh)
% otherwise pick the best one in the 10000 iterations (niter)

% Written by Feng Zhou, 01/05/2021

if nargin < 4
    niter = 10000;
end

if nargin < 3 || isempty(pthresh)
% it's almost balanced when main effect of group has a p value of 0.95?
% could be higher or set to 1;
    pthresh = 0.95;
end


% % turn off cvpartition warning
% % returned by [a, MSGID] = lastwarn()
% warning('off', 'stats:cvpartition:KFoldMissingGrp')

ndata = length(y);
p_highest = 0; %initial p value
for iter = 1:niter
    CVO = cvpartition(ndata,'KFold',nfolds);
    cv_iter = zeros(ndata,1);
    for i = 1:nfolds
        cv_iter(CVO.test(i)) = i;
    end
    p_iter  = anova1(y, cv_iter, 'off');
    if p_iter > p_highest
        p_highest = p_iter;
        cv = cv_iter;
    end
    
    if p_highest > pthresh
        break
    end
    
    if iter == niter
        fprintf('\n no sufficient split found, returning best (p=%f) \n \n', p_highest)
    end
end