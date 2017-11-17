function profiles = CenterProfiles(varargin)
% CenterProfiles centers a cell array of profiles by a specified algorithm. 
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
    'FWHM'
    'FWQM'
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
    
    % No centering
    case 1
        
        % Return raw profile
        profiles = varargin{1};
        
    % FWHM
    case 2
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action 
        Event('Centering profiles by FWHM');
        if nargin >= 3 && varargin{3} == 1
            Event('Centering reference profiles by FWHM');
        end
        
        % Loop through each profile
        for i = 1:length(profiles)
        
            % If X changes, this is an X profile
            if profiles{i}(1,1) ~= profiles{i}(2,1)
                
                % Shift measured profile by offset
                profiles{i}(:,1) = profiles{i}(:,1) - ...
                    FWXM(profiles{i}(:,1), profiles{i}(:,4), 0.5);
                
                % If center reference flag is set
                if size(profiles{i},2) >= 5 && nargin >= 3 && varargin{3} == 1
                    
                    % Re-interpolate reference with to center it
                    [~, ~, profiles{i}(:,5)] = FWXM(profiles{i}(:,1), ...
                        profiles{i}(:,5), 0.5);
                end

            % Otherwise, if Y changes, this is an Y profile
            elseif profiles{i}(1,2) ~= profiles{i}(2,2)
                
                % Shift measured profile by offset
                profiles{i}(:,2) = profiles{i}(:,2) - ...
                    FWXM(profiles{i}(:,2), profiles{i}(:,4), 0.5);
                
                % If center reference flag is set
                if size(profiles{i},2) >= 5 && nargin >= 3 && varargin{3} == 1
                    
                    % Re-interpolate reference with to center it
                    [~, ~, profiles{i}(:,5)] = FWXM(profiles{i}(:,2), ...
                        profiles{i}(:,5), 0.5);
                end
            end
        end 
        
        % Clear temporary variables
        clear i;
        
    % FWQM
    case 3
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action 
        Event('Centering profiles by FWQM');
        if nargin >= 3 && varargin{3} == 1
            Event('Centering reference profiles by FWHM');
        end

        % Loop through each profile
        for i = 1:length(profiles)
        
            % If X changes, this is an X profile
            if profiles{i}(1,1) ~= profiles{i}(2,1)
                
                % Shift measured profile by offset
                profiles{i}(:,1) = profiles{i}(:,1) - ...
                    FWXM(profiles{i}(:,1), profiles{i}(:,4), 0.25);
                
                % If center reference flag is set
                if size(profiles{i},2) >= 5 && nargin >= 3 && varargin{3} == 1
                    
                    % Re-interpolate reference with to center it
                    [~, ~, profiles{i}(:,5)] = FWXM(profiles{i}(:,1), ...
                        profiles{i}(:,5), 0.25);
                end

            % Otherwise, if Y changes, this is an Y profile
            elseif profiles{i}(1,2) ~= profiles{i}(2,2)
                
                % Shift measured profile by offset
                profiles{i}(:,2) = profiles{i}(:,2) - ...
                    FWXM(profiles{i}(:,2), profiles{i}(:,4), 0.25);
                
                % If center reference flag is set
                if size(profiles{i},2) >= 5 && nargin >= 3 && varargin{3} == 1
                    
                    % Re-interpolate reference with to center it
                    [~, ~, profiles{i}(:,5)] = FWXM(profiles{i}(:,2), ...
                        profiles{i}(:,5), 0.25);
                end
            end
        end 
        
        % Clear temporary variables
        clear i;
end
