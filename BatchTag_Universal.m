% Batch Function


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
addpath(genpath('C:\Users\rossc\Documents\GitHub\CATS Scripts_RN'));
addpath(genpath('C:\Users\rossc\Documents\GitHub\CATS-Methods-Materials'));
% path of DeployGPS.mat
deployPath = 'C:\Users\rossc\Documents\GitHub\CATS Scripts_RN\CATS-scripts-_RN\DeployGPS.mat';
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
DepthPresence = table();
DepthRate = {}; % Change in Depth, cell array of each dive for each deployment
Dives = table(); % finddives2 output and stats per dive
Surfacings = {}; % Cell structure for surfacings analysis output for each tag

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


    
  % Add Custom Functions here - Variables to use:
    % prh
    % lunges
    
    if isfield(prh,'geoPtrack')
        % Export 3D Whale Tracks to CSV
        GeoPTrack2CSV(prh,"E:\BigGulp\Research\PROJECTS\NSF_SWARM OPP 2\Whale data\3D WhaleTracks");
    end
     
  end



end

  clearvars -except valid_FR HourlyMetrics Bubble_Nets Deploy_Meta DepthPresence DepthRate Dives Surfacings skippedprh skippedlunge skippedstrategy 