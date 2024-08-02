% Prompt the user to select a folder
folderPath = uigetdir();

if folderPath == 0
    error('No folder selected');
end

% Find all CSV files in the selected folder
csvFiles = dir(fullfile(folderPath, '*.csv'));

if isempty(csvFiles)
    error('No CSV files found in the selected folder');
end

% Initialize an empty table
combinedTable = table();

% List to hold names of files that do not have the same number of columns
mismatchedFiles = {};

% Loop through each CSV file
for i = 1:length(csvFiles)
    filePath = fullfile(folderPath, csvFiles(i).name);
    tempTable = readtable(filePath);
    
    % If this is the first file, get the number of columns
    if i == 1
        numColumns = width(tempTable);
        combinedTable = tempTable;  % Initialize combinedTable with the first table
    else
        % Check if the number of columns matches
        if width(tempTable) == numColumns
            combinedTable = [combinedTable; tempTable];
        else
            mismatchedFiles{end+1} = csvFiles(i).name;  % Add to mismatched files list
        end
    end
end

% Define the output file path
outputFilePath = fullfile(folderPath, 'combined.csv');

% Export the combined table as a CSV file
writetable(combinedTable, outputFilePath);

disp(['Combined CSV file saved to: ' outputFilePath]);

% Print the names of files that did not match the column count
if ~isempty(mismatchedFiles)
    disp('The following files were not combined due to column mismatch:');
    for i = 1:length(mismatchedFiles)
        disp(mismatchedFiles{i});
    end
else
    disp('All files had matching columns and were combined successfully.');
end
