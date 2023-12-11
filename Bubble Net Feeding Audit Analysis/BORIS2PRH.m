% Individual Analysis - Turn BORIS Data into PRH Index Values
% Load BORIS cleaned BORIS data + PRH deployment
    % import BORIS data as "data" variable

function [BORIS, Video] = BORIS2PRH(data,INFO,vidNam,vidDN,vidDurs,DN)

% Get WhaleID - Assumes taken from Processed data folder (Antarctic)
    % pat = "mn" + digitsPattern(6) + "-" + digitsPattern(2) + " (A";
    % WhaleID_all = extractBefore(extract(data.MediaFileName,pat),' (A');
WhaleID_all = extractBetween(data.MediaFileName,'/mn',' (A','Boundaries','inclusive');
WhaleID_all = extractBetween(WhaleID_all,'/',' (A');

    % unique(WhaleID_all);

% Add WhaleID Column
data.WhaleID = WhaleID_all;

% Extract data only relevant to this Deployment
BORIS = data(find(data.WhaleID == string(INFO.whaleName)),:);

% Extract Video Number - BORIS
VidNum = string(extractBetween( BORIS.ObservationId , '(' , ')' ));
% Check if multiple string patterns were found, extract only 1st string
    %(vid num)
    switch size(VidNum,2)
        case 0 % Non-Processed data
             BORIS.VidNum = extractBetween(string(BORIS.ObservationId),"-00",".mov");
        case 1 % Processed Data with 1 string found
            VidNum = VidNum(find(~contains(VidNum, '.'))); % Remove any matches to dates within parentheses
            BORIS.VidNum = VidNum;
        otherwise % Processed Data with multiple strings found
            BORIS.VidNum = VidNum(:,1);
    end

% Extract Vid Number - Deployment (Create Video Table)
checkempty = ~cellfun(@isempty,vidNam); % Check for Empty value (likely in first cell)
Video = table(string(cell2mat(vidNam(checkempty))),vidDN(checkempty),vidDurs(checkempty), ...
    'VariableNames',["VidName","VidDN","VidDurs"]);
Video.VidNum = extractBefore(string(Video.VidName),'.');
Video.VidNum = char(Video.VidNum);
Video.VidNum = str2num(Video.VidNum(:,end-2:end)); % Assumes 3 digit number!

% Match Each Observation to Tag Video Index
TrueVidNum_Start = zeros(size(BORIS,1),1); % Dummy Variable START
TrueVidNum_Stop = zeros(size(BORIS,1),1); % Dummy Variable STOP
VidMatch_Start = zeros(size(BORIS,1),1); % Dummy Variable START
VidMatch_Stop = zeros(size(BORIS,1),1); % Dummy Variable STOP

for zz = 1:length(BORIS.VidNum)

    % Check for Hyphen in Video String
    if ~contains(BORIS.VidNum(zz),'-')

        % If the Observation is from a single Video
        TrueVidNum_Start(zz) = str2num(BORIS.VidNum(zz));
        TrueVidNum_Stop(zz) = str2num(BORIS.VidNum(zz));

        % Video Range Check - Checks that a Video exists for each video in
        % Range
        if isempty(find(TrueVidNum_Start(zz) ==  Video.VidNum))
            disp('Video not found in PRH, setting Video Match to 0')
            VidMatch_Start(zz) = 0;
            VidMatch_Stop(zz) = 0;
        else
            VidMatch_Start(zz) = find(TrueVidNum_Start(zz) ==  Video.VidNum);
            VidMatch_Stop(zz) = find(TrueVidNum_Stop(zz) ==  Video.VidNum);
        end


    else % If the Observation is within a number range
        % Get Range of Videos in Observation
        VidRange = [str2num(extractBefore(BORIS.VidNum(zz),'-')):str2num(extractAfter(BORIS.VidNum(zz),'-'))];
        VidRange = VidRange';

        % Video Range Check - Checks that a Video exists for each video in
        % Range
        VidCheck = zeros(length(VidRange),1);
        for VC = 1:length(VidRange)
            VidCheck(VC) = ~isempty(find(Video.VidNum == VidRange(VC)));
        end
        % Remove Vids from Range with no matching video
        if sum(VidCheck) < length(VidCheck)
            VidRange = VidRange(find(VidCheck));
        end

        % Get Video Durations
        VidRangeDur = zeros(length(VidRange),1); % Dummy Variable
        for VR = 1:length(VidRange)
            idx = find(Video.VidNum == VidRange(VR)); % Find Duration
            if VR == 1
                VidRangeDur(VR,1) = Video.VidDurs(idx);
            else
                VidRangeDur(VR,1) = Video.VidDurs(idx) + VidRangeDur(VR-1,1) + 3*VR; % 3 Seconds added to duration to mark the time gap set between videos (3 seconds for each video in range)
            end
        end

        % find Match using VidRangeMatch function
            TrueVidNum_Start(zz) = VidRangeMatch(BORIS.Start_s_(zz),VidRangeDur, VidRange);
            TrueVidNum_Stop(zz) = VidRangeMatch(BORIS.Stop_s_(zz),VidRangeDur, VidRange);
            VidMatch_Start(zz) = find(TrueVidNum_Start(zz) ==  Video.VidNum);
            VidMatch_Stop(zz) = find(TrueVidNum_Stop(zz) ==  Video.VidNum);

    end
