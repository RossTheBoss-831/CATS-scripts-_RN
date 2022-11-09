% Batch Processesor for CATS deployments
    % Select Folder that contains all deployment folders you wish to
    % process.
    % Inputs: 
        % prh (required)
        % lunges (optional)
        % strategy (optional)
    % Outputs:
        % Deploy_Meta: Deployment metadata (table)
            % Deployment ID
            % Tagon time
            % Tagoff time
            % UTC (for antarctic)
            % Tag-on Data Duration
            % Tag-on Video Duration
            % Tag-on Audio Duration
            % With Lunge File:
                % Number of Detected Lunges
            % With Strategy File:
                % Number of HC Bubble Nets
                % Number of LC Bubble Nets
        % Bubble_Nets: Data related to each bubble net event
            % Deployment ID
            % Bubble Net Confidence Score
            % Day of Year
            % Start Time
            % End Time
            % Duration
            % Start Depth
            % End Depth
            % Depth Delta
            % Lunge Detected (0/1)
            % Lunge Time
            % Lunge Depth
            

% To Do:
    % Add fuctionality with DTAGs
    % Review Lunge, PRH and Strategy files to make standard
%% Add File Paths
clear;
%Solar Angle
%addpath(genpath('D:\LTER_Humpback Foraging in the Antarctic Summer\Analysis\Analysis 2 (Generalized Modelling)\Public scripts\chadagreene-CDT-9ef9171'))
addpath(genpath('X:\PROJECTS\LTER_Humpback Foraging in the Antarctic Summer\Analysis\Public Scripts\chadagreene-CDT-9ef9171'));
addpath(genpath('C:\Users\rossc\OneDrive\Documents\GitHub\CATS-scripts-_RN'));
addpath(genpath('C:\Users\rossc\OneDrive\Documents\GitHub\CATS-Methods-Materials'));
% path of DeployGPS.mat
deployPath = 'C:\Users\rossc\Documents\GitHub\CATS Scripts_RN\CATS-scripts-_RN\DeployGPS.mat';

%% IAATO Analysis
    diveplotson = true; % set to false for no dive plots
    diveplotlocation = 'X:\PROJECTS\IAATO_Antarctic Humpback Ship Strike Vulnerability\Tag Analysis\Deployment Dive Plots';
    % IAATO
    th = 5; % Minimum depth needed for finddives2 to consider it a dive
    %Depth_Risk_TH = [0,5,15]; % 1st Value is Surface, 2nd is Near Surface, 3rd is Max Depth of Risk
%% Select and Load Tag Directory
dname = uigetdir();
dfiles = dir(dname);
cd(dname)

% Select Only Humpback Folders
match = [];
startIndex = [];
for ii = 1:size(dfiles,1)
str = dfiles(ii).name;
expression = 'mn';
startIndex = regexp(str,expression);
    if ~isempty(startIndex)
        match(ii,1) = 1;
    else
        match(ii,1) = 0;
    end
end
dfiles_mn = dfiles(find(match == true));

%% Create Output Variables and Process Deployment archive

% Create Major Output Variables
skippedprh = [];
skippedlunge = [];
skippedstrategy = [];

Bubble_Nets = table();
Deploy_Meta = table();
HourlyMetrics = table();
DepthPresence = table('Size',[1,500],'VariableTypes',repmat("double",1,500), 'VariableNames', string(1:1:500));

valid_FR = zeros(length(dfiles_mn),1);  % Variable to track which deployments are usable for HFR analysis


