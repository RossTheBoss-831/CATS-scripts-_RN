%% Calculate Lat and Long from Focal Follows
    % 7.6.2021
    % Originally used for 2021 Stellwagen data and conversions for GPX
    % format.
    
    %Input:
        % Excel file of Vessel GPS data [lat lon time]
            % x by 3 excel file with the above column names
            % Time is converted from gpx time format, function may not work
            % if not in gpx format.
        % Excel File of Focal Follow data [Timestamp_local Range_nm Bearing_true]
            % x by 3 excel file with the above column names

    % Need to Add:
        % GPS time, identify standard format. Only convert from GPX format
        % if format is identified.
clear;

% Import GPS Data
    [filename,fileloc]=uigetfile('*.*', 'Select GPS Data');
    cd(fileloc);
    disp('Loading GPS Data'); 
    gps = readtable(filename);

% Check if GPS data loaded
    if ~isempty(gps)
        disp('GPS Successfully Loaded');
    else
        disp('GPS Data Not Loaded');
    end


% Import Focal Follow data
    [filename,fileloc]=uigetfile('*.*', 'Select Range and Bearing Data');
    cd(fileloc);
    disp('Loading Range and Bearing Data'); 
    RaB = readtable(filename);


% Check if Range and Bearing data loaded
    if ~isempty(RaB)
        disp('Range and Bearing Data Successfully Loaded');
    else
        disp('Range and Bearing Data Not Loaded');
    end

% Convert Variables
    %UTC
        prompt = "What is the UTC correction? (ex. -4):  ";
        UTC = input(prompt);

% Convert GPS time (UTC) to datenum
    gpsdate = extractBefore(string(gps.time),"T");
    gpsdate = datetime(gpsdate,'InputFormat','yyyy-MM-dd');

    gpstime = extractBefore(extractAfter(string(gps.time),"T"),"Z");
    gpstime = datetime(gpstime,'InputFormat','HH:mm:ss');

    gpsDT = datetime(year(gpsdate),month(gpsdate),day(gpsdate),hour(gpstime),minute(gpstime),second(gpstime));

% Convert GPS time to Local Time
    gpsDT = gpsDT + hours(UTC);
    

% Find Closest Times Between Focal Follow times and GPS Times
    sec_diff = []; % Difference between matched times
    dx = datetime();
    idx = []; % Index of closest GPS time
        for ii = 1:length(RaB.Timestamp_local)

           [x i] = min(abs(datenum(RaB.Timestamp_local(ii)) - datenum(gpsDT)));
           dx(ii) = datetime(x,'ConvertFrom','datenum');
           idx(ii) = i;
           sec_diff(ii) = second(dx(ii)) + minute(dx(ii))*60 + hour(dx(ii))*120; % Time difference in seconds

           % Display check
           disp(['Focal Time',string(RaB.Timestamp_local(ii))]);
           disp(['GPS Time',string(gpsDT(i))]);
           disp(sec_diff(ii));
        end

        
% Use matlab function 'reckon' to calculate corrected GPS points of vessel
% track at focal follow points
    Corr_GPS = table();
        for ii = 1:length(RaB.Timestamp_local)
            hh = idx(ii);
            lat1 = gps.lat(hh); % Vessel Latitude
            lon1 = gps.lon(hh); % Vessel Longitude
            dist = nm2deg(RaB.Range_nm(ii)); % convert nautical miles to degrees 
            az = RaB.Bearing_true(ii);% Degrees from True North

            [lat2 lon2] = reckon(lat1,lon1,dist,az); % reckon function to find corrected GPS cooridates
            Corr_GPS = [Corr_GPS; table(RaB.Timestamp_local(ii),lat2,lon2)];
        end
        
% Assign Variable Names and add metadata
    Corr_GPS.Properties.VariableNames = {'Time','Lat','Lon'};
    metadata = table(gpsDT(idx),gps.lat(idx),gps.lon(idx),sec_diff');
    GPSdata = [Corr_GPS, metadata];
    GPSdata.Properties.VariableNames = {'Time','Lat','Lon','Vessel Time','Vessel Lat','Vessel Lon','Time Difference (Seconds)'};

% Save File
    writetable(GPSdata, 'FocalFollow_GPS.csv');



