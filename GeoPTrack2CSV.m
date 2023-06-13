% GeoPTrack to CSV


function GeoPTrack2CSV = GeoPTrack2CSV(prh,saveloc);

if nargin < 2
    saveloc = uigetdir();
end

Gi = find(~isnan(prh.GPS(:,1))); [~,G0] = min(abs(Gi-find(prh.tagon,1))); 
G1 = prh.GPS(Gi(G0),:);  [x1,y1,z1] = deg2utm(G1(1),G1(2)); 
[Lats,Longs] = utm2deg(prh.geoPtrack(prh.tagon,1)+x1,prh.geoPtrack(prh.tagon,2)+y1,repmat(z1,sum(prh.tagon),1)); 
lats = nan(size(prh.tagon)); longs = lats; lats(prh.tagon) = Lats; longs(prh.tagon) = Longs;

WhaleName = repmat(prh.INFO.whaleName,length(Lats),1);
UTC = repmat(prh.INFO.UTC,length(Lats),1);
DateTimeLocal = datetime(prh.DN(prh.tagon),"ConvertFrom","datenum");
Depth = prh.p(prh.tagon);

exportT = table(WhaleName, DateTimeLocal ,UTC,Lats,Longs,Depth);

filename = strcat(saveloc,'\',WhaleName(1,:),'_3DTrack.csv');
writetable(exportT,filename);


end