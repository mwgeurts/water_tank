function data = ParseDV1Dcsv(path, names)
% ParseDV1Dcsv extracts water tank profiles from Standard Imaging DoseView 
% 1D water tank formatted .csv files. Each profile is returned an array of 
% position and signal values. If two or more channels exist in the data, the 
% function will try to identify which channel is reference and prompt the
% user whether they want to normalize by it.
%
% The following variables are required for proper execution:
%   path: string containing the path to the .csv files
%   names: string or cell array of strings containing the file(s) to be 
%       loaded
%
% The following structure fields are returned upon successful completion:
%   timestamp: array of date/time each file was saved, as an integer
%   version: cell array of file version strings
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

% Initialize profile array
data.profiles = cell(0);

% Loop through each file
for f = 1:length(names)

    % Initialize raw cell array
    raw = cell(0);
    
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

        % Store header data
        if length(l) > 27 && strcmp(l(1:27), 'DoseView 1D Software Export')

            % Get next line, separating by commas
            t = strsplit(fgetl(fid), ',');
            
            % Store header data
            data.timestamp(f) = datenum(t{2}, 'yyyy-mm-dd HH:MM:SS AM');
            data.version{f} = t{3};
            data.clr{f} = t{4};
            data.os{f} = t{5};
            
        % Store charge table
        elseif length(l) >= 12 && strcmp(l(1:12), 'Charge Table')
            
            % Skip next line
            fgetl(fid);
            
            % Initialize variable to store raw profile data
            raw = zeros(0,4);
            
            % Scan charge table
            l = fgetl(fid);
            while ~feof(l) && ~isempty(l)
                
                % Split line
                t = strsplit(l, ',');
                
                % Store electrometer info & firmware
                data.inputs{f,1:2} = cell(t{3}, t{5});
                data.serial{f,1:2} = cell(t{4}, t{6});
                data.firmware{f} = t{7};
                data.range{f,1:2} = cell(t{14}, t{15});
                data.bias(f,1:4) = [str2double(t{16}) str2double(t{17}) ...
                    str2double(t{18}) str2double(t{19})];
                data.type{f} = t{20};
                data.cumulative{f} = t{21};
                
                % Store depth, charge, and duration values
                raw(size(raw,1)+1,:) = [str2double(t{10}) ...
                    str2double(t{11}) str2double(t{12}) str2double(t{22})];
                
                % Get next line
                l = fgetl(fid);
            end
        end
    end

    % Close file
    fclose(fid);
    
    % If raw is still empty, continue to next file
    if isempty(raw)
        continue;
    end
    
    % Log event
    if exist('Event', 'file') == 2
        Event(sprintf('%i data points parsed', size(raw,1)));
    end
    
    % If two channels exist, look for channel with less variation
    if ~isnan(raw(1,2)) && ~isnan(raw(1,3))
        
        % Ask user if they wish to normalize by reference (only once)
        if ~exist('y', 'var')
            
            % If a GUI exists
            if usejava('jvm') && feature('ShowFigureWindows')
                y = questdlg('Normalize by reference channel?', ...
                    'Normalize', 'Yes', 'No', 'Yes');
            else
                y = input(['Normalize by reference channel ', ...
                    '(1 == yes, 0 == no)? ']);
                if y == 1; y = 'Yes'; else; y = 'No'; end
            end
        end
        
        % If user clicked yes
        if  strcmp(y, 'Yes')
            
            % Normalize channel with greater variation by channel with less
            if std(raw(:,2))/mean(raw(:,2)) > std(raw(:,3))/mean(raw(:,3)) 
                raw(:,2) = raw(:,2) ./ raw(:,3);
            else
                raw(:,2) = raw(:,3) ./ raw(:,2);
            end
        
        % Otherwise the user clicked no or cancel    
        else
            
            % Move channel with greater variation to raw(:,2)
            if std(raw(:,2))/mean(raw(:,2)) < std(raw(:,3))/mean(raw(:,3))
                raw(:,2) = raw(:,3);
            end
        end 
        
    % Otherwise, if only channel 2 data exists
    elseif ~isnan(raw(1,3))
        raw(:,2) = raw(:,3);
    end
    
    % Store profile as depth profile assuming water tank was positioned
    % along CAX, diving by duration
    data.profiles{f} = horzcat(zeros(size(raw,1),2), raw(:,1), ...
        raw(:,2) ./ raw(:,4));
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
clear i f l fid raw;
