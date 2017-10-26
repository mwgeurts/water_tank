function profile = ScaleProfiles(varargin)
% ScaleProfiles scales a cell array of profiles by a specified algorithm. 
% If called with no inputs, it will return a list of available algorithms 
% that can be used. If called with inputs, the first must be the
% name of the file while the second is an integer corresponding to the
% algorithm.
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

% Specify options and order
options = {
    'None'
    'Max Value'
    'CAX'
    'CAX/PDD'
};

% If no input arguments are provided
if nargin == 0
    
    % Return the options
    profile = options;
    
    % Stop execution
    return;
end

% Execute code block based on format provided in varargin{2}
switch varargin{2}
    
    % No Scaling
    case 1
        
        % Return raw profile
        profile = varargin{1};
        
    % Max Value
    case 2
        
        % Start with raw profile
        profile = varargin{1};
        
        % Log action 
        Event('Profiles scaled to maximum values');

        % Loop through each profile
        for i = 1:length(profile)
        
            % Scale by max;
            profile{i}(:,4) = profile{i}(:,4) / max(profile{i}(:,4));
            profile{i}(:,5) = profile{i}(:,5) / max(profile{i}(:,5));
        end 
        
        % Clear temporary variables
        clear i;
        
    % CAX/PDD
    case 3
        
        % Start with raw profile
        profile = varargin{1};
        
        % Log action 
        Event('Profiles scaled to match CAX value');

        % Loop through each profile
        for i = 1:length(profile)
        
            % If X changes, this is an X profile
            if profile{i}(1,1) ~= profile{i}(2,1)
                
                % Scale measured data to CAX
                profile{i}(:,4) = profile{i}(:,4) / interp1(profile{i}(:,1), ...
                    profile{i}(:,4), 0);
                
                % Scale reference data to CAX
                profile{i}(:,5) = profile{i}(:,5) / interp1(profile{i}(:,1), ...
                    profile{i}(:,5), 0);
                
            % Otherwise, if Y changes, this is an Y profile
            elseif profile{i}(1,2) ~= profile{i}(2,2)
                
                % Scale measured data to CAX
                profile{i}(:,4) = profile{i}(:,4) / interp1(profile{i}(:,2), ...
                    profile{i}(:,4), 0);
                
                % Scale reference data to CAX
                profile{i}(:,5) = profile{i}(:,5) / interp1(profile{i}(:,2), ...
                    profile{i}(:,5), 0);
                
            % Otherwise, if Z changes, this is an depth profile
            elseif profile{i}(1,3) ~= profile{i}(2,3)
                
                % Scale measured data to match reference Dmax
                profile{i}(:,4) = profile{i}(:,4) * max(profile{i}(:,5)) / ...
                    max(profile{i}(:,4));
            end
        end 
        
        % Clear temporary variables
        clear i;    
        
    % CAX/PDD
    case 4
        
        % Start with raw profile
        profile = varargin{1};
        
        % Log action 
        Event('Profiles scaled to match CAX value at reference depth');

        % Loop through each profile
        for i = 1:length(profile)
        
            % If X changes, this is an X profile
            if profile{i}(1,1) ~= profile{i}(2,1)
                
                % Scale measured data to match at the reference CAX
                profile{i}(:,4) = profile{i}(:,4) * interp1(profile{i}(:,1), ...
                    profile{i}(:,5), 0) / interp1(profile{i}(:,1), ...
                    profile{i}(:,4), 0);
                
            % Otherwise, if Y changes, this is an Y profile
            elseif profile{i}(1,2) ~= profile{i}(2,2)
                
                % Scale measured data to match at the reference CAX
                profile{i}(:,4) = profile{i}(:,4) * interp1(profile{i}(:,2), ...
                    profile{i}(:,5), 0) / interp1(profile{i}(:,2), ...
                    profile{i}(:,4), 0);
                
            % Otherwise, if Z changes, this is an depth profile
            elseif profile{i}(1,3) ~= profile{i}(2,3)
                
                % Scale measured data to match reference Dmax
                profile{i}(:,4) = profile{i}(:,4) * max(profile{i}(:,5)) / ...
                    max(profile{i}(:,4));
            end
        end 
        
        % Clear temporary variables
        clear i;
        
    
end
