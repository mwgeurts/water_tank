function data = ParseW2CAD(path, names)
% ParseW2CAD extracts profiles stored in Eclipse W2CAD formatted files.
% Each profile is returned an array of position and signal values.
%
% The following variables are required for proper execution:
%   path: string containing the path to the TXT/ASC files
%   names: string or cell array of strings containing the file(s) to be 
%       loaded
%
% The following structure fields are returned upon successful completion:
%
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
    Event(['Loading W2CAD file ', strjoin(names, '\nLoading W2CAD file ')]);
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
    
    % Loop through file contents
    while ~feof(fid)

        % Get line
        l = fgetl(fid);

        % Start next profile
        if startsWith(l, '$STOM')
            
            % Increment counter
            i = i + 1;
            
            % Initialize data point counter
            j = 0;
        
        % Store comments
        elseif length(l) > 10 && startsWith(l, '# Comment:')
            data.comments{i} = strip(l(11:end));
            
        % Store detector
        elseif length(l) > 11 && startsWith(l, '# Detector:')
            data.detector{i} = strip(l(12:end));
            
        % Store operator
        elseif length(l) > 11 && startsWith(l, '# Operator:')
            data.operator{i} = strip(l(12:end));
            
        % Store version
        elseif length(l) > 8 && startsWith(l, '%VERSION')
            data.version(i) = str2double(l(9:end));
            
        % Store date
        elseif length(l) > 5 && startsWith(l, '%DATE')
            data.date(i) = datenum(l(6:end), 'dd-mm-yyyy');
            
        % Store detector type
        elseif length(l) > 5 && startsWith(l, '%DETY')
            switch strip(l(6:end))
                case 'CHA'
                    data.detector{i} = 'Chamber';
                case 'DIO'
                    data.detector{i} = 'Diode';
                case 'DIA'
                    data.detector{i} = 'Diamond';
                otherwise
                    data.detector{i} = strip(l(6:end));
            end
            
        % Store beam type
        elseif length(l) > 5 && startsWith(l, '%BMTY')
            switch strip(l(6:end))
                case 'PHO'
                    data.modality{i} = 'Photon';
                case 'ELE'
                    data.modality{i} = 'Electron';
                otherwise
                    data.modality{i} = strip(l(6:end));
            end
          
        % Store field size in cm
        elseif length(l) > 5 && startsWith(l, '%FLSZ')
            data.field(i,:) = cell2mat(textscan(l(6:end), ...
                '%f * %f'))/10;
        
        % Store profile type
        elseif length(l) > 5 && startsWith(l, '%TYPE')
            switch strip(l(6:end))
                case 'OPD'
                    data.type{i} = 'PDD';
                case 'OPP'
                    data.type{i} = 'Profile';
                case 'DPR'
                    data.type{i} = 'Diagonal';
                otherwise
                    data.type{i} = strip(l(6:end));
            end
            
        % Store axis
        elseif length(l) > 5 && startsWith(l, '%AXIS')
            data.axis{i} = strip(l(6:end));
            
        % Initialize points array
        elseif length(l) > 5 && startsWith(l, '%PNTS')
            data.profiles{i} = zeros(str2double(l(6:end)), 4);
            
        % Store step size
        elseif length(l) > 5 && startsWith(l, '%STEP')
            data.step(i) = str2double(l(6:end));
            
        % Store SSD in cm
        elseif length(l) > 4 && startsWith(l, '%SSD')
            data.ssd(i) = str2double(l(5:end))/10;
            
        % Store depth in mm
        elseif length(l) > 5 && startsWith(l, '%DPTH')
            data.depth(i) = str2double(l(6:end));
            
        % Parse data
        elseif length(l) > 1 && startsWith(l, '<')
            j = j + 1;
            data.profiles{i}(j,:) = cell2mat(textscan(l(2:end), ...
                '%f %f %f %f'));
        end
    end

    % Close file
    fclose(fid);
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
clear f fid i j l t;