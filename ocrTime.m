% ocrTime

% Need to add
    % Time could appear multiple times, need to make sure it is the correct
    % time, aka take first instance or check that it exists in the top
    % quadrant of the video by using the text position information.
    % Combined with the size of the image in pixels.

    %VidDuration = 2
    function [Time,Time_string, index, DurDelta, TimePosition_out, IndexPosition_out] = ocrTime(vidObj,AnalysisDur,TimePosition,IndexPosition)

vidObj.CurrentTime = AnalysisDur; % Set Video Duration to variable
vidFrame = readFrame(vidObj); % Read Video Frame
results = ocr(vidFrame); % Perform OCR

TimePosition_OG = TimePosition;
IndexPosition_OG = IndexPosition;

% Display Text and Bounding Boxes - If you want to see the boundary
% boxes, run this
% figure % Generate Fig
% word = results.Words
% wordBBox = results.WordBoundingBoxes
% Iname = insertObjectAnnotation(vidFrame,"rectangle",wordBBox,word);
% imshow(Iname)
    
% Time Identification Section
    % This gets Time First, then index of that Time.
 

% Set Duration Change Variable
DurDelta = 0;

% Manually Selected Positions of Time and Index
TimePosition_out = [];
IndexPosition_out = [];

checkTime = [];
while isempty(checkTime)

    % Reset Output Variables:
    Time = [];
    Time_string = [];
    index = [];

    time = find(ismember(results.Words,'Time'));

    if ~isempty(time)
        time = time(1); % First Instance
        checkequals = results.Words{time+1} == '=';
        if ~isempty(checkequals)
            checkvalue = results.Words{time+2};
            pat = '\d{2}:\d{2}:\d{2}.\d{1}';
    
           if ~isempty(regexp(checkvalue, pat, 'match'))
               formatSpec = 'HH:mm:ss.S';
               dateTimeObj = datetime(checkvalue, 'InputFormat', formatSpec);
               TimePosition_out = results.WordBoundingBoxes(time+2,:);
               Time = timeofday(dateTimeObj);
               Time_string = string(checkvalue);
           else
                disp('Time in unrecognized Format')
           end
    
        else % If Equals is not found in next index
            disp('Could not Find Equals')
        end
    
    else % If Time Word is not found
        disp('Could not Find Time in Words')
    end

    % If Time is not found automatically, try using input Bounding Boxes
        if isempty(Time) & ~isempty(TimePosition)
            expandAttempt = 10; % Number of times it expands the bounds looking for a time pattern
            scaleFactor_height = 1.4; % Expansion factor if not found with original bounds on each iteration
            scaleFactor_width = 1.05; % Expansion factor if not found with original bounds on each iteration

            BB = 0; % Tracker index

            while BB <= expandAttempt & isempty(Time)
                BB = BB + 1; % Tracker for number of Tries

                if BB > 1 % If no match is found on the first try, expand bounds
                    
                    % Expand to New Width and Height by ScaleFactor
                    originalWidth = TimePosition(3);
                    originalHeight = TimePosition(4);
                    newWidth = originalWidth * scaleFactor_width;
                    newHeight = originalHeight * scaleFactor_height;
                    % Shift new Center Position to Original Center Position
                    left = TimePosition(1);
                    bottom = TimePosition(2);
                    
                    % Calculate the adjustment needed
                    deltaWidth = newWidth - originalWidth;
                    deltaHeight = newHeight - originalHeight;
                    
                    % Adjust the left and bottom to keep the center the same
                    TimePosition(1) = left - deltaWidth / 2;
                    TimePosition(2) = bottom - deltaHeight / 2;
                    
                    % Update the width and height
                    TimePosition(3) = newWidth;
                    TimePosition(4) = newHeight;
                end

                selectedRegion = imcrop(vidFrame, TimePosition);
                % imshow(selectedRegion)
                results_TimeBounds = ocr(selectedRegion);
                checkvalue = regexp(results_TimeBounds.Text, '\d{2}:\d{2}:\d{2}.\d{1}', 'match');
        
               if ~isempty(checkvalue)
                   formatSpec = 'HH:mm:ss.S';
                   dateTimeObj = datetime(checkvalue, 'InputFormat', formatSpec);
                   TimePosition_out = TimePosition;
                   Time = timeofday(dateTimeObj);
                   Time_string = string(checkvalue);
               else
                    disp('Expanding Bounding Box')
               end
            end

            % If Auto-Detection was Unsuccesful, change the time position
            % back to original input to avoid runaway positions.
            if isempty(Time)
               TimePosition = TimePosition_OG;
            end

        end

    % % If Variables not Found during script, enter placeholders
    % if ~exist('Time','Var')
    %     Time = duration();
    %     timeString = "";
    % end

    % Index Identification Section
    while isempty(index)
    
        % % Search for index word
        % pattern = 'index'; 
        % findindex1 = find(cellfun(@(x) ~isempty(regexp(x, pattern, 'match')), results.Words));

        % Search for Index Digits Pattern
        findindex = [];
        pattern = '^\d+:\d+$';
        findindex = find(cellfun(@(x) ~isempty(regexp(x, pattern, 'match')), results.Words));

        if ~isempty(findindex)
            findindex(find(results.WordBoundingBoxes(findindex, 2) > vidObj.Height*.75)) = []; % Remove points found in the lower 75 percent of video. Which are likely from the Time Series plot
        end

        if ~isempty(findindex)
            IndexPosition_out = results.WordBoundingBoxes(findindex,:);
            index = str2num(extractBefore(results.Words{findindex},':'));
        end

        % If Index is not found automatically, try using input Bounding Boxes
        if isempty(index) & ~isempty(IndexPosition)

            expandAttempt = 10; % Number of times it expands the bounds looking for a time pattern
            scaleFactor_height = 1.4; % Expansion factor if not found with original bounds on each iteration
            scaleFactor_width = 1.05; % Expansion factor if not found with original bounds on each iteration

            BB = 0; % Tracker index

            while BB <= expandAttempt & isempty(index)
                BB = BB + 1; % Tracker for number of Tries

                if BB > 1 % If no match is found on the first try, expand bounds
                    
                    % Expand to New Width and Height by ScaleFactor
                    originalWidth = IndexPosition(3);
                    originalHeight = IndexPosition(4);
                    newWidth = originalWidth * scaleFactor_width;
                    newHeight = originalHeight * scaleFactor_height;
                    % Shift new Center Position to Original Center Position
                    left =IndexPosition(1);
                    bottom = IndexPosition(2);
                    
                    % Calculate the adjustment needed
                    deltaWidth = newWidth - originalWidth;
                    deltaHeight = newHeight - originalHeight;
                    
                    % Adjust the left and bottom to keep the center the same
                    IndexPosition(1) = left - deltaWidth / 2;
                    IndexPosition(2) = bottom - deltaHeight / 2;
                    
                    % Update the width and height
                    IndexPosition(3) = newWidth;
                    IndexPosition(4) = newHeight;
                end

                selectedRegion = imcrop(vidFrame, IndexPosition);
                
                results_IndexBounds = ocr(selectedRegion);
                findindex = regexp(results_IndexBounds.Text, '\d+', 'match');
        
                if ~isempty(findindex)
                    figure;
                    imshow(selectedRegion);
                    xlabel(string(findindex{1}),'FontSize',18);

                    % Get the position of the current figure
                    fig = gcf;
                    figPosition = get(fig, 'Position');
                    
                    % Define the offset to position the dialog to the right
                    offset = 450;
                    set(fig, 'Position', [figPosition(1) - offset, figPosition(2), figPosition(3), figPosition(4)]);

                    % Give User a Dialog to Confirm Index (Index looks like
                    % every other number on this screen, and the colon is
                    % difficult to detect using OCR
                    choice = questdlg('Select an option:', 'Options', 'Index is Correct', 'Index is Not Correct', 'Enter Index Manually', 'Index is Correct');

                    % Check the user's choice
                    switch choice
                        case 'Index is Correct'
                            IndexPosition_out = IndexPosition;
                            index = str2num(findindex{1});
                        case 'Index is Not Correct'
                            findindex = [];
                        case 'Enter Index Manually'
                            prompt = 'Enter the Index:  ';
                            userInput = inputdlg(prompt);
                            %userInput = string(input('Enter the Index:  '))
                            index = str2num(userInput{1});
                        case 'Index not Correct and Stop Auto-Detect'
                            BB = expandAttempt + 1;
                            findindex = [];
                    end

               else
                    disp('Expanding Bounding Box')
               end

               close all

            end

            % If Auto-Detection was Unsuccesful, change the time position
            % back to original input to avoid runaway positions.
            if isempty(index)
               IndexPosition = IndexPosition_OG;
            end

        end
    
        % If Values could not be found confidently automatically, move to
        % manual approach:
        if isempty(Time) | isempty(Time_string) | isempty(index)
            manualcheck = 0;
        else
            manualcheck = 1;
        end

        while manualcheck ~= 1

            % Manual Time Identification
            % If Time was not found, perform Time Identification first
            while isempty(Time)
                % Plot Image and Identify Time
                figure(1);
                imshow(vidFrame);
                zoom on;

                % Display a message prompting the user to press Enter
                disp(strcat("Zoom in on TIME as Needed. ", "Press Enter when ready to Draw Bounding Box", ...
                    " If you want to Analyze a Different Frame (+/- 1 Frame), Press S"))
                title("Select TIME",'FontSize',18)
                xlabel(strcat("Zoom in on TIME as Needed. ", "Press Enter when ready to Draw Bounding Box", ...
                    " If you want to Analyze a Different Frame (+/- 1 Frame), Press S"))
                % Enter - Continue (13)
                % S = (115) - New Frame - Skips 1 Second Forward and generates new Frame
                c = 0;
                while ~ismember(c,[13,115])
                    w = waitforbuttonpress;
                    if w == 1
                        c = double(get(gcf,'CurrentCharacter'))
                    end
                end
                zoom off;

                % Change Frame
                if c == 115
                    % Set Video Duration to + 1 Frame (based on frame rate of video), unless at the end of
                    % the video
                    if AnalysisDur + 1 < vidObj.Duration && ~exist('EndPosition','var')
                        % AnalysisDur = AnalysisDur + 1;
                        AnalysisDur = AnalysisDur + (1/vidObj.FrameRate);
                        vidObj.CurrentTime = AnalysisDur;
                        DurDelta = DurDelta + (1/vidObj.FrameRate);
                    else
                        EndPosition = 1; % This prevents a video from going back and forth at the end. Marking that we are at the end of the video and to keep going backwards until a good frame
                        AnalysisDur = AnalysisDur - (1/vidObj.FrameRate);
                        vidObj.CurrentTime = AnalysisDur;
                        DurDelta = DurDelta - (1/vidObj.FrameRate);
                    end

                    % Re-Perform OCR
                    disp(strcat("Now Displaying at Duration (s): ", string(AnalysisDur)))
                    vidObj.CurrentTime = AnalysisDur; % Set Video Duration to variable
                    vidFrame = readFrame(vidObj); % Read Video Frame
                    results = ocr(vidFrame); % Perform OCR

                    % ADD SKIP TO NEXT FRAME
                    close all % close figures
                    continue;
                end
                % Prompt the user to select a bounding box
                disp('Draw a Box Around the TIME, Press Enter to Select')
                title('Draw a Box Around the TIME, Press Enter to Select')
                r1 = drawrectangle('Label','OuterRectangle','Color',[1 0 0]);
                
                % Extract the selected region from the image
                TimePosition_out = r1.Position; % Selected Time Position
                selectedRegion = imcrop(vidFrame, TimePosition_out);
                
                
                fig = figure(1);
              
                % Plot Cropped Selected Region
                imshow(selectedRegion);
        
                % Set Figure to Middle of Screen and Correct Size for easy viewing :)
                % Get the screen size
                screenSize = get(0, 'ScreenSize');
                
                % Calculate the position to center the figure
                figWidth = 600; % Set the width of your figure
                figHeight = 400; % Set the height of your figure
                figX = (screenSize(3) - figWidth) / 2;
                figY = (screenSize(4) - figHeight) / 2;
                
                % Set the figure's position
                set(fig, 'Position', [figX, figY, figWidth, figHeight]);
        
                % Get the current position of the figure
                figPosition = get(gcf, 'Position');
                
                % Get the current position of the xlabel
                xlabelPosition = get(get(gca, 'xlabel'), 'Position');
                
                % Adjust the figure width based on the xlabel width
                newWidth = figPosition(3) + xlabelPosition(3);
                figPosition(3) = newWidth;
                
                % Set the new position for the figure
                set(gcf, 'Position', figPosition);
        
                % Perform OCR on Selected Region
                results_select = ocr(selectedRegion);
        
                % Check OCR for Index - Look for Digits
                pattern = '\d{1,2}:\d{2}:\d{2}\.\d'; 
                selectcheck = regexp(results_select.Text,pattern,'match');
                if isempty(selectcheck)
                    selectcheck{1} = "No Match Found";
                end
                xlabel(['Selected Region';string(selectcheck{1});'Press the Corresponding Key:'; ...
                    'Enter - Correct Value'; 'T - Try Again, Re-Draw Box'; 'M - Manual Entry'; 'S - Skip Value (Filler Value will be added, -2)'], 'FontSize', 16)
                disp(['Selected Region';string(selectcheck{1});'Press the Corresponding Key:'; ...
                    'Enter - Correct Value'; 'T - Try Again, Re-Draw Box'; 'M - Manual Entry'; 'S - Skip Value (Filler Value will be added, -2)'])
        
                % Wait for User Input
                    % Enter = Correct Info Found (13)
                    % T = Try Box Again (116)
                    % M = Manual Entry (109)
                    % S = Skip (115)
                c = 0;
                while ~ismember(c,[13,109,115,116])
                    w = waitforbuttonpress;
                    if w == 1
                        c = double(get(gcf,'CurrentCharacter'))
                    end
                end
        
                % Handle User Selection
                switch c
                    case 13 % Enter = Correct Info Found (13)
                        Time_string = string(selectcheck{1})
                        formatSpec = 'HH:mm:ss.S';
                        dateTimeObj = datetime(string(selectcheck{1}), 'InputFormat', formatSpec);
                        Time = timeofday(dateTimeObj);
                    case 109 % M = Manual Entry (109)
                        % Get user input for a number
                        prompt = 'Enter the Time in the format HH:mm:ss.S :   ';
                        % userInput = string(input('Enter the Time in the format HH:mm:ss.S :   ','s'));
                        userInput = inputdlg(prompt)
                        formatSpec = 'HH:mm:ss.S';
                        dateTimeObj = datetime(userInput, 'InputFormat', formatSpec);
                        Time_string = string(userInput{1});
                        Time = timeofday(dateTimeObj);
                    case 115 % S = Skip (115)
                        disp('Index Could not be Found')
                        Time = timeofday(NaT);
                        Time_string = "NaN";
                    case 116 % T = Try Box Again (116)
                        % Repeat Loop
                        continue;
                end

                % Close Figures
                close all

            end % End Time Identification Section

            % Manual Index Identification Section
            while isempty(index)
                % Plot Image and Identify Index
                figure(1);
                imshow(vidFrame);
                zoom on;
                
                % Display a message prompting the user to press Enter
                disp(strcat("Zoom in on INDEX as Needed.", " Press Enter when ready to Draw Bounding Box", ...
                    " If you want to Analyze a Different Frame (+/- 1 Sec), Press N"))
                title("Select INDEX",'FontSize',18)
                xlabel(strcat("Zoom in on INDEX as Needed.", " Press Enter when ready to Draw Bounding Box", ...
                    " If you want to Analyze a Different Frame (+/- 1 Sec), Press N"))
                % Enter - Continue (13)
                % N - New Frame - Skips 1 Second Forward and generates new Frame
                c = 0;
                while ~ismember(c,[13,78])
                    w = waitforbuttonpress;
                    if w == 1
                        c = double(get(gcf,'CurrentCharacter'))
                    end
                end
                zoom off;
        
                % If User Asks to Change Frame
                if c == 78
                    % Set Video Duration to + 1 Frame (based on frame rate of video), unless at the end of
                    % the video
                    if AnalysisDur + 1 < vidObj.Duration && ~exist('EndPosition','var')
                        % AnalysisDur = AnalysisDur + 1;
                        AnalysisDur = AnalysisDur + (1/vidObj.FrameRate);
                        vidObj.CurrentTime = AnalysisDur;
                        DurDelta = DurDelta + (1/vidObj.FrameRate);
                    else
                        EndPosition == 1;
                        AnalysisDur = AnalysisDur - (1/vidObj.FrameRate);
                        vidObj.CurrentTime = AnalysisDur;
                        DurDelta = DurDelta - (1/vidObj.FrameRate);
                    end

                    % Re-Perform OCR
                    disp(strcat("Now Displaying at Duration (s): ", string(AnalysisDur)))
                    vidObj.CurrentTime = AnalysisDur; % Set Video Duration to variable
                    vidFrame = readFrame(vidObj); % Read Video Frame
                    results = ocr(vidFrame); % Perform OCR

                    % ADD SKIP TO NEXT FRAME
                    close all % close figures
                    Time = []; % Redo Time if Index Frame Fails.
                    index = []; % Redo index due to redo of Time
                    continue;
                end
        
                % Prompt the user to select a bounding box
                disp('Draw a Box Around the INDEX Number, Press Enter to Select')
                title('Draw a Box Around the INDEX Number, Press Enter to Select')
                r1 = drawrectangle('Label','OuterRectangle','Color',[1 0 0]);
                
                % Extract the selected region from the image
                IndexPosition_out = r1.Position;
                selectedRegion = imcrop(vidFrame, IndexPosition_out);
                
                fig = figure(1);
              
                % Plot Cropped Selected Region
                imshow(selectedRegion);
        
            % Set Figure to Middle of Screen and Correct Size for easy viewing :)
                % Get the screen size
                screenSize = get(0, 'ScreenSize');
                
                % Calculate the position to center the figure
                figWidth = 600; % Set the width of your figure
                figHeight = 400; % Set the height of your figure
                figX = (screenSize(3) - figWidth) / 2;
                figY = (screenSize(4) - figHeight) / 2;
                
                % Set the figure's position
                set(fig, 'Position', [figX, figY, figWidth, figHeight]);
        
                % Get the current position of the figure
                figPosition = get(gcf, 'Position');
                
                % Get the current position of the xlabel
                xlabelPosition = get(get(gca, 'xlabel'), 'Position');
                
                % Adjust the figure width based on the xlabel width
                newWidth = figPosition(3) + xlabelPosition(3);
                figPosition(3) = newWidth;
                
                % Set the new position for the figure
                set(gcf, 'Position', figPosition);
        
                % Perform OCR on Selected Region
                results_select = ocr(selectedRegion);
        
                % Check OCR for Index - Look for Digits
                pattern = '\d+'; 
                selectcheck = regexp(results_select.Text,pattern,'match');
                if isempty(selectcheck)
                    selectcheck{1} = "No Match Found"
                end
                xlabel(['Selected Region';string(selectcheck{1});'Press the Corresponding Key:'; ...
                    'Enter - Correct Value'; 'T - Try Again, Re-Draw Box'; 'M - Manual Entry'; 'S - Skip Value (Filler Value will be added, -2)'], 'FontSize', 16)
                disp(['Selected Region';string(selectcheck{1});'Press the Corresponding Key:'; ...
                    'Enter - Correct Value'; 'T - Try Again, Re-Draw Box'; 'M - Manual Entry'; 'S - Skip Value (Filler Value will be added, -2)'])
        
                % Wait for User Input
                    % Enter = Correct Info Found (13)
                    % T = Try Box Again (116)
                    % M = Manual Entry (109)
                    % S = Skip (115)
                c = 0;
                while ~ismember(c,[13,109,115,116])
                    w = waitforbuttonpress;
                    if w == 1
                        c = double(get(gcf,'CurrentCharacter'));
                    end
                end
        
                % Handle User Selection
                switch c
                    case 13 % Enter = Correct Info Found (13)
                        index = str2double(selectcheck{1});
                    case 109 % M = Manual Entry (109)
                        prompt = 'Enter the Index:  ';
                        userInput = inputdlg(prompt);
                        %userInput = string(input('Enter the Index:  '))
                        index = str2num(userInput{1});
                    case 115 % S = Skip (115)
                        disp('Index Could not be Found')
                        index = -2;
                        manualcheck = 1;
                        continue;
                    case 116 % T = Try Box Again (116)
                        % Repeat Loop
                        continue;
                end

                % Close Figures
                close all

            end
            manualcheck = 1;
        end 
    end

    if ~isempty(Time) & ~isempty(Time_string) & ~isempty(index)
        checkTime = 1;
    end
end % Time While Loop
%disp('OCR Complete')
end

