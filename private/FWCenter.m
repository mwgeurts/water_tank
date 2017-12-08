function profiles = FWCenter(profiles, x, varargin)
% FWCenter is called by CenterProfiles when performing FWXM-based profile 
% shifts. It is called with two or three inputs: a profiles cell array, 
% fraction x of the maximum value, and an optional flag to center (1) or
% not (0) the reference channel as well. If not provided the reference
% channel will not be centered. Note, the measured profile is centered by 
% shifting the x values, while the reference profile is centered by
% re-interpolating the values.
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2017 University of Wisconsin Board of Regents
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the  
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along 
% with this program. If not, see http://www.gnu.org/licenses/.

% Loop through each profile
for i = 1:length(profiles)

    % If X and Y changes, this is a diagonal profile
    if (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1 && ...
            (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1

        % Compute angle
        a = atan((profiles{i}(end,1) - profiles{i}(1,1)) ...
            / (profiles{i}(end,2) - profiles{i}(1,2)));

        % Compute center
        c = FWXM(sqrt(profiles{i}(:,1).^2 + profiles{i}(:,2).^2) .* ...
            sign(profiles{i}(:,1)), profiles{i}(:,4), x);

        % Shift X by sine
        profiles{i}(:,1) = profiles{i}(:,1) - c * sin(a);

        % Shift Y by cosine
        profiles{i}(:,2) = profiles{i}(:,2) - c * cos(a);

        % If center reference flag is set
        if size(profiles{i},2) >= 5 && nargin >= 3 && varargin{1} == 1

            % Re-interpolate reference with to center it
            [~, ~, profiles{i}(:,5)] = ...
                FWXM(sqrt(profiles{i}(:,1).^2 + profiles{i}(:,2).^2) ...
                .* sign(profiles{i}(:,1)), profiles{i}(:,5), x);
        end

    % If only X changes, this is an X profile
    elseif (max(profiles{i}(:,1)) - ...
            min(profiles{i}(:,1))) > 1

        % Shift measured profile by offset
        profiles{i}(:,1) = profiles{i}(:,1) - ...
            FWXM(profiles{i}(:,1), profiles{i}(:,4), x);

        % If center reference flag is set
        if size(profiles{i},2) >= 5 && nargin >= 3 && varargin{1} == 1

            % Re-interpolate reference with to center it
            [~, ~, profiles{i}(:,5)] = FWXM(profiles{i}(:,1), ...
                profiles{i}(:,5), x);
        end

    % Otherwise, if only Y changes, this is a Y profile
    elseif (max(profiles{i}(:,2)) - ...
            min(profiles{i}(:,2))) > 1

        % Shift measured profile by offset
        profiles{i}(:,2) = profiles{i}(:,2) - ...
            FWXM(profiles{i}(:,2), profiles{i}(:,4), x);

        % If center reference flag is set
        if size(profiles{i},2) >= 5 && nargin >= 3 && varargin{1} == 1

            % Re-interpolate reference with to center it
            [~, ~, profiles{i}(:,5)] = FWXM(profiles{i}(:,2), ...
                profiles{i}(:,5), x);
        end
    end
end 

% Clear temporary variables
clear i a c;