end

% Add Variables to BORIS Table
    % TrueVidNum - This is the "Actual Video Number", and parses each
        % observation to its actual video, rather than the potential range,
    % VidMatch - Index Numbers for the Video table variable that match with
        % each observation
BORIS.TrueVidNum_Start = TrueVidNum_Start;
BORIS.TrueVidNum_Stop = TrueVidNum_Stop;

BORIS.VidMatch_Start = VidMatch_Start;
BORIS.VidMatch_Stop = VidMatch_Stop;


% Clean Dates to round Second Numbers in Video Table
vDV = datevec(Video.VidDN);
Video.DT = datetime(vDV(:,1),vDV(:,2),vDV(:,3),vDV(:,4),vDV(:,5),floor(vDV(:,6))); % Round Seconds

% Create DT Array for PRH
DT = datetime(DN,'ConvertFrom','datenum');

% Find Video Start Indecies
index = zeros(length(Video.DT),1);
for ii = 1:length(Video.DT)
    if dateshift(Video.DT(ii),'end','second') < dateshift(DT(1),'end','second')
        disp(strcat(WhaleID_all," : Video audited was prior to deployment, setting Index to index 1"))
        index(ii) = -1;
    elseif dateshift(Video.DT(ii),'end','second') > dateshift(DT(end),'end','second')
        disp(strcat(WhaleID_all," : Video audited was after deployment, setting Index to final prh index"))
        index(ii) = length(DT);
    end
    [~ ,index(ii)] = ismember(dateshift(Video.DT(ii),'end','second'),dateshift(DT,'end','second')); % Round Datetimes to nearest second for easy matching
end

% Add Start Index Variable to Table
Video.Index = index;

% Create an Index Variable for the Bubble Net Events
StartIndex = zeros(size(BORIS,1),1); % Starter Variable (Start PRH Index)
StopIndex = zeros(size(BORIS,1),1); % Starter Variable (Stop PRH Index)
ObsStart = NaT(size(BORIS,1),1); % Starter Variable (Start PRH Time)
ObsStop = NaT(size(BORIS,1),1); % Starter Variable (Stop PRH Time)
for KK = 1:size(BORIS,1)

    % Observation Start
    if BORIS.VidMatch_Start(KK) == 0 % If Video was not found in PRH
        ObsStart(KK,1) = NaT;
        StartIndex(KK,1) = NaN;
    else
        ObsStart(KK,1) = Video.DT(BORIS.VidMatch_Start(KK)) + floor(seconds(BORIS.Start_s_(KK)));
    end

    if ObsStart(KK,1) > DT(end)
        StartIndex(KK,1) = length(DT);
        disp(strcat(WhaleID_all,' : Observation was after Tag Off, Index was set to final index'))
    elseif  ObsStart(KK,1) < DT(1)
        disp(strcat(WhaleID_all," : Observation audited was prior to deployment, setting Index to index -1"))
        StartIndex(KK,1) = -1;
    else
        [~ ,StartIndex(KK,1)] = ismember(ObsStart(KK,1),dateshift(DT,'end','second'));
    end

    % Observation Stop
    if BORIS.VidMatch_Stop(KK) == 0 % If Video was not found in PRH
        ObsStop(KK,1) = NaT;
        StopIndex(KK,1) = NaN;
    else
        ObsStop(KK,1) = Video.DT(BORIS.VidMatch_Stop(KK)) + floor(seconds(BORIS.Stop_s_(KK)));
    end

    if ObsStop(KK,1) > DT(end)
        StopIndex(KK,1) = length(DT);
        disp(strcat(WhaleID_all,' : Observation was after Tag Off, Index was set to final index'))
    elseif  ObsStop(KK,1) < DT(1)
        disp(strcat(WhaleID_all," : Observation audited was prior to deployment, setting Index to index -1"))
        StopIndex(KK,1) = -1;
    else
        [~ ,StopIndex(KK,1)] = ismember(dateshift(ObsStop(KK,1),'end','second'),dateshift(DT,'end','second'));
    end
end
% Add Index Variables to BORIS Table
BORIS.StartIndex = StartIndex;
BORIS.StopIndex = StopIndex;
BORIS.ObsStart = ObsStart;
BORIS.ObsStop = ObsStop;

% Save BORIS file as Matlab File to BubbleNetAudit Folder
% if ~exist('saveloc','var')
%     saveloc = uigetdir;
% end

% save(strcat(saveloc,'\',INFO.whaleName,"_BubbleNetAudit.mat"),'BORIS','Video');

end