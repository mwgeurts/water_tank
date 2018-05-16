function data = ParseEclipse(path, names)
% ParseEclipse extracts profiles exported from Eclipse. Each profile is 
% returned an array of position and signal values.
%
% The following variables are required for proper execution:
%   path: string containing the path to the TXT files
%   names: string or cell array of strings containing the file(s) to be 
%       loaded
%
% The following structure fields are returned upon successful completion:
%
%   profiles: cell array of profiles, where each cell contains a n x 4
%       array of IEC X, IEC Y, IEC Z (depth), and signal.
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2018 University of Wisconsin Board of Regents
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
    Event(['Loading Eclipse file ', ...
        strjoin(names, '\nLoading Eclipse file ')]);
    t = tic;
end

% Initialize return structure
data.profiles = cell(0);

% Initialize profile counter
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
    
    % Initialize temporary data cell array
    d = [];
    
    % Loop through file contents
    while ~feof(fid)

        % Get line
        l = fgetl(fid);

        % Store patient name
        if length(l) > 13 && startsWith(l, 'Patient Name:')
            data.name = strip(l(14:end));
            
        % Store patient ID
        elseif length(l) > 11 && startsWith(l, 'Patient ID:')
            data.id = strip(l(12:end));
            
        % Store plan
        elseif length(l) > 5 && startsWith(l, 'Plan:')
            data.plan = strip(l(6:end));
            
        % Store course
        elseif length(l) > 7 && startsWith(l, 'Course:')
            data.course = strip(l(8:end));
            
        % Store date
        elseif length(l) > 5 && startsWith(l, 'Date:')
            try
                data.date = datenum(l(6:end), ...
                    'dddd, mmmm dd, yyyy HH:MM:SS PM');  
            catch
                if exist('Event', 'file') == 2
                    Event(['Could not parse date: ', l(6:end)], 'WARN');
                else
                    warning(['Could not parse date: ', l(6:end)]);
                end
            end
            
        % Store exporter
        elseif length(l) > 12 && startsWith(l, 'Exported By:')
            data.user = strip(l(12:end));
            
        % Store start
        elseif length(l) > 6 && startsWith(l, 'Start:')
            data.start = cell2mat(textscan(l(7:end), '(%f, %f, %f)'));
            
        % Store end
        elseif length(l) > 4 && startsWith(l, 'End:')
            data.end = cell2mat(textscan(l(5:end), '(%f, %f, %f)'));
            
        % Parse data
        elseif ~isempty(l) && isfield(data, 'end')
            c = textscan(l, '%f');
            if ~isempty(c{1}) && (isempty(d) || size(c{1}, 1) == size(d, 2))
                d(size(d,1)+1,:) = c{1}';
            end
        end
    end

    % Close file
    fclose(fid);
    
    % Parse data
    if isfield(data, 'start') && isfield(data, 'end')
        x = data.start(1) + (data.end(1) - data.start(1)) / (size(d,1)-1) * ...
            (0:size(d,1)-1) * 10;
        y = data.start(3) + (data.end(3) - data.start(3)) / (size(d,1)-1) * ...
            (0:size(d,1)-1) * 10;
        z = data.start(2) + (data.end(2) - data.start(2)) / (size(d,1)-1) * ...
            (0:size(d,1)-1) * 10;
        for i = 2:size(d,2)
            data.profiles{length(data.profiles)+1} = [x' y' z' d(:,i)];
        end
    end
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
    if (max(data.profiles{i}(:,3)) - min(data.profiles{i}(:,3))) > 1
        
        % Log event
        if exist('Event', 'file') == 2
            Event('Sorting depth profile by descending IEC Z value');
        end
        
        % Store sorted table in descending order
        data.profiles{i} = flip(sortrows(data.profiles{i}, 3), 1);
    end
end

% Log event
if exist('Event', 'file') == 2
    Event(sprintf('%i data profiles extracted successfully in %0.3f seconds', ...
        length(data.profiles), toc(t)));
end

% Clear temporary variables
clear f fid i l c d t;