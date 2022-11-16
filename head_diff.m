% Calculate difference in heading

% All inputs must be entered in degrees (0-360) and assumes all input
% samples are within that range.

% Calculates the difference in degrees between the two inputs

% Inputs:
    % OG - Heading 1
    % NM - Heading 2
% Outputs:
    % Delta - Change in Heading bewteen OG and NM


function Delta = head_diff(OG,NM)

    if abs(OG - NM) > 180 % if the change in angle is greater than 180
        
        % if variable is greater than 180, subtract it by 360
        % if variable is less than or equal to 180, subtract by 0
        if OG > 180
            a = 360 - OG;
            b = NM - 0;
            Delta = a + b;
        else
            a = 360 - NM;
            b = OG - 0;
            Delta = a + b;
        end
    
    else % if not greater than 180, can be calculated normally
        Delta = abs(OG - NM);
    end

end