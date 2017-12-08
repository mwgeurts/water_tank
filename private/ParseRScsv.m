function data = ParseRScsv(path, names)
% ParseRScsv extracts profile calculated and measured data exported from 
% the RayStation physics module. Each profile is returned an array of 
% position and signal values. 
%
% The following variables are required for proper execution:
%   path: string containing the path to the .csv files
%   names: string or cell array of strings containing the file(s) to be 
%       loaded
%
% The following structure fields are returned upon successful completion:
%   version: 1 x n cell array, file version strings
%   exported: 1 x n array, date/time each file was saved, as an integer
%   machine: 1 x n cell array, machine names
%   status: 1 x n cell array, commissioning statuses
%   timestamp: 1 x n array, date/time systems were commissioned
%   measured: 1 x n vector whether profile was measured (1) or computed (0)
%   algorithm: 1 x n cell array, computation algorithm, if computed 
%   collimation: 1 x n cell array, field collimation type
%   unit: 1 x n cell array, signal unit (cGy)
%   energy: 1 x n cell array, energy
%   ssd: 1 x n vector, SSD in cm
%   collimator: n x 4 array of collimator settings in cm [X1 X2 Y1 Y2]
%   profiletype: 1 x n cell array, curve type (Crossline/Inline)
%   modality: 1 x n cell array, 'Photon' or 'Electron'
%   quantity: 1 x n cell array, signal type such as 'Relative Dose'
%   start: n x 3 array, profile start IEC X/Y/Z coordinates in mm
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
    Event(['Loading CSV file ', strjoin(names, '\nLoading CSV file ')]);
    tic;
end

% Initialize profile array and counter
data.profiles = cell(0);
c = 1;

% Loop through each file
for f = 1:length(names)

    % Initialize comments array
    comments = cell(0);
    
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

        % Store version
        if length(l) > 9 && strcmp(l(1:9), '#Exported')

            % Store version
            t = strfind(l, 'RayStation');
            if ~isempty(t)
                data.version{c} = l(t:end);
            end
            
        % Store export timestamp
        elseif length(l) > 5 && strcmp(l(1:5), '#Time')
            
            % Find time
            t = regexp(l, '[0-9/:]+', 'match');
            if ~isempty(t)
                data.exported(c) = datenum([t{1}, ' ', t{2}], ...
                    'mm/dd/yyyy HH:MM:SS');
            end
            
        % Store machine name
        elseif length(l) > 14 && strcmp(l(1:14), '#Machine Name:')
            data.machine{c} = strtrim(l(15:end));
            
        % Store status
        elseif length(l) > 19 && strcmp(l(1:19), '#Commission status:')
            data.status{c} = strtrim(l(20:end));
            
        % Store commissioned timestamp
        elseif length(l) > 17 && strcmp(l(1:17), '#Commission time:')
            
            % Find time
            t = regexp(l, '[0-9/:]+', 'match');
            if ~isempty(t)
                data.timestamp(c) = datenum([t{2}, ' ', t{3}], ...
                    'mm/dd/yyyy HH:MM:SS');
            end
            
        % Store measured
        elseif length(l) > 9 && strcmp(l(1:9), '#Measured')
            data.measured(c) = 1;
            
        % Store measured
        elseif length(l) > 9 && strcmp(l(1:9), '#Computed')
            data.measured(c) = 0;
        
        % Store algorithm
        elseif length(l) > 12 && strcmp(l(1:12), '#Dose curves')
            t = strsplit(l, ':');
            data.algorithm{c} = strtrim(t{2});
            
        % Store collimation
        elseif length(l) > 19 && strcmp(l(1:19), '#Field collimation:')
            data.collimation{c} = strtrim(l(20:end));
            
        % Store dose unit
        elseif length(l) > 11 && strcmp(l(1:11), '#Dose unit:')
            data.unit{c} = strtrim(l(12:end));
            
        % Store energy
        elseif length(l) > 6 && strcmp(l(1:6), 'energy')
            t = strsplit(l, ';');
            data.energy{c} = strtrim(t{2});

        % Store SSD in cm
        elseif length(l) > 3 && strcmp(l(1:3), 'SSD')
            t = strsplit(l, ';');
            data.ssd(c) = str2double(strtrim(t{2})) / 10;
            
        % Store fieldsize in cm
        elseif length(l) > 9 && strcmp(l(1:9), 'Fieldsize')
            t = strsplit(l, ';');
            data.collimator(c,:) = [str2double(strtrim(t{2})) ...
                str2double(strtrim(t{4})) ...
                str2double(strtrim(t{3})) ...
                str2double(strtrim(t{5}))] / 10;
        
        % Store CurveType
        elseif length(l) > 9 && strcmp(l(1:9), 'CurveType')
            t = strsplit(l, ';');
            data.profiletype{c} = strtrim(t{2});
            
        % Store RadiationType
        elseif length(l) > 13 && strcmp(l(1:13), 'RadiationType')
            t = strsplit(l, ';');
            data.modality{c} = strtrim(t{2});
            
            % Append unit to energy
            if strcmp(data.modality{c}, 'Photon')
                data.energy{c} = [data.energy{c}, ' MV'];
            else
                data.energy{c} = [data.energy{c}, ' MeV'];
            end 
        
        % Store Quantity
        elseif length(l) > 8 && strcmp(l(1:8), 'Quantity')
            t = strsplit(l, ';');
            data.quantity{c} = strtrim(t{2});
            
        % Store StartPoint in mm
        elseif length(l) > 10 && strcmp(l(1:10), 'StartPoint')
            t = strsplit(l, ';');
            data.start(c,:) = [str2double(strtrim(t{2})) ...
                str2double(strtrim(t{3})) ...
                str2double(strtrim(t{4}))];
            
            % Scan subsequent data
            raw = textscan(fid, '%f; %f');
            
            % If profile is IEC X
            if strcmp(data.profiletype{c}, 'Crossline')
                data.profiles{c} = horzcat(raw{1}, ...
                    repmat(data.start(c,2:3), length(raw{1}),1), raw{2});
                
            elseif strcmp(data.profiletype{c}, 'Inline')
                data.profiles{c} = horzcat(repmat(data.start(c,1), ...
                    length(raw{1}),1), raw{1}, ...
                    repmat(data.start(c,3), length(raw{1}),1), raw{2});
                
            elseif strcmp(data.profiletype{c}, 'Depth')
                data.profiles{c} = horzcat(repmat(data.start(c,1:2), ...
                    length(raw{1}),1), raw{1}, raw{2});

            end
            c = c+1;
        end
    end
    
    % Close file
    fclose(fid);
end

% Loop through each profile
for i = 1:length(data.profiles)

    % If signal is negative (negative bias), flip it
    if mean(data.profiles{i}(:,4)) < 0
        
        % Log event
        if exist('Event', 'file') == 2
            Event('Inverting negative signal (positive bias)');
        end
        
        % Store negative value
        data.profiles{i}(:,4) = -data.profiles{i}(:,4);
    end
    
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

% Clear temporary file
clear f i j c d y a b l fid raw;
