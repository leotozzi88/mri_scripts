function [connmat, volsremoved]=build_connmat_cifti(ciftiruns, tdfmotion, motionthresh, samplingrate, hpcutoff, gsr)
% This function builds connectivity matrices from parcellated CIFTI timeseries.
% It removes volumes that have motion above a specified threshold. A high-pass filter is applied to the data. It also performs grayordinate timeseries regression if requested.
% The script concatenates runs before computing the connectivity matrix.
% Input
% ciftiruns = a structure of filepaths for the runs to concatenate
% tdfmotion = a structure of filepaths of tab delimited files that are 1 column of motion
% parameters for each run
% motionthresh = the value of the motion parameter above which volumes are
% removed
% samplingrate = samplingrate (Hz) of the BOLD signal for filtering
% hpcutoff = value (Hz) for the highpass filter
% gsr = flag perform or not global signal regression (0 or 1)
% Output
% connmat = the connectivity matrix
% volsremoved = how many volumes were removed

for run=1:length(ciftiruns)
    
    disp(strcat('Processing',{' '}, ciftiruns{run}))
    
    if gsr==1
        disp('Doing GSR as requested')
    end
    
    % Initialise
    allruns=[];
    
    % Check if subject has motion files
    try
        % Load motion
        motion=dlmread(tdfmotion{run});
    catch
        disp(strcat(ciftiruns{run}, {' '}, 'is missing motion files'))
        continue
    end
    
    % Find volumes to remove
    run_rms_censor=motion>motionthresh;
    totmot=sum(run_rms_censor);
    disp(strcat(ciftiruns{run}, {' '}, 'total volumes discarded: ',{' '}, num2str(totmot)))
    volsremoved(run)=sum(run_rms_censor);
    
    % Check if subject has BOLD data
    try
        % Load timeseries
        rundatacif=ciftiopen(ciftiruns{run}, '/Applications/workbench/bin_macosx64/wb_command');
        rundata=rundatacif.cdata'; %ciftis have time on the columns
    catch
        disp(strcat(ciftiruns{run}, {' '}, 'is missing image files'))
        continue
    end
    
    % Consider doing mean grayordinate time series regression (MGTR, https://www.ncbi.nlm.nih.gov/pubmed/27571276)
    if gsr==1
        rundata=regressCfdsfromTS(rundata', mean(rundata, 2))';
    end
    
    % Filter, keeping high frequencies to not lose degrees of freedom
    rundata_f=highpass(rundata, hpcutoff, samplingrate); 
    
    % Censor motion
    rundata_fm=rundata_f;
    rundata_fm(run_rms_censor, :)=[];
    
    % Add data from run
    allruns=[allruns ; rundata_fm];
    
end

% Build connectivity matrix
connmat=corr(allruns);

end
