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

% Persistently store fractional value
persistent frac shift;

% Specify options and order
options = {
    'None'
    'Manual'
    'FWHM'
    'FWQM'
    'FWXM'
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
    
    % No centering
    case 1
        
        % Return raw profile
        profiles = varargin{1};
    
    % Manual
    case 2
        
        % Start raw profile
        profiles = varargin{1};
        
        % If shift is not defined
        if ~exist('shift', 'var') || isempty(shift) || isnan(shift(1)) || ...
                isnan(shift(2))
            shift = [0 0];
        end
        
        % Ask user for shift
        shift = str2double(inputdlg({'Enter IEC X shift (mm):', ...
            'Enter IEC Y shift (mm):'}, 'Manual Center', 1, ...
            {sprintf('%0.1f', shift(1)), sprintf('%0.1f', shift(2))}));
        
        % If the user provided a valid value
        if ~isempty(shift) && ~isnan(shift(1)) && ~isnan(shift(2)) && ...
                (nargin < 3 || varargin{3} == 0)
            
            % Log action 
            Event(sprintf(['Shifting profiles by %0.1f mm in IEC-X and ', ...
                '%0.1f mm in IEC-Y'], shift(1), shift(2)));

            % Loop through each profile
            for i = 1:length(profiles)

                % Shift IEC X
                profiles{i}(:,1) = profiles{i}(:,1) + shift(1);
                
                % Shift IEC Y
                profiles{i}(:,2) = profiles{i}(:,2) + shift(2);
            end
        end
        
    % FWHM
    case 3
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action 
        Event('Centering profiles by FWHM');
        if nargin >= 3 && varargin{3} == 1
            Event('Centering reference profiles by FWHM');
        end
        
        % Execute FWCenter
        if nargin >= 3
            profiles = FWCenter(profiles, 0.5, varargin{3});
        else
            profiles = FWCenter(profiles, 0.5);
        end
        
    % FWQM
    case 4
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action 
        Event('Centering profiles by FWQM');
        if nargin >= 3 && varargin{3} == 1
            Event('Centering reference profiles by FWHM');
        end

        % Execute FWCenter
        if nargin >= 3
            profiles = FWCenter(profiles, 0.25, varargin{3});
        else
            profiles = FWCenter(profiles, 0.25);
        end
        
    % FWXM
    case 5
        
        % Start with raw profile
        profiles = varargin{1};
        
        % If shift is not defined
        if ~exist('frac', 'var') || isempty(frac) || isnan(frac)
            frac = 0.5;
        end
        
        % Prompt user to enter fractional value or percentage
        frac = inputdlg(['Enter fractional value or percentage to center ', ...
            'profiles on:'], 'Enter Fraction', 1, ...
            {sprintf('%0.2f', frac)});
        
        % If the user clicked cancel, do not shift
        if isempty(frac)
            return;
        
        % Convert to number
        elseif iscell(frac)
            frac = str2double(strrep(frac{1}, '%', ''));
        end
        
        % If fractional value is NaN
        if isnan(frac)
            return;
        
        % If value is greater than 1, assume user provided percentage
        elseif frac > 1
            frac = frac / 100;
        end
        
        % Log action 
        Event(sprintf('Centering profiles by %0.2f maximum', frac));
        if nargin >= 3 && varargin{3} == 1
            Event(sprintf('Centering reference profiles by %0.2f maximum', ...
                frac));
        end

        % Execute FWCenter
        if nargin >= 3
            profiles = FWCenter(profiles, frac, varargin{3});
        else
            profiles = FWCenter(profiles, frac);
        end
        
    % Integral Area
    case 6
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action
        Event('Centering profiles using integral area');
        
        % If center reference flag is set, warn user
        if nargin >= 3 && varargin{3} == 1
            Event(['Reference profiles are not separately centered using ', ...
                'integral area'], 'WARN');
        end
        
        % Loop through each profile
        for i = 1:length(profiles)
        
            % If X and Y changes, this is a diagonal profile
            if (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1 && ...
                    (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
            
                % Find index of half cumulative sum
                idx = find(cumsum(profiles{i}(:,4)) > ...
                    sum(profiles{i}(:,4)) * 0.5, 1, 'first');
                
                % Shift X profile by offset
                profiles{i}(:,1) = profiles{i}(:,1) - profiles{i}(idx,1);
                
                % Shift Y profile by offset
                profiles{i}(:,2) = profiles{i}(:,2) - profiles{i}(idx,2);
                
            % If only X changes, this is an X profile
            elseif (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1
                
                % Find index of half cumulative sum
                idx = find(cumsum(profiles{i}(:,4)) > ...
                    sum(profiles{i}(:,4)) * 0.5, 1, 'first');
                
                % Shift measured profile by offset
                profiles{i}(:,1) = profiles{i}(:,1) - profiles{i}(idx,1);
                
            % Otherwise, if only Y changes, this is an Y profile
            elseif (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
                
                % Find index of half cumulative sum
                idx = find(cumsum(profiles{i}(:,4)) > ...
                    sum(profiles{i}(:,4)) * 0.5, 1, 'first');
                
                % Shift measured profile by offset
                profiles{i}(:,2) = profiles{i}(:,2) - profiles{i}(idx,2);
            end
        end 
        
        % Clear temporary variables
        clear i idx;
end
