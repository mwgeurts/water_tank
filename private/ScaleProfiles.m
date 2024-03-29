function profiles = ScaleProfiles(varargin)
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
    'Integral Area'
};

% If no input arguments are provided
if nargin == 0
    
    % Return the options
    profiles = options;
    
    % Stop execution
    return;
end

% Execute code block based on format provided in varargin{2}
switch varargin{2}
    
    % No Scaling
    case 1
        
        % Return raw profile
        profiles = varargin{1};
        
    % Max Value
    case 2
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action 
        Event('Profiles scaled to maximum values');

        % Loop through each profile
        for i = 1:length(profiles)
        
            % Scale by max;
            profiles{i}(:,4) = profiles{i}(:,4) / max(profiles{i}(:,4));
            profiles{i}(:,5) = profiles{i}(:,5) / max(profiles{i}(:,5));
        end 
        
        % Clear temporary variables
        clear i;
        
    % CAX/PDD
    case 3
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action 
        Event('Profiles scaled to match CAX value');

        % Loop through each profile
        for i = 1:length(profiles)
        
            % If X and Y changes, this is a diagonal profile
            if (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1 && ...
                    (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
            
                % Scale measured data to CAX
                profiles{i}(:,4) = profiles{i}(:,4) / ...
                    interp1(sqrt(profiles{i}(:,1).^2 + ...
                    profiles{i}(:,2).^2) .* sign(profiles{i}(:,1)), ...
                    profiles{i}(:,4), 0, 'linear');
                
                % Scale reference data to CAX
                profiles{i}(:,5) = profiles{i}(:,5) / ...
                    interp1(sqrt(profiles{i}(:,1).^2 + ...
                    profiles{i}(:,2).^2) .* sign(profiles{i}(:,1)), ...
                    profiles{i}(:,5), 0, 'linear');
                
            % If only X changes, this is an X profile
            elseif (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1
                
                % Scale measured data to CAX
                profiles{i}(:,4) = profiles{i}(:,4) / ...
                    interp1(profiles{i}(:,1), ...
                    profiles{i}(:,4), 0, 'linear');
                
                % Scale reference data to CAX
                profiles{i}(:,5) = profiles{i}(:,5) / ...
                    interp1(profiles{i}(:,1), ...
                    profiles{i}(:,5), 0, 'linear');
                
            % Otherwise, if only Y changes, this is a Y profile
            elseif (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
                
                % Scale measured data to CAX
                profiles{i}(:,4) = profiles{i}(:,4) / ...
                    interp1(profiles{i}(:,2), ...
                    profiles{i}(:,4), 0, 'linear');
                
                % Scale reference data to CAX
                profiles{i}(:,5) = profiles{i}(:,5) / ...
                    interp1(profiles{i}(:,2), ...
                    profiles{i}(:,5), 0, 'linear');
                
            % Otherwise, if Z changes, this is a depth profile
            elseif (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1
                
                % Scale measured data to match reference Dmax
                profiles{i}(:,4) = profiles{i}(:,4) * ...
                    max(profiles{i}(:,5)) / max(profiles{i}(:,4));
            end
        end 
        
        % Clear temporary variables
        clear i;    
        
    % CAX/PDD
    case 4
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action 
        Event('Profiles scaled to match CAX value at reference depth');

        % Loop through each profile
        for i = 1:length(profiles)
        
            % If X and Y changes, this is a diagonal profile
            if (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1 && ...
                    (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
                
                % Scale measured data to match at the reference CAX
                profiles{i}(:,4) = profiles{i}(:,4) * ...
                    interp1(sqrt(profiles{i}(:,1).^2 + ...
                    profiles{i}(:,2).^2) .* sign(profiles{i}(:,1)), ...
                    profiles{i}(:,5), 0, 'linear') / ...
                    interp1(sqrt(profiles{i}(:,1).^2 + ...
                    profiles{i}(:,2).^2) .* sign(profiles{i}(:,1)), ...
                    profiles{i}(:,4), 0, 'linear');
                
            % If only X changes, this is an X profile
            elseif (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1
                
                % Scale measured data to match at the reference CAX
                profiles{i}(:,4) = profiles{i}(:,4) * ...
                    interp1(profiles{i}(:,1), ...
                    profiles{i}(:,5), 0, 'linear') / ...
                    interp1(profiles{i}(:,1), ...
                    profiles{i}(:,4), 0, 'linear');
                
            % Otherwise, if only Y changes, this is a Y profile
            elseif (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
                
                % Scale measured data to match at the reference CAX
                profiles{i}(:,4) = profiles{i}(:,4) * ...
                    interp1(profiles{i}(:,2), ...
                    profiles{i}(:,5), 0, 'linear') / ...
                    interp1(profiles{i}(:,2), ...
                    profiles{i}(:,4), 0, 'linear');
                
            % Otherwise, if Z changes, this is a depth profile
            elseif (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1
                
                % Scale measured data to match reference Dmax
                profiles{i}(:,4) = profiles{i}(:,4) * ...
                    max(profiles{i}(:,5)) / max(profiles{i}(:,4));
            end
        end 
        
        % Clear temporary variables
        clear i;

    % Integral Area
    case 5
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action 
        Event('Profiles scaled to match integral area');

        % Loop through each profile
        for i = 1:length(profiles)
        
            % If X and Y changes, this is a diagonal profile
            if (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1 && ...
                    (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
                
                % Scale measured data to match integral area of reference
                profiles{i}(:,4) = profiles{i}(:,4) * ...
                    trapz(sqrt(profiles{i}(:,1).^2 + ...
                    profiles{i}(:,2).^2) .* sign(profiles{i}(:,1)), ...
                    profiles{i}(:,5)) / ...
                    trapz(sqrt(profiles{i}(:,1).^2 + ...
                    profiles{i}(:,2).^2) .* sign(profiles{i}(:,1)), ...
                    profiles{i}(:,4) .* double(profiles{i}(:,5) > 0));
                
            % If only X changes, this is an X profile
            elseif (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1
                
                % Scale measured data to match integral area of reference
                profiles{i}(:,4) = profiles{i}(:,4) * ...
                    trapz(profiles{i}(:,1), profiles{i}(:,5)) / ...
                    trapz(profiles{i}(:,1), profiles{i}(:,4) .* ...
                    double(profiles{i}(:,5) > 0));
                
            % Otherwise, if only Y changes, this is a Y profile
            elseif (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
                
                % Scale measured data to match integral area of reference
                profiles{i}(:,4) = profiles{i}(:,4) * ...
                    trapz(profiles{i}(:,2), profiles{i}(:,5)) / ...
                    trapz(profiles{i}(:,2), profiles{i}(:,4) .* ...
                    double(profiles{i}(:,5) > 0));
                
            % Otherwise, if Z changes, this is a depth profile
            elseif (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1
                
                % Scale measured data to match integral area of reference
                profiles{i}(:,4) = profiles{i}(:,4) * ...
                    trapz(profiles{i}(:,3), profiles{i}(:,5)) / ...
                    trapz(profiles{i}(:,3), profiles{i}(:,4) .* ...
                    double(profiles{i}(:,5) > 0));
            end
        end 
        
        % Clear temporary variables
        clear i;
end
