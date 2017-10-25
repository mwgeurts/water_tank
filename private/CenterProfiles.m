function profile = CenterProfiles(varargin)
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
    profile = options;
    
    % Stop execution
    return;
end

% Execute code block based on format provided in varargin{2}
switch varargin{2}
    
    % No centering
    case 1
        
        % Return raw profile
        profile = varargin{1};
        
    % FWHM
    case 2
        
        % Start with raw profile
        profile = varargin{1};
        
        % Log action 
        Event('Centering profiles by FWHM');

        % Loop through each profile
        for i = 1:length(profile)
        
            % If X changes, this is an X profile
            if profile{i}(1,1) ~= profile{i}(2,1)
                
                % Find index of central value
                [~, I] = min(abs(profile{i}(:,1)));

                % Find highest lower index just below half maximum
                lI = find(profile{i}(1:I,4) < 0.5 * ...
                    max(profile{i}(:,4)), 1, 'last');

                % Find lowest upper index just above half maximum
                uI = find(profile{i}(I:end,4) < 0.5 * ...
                    max(profile{i}(:,4)), 1, 'first');

                try
                    % Interpolate to find lower half-maximum value
                    l = interp1(profile{i}(lI-1:lI+2,4), profile{i}(...
                        lI-1:lI+2,1), 0.5 * max(profile{i}(:,4)), 'linear');

                    % Interpolate to find upper half-maximum value
                    u = interp1(profile{i}(I+uI-3:I+uI,4), profile{i}(...
                        I+uI-3:I+uI,1), 0.5 * max(profile{i}(:,4)), 'linear');

                    % Shift measured profile by offset
                    profile{i}(:,4) = interp1(profile{i}(:,1), ...
                        profile{i}(:,4), profile{i}(:,1) + (l+u)/2, ...
                        'linear', 0);
                catch
                    Event(sprintf(['FWHM could not be computed for ', ...
                        'profile %i'], i), 'WARN');
                end

            % Otherwise, if Y changes, this is an Y profile
            elseif profile{i}(1,2) ~= profile{i}(2,2)
                
                % Find index of central value
                [~, I] = min(abs(profile{i}(:, 2)));

                % Find highest lower index just below half maximum
                lI = find(profile{i}(1:I,4) < 0.5 * ...
                    max(profile{i}(:,4)), 1, 'last');

                % Find lowest upper index just above half maximum
                uI = find(profile{i}(I:end,4) < 0.5 * ...
                    max(profile{i}(:,4)), 1, 'first');

                try
                    % Interpolate to find lower half-maximum value
                    l = interp1(profile{i}(lI-1:lI+2,4), profile{i}(...
                        lI-1:lI+2,2), 0.5 * max(profile{i}(:,4)), 'linear');

                    % Interpolate to find upper half-maximum value
                    u = interp1(profile{i}(I+uI-3:I+uI,4), profile{i}(...
                        I+uI-3:I+uI,2), 0.5 * max(profile{i}(:,4)), 'linear');

                    % Shift measured profile by offset
                    profile{i}(:,4) = interp1(profile{i}(:,2), ...
                        profile{i}(:,4), profile{i}(:,2) + (l+u)/2, ...
                        'linear', 0);
                catch
                    Event(sprintf(['FWHM could not be computed for ', ...
                        'profile %i'], i), 'WARN');
                end
            end
        end 
        
        % Clear temporary variables
        clear i;
        
    % FWQM
    case 3
        
        % Start with raw profile
        profile = varargin{1};
        
        % Log action 
        Event('Centering profiles by FWQM');

        % Loop through each profile
        for i = 1:length(profile)
        
            % If X changes, this is an X profile
            if profile{i}(1,1) ~= profile{i}(2,1)
                
                % Find index of central value
                [~, I] = min(abs(profile{i}(:,1)));

                % Find highest lower index just below half maximum
                lI = find(profile{i}(1:I,4) < 0.25 * ...
                    max(profile{i}(:,4)), 1, 'last');

                % Find lowest upper index just above half maximum
                uI = find(profile{i}(I:end,4) < 0.25 * ...
                    max(profile{i}(:,4)), 1, 'first');

                try
                    % Interpolate to find lower half-maximum value
                    l = interp1(profile{i}(lI-1:lI+2,4), profile{i}(...
                        lI-1:lI+2,1), 0.25 * max(profile{i}(:,4)), 'linear');

                    % Interpolate to find upper half-maximum value
                    u = interp1(profile{i}(I+uI-3:I+uI,4), profile{i}(...
                        I+uI-3:I+uI,1), 0.25 * max(profile{i}(:,4)), 'linear');

                    % Shift measured profile by offset
                    profile{i}(:,4) = interp1(profile{i}(:,1), ...
                        profile{i}(:,4), profile{i}(:,1) + (l+u)/2, ...
                        'linear', 0);
                catch
                    Event(sprintf(['FWQM could not be computed for ', ...
                        'profile %i'], i), 'WARN');
                end

            % Otherwise, if Y changes, this is an Y profile
            elseif profile{i}(1,2) ~= profile{i}(2,2)
                
                % Find index of central value
                [~, I] = min(abs(profile{i}(:, 2)));

                % Find highest lower index just below half quarter
                lI = find(profile{i}(1:I,4) < 0.25 * ...
                    max(profile{i}(:,4)), 1, 'last');

                % Find lowest upper index just above half quarter
                uI = find(profile{i}(I:end,4) < 0.25 * ...
                    max(profile{i}(:,4)), 1, 'first');

                try
                    % Interpolate to find lower half-quarter value
                    l = interp1(profile{i}(lI-1:lI+2,4), profile{i}(...
                        lI-1:lI+2,2), 0.25 * max(profile{i}(:,4)), 'linear');

                    % Interpolate to find upper half-quarter value
                    u = interp1(profile{i}(I+uI-3:I+uI,4), profile{i}(...
                        I+uI-3:I+uI,2), 0.25 * max(profile{i}(:,4)), 'linear');

                    % Shift measured profile by offset
                    profile{i}(:,4) = interp1(profile{i}(:,2), ...
                        profile{i}(:,4), profile{i}(:,2) + (l+u)/2, ...
                        'linear', 0);
                catch
                    Event(sprintf(['FWQM could not be computed for ', ...
                        'profile %i'], i), 'WARN');
                end
            end
        end 
        
        % Clear temporary variables
        clear i;
end
