% Lunge Statistics


function LungeTable = LungeStats(LungeI, Depth, DateNumber, WhaleID, UTC)

% Lunge Depth
LungeDepth = Depth(LungeI);

% Local Time of Lunge
LungeTime = DateNumber(LungeI);
LungeTime = datetime(LungeTime,'ConvertFrom','datenum');

% UTC Time Calculation
UTCTime = LungeTime - hours(UTC);

%Generate Whale IDs for Length of Lunges
WhaleIDs = repmat(string(WhaleID), length(LungeI),1);

% Create Table
LungeTable = table(WhaleIDs,LungeTime,UTCTime,LungeDepth);


end