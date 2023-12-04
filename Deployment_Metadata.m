function Deploy_Meta = Deployment_Metadata (prh, lunges)

% Depoyment Metadata - Process for creating the Deploy_Meta Table

  if ~isempty(prh)
      % Tag on and Tag Off Times
      whaleName = prh.INFO.whaleName; % Tag ID
      WID = string(prh.INFO.whaleName); % whale ID
      tagon_localtime = datetime(prh.DN(find([prh.tagon] == 1,1,'first')), 'convertfrom','datenum');
      tagoff_localtime = datetime(prh.DN(find([prh.tagon] == 1,1,'last')), 'convertfrom','datenum');

      try UTC = prh.INFO.UTC; % UTC 
      catch
           UTC = -3;
           disp(strcat('UTC not found in PRH file, setting to default of: ',string(UTC)))
      end

      % On Whale Data Duration
      data_duration = sum([prh.tagon])/prh.fs/60/60; % Duration in hours
      % Video Data Duration (On-Whale)
      if isfield(prh,'camon')
        vid_duration = length(find([prh.tagon] & [prh.camon] == 1))/10/60/60; % Duration in Hours
      else
        vid_duration = 0;
      end
      % Audio Data Duration (On-Whale)
      if isfield(prh,'audon')
        aud_duration = length(find([prh.tagon] & [prh.audon] == 1))/10/60/60;
      else
        aud_duration = 0;
      end
      
      if ~isempty(lunges)
      % Number of Detected Lunges
        lunge_count = length([lunges.LungeI]);
      else
          lunge_count = 0;
      end


      % IAATO VALUES per deployment
        % Percentage of Time in 0 - 5 meters (Surface)
            SURF = sum(prh.p(prh.tagon) <= 5)/sum(prh.tagon)*100;
        % Percentage of Time in Near Surface based on avg cruise ship draft (>5 - 15 meters)
            SUBSURF = sum(prh.p(prh.tagon) > 5 & prh.p(prh.tagon) <= 15)/sum(prh.tagon)*100;
        % Percentage at Depth
            ATDEPTH = 100 - (SURF + SUBSURF);

      % Add to Deploy_Meta Table
      Deploy_Meta = table(string(whaleName),tagon_localtime,tagoff_localtime,UTC,data_duration,vid_duration,aud_duration,lunge_count,SURF, SUBSURF, ATDEPTH);
      
  else
      disp('empty PRH file, could not perform Deployment Metadata function')
  end
end