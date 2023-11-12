%
% load prh file that corresponds to BORIS video
% BORIS data
% oi = '"D:\Elasmobranchs\Basking Shark\CATS\tag_data\cm220504-D1 (Ireland)\cm220504-D1 10Hzprh.mat"';
oi = '"G:\Shared drives\Basking Shark\tag_data\cm220505-C2 (Ireland)\cm220505-C2 10Hzprh.mat"';
oi = oi(2:end-1);
load(oi);

fileloc = oi(1:max(regexp(oi,'\')));

D = dir(fileloc);
D = {D.name}';
load([fileloc D{~cellfun(@isempty,cellfun(@(x) strfind(x,'truncate.mat'),D,'uniformoutput',false))}]);

%Boris audits in Analysis/BORIS folder
Bfiles = [oi(1:max(regexp(oi,'\'))) 'Analysis\BORIS\'];
D = dir(Bfiles); D = {D.name}';
% clear BORIS
warning('off','all');
%%
clear BORIS
for i = 3:length(D)

    if isfolder([Bfiles D{i}]); continue; end
    vd = readtable([Bfiles D{i}]);
    try vid = vd.MediaFile{1}; catch; vid = vd.MediaFileName{1}; end
%     vid = vid(max([regexp(vid,'\') regexp(vid,'/')])+1:end);

    s=regexp(vid,'('); m = regexp(vid,'-'); e = regexp(vid,')');
    s = s(1); e = e(1);
    if max(m)>e; m = max(m(1:end-1)); else m = max(m); end
    if m<s; m = e; end
    d = vid(s:m);
    vN1 = str2num(d(isstrprop(d,'digit')));
    if m == e; m = s; end
    d = vid(m:e);
    vN2 = str2num(d(isstrprop(d,'digit')));
        try viddur = str2num(vd.TotalLength{1}); catch; viddur = vd.MediaDuration_s_(1); end
    numgaps = (viddur-sum(vidDurs(vN1:vN2)))/3;
    if numgaps - floor(numgaps) < 1; numgaps = floor(numgaps); else error('Number of gaps could not be determined'); end
 
    Time = nan(size(vd,1),2); vN = Time; I = vN; 
    v = vN1; gapn = 0; %gap is because when auditing processed videos there are 3 seconds of dead time between videos, will only work if vidDN is set up appropriately with nans where there are no videos
%     clear vidT
%     if numgaps > 0;
%         startt = 


    if abs(viddur-sum(vidDurs(vN1:vN2))-numgaps*3)>3; 
        warning(['Video length differs from raw video length, assuming video ' num2str(v) ' was cropped by ' num2str(vidDurs(v)-viddur) ' s']);
        vidadj = sum(vidDurs(vN1:vN2))+numgaps*3-viddur;
    else vidadj = 0;
    end
    for ii = 1:size(vd,1)
        v = vN1; gapn = 0;
        Time(ii,1)= str2num(vd.Start_s_{ii})+vidadj;
        Time(ii,2)= str2num(vd.Stop_s_{ii})+vidadj;
        %         if i == 3; Time(ii) = Time(ii)+(vidDurs(vN1)-str2num(vd.Total_length{ii}));
        %         else
%         if Time(ii,1)<vidDurs(vN1); Time(ii,1) = Time(ii,1)+
            while Time(ii,2)>=sum(vidDurs(vN1:v))+2; v = v+1; if ~isnan(vidDN(v)) && ~isnan(vidDurs(v)); gapn = gapn+1; end
                if v>vN2 || gapn>numgaps; error('Misreading videonumber'); end
            end %2 seconds is wiggle room
            Time(ii,2) = Time(ii,2)-sum(vidDurs(vN1+1:v-1))-gapn*3; % 3 is duration between videos
                   vN(ii,2) = v;
            v = vN1; gapn = 0; 
            while Time(ii,1)>=sum(vidDurs(vN1:v))+2; v = v+1; if ~isnan(vidDN(v)) && ~isnan(vidDurs(v)); gapn = gapn+1; end
                if v>vN2 || gapn>numgaps; error('Misreading videonumber'); end
            end %2 seconds is wiggle room
            Time(ii,1) = Time(ii,1)-sum(vidDurs(vN1+1:v-1))-gapn*3;
%         end
        vN(ii,1) = v;
%         if abs(sum(vidDurs(vN1:vN2))-str2num(vd.Total_length{ii}))>1% && i~=3 && i~=length(D); % checks that the processed videos are the length that they should be (indicating that the BORIS time stamps are right)
%             if ii == 1; disp(['Video lengths do not agree, likely an error in ' D{i} '. Processed length: ' vd.Total_length{ii} ' s   Raw video duration: ' num2str(vidDurs(v))]); end
%             if (strcmp(vd.Behavior{ii},'Pit') || strcmp(vd.Behavior{ii},'Begin Stationary Foraging') || strcmp(vd.Behavior{ii},'End Stationary Foraging')) && ~isempty(vd.Comment{ii})
%             t = datenum(vd.Comment{ii},'HH:MM:SS.fff')-floor(datenum(vd.Comment{ii},'HH:MM:SS.fff'))+floor(vidDN(v));
%             Time(ii) = (t-vidDN(v))*24*60*60;
%             if ~exist('vidT','var'); vidT = datestr(Time(ii)/24/60/60,'MM:SS.fff'); end
%             end
%         end
        [~,I(ii,1)] = min(abs(DN-(vidDN(vN(ii,1))+Time(ii,1)/24/60/60)));
        [~,I(ii,2)] = min(abs(DN-(vidDN(vN(ii,2))+Time(ii,2)/24/60/60)));
    end
    vd.I = I;
    vd.vid = vN;
    vd.vidTime = Time;
    vd.startTime = datestr(DN(I(:,1)));
%     if exist('vidT','var'); disp(['extracting time stamps from comments section after ' vidT '.']); end
    Behav = vd.Behavior;
%     isFocal = cellfun(@(x) strcmp(x,'Focal Animal'),vd.Subject);
    Comment = vd.CommentStart;
%     try Mod1 = vd.Modifier_1; catch; Mod1 = cell(size(Comment)); end
%     vd = table(vN,Time,I,Behav,isFocal,Comment,Mod1);
    if ~iscell(vd.CommentStop); vd.CommentStop = cell(size(vd,1),1); end
    if ~exist('BORIS','var'); BORIS = vd;
    else BORIS = [BORIS; vd];
    end
end


warning('on','all');
BORIS.seabed = cellfun(@(x) strcmp(x,'Swims near seabed'),BORIS.Behavior);
BORIS.MO = cellfun(@(x) strcmp(x,'Rostrum lift'),BORIS.Behavior);
BORIS.MC = cellfun(@(x) strcmp(x,'Rostrum depression'),BORIS.Behavior);
BORIS.GillO = cellfun(@(x) strcmp(x,'Gill arches expanding'),BORIS.Behavior);
BORIS.GillC = cellfun(@(x) strcmp(x,'Gill arches collapsing'),BORIS.Behavior);
BORIS.MaxG = cellfun(@(x) strcmp(x,'Maximum gap'),BORIS.Behavior);
BORIS.Munch = cellfun(@(x) strcmp(x,'Munching'),BORIS.Behavior);
BORIS.Cough = cellfun(@(x) strcmp(x,'Coughing'),BORIS.Behavior);
save([Bfiles 'BORIStables.mat'],'BORIS')
disp('Section 1 finished');