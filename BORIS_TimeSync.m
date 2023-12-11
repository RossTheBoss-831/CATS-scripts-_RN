% BORIS_TimeSync

    % This script was made to correct BORIS audits performed on CATS tag
    % videos that consist of a data overlay, and where that data overlay
    % displays at the correct time synchronization to the displayed video.

    % This script is not limited to BORIS data, any media durations can be
    % input and the assocaited data overlay will be output. However, this
    % was crafted with BORIS audits in mind.

    % Required Toolboxes
        % Computer Vision
        % Statistics

    % INPUTS:
        % Obs_Media
            % n x 1 string array of Media File Names (ex. "mn201017-54 (03).mp4") related
            % to Durations Matrix. This matrix can include media names not
            % present in VidDir. Only videos matching those in VidDir will
            % be analyzed unless Process Input is set to "All".
        % Obs_Durations
            % n x 2 matrix of [Start Durations, End Durations] in seconds
            % These should be X seconds into the media duration
        % VidDir
            % n x 1 string array of full file paths of Video Directories
            % you would like to load in and analyze.
        % Process
            % Set to "All" if you would like all Videos in the VidDir
            % variable to be analyzed, rather than just videos that match
            % values in the BORIS media.
            % Setting to "All" will process metadata for the dataVid,
            % regardless if an Observation is found associated with that
            % video.
            % If you only wish to process videos present in both the Video
            % Directory and the Observation Media, leave this variable
            % blank: []

    % OUTPUTS
        % dataObs - Metadata related to each BORIS data observation entered
        % in INPUT. This variable maintains Index numbers of INPUT.
        % Unanalyzed Observations will be included in output with filler
        % data.
            % ObsMedia - Media file name that was processed for this Observation
            % ObsDuration_Start -  Original Start Duration from input variable BORIS_Durations
            % ObsDuration_Stop - Original Stop Duration from input variable BORIS_Durations
            % CorrDuration_Start - Corrected Duration (Observation StartTime - Video StartTime)
                % Video StartTime taken from the 'StartTime' variable from the Output dataVid table
            % StartTime - DURATION - Datetime of data overlay at ObsDuration_Start
            % StartTime_string - STRING - Datetime of data overlay at ObsDuration_Start
            % StartIndex - Index of data overlay at ObsDuration_Start
            % CorrDuration_End - Corrected Duration (Observation EndTime - Video StartTime)
                % Video StartTime taken from the 'StartTime' variable from the Output dataVid table
            % EndTime - DURATION - Datetime of data overlay at ObsDuration_End
            % EndTime_string - STRING - Datetime of data overlay at ObsDuration_End
            % EndIndex - Index of data overlay at ObsDuration_End
        % dataVid - Table of metadata related to each video analyzed
        	% Vid_Directory - Directory of Analyzed Video
	        % Media_Name - Media Name of analyzed Video
	        % StartMediaDuration - Video Duration in which media began (typically 0, unless black inital frames)
	        % StartTime - DURATION - Data time as displayed in data overlay at StartMediaDuration
	        % StartTime_string - STRING - Data time as displayed in data overlay at StartMediaDuration
	        % StartIndex - Index of data overlay at StartMediaDuration
	        % EndMediaDuration - Video Duration in which media ends (Final readable frame)
	        % EndTime - DURATION - Data time as displayed in data overlay at EndMediaDuration
	        % EndTime_string - STRING - Data time as displayed in data overlay at EndMediaDuration
	        % EndIndex - Index of data overlay at EndMediaDuration
	        % TotalVideoDuration - Total Duration of Video (As included in Video Object Variable, this may not equal EndMediaDuration - StartMediaDuration). This includes frames in which data overlay can not be read (black frames).
	        % Observation_indicies - Indicies of the Output dataObs that were analyzed in association with each video
        % Obsidx - Index of inputs BORIS_Media and BORIS_Durations that
            % were analyzed by this code

    % Current Bugs:
        % Duration Delta is not yet incorporated into an output

function [dataObs, dataVid, Obsidx] = BORIS_TimeSync(Obs_Media,Obs_Durations,VidDir,Process)

if ~exist('Process','var')
    Process = "BORIS";
