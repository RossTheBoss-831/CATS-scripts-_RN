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
            

% To Do:
    % Add fuctionality with DTAGs
    % Review Lunge, PRH and Strategy files to make standard


%% Add File Paths
clear;
%Solar Angle
%addpath(genpath('D:\LTER_Humpback Foraging in the Antarctic Summer\Analysis\Analysis 2 (Generalized Modelling)\Public scripts\chadagreene-CDT-9ef9171'))
addpath(genpath('C:\Users\rossc\OneDrive\Documents\GitHub\CATS-scripts-_RN'));
addpath(genpath('C:\Users\rossc\OneDrive\Documents\GitHub\CATS-Methods-Materials'));
% path of DeployGPS.mat
deployPath = 'C:\Users\rossc\OneDrive\Documents\GitHub\CATS-scripts-_RN\DeployGPS.mat';


%% Select and Load Tag Directory
dname = uigetdir([],'Select CATS data Directory Folder');
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


%% Perform Analyses

% Analysis Sets, set to TRUE to perform on each tag.

Metadata_check = true; % Metadata Analysis
    if Metadata_check ==  true
        Deploy_Meta = table();
    end

HourlyMetrics_check = false; % Hourly Metrics Analysis
    if HourlyMetrics_check == true
        HourlyMetrics = table();
        valid_FR = zeros(length(dfiles_mn),1);  % Variable to track which deployments are usable for HFR analysis
    end

IAATOprelim_check = false; % IAATO - Shipstrike preliminary Analysis
    if IAATOprelim_check == true
        DepthPresence = table();
        LungeTable = table();
        DepthRate = {}; % Change in Depth, cell array of each dive for each deployment
        Dives = table(); % finddives2 output and stats per dive
        Surfacings = {}; % Cell structure for surfacings analysis output for each tag
    end

BORIS_BNF_check = true; % BORIS Bubble Net Feeding Analysis
    if BORIS_BNF_check == true
        skippedBORIS = [];
        BORIS_BNF = table(); %empty data table
        BORIS_path = ""; % Enter BORIS path, for your specific computer for easy processing
        % If no path exists, select path:
        if BORIS_path == ""
            [~,BORIS_path] = uigetfile('*.xlsx;*.mat','Select Any a file in the BORIS data directory');
        end
    end

% Create load tracking Variables
skippedprh = [];
skippedlunge = [];

% Cycle through all deployments in directory
for jj = 1:size(dfiles_mn)
    fname = dfiles_mn(jj).name;
    fileloc = dfiles_mn(jj).folder;
    cd([fileloc,'\', fname])

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

% Find and Load Lunge File
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

% Check File Load Status
    if isempty(lunges)
        display(strcat("Could not find lunges file for:  ", fname));
        skippedlunge = [skippedlunge;string(fname)];
    end

    if ~exist('MISHAP','var') % If the MISHAP variable was not created, set to 0.
      MISHAP = 0;
    end

 
  % Perform Functions to Loaded Files - PRH, Lunge
    % Add function blocks here if adding a new function. Will also need a
    % function selector at beginning of section.

% General Deployment Metadata Analysis
  if Metadata_check == true
      Deploy_Meta_temp = Deployment_Metadata(prh,lunges);
      Deploy_Meta = [Deploy_Meta;Deploy_Meta_temp];
  end

% HourlyMetrics Analysis
  if HourlyMetrics_check == true && exist('lunges','var')
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
    LungeTable_temp = HourlyMetrics(prh,lunges);
    LungeTable = [LungeTable; LungeTable_temp];
  elseif exist('lunges','var') == 0
      disp(strcat('No lunges found, skipping Hourly metrics analysis for: ',fname))
  end

% IAATO Preliminary Analysis - NEED TO REINTEGRATE EVENTUALLY
  if IAATOprelim_check == true
  end

% BORIS Bubble Net Audit Analysis
disp(string(prh.INFO.whaleName))
    if BORIS_BNF_check == true
        try 
            BORIS_temp = BORIS_BNF_analysis(prh,lunges,BORIS_path);
            if ~isempty(BORIS_temp)
                BORIS_BNF = [BORIS_BNF; BORIS_temp];
            end
        catch
            skippedBORIS = [skippedBORIS;string(fname)];
        end
    end

end

clearvars -except valid_FR LungeTable HourlyMetrics Bubble_Nets Deploy_Meta DepthPresence DepthRate Dives Surfacings skippedprh skippedlunge skippedstrategy BORIS_BNF