% Cycle through all deployments in directory
for jj = 1:size(dfiles_mn)
   fname = dfiles_mn(jj).name;
   fileloc = dfiles_mn(jj).folder;
   cd([fileloc,'\', fname])
   
   % Clear Load Variables
   prh = [];
   lunges = [];
   strategy = [];
   
% Find and Load PRH File
  try prh = load([fname(1:end-11),'10Hzprh']);
  catch
      tdir = dir;
      for hh = 1:size(tdir,1)
          if ~isempty(regexp(tdir(hh).name,'prh'))
              prh = load([tdir(hh).folder, '\',tdir(hh).name]);
              display(strcat("Could not find 10Hzprh file, loaded instead:  ",tdir(hh).name));
               if regexp(tdir(hh).name,'speed')
                   MISHAP = 1;
                   % Load MISHAP related files needed
                   WID = string(tdir(hh).name(1:9));
                   prh.INFO.whaleName = WID;
                   prh.INFO.UTC = -3; % Local Palmer Time
                   TagStatus = load([tdir(hh).folder, '\',char(WID),'_tagon.mat']);
                   prh.tagon = TagStatus.tagon; % set variable to prh file
               else
                   MISHAP = 0;
               end
          end
      end
  end
  
if isempty(prh)
    display(strcat("Could not find prh file for:  ", fname," Skipping Deployment"));
    skippedprh = [skippedprh;string(fname)]; %Matlab says I can optimize this for speed, but who needs that right?
    continue
end
  
%Find and Load Lunge File
    try lunges = load([fname(1:end-12),'_lunges.mat']);
  catch
      tdir = dir;
      for hh = 1:size(tdir,1)
          if ~isempty(regexp(tdir(hh).name,'lunges.mat'))
              lunges = load([tdir(hh).folder, '\',tdir(hh).name]);
              display(strcat("Could not find lunges file, loaded instead:  ",tdir(hh).name))
          end
      end
    end
  
 % Find and Load Strategy File
    try strategy = load([fname(1:end-12),'strategy']);
  catch
      tdir = dir;
      for hh = 1:size(tdir,1)
          if ~isempty(regexp(tdir(hh).name,'strategy'))
              lunges = load([tdir(hh).folder, '\',tdir(hh).name]);
              display(strcat("Could not find strategy file, loaded instead:  ",tdir(hh).name))
          end
      end

    end
  
  % Check File Load Status
      if isempty(lunges)
       display(strcat("Could not find lunges file for:  ", fname));
       skippedlunge = [skippedlunge;string(fname)];
      end
      if isempty(strategy)
       display(strcat("Could not find strategy file for:  ", fname));
       skippedstrategy = [skippedstrategy;string(fname)];
      end
    

  % Perform actions to Loaded Files (PRH, Lunge Strategy)
  
  if ~exist('MISHAP','var') % If the MISHAP variable was not created, set to 0.
      MISHAP = 0;
  end
  
% Depoyment Metadata - Process for creating the Deploy_Meta Table

  if ~isempty(prh)
      % Tag on and Tag Off Times
      whaleName = prh.INFO.whaleName; % Tag ID
      WID = string(prh.INFO.whaleName); % whale ID
      tagon_localtime = datetime(prh.DN(find([prh.tagon] == 1,1,'first')), 'convertfrom','datenum');
      tagoff_localtime = datetime(prh.DN(find([prh.tagon] == 1,1,'last')), 'convertfrom','datenum');
      try UTC = prh.INFO.UTC; % UTC 
      catch
           UTC = -3;
      end
      % On Whale Data Duration
      data_duration = sum([prh.tagon])/prh.fs/60/60; % Duration in hours
      % Video Data Duration (On-Whale)
      if isfield(prh,'camon')
        vid_duration = length(find([prh.tagon] & [prh.camon] == 1))/10/60/60; % Duration in Hours
      else
        vid_duration = 0;
      end
      % Audio Data Duration (On-Whale)
      if isfield(prh,'audon')
        aud_duration = length(find([prh.tagon] & [prh.audon] == 1))/10/60/60;
      else
        aud_duration = 0;
      end
      
      if ~isempty(lunges)
      % Number of Detected Lunges
        lunge_count = length([lunges.LungeI]);
      else
          lunge_count = 0;
      end
      
      % Number of Bubble Net Events (HC)
      % Number of Bubble Net Events (LC)
      if ~isempty(strategy)
          try disp(strategy.BubbleC)
          catch
              strategy.BubbleC = strategy.StrategyC;
              strategy.BubbleE = strategy.StrategyE;
              strategy.BubbleS = strategy.StrategyS;
          end

          BubbleNetHQ_count = length(find([strategy.BubbleC]==1));
          BubbleNetLQ_count = length(find([strategy.BubbleC]==2));
      else
          BubbleNetHQ_count = 0;
          BubbleNetLQ_count = 0;
      end

      % IAATO VALUES per deployment
        % Percentage of Time in 0 - 5 meters (Surface)
            SURF = sum(prh.p(prh.tagon) <= 5)/sum(prh.tagon)*100;
        % Percentage of Time in Near Surface based on avg cruise ship draft (>5 - 15 meters)
            SUBSURF = sum(prh.p(prh.tagon) > 5 & prh.p(prh.tagon) <= 15)/sum(prh.tagon)*100;
        % Percentage at Depth
            ATDEPTH = 100 - (SURF + SUBSURF);

      % Add to Deploy_Meta Table
      Deploy_Meta_temp = table(string(whaleName),tagon_localtime,tagoff_localtime,UTC,data_duration,vid_duration,aud_duration,lunge_count,BubbleNetHQ_count,BubbleNetLQ_count,SURF, SUBSURF, ATDEPTH);
      Deploy_Meta = [Deploy_Meta;Deploy_Meta_temp];
     
  end
  
  
    % Bubble Net Metrics - Update the Bubble_Nets table
  if ~isempty(strategy) && ~isempty(strategy.BubbleC) && MISHAP ~= 1
      % Make table with each Bubble Net Event a Row
            len = length([strategy.BubbleC]); % Number of Bubble Net Events
      % WhaleID
            bubble_WID = "";
            bubble_WID(1:len,1) = string(whaleName);
      % Confidence Score (strategy.BubbleC)
      % Day of Year
            Bubble_doy = day(datetime(prh.DN([strategy.BubbleS]),'convertfrom','datenum'),'dayofyear');
      % Start Time
            BubbleStart_time = datetime(prh.DN([strategy.BubbleS]),'convertfrom','datenum');
      % End Time
            BubbleEnd_time = datetime(prh.DN([strategy.BubbleE]),'convertfrom','datenum');
      % Duration
            Bubble_duration = etime(datevec(prh.DN([strategy.BubbleE])), datevec(prh.DN([strategy.BubbleS])));
      % Start Depth
            BubbleStart_depth = prh.p([strategy.BubbleS]);
      % End Depth
            BubbleEnd_depth = prh.p([strategy.BubbleE]);
      % Depth Delta
            Bubble_depthdelta = BubbleEnd_depth - BubbleStart_depth;
            
            if ~isempty(lunges)
              % Lunge Detected (0 or 1)
                %clear variables
                  BubbleLunge_detect = [];
                  BubbleLunge_depth = [];
                  BubbleLunge_time = datetime();
              for kk = 1:len
                  % Detect a lunge between Start and End of Detected bubble
                  % net. I added 100 index (10 seconds) onto the end to capture
                  % any where I placed the end marker prior to the lunge.
                  % Which might be common.
                lunge_detect = find(lunges.LungeI >= strategy.BubbleS(kk)& lunges.LungeI <= strategy.BubbleE(kk)+100);
                BubbleLunge_detect(kk,1) = length(lunge_detect);
              % Lunge Depth
                  if BubbleLunge_detect(kk,1) > 0
                       try 
                           BubbleLunge_depth(kk,1) = prh.p(lunges.LungeI(lunge_detect));
                           BubbleLunge_time(kk,1) = datetime(prh.DN(lunges.LungeI(lunge_detect)),'convertfrom','datenum');
                       catch
                           display(strcat("Multiple Lunges May have been detected within a single bubble net, check deployment:  ",fname));
                       end
                  else
                        BubbleLunge_depth(kk,1) = NaN;
                        BubbleLunge_time(kk,1) = NaT;
                  end
              end
            else
                BubbleLunge_detect = zeros(len,1);
                BubbleLunge_depth = NaN(len,1);
            end
      
      Bubble_Nets_temp = table(bubble_WID,[strategy.BubbleC],Bubble_doy,BubbleStart_time,BubbleEnd_time,Bubble_duration,BubbleStart_depth,BubbleEnd_depth,Bubble_depthdelta,BubbleLunge_detect,BubbleLunge_time,BubbleLunge_depth);
      Bubble_Nets = [Bubble_Nets;Bubble_Nets_temp];
  end
 
  
  
  % Hourly Metrics - Feeding - Presence
  
  
  % Load sample data (COMMENT OUT BEFORE RUNNING FOR REAL)
%     FeedingRate = table();
%     prh = load('D:\Remote Work Enviornment\LTER_Humpback Foraging in the Antarctic Summer\CATS DATA\mn200105-52 (Antarctic)\mn200105-52 10Hzprh.mat');
%     lunges = load('D:\Remote Work Enviornment\LTER_Humpback Foraging in the Antarctic Summer\CATS DATA\mn200105-52 (Antarctic)\mn200105-52lunges.mat');
%     dfiles_mn = 1
%     jj = 1
    
    
    
    % Check if Deployment is more than 2 hours in duration
        min_hours = 2;
        if length(prh.p) > (prh.fs*60*60*min_hours)
            if exist('lunges','var') && ~isempty(lunges)% Check that Lunge File exists and was loaded
                valid_FR(jj) = 1;
            else
                disp('Could not find Lunge File, no HFR stats taken')
                valid_FR(jj) = 0;
            end
        else
            valid_FR(jj) = 0;
            disp("Deployment Invalid for HFR Analysis")
        end
        
    % Check if valid, then continue with stats collecting
        if valid_FR(jj) == 1
            % Collect following variables per FULL hour of data
                % Discretize data hours
                    DV = datevec(prh.DN);
                    
                    %remove nan's for unique function
                    DV_nonan = DV(~isnan(DV(:,1)),:);
                    Uhours = unique(DV_nonan(:,1:4),'rows');% Unique Hours ([Ax2] day, hour)
                    
                    for UU = 1:size(Uhours,1)
                        HOD = Uhours(UU,4); % Hour of Day
                        Day = Uhours(UU,3); % day
                        Month = Uhours(UU,2); % month
                        Year = Uhours(UU,1); % year
                        DOY = day(datetime(Year,Month,Day),'dayofyear'); % day of year
                        
                        % WhaleID
                        if ~exist('WID','var')
                            WID = string(prh.INFO.whaleName);
                        end
                        
                        uI = find(DV(:,3) ==  Day & DV(:,4) == HOD ); % Index numbers of current hour
                        
                        % Check if uI matches any portions where tag is off, if
                        % so, skip.
                        tagon_idx = find(prh.tagon == 0);
                        if 0 < sum(ismember(uI,tagon_idx))
                            disp("skipping hour due to partial tag off");
                            continue
                        end
                        
                % Deployment Location
                
                if isfield(prh,'GPS')
                    Lat = prh.GPS(1,1); % Deployment Latitude
                    Lon = prh.GPS(1,2); % Deployment Longitude
                else
                    try 
                        load(deployPath)
                        allWIDs = table2array(DeployGPS(:,1));
                        Widx = find(string(WID) == allWIDs); % Check GPS table for deployment row
                        Lat = DeployGPS.Lat(Widx);
                        Lon = DeployGPS.Lon(Widx);
                    catch
                        disp("No GPS found in file, set manually using import table")
                           Lat = nan; % Lat for Palmer Canyon Head
                           Lon = nan; % Long for Palmer Canyon Head - Made this negative so that the results match the NOAA calculator. I don't know why, but this works.
                    end
                end
                

                    % Calculate Datenumber in UTC
                        DN = datenum(datetime(Year,Month,Day,HOD,0,0)); % Create Datenumber Array to start time
                        DNUTC = DN + datenum(hours(3)); % Convert to UTC (-3)

                    % GPS Info
                        if isempty(Lat) | isempty(Lon)
                            Lat = -64.9; % Lat for Palmer Canyon Head
                            Lon = -64.3; % Long for Palmer Canyon Head - Made this negative so that the results match the NOAA calculator. I don't know why, but this works.
                            %Lat = 36.9 % Santa  Cruz
                            %Lon = -122.0 % Santa  Cruz
                            %Lat = 0 % Equator
                            %Long = 0 % Equator
                        end

                        % Calculates Solar Elevation for each Hour (10 min increments then
                        % averaged)
                        Laz = []; % reset variable
                        Lel = []; % reset variable
                        for UD = 1:7
                            [Laz(UD,1),Lel(UD,1)] = sun_angle(DNUTC,Lat,Lon);
                            DNUTC = DNUTC + datenum(minutes(10));
                        end
                            MSE = mean(Lel); % Mean Solar Elevation (From 7 samples, 1 measure per 10 min)
                            CSE = Lel(4); % Center Solar Elevation (@ 0030 mark of each hour)

                    % Discretize into Night or Day using -6 Civil Twilight as the Boundary
                        %Y = discretize(Lel,[min(Lel),-6,max(Lel)])

                % Hourly Feeding Rate
                    HFR = sum(ismember(uI, lunges.LungeI));

                % Mean Lunge Depth
                    MLD = mean(lunges.LungeDepth(ismember(lunges.LungeI,uI)));
                             
                % IAATO VALUES per deployment for Presence at Surface,

                    %FD_Dive_TH = 5; % Minimum depth needed for finddives2
                    %to consider it a dive (Threshold at top of script)
                    %Depth_Risk_TH = [0,5,15]; % 1st Value is Surface, 2nd
                    %is Near Surface, 3rd is Max Depth of Risk (Threshold at top of script)
                % Subsurface and At Depth
                    % Percentage of Time in 0 - 5 meters (Surface)
                        SURF_H = sum(prh.p(uI) <= 5)/length(uI)*100;
                    % Percentage of Time in Near Surface based on avg cruise ship draft (>5 - 15 meters)
                        SUBSURF_H = sum(prh.p(uI) > 5 & prh.p(uI) <= 15)/length(uI)*100;
                    % Percentage at Depth
                        ATDEPTH_H = 100 - (SURF_H + SUBSURF_H);

                % Seconds within 1m Bin Depths (0 to 500m)
                    h = histogram(abs(p),'BinEdges',[0:1:500]); % create histogram with 1m bins to 500m
                    hh = array2table(h.Values/fs, 'VariableNames',string([1:1:500]), RowNames=WID); % Convert values of histagram to seconds
                    close % close histogram plot
                    DepthPresence = [DepthPresence; hh];


                % Find Dives Stats
                % finddives2 table ->[start_cue(in seconds) end_cue(in seconds) max_depth cue_at_max_depth mean_depth mean_compression]
                    FD = finddives2(p,fs,th);
                    % Dive Duration
                    divedur = FD(:,2) - FD(:,1);
                    maxdivedur = max(divedur);
                    % Max Dive Depth - in finddives table
                    % Start Cue Index
                        Start_Cue_Idx = FD(:,1) * fs;
                        End_Cue_Idx = FD(:,2) * fs;
                    % Rates of Depth Change (DC) for each detected dive
                        DepthChange = NaN(ceil(max(divedur)),length(Start_Cue_Idx)); % Creates array with Columns equal to number of dives and rows equal to longest dives (1 Second = 1 row)
                        rt = 1; % Amount of time in seconds to measure differenes in depth
                        for i = 1:length(Start_Cue_Idx)
                            DC = Start_Cue_Idx(i):rt*fs:End_Cue_Idx(i);
                            for k = 1:length(DC)- 2 % minus 2 is to prevent going over index when measuring rate
                               DepthChange(k,i) = mean(p(DC(k+1):DC(k+2)-1)) - mean(p(DC(k):DC(k+1)-1));
                            end
                        end
                        
                    % Identify Decent Phase
                    for 1:size(DepthChange,2) % For Each Dive
                        for 1:length(DepthChange) % For each second of Dive
                            
                        end
                    end
                        
                    % Rate of Depth Change Plots
                        if diveplotson ==  true     
                            for dp = 1:size(DepthChange,2)
                                plot(-DepthChange(~isnan(DepthChange(:,dp)),dp)); % Plots only values and removes NaN fillers
                                if dp == 1
                                hold on
                                yline(0)
                                end
                            end
                        end
                        
                    % Ascent Rate
                    % Descent Heading Change
                    % Surfacing Duration - use findsurfacing script?
                    % Number of Breaths
                    % 


                 % Create data row and add to table
                    % Added UU, which indicates the number of hours since
                    % the analytical tag on began. Used for the temporal
                    % auto-correlation
                     
                     temp_HourlyMetrics = table(WID, Lat, Lon, Year, Month, Day, DOY, HOD, MSE, CSE, HFR, MLD, UU, SURF_H, SUBSURF_H, ATDEPTH_H);
                     HourlyMetrics = [HourlyMetrics; temp_HourlyMetrics];
                     temp_HourlyMetrics = [];
                  end
        end
end

clearvars -except valid_FR HourlyMetrics Bubble_Nets Deploy_Meta DepthPresence skippedprh skippedlunge skippedstrategy