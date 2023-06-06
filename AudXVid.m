% Extract Audio from Video
    % Purpose:
        % Loads in video files and strips audio
    % To Run: 
        % press the Run Code button above
        % It will ask you to select a file, select any one of the video files
        % you wish to extract the audio from.
        % It will automatically extract from every video (of the same file
        % type) within the folder of the file you selected
    % Outputs into a WAV format

function[] = AudXVid(file,path)

if nargin == 1
    error("Not enough Input Arguments");
end

if nargin == 0
    [file,path] = uigetfile('..\*.*');
end

filename = strcat(path,file);
filetype = char(filename); filetype = filetype(end-3:end);

filedir = dir(path);

for ii = 1:length(filedir)

    TF = strfind(filedir(ii).name,filetype);

    if isempty(TF)
        continue
    else
        [y,Fs] = audioread(strcat(filedir(ii).folder,'\',filedir(ii).name));
        audiowrite(strcat(path,'\',extractBefore(filedir(ii).name,filetype),'.WAV'),y,Fs);

        disp(strcat(extractBefore(filedir(ii).name,filetype),' - Complete!'))
    end

end

end