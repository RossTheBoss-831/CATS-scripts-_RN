% BORIS Bubble Net Feeding Analysis

% Includes loading the BORIS Audit, as well as the TimeSync correction file

% Input: BORIS_dir -> Directory where BORIS data files and TimeSync Files
% are located.

function BORIS_BNF = BORIS_BNF_analysis(prh,lunges,BORIS_path)

% If BORIS path not included, ask for it
if isempty(BORIS_path)
    [~,BORIS_path] = uigetfile('*.xlsx;*.mat','Title','Select Any Video from Deployment');
end

% Get File list at directory
direct = dir(BORIS_path);
filelist = find(~cellfun(@isempty,strfind({direct.name},'.xlsx'))  + ~cellfun(@isempty,strfind({direct.name},'.mat')));
BORIS_files = string({direct(filelist).name})';

% Get BORIS file of deployment
pattern1 = [prh.INFO.whaleName, '.*.xlsx'];
matches1 = regexp(BORIS_files, pattern1, 'match');
BORIS_audit_idx = find(~cellfun(@isempty, matches1));

% Get BORIS timesync file of deployment
pattern2 = [prh.INFO.whaleName, '_TimeSync.mat'];
matches2 = regexp(BORIS_files, pattern2, 'match');
BORIS_TimeSync_idx = find(~cellfun(@isempty, matches2));

% Load Files
try BORIS_audit = importMultiBORIS(strcat(BORIS_path, BORIS_files(BORIS_audit_idx)));
catch disp(['no BORIS Audit found for: ', prh.INFO.whaleName]) 
    BORIS_BNF = table();
    return
end

try BORIS_TimeSync = load([BORIS_path, char(BORIS_files(BORIS_TimeSync_idx))]);
catch disp(['no BORIS TimeSync found for: ', prh.INFO.whaleName])
end

% Perform TimeSync Correction
if exist('BORIS_TimeSync','var')
    % Create BORIS table with corrected values
    BORIS = [];
else
    % Load BORIS without Correction
    [BORIS, Video] = BORIS2PRH(BORIS_audit,prh.INFO,prh.vidNam,prh.vidDN,prh.vidDurs,prh.DN);
end

% Analyses

% Total Feeding Rates during periods of Audit
    % Find the Lunges that occured only during when video was audited
    AllVideoIndex = [];
    for ii = 1:size(BORIS,1)
        R = BORIS.StartIndex(ii):BORIS.StopIndex(ii);
        AllVideoIndex = [AllVideoIndex;R'];
    end
    % Find common indicies of Lunges I and VideoI
    AllVideoLungesI = intersect(lunges.LungeI, AllVideoIndex);


% Total amount of Video Audited
TotalVideoAudted_s = sum(prh.camon)/prh.fs;

% Get Bubble events
BubbleEvents = BORIS(find(BORIS.Behavior == "Bubble Event"),:);

% Bubble Net Feeding Rates
N_BN = size(BubbleEvents,1); % Total number of Bubble Events
FRate_s_BN = size(BubbleEvents,1)/sum(Video.VidDurs); % Bubble Events per Second
FRate_m_BN = size(BubbleEvents,1)/(sum(Video.VidDurs)/60); % Bubble Events per Minute
FRate_h_BN = size(BubbleEvents,1)/((sum(Video.VidDurs)/60)/60); % BubbleEvents per Hour

% Bubble Net Duration Stats
MinDur_s_BN = min(BubbleEvents.Duration_s_); if isempty(MinDur_s_BN); MinDur_s_BN = NaN; end
MaxDur_s_BN = max(BubbleEvents.Duration_s_); if isempty(MaxDur_s_BN); MaxDur_s_BN = NaN; end
try MeanDur_s_BN = mean(BubbleEvents.Duration_s_); catch MeanDur_s_BN = NaN; end% 
try MedianDur_s_BN = median(BubbleEvents.Duration_s_); catch MedianDur_s_BN = NaN; end% 
try StdDur_s_BN = std(BubbleEvents.Duration_s_); catch StdDur_s_BN = NaN; end%

% All Lunges Feeding Rates
N_L = length(AllVideoLungesI); % Total number of Lunges during audited video
FRate_s_L = length(AllVideoLungesI)/sum(Video.VidDurs); % Lunges per Second
FRate_m_L = length(AllVideoLungesI)/(sum(Video.VidDurs)/60); % Lunges per Minute
FRate_h_L = length(AllVideoLungesI)/((sum(Video.VidDurs)/60)/60); % Lunges per Hour

% Stats for Bubble nets in 5 Second Threshold
BubbleEvents_th = BubbleEvents(find(BubbleEvents.Duration_s_ >= 5),:); % 5 Second Threshold
N_BNth = size(BubbleEvents_th,1); % Total number of Bubble Events in threshold
FRate_s_BNth = size(BubbleEvents_th,1)/sum(Video.VidDurs); % Bubble Events per Second
FRate_m_BNth = size(BubbleEvents_th,1)/(sum(Video.VidDurs)/60); % Bubble Events per Minute
FRate_h_BNth = size(BubbleEvents_th,1)/((sum(Video.VidDurs)/60)/60); % BubbleEvents per Hour

% Bubble Net Duration Stats - In threshold
MinDur_s_BNth = min(BubbleEvents_th.Duration_s_); if isempty(MinDur_s_BNth); MinDur_s_BNth = NaN; end
MaxDur_s_BNth = max(BubbleEvents_th.Duration_s_); if isempty(MaxDur_s_BNth); MaxDur_s_BNth = NaN; end
try MeanDur_s_BNth = mean(BubbleEvents_th.Duration_s_); catch MeanDur_s_BNth = NaN; end% 
try MedianDur_s_BNth = median(BubbleEvents_th.Duration_s_); catch MedianDur_s_BNth = NaN; end% 
try StdDur_s_BNth = std(BubbleEvents_th.Duration_s_); catch StdDur_s_BNth = NaN; end% 

% Compile output data file
BORIS_BNF = table(string(prh.INFO.whaleName),TotalVideoAudted_s,N_BN,FRate_s_BN,FRate_m_BN,FRate_h_BN, ...
    MinDur_s_BN,MaxDur_s_BN,MeanDur_s_BN,MedianDur_s_BN,StdDur_s_BN, ...
    N_L,FRate_s_L,FRate_m_L,FRate_h_L, ...
    N_BNth,FRate_s_BNth,FRate_m_BNth,FRate_h_BNth, ...
    MinDur_s_BNth,MaxDur_s_BNth,MeanDur_s_BNth,MedianDur_s_BNth,StdDur_s_BNth, ...
    {BubbleEvents.Duration_s_});
% Name Output table Columns
BORIS_BNF.Properties.VariableNames{1} = 'Deployment ID';
BORIS_BNF.Properties.VariableNames{25} = 'BN Durations';



end