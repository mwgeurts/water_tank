function data = ParseIBAtxt(path, names)
% ParseIBAtxt extracts water tank profiles from IBA OmniPro RFA300 ASCII 
% BDS formatted text files. Each profile is returned an array of position
% and signal values. This function has been tested with OmniPro 6 and 7
% exported ASCII files.
%
% The following variables are required for proper execution:
%   path: string containing the path to the TXT files
%   names: string or cell array of strings containing the file(s) to be 
%       loaded
%
% The following structure fields are returned upon successful completion:
%   profiles: cell array of profiles, where each cell contains a n x 4
%       array of IEC X, IEC Y, IEC Z (depth), and signal.
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

% If not cell array, cast as one
if ~iscell(names); names = cell({names}); end

% Log start of file load and start timer
if exist('Event', 'file') == 2
    Event(['Loading ASCII file ', strjoin(names, '\nLoading ASCII file ')]);
    tic;
end

% Initialize return structure
data.profiles = cell(0);

% Initialize counter
i = 0;

% Loop through each file
for f = 1:length(names)

    % Open file to provided filename 
    fid = fopen(fullfile(path, names{f}), 'r');

    % Verify file handle is valid
    if fid >= 3
        if exist('Event', 'file') == 2
            Event(['Read handle successful for ', names{f}]);
        end
    else
        if exist('Event', 'file') == 2
            Event(['Read handle not successful for ', names{f}], 'ERROR');
        else
            error(['Read handle not successful for ', names{f}]);
        end
    end
    
    % Loop through file contents
    while ~feof(fid)

        % Get line
        l = fgetl(fid);

        % If line matches format
        if length(l) > 1 && strcmp(l(1), '=')
            if length(data.profiles) == i
                data.profiles{i} = vertcat(data.profiles{i}, ...
                    cell2mat(textscan(l(2:end), '%f %f %f %f')));
            else
                data.profiles{i} = ...
                    cell2mat(textscan(l(2:end), '%f %f %f %f'));
            end

        else
            i = i + 1;
        end
    end

    % Close file
    fclose(fid);
end

% Remove empty cells
data.profiles = data.profiles(~cellfun('isempty', data.profiles));

% Log event
if exist('Event', 'file') == 2
    Event(sprintf('%i data profiles extracted', length(data.profiles)));
end

% Loop through each profile
for i = 1:length(data.profiles)

    % If depth is negative (given by a negative mean value), flip
    % the dimension so that depths are down
    if mean(data.profiles{i}(:,3)) < 0
        
        % Log event
        if exist('Event', 'file') == 2
            Event('Flipping IEC Z axis (positive down)');
        end
        
        % Store negative value
        data.profiles{i}(:,3) = -data.profiles{i}(:,3);
    end
    
    % If depth changes (i.e. PDD), sort descending
    if data.profiles{i}(2,3) ~= data.profiles{i}(1,3)
        
        % Log event
        if exist('Event', 'file') == 2
            Event('Sorting depth profile by descending IEC Z value');
        end
        
        % Store sorted table in descending order
        data.profiles{i} = flip(sortrows(data.profiles{i}, 3), 1);
    end
end

% Clear temporary variables
clear f fid i l;