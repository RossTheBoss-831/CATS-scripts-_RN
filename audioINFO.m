% CATS Info For Arianna

% Total Data Time
try
    DataTimeHours = ((size(DN,1)/fs)/60)/60;
    disp(strcat("Total Data Time (hours) = ",string(DataTimeHours)))
catch
    disp("Error calculating Total data time")
end
% Total Data Time on Animal (Hours)
try
    DataOnAnimalHours = ((size(DN(tagon),1)/fs)/60)/60;
    disp(strcat("Total Data Time - ON ANIMAL (hours) = ",string(DataOnAnimalHours)))
catch
     disp("Error calculating Total Data time - ON ANIMAL")
end

% Total Aud Time (using audon)
try
    audiotime = ((size(DN(audon),1)/fs)/60)/60;
    disp(strcat("Total Audio Time - ON ANIMAL (hours) = ",string(audiotime)))
catch
    disp("Error calculating Total Audio Time")
end

% Total Number of Videos on Animal
try
    numofvids = length(viddeploy);
    disp(strcat("Number of Videos - On Animal = ",string(numofvids)))
catch
    disp("Error calculating Total number of videos")
end
% Total Video Time (Hours)
try
    totalVidTime = (nansum(vidDurs(viddeploy))/60)/60;
    disp(strcat("Total Video Time - On Animal (hours) = ",string(totalVidTime)))
catch
    disp("Error calculating Total Video time")
end

% Flownoise
try
    flowNoiseTime = ((sum(~isnan(flownoise))/fs)/60)/60;
    disp(strcat("Total Flow Noise data (hours) = ",string(totalVidTime)))
catch
    disp("Error calculating Total Video time")
end