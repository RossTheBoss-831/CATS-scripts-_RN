% Code to Correct BORIS Notations to Data Overlay
    % Required Toolboxes
        % Computer Vision

    %INPUTS:
        % BORIS_Media
            % n x 1 string array of Media File Names (ex. "mn201017-54 (03).mp4") related
            % to Durations Matrix. This matrix can include media names not
            % present in VidDir. Only videos matching those in VidDir will
            % be analyzed.
        % BORIS_Durations
            % n x 2 matrix of [Start Durations, End Durations] in seconds
        % VidDir
            % n x 1 string array of full file paths of Video Directories
            % you like to load in and analyze.
        % Process
            % Set to "All" if you would like all Videos in the VidDir
            % variable to be analyzed, rather than just videos that match
            % values in the BORIS media.

    % OUTPUTS
        % dataObs - Corrected times for input observations
        % dataVid - Table of Start and End Times of each video Processed
        % Obsidx - Index of inputs BORIS_Media and BORIS_Durations that
            % were analyzed by this code

    % Current Bugs:
        % Duration Delta is not yet incorporated into an output

function [dataObs, dataVid, Obsidx] = BORIS_TimeSync(BORIS_Media,BORIS_Durations,VidDir,Process)

if ~exist('Process','var')
    Process = "BORIS";
end

% If no Video Directory Array was given, find all MP4 files in folder
    % of choice
if isempty(VidDir)
    [~,path] = uigetfile('*.mp4','Title','Select Any Video from Deployment');
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
if isempty(BORIS_Media) || isempty(BORIS_Durations)
    BORIS = importMultiBORIS;
    pat = '[a-z]{2}\d{6}-\d{1,2}[^\/\\]+.mp4';
    BORIS_Media = regexp(BORIS.MediaFileName, pat, 'match');
    BORIS_Media(cellfun(@isempty,BORIS_Media)) = {""}; % Finds no Matches and replaces with empty string (Unprocessed vids will not match)
    BORIS_Media = [BORIS_Media{:}]';
    BORIS_Durations = [BORIS.Start_s_, BORIS.Stop_s_];
end

% Extract Media name from filepaths of Deployment Videos
pat = '[a-z]{2}\d{6}-\d{1,2}[^\/\\]+.mp4';
VidMedia = regexp(VidDir, pat, 'match');
VidMedia(cellfun(@isempty,VidMedia)) = {""}; % Finds no Matches and replaces with empty string (Unprocessed vids will not match)
VidMedia = [VidMedia{:}]';

% For Each Unique Media Filename in BORIS - MAKE FOR LOOP
UniqueMedia = unique(BORIS_Media(BORIS_Media ~= ""));

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
dataObs = cell2table(cell(0,9), 'VariableNames', {'ObsMedia','ObsDuration_Start','ObsDuration_Stop', ...
    'StartTime','StartTime_string','StartIndex', ...
    'EndTime','EndTime_string','EndIndex'});
dataVid = cell2table(cell(0,12), 'VariableNames', {'Vid_Directory','Media_Name', ...
    'StartMediaDuration','StartTime','StartTime_string','StartIndex', ...
    'EndMediaDuration','EndTime','EndTime_string','EndIndex', ...
    'TotalVideoDuration','Observation_indicies'});

% Create Data Arrays:
    % Unanalyzed durations will have filler data added
    % Times = Empty Duration
    % Index = 0
    % Time_string = Empty String
B = 1:size(BORIS_Durations,1); % Size of Arrays
StartTime(B,1) = duration();
StartTime_string(B,1) = string();
StartTime_index(B,1) = 0;

StopTime(B,1) = duration();
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
    Bidx = find(BORIS_Media == AV);

    % To correct an issue where Video names in Video Folder may not always
        % be exactly the same as what was audited. Sometimes with an extra (1),
        % or so at the end. Attempts to find a partial match and prompts user
        % to confirm the same video.
    if isempty(Bidx) % try to truncate video name to see if you find matches
        TruncName = regexp(AV, '^(.*?\))', 'tokens', 'once');
        Bidx = find(contains(BORIS_Media, TruncName));
        if ~isempty(Bidx)
            % Prompt User to answer if videos are the same
            message = ["A video from your video folder found no perfect match in your BORIS data, but a partial match was found:", ...
                strcat("In Video Diretory: ",string(AV)),...
                strcat("In BORIS Media: ", string(BORIS_Media(Bidx))),...
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
    newRowTable1 = table(VidDir(Vidx),AV,Time,StartMediaDuration,timeString, ...
        index,finalFrameDuration,Time2,timeString2,index2,vidObj.Duration,{Bidx}, ...
        'VariableNames', dataVid.Properties.VariableNames);
    dataVid = [dataVid;newRowTable1];

    % Get Video Overlay Times per Observation
    for OO = 1:numel(Bidx)
        IDX = Bidx(OO);
        % Get Observation Start Time
        [StartTime(IDX),StartTime_string(IDX),StartTime_index(IDX), DurDelta, TimePosition, IndexPosition] = ocrTime(vidObj,BORIS_Durations(IDX,1), TimePosition, IndexPosition);
        
        % Get Observation End Time
        if BORIS_Durations(IDX,1) ~= BORIS_Durations(IDX,2) % If Start and Stop are not at same time

            % Check that Duration is not longer than video
                % If Obs is longer than video, change duration to the
                % second to last frame. The Final Frame cannot be read by
                % OCR.
            if BORIS_Durations(IDX,2) > vidObj.Duration
                
                % Display Data Change to User
                disp(["End Duration of Observation Longer than Video, changed Duration to match Video End", ...
                    string(BORIS_Media(IDX)), ...
                    strcat("Delta: ", string(finalFrameDuration - BORIS_Durations(IDX,2)))])

                % Change BORIS Duration value to that of Read Value
                BORIS_Durations(IDX,2) = finalFrameDuration;
            end

            [StopTime(IDX),StopTime_string(IDX),StopTime_index(IDX), DurDelta, TimePosition, IndexPosition] = ocrTime(vidObj,BORIS_Durations(IDX,2), TimePosition, IndexPosition);

        else % If Start and Stop are at same time, set Stop to Start Values
            StopTime(IDX) = StartTime(IDX);
            StopTime_string(IDX) = StartTime_string(IDX);
            StopTime_index(IDX) = StartTime_index(IDX);
        end
    end
    disp(strcat("OCR Complete for: ", AV));
end
    % Add All Observation data arrays to Table
    newRowTable2 = table(BORIS_Media,BORIS_Durations(:,1),BORIS_Durations(:,2), ...
        StartTime,StartTime_string,StartTime_index, ...
        StopTime,StopTime_string,StopTime_index, ...
        'VariableNames', dataObs.Properties.VariableNames);
    dataObs = [dataObs;newRowTable2];

    disp(strcat("BORIS_TimeSyc Complete! :)"));


% Save Data

% % Convert data1 to a table and save to Sheet1
% writetable(a, 'mn150321-3_TimeSync.xlsx', 'Sheet', 'Sheet1');
% 
% % Convert data2 to a table and save to Sheet2
% writetable(b, 'mn150321-3_TimeSync.xlsx', 'Sheet', 'Sheet2');
% 
% % Convert data2 to a table and save to Sheet2
% writetable(table(idx), 'mn150321-3_TimeSync.xlsx', 'Sheet', 'Sheet3');






end








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