function newts=regressCfdsfromTS(ts, confoundsmat)

if size(ts, 2)==size(confoundsmat, 1)
    disp('Regressors and ts have flipped dimensions, flipping regressors')
    confoundsmat=confoundsmat';    
end

newts = ts - (confoundsmat'-mean(confoundsmat')) * (pinv(confoundsmat'-mean(confoundsmat')) * ts'))';

end