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

% Loop through each CSV file and append its content to the combined table
for i = 1:length(csvFiles)
    filePath = fullfile(folderPath, csvFiles(i).name);
    tempTable = readtable(filePath);
    combinedTable = [combinedTable; tempTable];
end

% Define the output file path
outputFilePath = fullfile(folderPath, 'combined.csv');

% Export the combined table as a CSV file
writetable(combinedTable, outputFilePath);

disp(['Combined CSV file saved to: ' outputFilePath]);
