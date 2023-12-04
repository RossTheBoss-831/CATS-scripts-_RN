%% IAATO Summary Statisics (For use in Batch)

function ShipStrike_prelim(prh)

 % IAATO DATA TABLES and VALUES 

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

               
                
                 % Create data row and add to table
                    % Added UU, which indicates the number of hours since
                    % the analytical tag on began. Used for the temporal
                    % auto-correlation
                     
                     temp_HourlyMetrics = table(WID, Lat, Lon, Year, Month, Day, DOY, HOD, MSE, CSE, HFR, MLD, UU, SURF_H, SUBSURF_H, ATDEPTH_H);
                     HourlyMetrics = [HourlyMetrics; temp_HourlyMetrics];
                     temp_HourlyMetrics = [];
                 end % End of Hourly Based Stats
                    

        %IAATO Deployment Based Dive Statistics
     
         % DEPTH PRESENCE TABLE: Seconds within 1m Bin Depths (0 to 500m)
                    temp_histo = histogram(abs(prh.p),'BinEdges',[0:1:500]); % create histogram with 1m bins to 500m
                    temp_Depth_Presence = array2table(temp_histo.Values/prh.fs, 'VariableNames',string([1:1:500]), 'RowNames', string(WID)); % Convert values of histagram to seconds
                    close % close histogram plot
                    DepthPresence = [DepthPresence; temp_Depth_Presence];

                % DIVES TABLE - Dive Statistics and Metadata - finddives2
                % finddives2 table ->[start_cue(in seconds) end_cue(in seconds) max_depth cue_at_max_depth mean_depth mean_compression]
                    FD = finddives2(prh.p,prh.fs,5); % Threshold defined in Threshold Section of script set to 5 meters
                    
                    % Calculate Dive Stats and Create Dive Table
                        % Dive Duration
                            divedur = FD(:,2) - FD(:,1); % Dive Duration in Seconds
                            maxdivedur = max(divedur); % Longest Dive in Deployment (Defines length of DepthChange Table)
                    
                        % Start and End of Dives - Index Values
                            Start_Cue_Idx = FD(:,1) * prh.fs;
                            End_Cue_Idx = FD(:,2) * prh.fs;
                            MaxDepth_Cue_Idx = FD(:,4) * prh.fs;

                    % Rates of Depth Change (DC) for each detected dive
                        DepthChange = NaN(ceil(max(divedur)),length(Start_Cue_Idx)); % Creates array with Columns equal to number of dives and rows equal to longest dives (1 Second = 1 row)
                        
                        rt = 1; % Amount of time in seconds to measure differenes in depth
                        for i = 1:length(Start_Cue_Idx)
                            DC = Start_Cue_Idx(i):rt*prh.fs:End_Cue_Idx(i);
                            for k = 1:length(DC)- 2 % minus 2 is to prevent going over index when measuring rate
                               DepthChange(k,i) = mean(prh.p(DC(k+1):DC(k+2)-1)) - mean(prh.p(DC(k):DC(k+1)-1));
                            end
                        end

                    % Add DepthChange to Final cell array
                        DepthRate(jj) = {DepthChange}; 

                        
                    % Auto-Identify Decent Phase
                        Descent_Cue = NaN(size(DepthChange,2),1); % Number of seconds of into dive considered the "descent"
                        window = 6; %  Window amount of time (in seconds) reviewed of which mintime is evaluated
                        mintime = 5; % Threshold amount of seconds needing to be NOT descending before defining end
                        % of descent phase.
                    for i = 1:size(DepthChange,2) % For Each Dive
                        for k = 1:size(DepthChange,1)- window  % For each second of Dive
                            if sum(DepthChange(k:k+window-1,i)<=0) >= mintime % 
                                Descent_Cue(i,1) = k;
                                break
                            end
                        end
                    end
                    
                    % Auto-Identify Ascent Phase
                        Ascent_Cue = NaN(size(DepthChange,2),1); % Number of seconds of into dive considered the "ascent"
                        window = 6;
                        mintime = 5; % Amount of time (in seconds) NOT ascending before defining start
                        % of ascent phase. Looks at dive in reverse.
                    for i = 1:size(DepthChange,2) % For Each Dive
                        flipdive = flip(DepthChange(:,i)); % flips dive
                        for k = 1:size(DepthChange,1)- window % For each second of Dive
                            if sum(flipdive(k:k+window-1)>=0) >= mintime
                                 % last index of dive
                                Ascent_Cue(i,1) = size(DepthChange,1)- k;
                                break
                            end
                        end
                    end
                    
                    % Remove NaNs from

                    % Check if Ascent and Descent overlap, if so, swap variables. (Overlaping can occur on short or irregular dives where 
                    % the opposite detection works better) Thus, swapping helps better identify phases.
                        for ii = 1:length(Ascent_Cue)
                            if Ascent_Cue(ii) < Descent_Cue(ii) & Ascent_Cue(ii)*Descent_Cue(ii) ~= 0
                                % If so, swap variables
                                tempA = Ascent_Cue(ii);
                                Ascent_Cue(ii) = Descent_Cue(ii);
                                Descent_Cue(ii) = tempA;
                                tempA = [];
                            end
                        end

                    % Create Index Variables for Ascent and Descent
                        Ascent_idx = (FD(:,1) + Ascent_Cue) * prh.fs; % Start cue of Dive + Ascent Cue time multiplied by sampling rate
                        Descent_idx = (FD(:,1) + Descent_Cue) * prh.fs; % Create Index Variable

                    % Descent End Depth - Depth at which the Descent phase turns to Bottom Phase
                        Descent_End_Depth = []; 
                        for DD = 1:length(Descent_idx)
                             if isnan(Descent_idx(DD))
                                 Descent_End_Depth(DD,1) = NaN;
                             else
                                 Descent_End_Depth(DD,1) = prh.p(Descent_idx(DD));
                             end
                         end
                    % Ascent Start Depth - Depth at which the animal begins their ascent to the surface
                         Ascent_Start_Depth = [];
                         for DD = 1:length(Ascent_idx)
                             if isnan(Ascent_idx(DD))
                                 Ascent_Start_Depth(DD,1) = NaN;
                             else
                                 Ascent_Start_Depth(DD,1) = prh.p(Ascent_idx(DD));
                             end
                         end
                    % Descent Duration - Duration from Dive Start to End of Descent
                        Descent_Dur = Descent_Cue;
                    % Ascent Duration - Duration from Start of Ascent to End of Dive (surface)
                        Ascent_Dur = divedur - Ascent_Cue;

                    % Mean Descent Rate - Average rate of Depth Change during Descent Phase
                        Dive_Start_Depth = prh.p(Start_Cue_Idx);
                        Mean_Descent_Rate = (Descent_End_Depth - Dive_Start_Depth) ./ Descent_Dur;

                    % Mean Ascent Rate - Average rate of Depth Change during Ascent Phase
                        Dive_End_Depth = prh.p(End_Cue_Idx);
                        Mean_Ascent_Rate = (Dive_End_Depth - Ascent_Start_Depth) ./ Ascent_Dur;

                    % Local Times of Dive Events
                        DT = datetime(prh.DN, 'ConvertFrom', 'datenum'); % local times
                        Dive_Start_LocalTime = DT(Start_Cue_Idx); % Dive Start Time
                        Dive_End_LocalTime = DT(End_Cue_Idx); % Dive End Time
                        Max_Depth_LocalTime = DT(MaxDepth_Cue_Idx); % Time at Max Depth

                    % Heading Changes during Descent
                        % convert to degrees - NOT TRUE DEGREES - ONLY RELATIVE DEGREES
                            tempHead = (prh.head + abs(min(prh.head)));
                            Degree_Head = (tempHead/max(tempHead))*360; % Convert from -pi:pi to 0:360
                            %histogram(Degree_Head)


            
                        % For each Descent, calculate changes in heading
                            % Clear Variables per deployment:
                                Max_Head_Change = [];
                                Max_Head_Change_Idx = [];
                                Max_Head_Change_Depth = [];
                                Descent_End_Heading_Change = [];
                                Max_Head_Change_Seconds = [];
                                
                            for ii = 1:length(Descent_idx)
                                Didx = Start_Cue_Idx(ii):Descent_idx(ii); % descent index
                                
                                if isnan(Didx) % Insert NaN's if Descent is NaN
                                % Max Change in Heading - set to NaN
                                    Max_Head_Change(ii,1) = NaN;
                                    Max_Head_Change_Idx(ii,1) = NaN;

                                % Depth of Max Heading Change
                                    Max_Head_Change_Depth(ii,1) = NaN;

                                % Time into Dive of Max Heading Change
                                    Max_Head_Change_Seconds(ii,1) = NaN;

                                % Heading Change at End of Descent
                                    Descent_End_Heading_Change(ii,1) = NaN;
                                    
                                else % If Descent is NOT a NaN
                                   Descent_Head = Degree_Head(Didx); % Heading values during descent
                                   
                                    Head_Change = []; % reset array per descent
                                    for gg = 1:length(Didx) % Find differences between original dive heading and headings throughout Descent
                                        Head_Change(gg) = head_diff(Descent_Head(1),Descent_Head(gg));
                                    end

                                % Max Change in Heading - ONLY FINDS THE 1st Value. If the max heading happens twice on the descent it ignores anything after 1st.
                                    [Max_Head_Change(ii,1), Max_Head_Change_Idx(ii,1)] = max(Head_Change);

                                % Depth of Max Heading Change
                                    descent_depth = prh.p(Didx);
                                    Max_Head_Change_Depth(ii,1) = descent_depth(Max_Head_Change_Idx(ii));

                                % Time into Dive of Max Heading Change
                                    Max_Head_Change_Seconds(ii,1) = Max_Head_Change_Idx(ii)/prh.fs;

                                % Heading Change at End of Descent
                                    Descent_End_Heading_Change(ii,1) = Head_Change(end);
                                    
                                end
                            end



                    % Consolidate Variables into Dive Table
                        %finddives2 export table-> [start_cue(in seconds) end_cue(in seconds) max_depth cue_at_max_depth mean_depth mean_compression]
                            FindDives = FD; % rename variables for ease of reading
                            Dive_Start_Cue = FindDives(:,1);
                            Dive_End_Cue = FindDives(:,2);
                            Max_Depth = FindDives(:,3);
                            cue_at_max_depth = FindDives(:,4);
                            mean_depth = FindDives(:,5);
                            mean_compression = FindDives(:,6);
                            % Assign Table
                                temp_Dives = table(repmat(WID,size(FD,1),1), Dive_Start_LocalTime, Start_Cue_Idx, Dive_Start_Depth, Dive_End_LocalTime, End_Cue_Idx, Dive_End_Depth, divedur, Descent_End_Depth,...
                                    Descent_Dur, Mean_Descent_Rate, Descent_Cue, Descent_idx, Ascent_Start_Depth, Ascent_Dur, Mean_Ascent_Rate, Ascent_Cue, Ascent_idx,...
                                    Dive_Start_Cue, Dive_End_Cue, Max_Depth, Max_Depth_LocalTime, cue_at_max_depth,...
                                    Max_Head_Change, Max_Head_Change_Depth, Max_Head_Change_Seconds, Descent_End_Heading_Change, mean_depth, mean_compression);
                                Dives = [Dives; temp_Dives];
                                
                    % SURFACINGS ANALYSIS - using the findsurfacings.m script in CATS TOOLS
                        period = 60; % Default Value for time chunck period of analysis 
                        thresh = 1; % Default threshold for surfacing detection
                        surfs = []; % Reset Variable
                        surfs = findsurfacings(prh.p,prh.fs,prh.tagon,period,thresh);
                    
                    % Add Surfacings analysis to cell table
                        Surfacings(jj) = {surfs};
                    
                    
                    % Rate of Depth Change Plots - NEEDS WORK
%                         if diveplotson ==  true     
%                             for dp = 1:size(DepthChange,2)
%                                 plot(-DepthChange(~isnan(DepthChange(:,dp)),dp)); % Plots only values and removes NaN fillers
%                                 if dp == 1
%                                 hold on
%                                 yline(0)
%                                 end
%                             end
%                         end
                        
                    
                    % Surfacing Duration - use findsurfacing script?
                    % Number of Breaths

                % END OF IAATO ANALYSIS

end