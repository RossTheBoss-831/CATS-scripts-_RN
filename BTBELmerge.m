% Merge BTBEL Export Tables
%     The BTBELmerge script can be opened in Matlab (any 2022 version, although it probably works in all versions).
%     
%     What does it do:
% 	    -This script merges the excel files exported from the ipad into a single worksheet
%     
%     What is required:
% 	    - All excel export files need to be in the same folder
% 	    - Matlab must be installed on computer
%     
%     How to Run:
% 	    - After your excel files are exported from the ipad and downloaded to your computer
% 	    - Open the script in Matlab (double click script)
% 	    - Press the "Run" play button in Matlab
% 	    - A new window will open, in this window select all (you can select multiple files) excel export files you wish to merge
% 	    - Press "open"
% 	    - The script will run and a file called "BTBELmerge.xlsx" will be created in the same folder as your export files.

function BTBELmerge

    % Set Export Filename
    filename = "BTBELmerged.xlsx";
    
    % Select Files
    [importfiles, path] = uigetfile('*.xlsx','Select the INPUT DATA FILE(s)','MultiSelect','on');
    filename2 = [char(path),char(filename)]; % Add path
    
    % Import and Write Table for each file
    for ii = 1:length(importfiles)
        filepath = [char(path), char(importfiles(ii))];
        T = readtable(filepath,'VariableNamingRule','preserve');
    
        tn = char(importfiles(ii)); % Extract Table name
        tn = tn(7:end-5); % remove Export and filetype
    
        writetable(T,filename2,'sheet',tn);
    end

end