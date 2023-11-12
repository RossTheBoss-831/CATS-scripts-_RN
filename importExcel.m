% Import Excel File as a table

function ExcelData = importExcel(filepath)

if nargin < 1
    [file, path] = uigetfile('*.xlsx');
    filepath = strcat(path,file);
end

T = readtable(filepath);

end