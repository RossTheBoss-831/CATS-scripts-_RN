% Merge BTBEL Export Tables
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