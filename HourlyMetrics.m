
 % Hourly Metrics - Feeding - Presence


function LungeTable = HourlyMetrics(prh,lunges)

  
  % Load sample data (COMMENT OUT BEFORE RUNNING FOR REAL)
%     FeedingRate = table();
%     prh = load('D:\Remote Work Enviornment\LTER_Humpback Foraging in the Antarctic Summer\CATS DATA\mn200105-52 (Antarctic)\mn200105-52 10Hzprh.mat');
%     lunges = load('D:\Remote Work Enviornment\LTER_Humpback Foraging in the Antarctic Summer\CATS DATA\mn200105-52 (Antarctic)\mn200105-52lunges.mat');
%     dfiles_mn = 1
%     jj = 1
    
   
        
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
                             
   

                % LUNGE STATS TABLE (Made for Jenny Allen)
                    % Uses function LungeStats
                if exist('lunges','var')
                    LungeTable = LungeStats(lunges.LungeI,prh.p,prh.DN,prh.INFO.whaleName,prh.INFO.UTC);
                    
                end


end