end

% If no Video Directory Array was given, find all MP4 files in folder
    % of choice
if isempty(VidDir)
    [~,path] = uigetfile('*.mp4','Select Any Video from Deployment');
    direct = dir(path)
    filelist = ~cellfun(@isempty,strfind({direct.name},'.mp4')); % + ~cellfun(@isempty,strfind({direct.name},'.mov')
    VidDir = strings([sum(filelist),1])
    for ii = 1:sum(filelist)
        names = {direct(filelist).name};
        folders = {direct(filelist).folder};
        VidDir(ii,1) = strcat(folders{ii},'\',names{ii});
    end
end

% If No BORIS Arrays were included
if isempty(Obs_Media) || isempty(Obs_Durations)
    BORIS = importMultiBORIS;
    pat = '[a-z]{2}\d{6}-\d{1,2}[^\/\\]+.mp4';
    Obs_Media = regexp(BORIS.MediaFileName, pat, 'match');
    Obs_Media(cellfun(@isempty,Obs_Media)) = {""}; % Finds no Matches and replaces with empty string (Unprocessed vids will not match)
    if size(Obs_Media , 1) > 1
        Obs_Media = [Obs_Media{:}]';
    end
    Obs_Durations = [BORIS.Start_s_, BORIS.Stop_s_];
end

% Extract Media name from filepaths of Deployment Videos
pat = '[a-z]{2}\d{6}-\d{1,2}[^\/\\]+.mp4';
VidMedia = regexp(VidDir, pat, 'match');
VidMedia(cellfun(@isempty,VidMedia)) = {""}; % Finds no Matches and replaces with empty string (Unprocessed vids will not match)
if size(VidMedia,1) > 1
    VidMedia = [VidMedia{:}]';
end
% For Each Unique Media Filename in BORIS - MAKE FOR LOOP
try
UniqueMedia = unique(Obs_Media(Obs_Media ~= ""));
catch
    
end

% Find BORIS Media and Video Directory that match
    % Will process only Videos that are both in BORIS and Directory files
    % If Process is set to "All", it will process every video in Video
    % Directory
if Process ~= "All"
    AnalyzeVids = intersect(UniqueMedia, VidMedia);
else
    AnalyzeVids = VidMedia;
end

% Create data Table for Observations
dataObs = cell2table(cell(0,11), 'VariableNames', {'ObsMedia','ObsDuration_Start','ObsDuration_Stop', ...
    'CorrDuration_Start','StartTime','StartTime_string','StartIndex', ...
    'CorrDuration_Stop','StopTime','StopTime_string','StopIndex'});
dataVid = cell2table(cell(0,12), 'VariableNames', {'Vid_Directory','Media_Name', ...
    'StartMediaDuration','StartTime','StartTime_string','StartIndex', ...
    'EndMediaDuration','EndTime','EndTime_string','EndIndex', ...
    'TotalVideoDuration','Observation_indicies'});
dataObs.Properties.VariableUnits = {'media_name', 'seconds','seconds','seconds','time','time','PRHindex','seconds','time','time','PRHindex'};
dataVid.Properties.VariableUnits = {'directory', 'media_name','seconds','time','time','PRHindex','seconds','time','time','PRHindex','seconds','dataObsIndex'};


% Create Data Arrays:
    % Unanalyzed durations will have filler data added
    % Times = Empty Duration
    % Index = 0
    % Time_string = Empty String
B = 1:size(Obs_Durations,1); % Size of Arrays
CorrDuration_Start(B,1) = -1;
StartTime(B,1) = duration();
        StartTime.Format = StartTime.Format + ".S";
StartTime_string(B,1) = string();
StartTime_index(B,1) = 0;

CorrDuration_Stop(B,1) = -1;
StopTime(B,1) = duration();
    StopTime.Format = StopTime.Format + ".S";
StopTime_string(B,1) = string();
StopTime_index(B,1) = 0;

% Indecies of BORIS Observation Arrays analyzed by this code
Obsidx = [];

% Time Position and Index Position - Reset Every Function Run (Previously
% had it on each video, but seems un-nessesary. Best to have Per
% Deployment, but thats another story...
TimePosition = [];
IndexPosition = [];

% Cycle Through Videos to Analyze
for aa = 1:length(AnalyzeVids)

    % Asign Next video to AV
    AV = AnalyzeVids(aa);

    % Find Video Index from VidMedia
    Vidx = find(VidMedia == AV);

    % Find Video Indecies in BORIS Media
    Bidx = find(Obs_Media == AV);

    % To correct an issue where Video names in Video Folder may not always
        % be exactly the same as what was audited. Sometimes with an extra (1),
        % or so at the end. Attempts to find a partial match and prompts user
        % to confirm the same video.
    if isempty(Bidx) % try to truncate video name to see if you find matches
        TruncName = regexp(AV, '^(.*?\))', 'tokens', 'once');
        Bidx = find(contains(Obs_Media, TruncName));
        if ~isempty(Bidx)
            % Prompt User to answer if videos are the same
            message = ["A video from your video folder found no perfect match in your BORIS data, but a partial match was found:", ...
                strcat("In Video Diretory: ",string(AV)),...
                strcat("In BORIS Media: ", string(Obs_Media(Bidx))),...
                "Would you like to proceed with this Analysis by treating these as the same video?"];
            answer = questdlg(message, ...
                'Partial Match Found',...
	        'Yes, Videos are the Same','No, Skip this Video','Yes, Videos are the Same');
            % Handle response
            switch answer
                case 'Yes, Videos are the Same'
                    % Script Continues
                case 'No, Skip this Video'
                    Bidx = []; % Remove index
            end
        else % If no partial match is found
            disp(strcat('No Video Match Found for: ', string(AV),' In BORIS observation data'));
        end
    end

% Add Indicies to running list of Analyzed INdex Numbers
    Obsidx = [Obsidx;Bidx];

% Load Video
    vidObj = VideoReader(VidDir(Vidx));

% Get Video Start Time
    StartMediaDuration = 0; % First Video Frame
    [Time,timeString,index, DurDelta, TimePosition, IndexPosition] = ocrTime(vidObj,StartMediaDuration,TimePosition,IndexPosition);

% Get Video End Time
    % Get Final Frame Number - 1 (Last Frame can't be read in OCR)
    finalFrame = read(vidObj, vidObj.NumFrames-1);

% Get the Duration at Final Frame - 1
    finalFrameDuration = vidObj.CurrentTime;
    [Time2,timeString2,index2, DurDelta2, TimePosition, IndexPosition] = ocrTime(vidObj,finalFrameDuration,TimePosition,IndexPosition);

% Add to Video Data Table
    newRowTable1 = table(VidDir(Vidx),AV,StartMediaDuration,Time,timeString, ...
        index,finalFrameDuration,Time2,timeString2,index2,vidObj.Duration,{Bidx}, ...
        'VariableNames', dataVid.Properties.VariableNames);
    dataVid = [dataVid;newRowTable1];

    % Get Video Overlay Times per Observation
    for OO = 1:numel(Bidx)
        IDX = Bidx(OO);
        % Get Observation Start Time
        [StartTime(IDX),StartTime_string(IDX),StartTime_index(IDX), DurDelta, TimePosition, IndexPosition] = ocrTime(vidObj,Obs_Durations(IDX,1), TimePosition, IndexPosition);
        
        % Get Corrected Start Duration
        CorrDuration_Start(IDX) = seconds(StartTime(IDX) - Time);

        % Get Observation End Time
        if Obs_Durations(IDX,1) ~= Obs_Durations(IDX,2) % If Start and Stop are not at same time

            % Check that Duration is not longer than video
                % If Obs is longer than video, change duration to the
                % second to last frame. The Final Frame cannot be read by
                % OCR.
            if Obs_Durations(IDX,2) > vidObj.Duration
                
                % Display Data Change to User
                disp(["End Duration of Observation Longer than Video, changed Duration to match Video End", ...
                    string(Obs_Media(IDX)), ...
                    strcat("Delta: ", string(finalFrameDuration - Obs_Durations(IDX,2)))])

                % Change BORIS Duration value to that of Read Value
                Obs_Durations(IDX,2) = finalFrameDuration;
            end

        try 
            [StopTime(IDX),StopTime_string(IDX),StopTime_index(IDX), DurDelta, TimePosition, IndexPosition] = ocrTime(vidObj,Obs_Durations(IDX,2), TimePosition, IndexPosition);
        catch % Sometimes it dosen't like to read the final frame, this takes us < 0.01 seconds closer
            [StopTime(IDX),StopTime_string(IDX),StopTime_index(IDX), DurDelta, TimePosition, IndexPosition] = ocrTime(vidObj,Obs_Durations(IDX,2)*0.999999, TimePosition, IndexPosition);
        end

        % Get Corrected Stop Duration
        CorrDuration_Stop(IDX) = seconds(StopTime(IDX) - Time);

        else % If Start and Stop are at same time, set Stop to Start Values
            StopTime(IDX) = StartTime(IDX);
            StopTime_string(IDX) = StartTime_string(IDX);
            StopTime_index(IDX) = StartTime_index(IDX);
            CorrDuration_Stop(IDX) = CorrDuration_Start(IDX);
        end
    end
    disp(strcat("OCR Complete for: ", AV));
end
    % Add All Observation data arrays to Table
    newRowTable2 = table(Obs_Media,Obs_Durations(:,1),Obs_Durations(:,2), ...
        CorrDuration_Start,StartTime,StartTime_string,StartTime_index, ...
        CorrDuration_Stop,StopTime,StopTime_string,StopTime_index, ...
        'VariableNames', dataObs.Properties.VariableNames);
    dataObs = [dataObs;newRowTable2];

    disp(strcat("BORIS_TimeSyc Complete! :)"));

end

%% Save Data

% saveloc = 'E:\BigGulp\Research\PROJECTS\Antarctic Humpback Bubble Net Behavior\Video Audit\Simplified Audit\Project Folders\TimeSync Tables\'
% 
% % Save Data
% pattern = '^(.*?)(?=\()';
% deploymentID = strtrim(regexp(dataVid.Media_Name(1), pattern , 'tokens', 'once'));
% filename = '_TimeSync';
% 
% % Save Video Metadata to Excel Sheet
% writetable(dataVid, strcat(saveloc,deploymentID,filename,'.xlsx'), 'Sheet', 'Video data');
% 
% % Save Observation data to Excel Sheet
% writetable(dataObs, strcat(saveloc,deploymentID,filename,'.xlsx'), 'Sheet', 'Observation data');
% 
% % Convert Index to table and Save to Excel Sheet
% writetable(table(Obsidx), strcat(saveloc,deploymentID,filename,'.xlsx'), 'Sheet', 'Analyzed Observation Indicies');
% 
% % Save as Matlab File
% save(strcat(saveloc,deploymentID,filename,'.mat'), 'dataVid', 'dataObs', 'Obsidx');




%%
%     % Load Video
%     [file,path] = uigetfile('*.mp4');
%     vidObj = VideoReader(strcat(path,file))
%     vidObj.CurrentTime = 100; % VIDEO DURATION VARIABLE
% 
% % Load in Video Frame
% vidFrame = readFrame(vidObj);
% I = imshow(vidFrame)
% 
% results = ocr(vidFrame);
% 
% results.Words == 'Time'
% end

% Export Table with
    % Media Name
    % Media Directory
    % Start Duration
    % End Duration

% Ask for Directory

% Generate Video List

% Loop Through Videos with Relevant BORIS data




    
% 
% % Display Wordbox of 1 item
%     figure
%     word = results.Words{3}
%     wordBBox = results.WordBoundingBoxes(3,:) 
%     Iname = insertObjectAnnotation(vidFrame,"rectangle",wordBBox,word);
%     imshow(Iname)
% 
% % Display All Text
%     Iname2 = insertObjectAnnotation(vidFrame,"rectangle",results.WordBoundingBoxes,results.Words);
%     imshow(Iname2)
    %V = mmread(strcat(path,file))

    % Try to Read at Position
    % If it Fails, Select Position Manually


    % CHECKS
        % CHECK THAT ALL TIMES ARE IN APPROPRIATE FORMAT
        % Times are Sequential and dont jump around