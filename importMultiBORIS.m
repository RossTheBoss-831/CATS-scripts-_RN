% importMultiBORIS

    % Run this script to import multiple Excel worksheets and export an
    % aggregated excel worksheet at the same file location.

    % Filepaths can be imported as a variable as a string array for each
    % file you wish to aggregate and load into Matlab

    % If you do not input the filepaths, it will ask you to select which
    % files you wish to aggregate

function data = importMultiBORIS(filepaths)

if nargin < 1
    [files, path] = uigetfile('*.xlsx', 'MultiSelect','on');
    files = string(files);
    
    filepaths = strings(length(files),1);

    for ii = 1:length(filepaths)
        filepaths(ii) = strcat(path,files(ii));
    end
end


% Create Data Table
    data = table(); % Data export Table 

% Cycle through and load data - Comments need to be cleaned while importing
for tt = 1:length(filepaths)
    data_temp = readtable(filepaths(tt));
    data_temp.CommentStart = num2cell(data_temp.CommentStart); % Transcribe to consistant format
    data_temp.CommentStop = num2cell(data_temp.CommentStop); % Transcribe to consistant format
    data_temp.Description = num2cell(data_temp.Description); % Transcribe to consistant format

    data = [data;data_temp];
end

% Clean Data Table and Convert to usable variables
    data.ObservationId = cellfun(@string,data.ObservationId);
    data.ObservationDate = cellfun(@datetime,data.ObservationDate);
    data.ObservationType = cellfun(@string,data.ObservationType);
    data.Source = cellfun(@string,data.Source);
    data.TotalDuration = cellfun(@str2num,data.TotalDuration);
    data.MediaDuration_s_ = cellfun(@str2num,data.MediaDuration_s_);
    data.FPS_frame_s_ = cellfun(@str2num,data.FPS_frame_s_);
    data.Subject = cellfun(@string,data.Subject);
    data.Behavior = cellfun(@string,data.Behavior);
    data.BehavioralCategory = cellfun(@string,data.BehavioralCategory);
    data.BehaviorType = cellfun(@string,data.BehaviorType);
    data.Start_s_ = cellfun(@str2num,data.Start_s_);
    data.Stop_s_ = cellfun(@str2num,data.Stop_s_);
    % Deal with Durations that are listed as 'NA' for POINT markers
    try data.Duration_s_ = cellfun(@str2num,data.Duration_s_); 
    catch
        Duration_s_ = zeros(numel(data.Duration_s_),1);
        for ii = 1:numel(data.Duration_s_)
            if string(data.Duration_s_(ii)) == "NA"
               Duration_s_(ii,1) = nan;
            else
               Duration_s_(ii,1) = str2double(data.Duration_s_{ii});
            end
        end
    data.Duration_s_ = Duration_s_;
    end
    data.MediaFileName = cellfun(@string,data.MediaFileName);    
    data.CommentStart = cellfun(@string,data.CommentStart);
    data.CommentStart(ismissing(data.CommentStart)) = ""; % Remove Missing Values, replace with empty strings
    data.CommentStop = cellfun(@string,data.CommentStop);
    data.CommentStop(ismissing(data.CommentStop)) = ""; % Remove Missing Values, replace with empty strings

% Export Data Table
    % writetable(data,strcat(path,'BORISdata_Aggregate.xlsx'));



end