function trueVid = VidRangeMatch(ObsTime,VidRangeDurs, VidRange)
    % Internal Function to Match the Observation Duration Notations
    % to the video when the Observation consists of a Range
    % (##-##) of videos
        % Inputs
            % ObsTime - Time in Seconds of Observation (Start or
            % Stop)
            % VidRangeDurations - Array of Durations denoting the
            % summed durations of VidRange (See Get Video Durations
            % section)
            % VidRange - Array of Video Numbers corresponding to
            % Duration array

        T = ObsTime > VidRangeDurs;

        if sum(T) == 0 % If 0, then the Observation was during 1st video
            trueVid = 1;
        else % If not, find video
            trueVid = find(T == 0,1,'first');
        end
        trueVid = VidRange(trueVid);
    end