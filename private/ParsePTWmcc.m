function data = ParsePTWmcc(path, names)
% ParsePTWmcc reads in PTW MEPHYSTO ASCII mcc files into a MATLAB structure
% containing arrays of each header parameter and scan. Each scan is
% converted into an n x 4 array, with columns X, Y, Z, and signal, based on
% the values of the SCAN_CURVETYPE header. This assumes that the tank is
% set up such that IEC X is aligned in the cross plane direction. The scan
% data can be found in the return structure field 'profiles' cell array.
% TPR, DDC, OUTPUT_FACTOR, and SCAN_DIAGONAL curves are not supported at
% this time.
%
% The format of the PTW mcc file was derived from the following file:
% http://bistromath.kegge13.nl/MEPHYSTO_mcc_data_format_description.pdf.
% The function has not been thoroughly tested, as the author does not have
% PTW water tanks at his center.
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
    Event(['Loading PTW water tank file ', strjoin(names, ...
        '\nLoading PTW water tank file ')]);
    tic;
end

% Initialize return structure
data.profiles = cell(0);
c = 0;

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
    
    % Initialize header and scan flags
    header = false;
    scan = false;
    
    % Loop through file contents
    while ~feof(fid)

        % Get line
        l = strtrim(fgetl(fid));
        
        % If line is BEGIN_SCAN_DATA
        if startsWith(l, 'BEGIN_SCAN_DATA')
            
            % Set flag
            header = true;
        
        % Otherwise, skip ahead
        elseif ~header
            continue;
        end

        % If line is BEGIN_SCAN
        if startsWith(l, 'BEGIN_SCAN')
            
            % Increment profiles
            c = length(data.profiles) + 1;
            
            % Set flag
            scan = true;
            
        % If line is END_SCAN
        elseif startsWith(l, 'END_SCAN')
            
            % Set flag
            scan = false;
        
        % Otherwise, if line is a key/value pair
        elseif contains(l, '=')
            
            % Parse name and value
            fields = strsplit(l, '=');
            
            % Parse empty/text values
            if isempty(fields{2})
                
                % Store scan data in cell array
                if scan
                    data.(lower(fields{1})){c} = fields{2};
                else
                    data.(lower(fields{1})) = fields{2};
                end

            % Parse numerical values
            elseif regexp(fields{2}, '^-?\d*\.?\d*$', 'once')
                
                % Store scan data in array
                if scan
                    data.(lower(fields{1}))(c) = str2double(fields{2});
                else
                    data.(lower(fields{1})) = str2double(fields{2});
                end
                
            % Parse numerical arrays
            elseif regexp(fields{2}, '^(-?\d*\.?\d*;?\s?)+$', 'once')
                
                % Split values
                arr = textscan(fields{2}, '%f', 'Delimiter', {';'});
                
                % Store scan data in array
                if scan
                    data.(lower(fields{1}))(c, 1:length(arr{1})) = arr{1};
                else
                    data.(lower(fields{1})) = arr{1};
                end
                
                % Clear temporary variables
                clear arr;

            % Parse date/time values
            elseif regexp(fields{2}, '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$')
                
                % Store scan data in array
                if scan
                    try
                        data.(lower(fields{1}))(c) = ...
                            datenum(fields{2}, 'yyyy-mm-dd HH:MM:SS');
                    catch
                        data.(lower(fields{1}))(c) = [];
                    end
                else
                    try
                        data.(lower(fields{1})) = ...
                            datenum(fields{2}, 'yyyy-mm-dd HH:MM:SS');
                    catch
                        data.(lower(fields{1})) = [];
                    end
                end

            % Parse textual values    
            else
                
                % Store scan data in cell array
                if scan
                    data.(lower(fields{1})){c} = fields{2};
                else
                    data.(lower(lower(fields{1}))) = fields{2};
                end
            end
            
            % Clear temporary variables
            clear fields;
            
        % Otherwise, if this is the start of the data block
        elseif startsWith(l, 'BEGIN_DATA')
            
            % Test the first line to see how many columns there are
            p = ftell(fid);
            l = fgetl(fid);
            n = textscan(l, '%f');
            s = textscan(l, '%s');
            fseek(fid, p, -1);
            
            % Scan the file based on the number of columns
            raw = textscan(fid, strcat(repmat('%f ', 1, length(n{1})), ...
                repmat(' %s', 1, length(s{1}) - length(n{1}))));
            
            % If reference data exists, normalize by the reference
            if length(raw) > 2 && isnumeric(raw{3})
                
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
                    
                    % Log event
                    if exist('Event', 'file') == 2
                        Event(sprintf(['Normalizing profile %i by ', ...
                            'reference channel %i'], c));
                    end
                    
                    % Normalize by reference data
                    raw{2} = raw{2} ./ raw{3} .* mean(raw{3});
                end
            end
            
            % Generate data.profiles based on parameters
            if isfield(data, 'scan_curvetype')
                
                % If PDD
                if strcmp(data.scan_curvetype{c}, 'PDD')
                    
                    % If off axis values exist for this scan
                    if isfield(data, 'scan_offaxis_inplane') && ...
                            data.scan_offaxis_inplane(c) ~= 0 && ...
                            isfield(data, 'scan_offaxis_crossplane') && ...
                            data.scan_offaxis_crossplane(c) ~= 0
                        
                        % Store off axis profile
                        data.profiles{c} = horzcat(ones(length(raw{1}), 1) * ...
                            data.scan_offaxis_crossplane(c), ...
                            ones(length(raw{1}), 1) * ...
                            data.scan_offaxis_inplane(c), raw{1}, raw{2});
                    
                    % Otherwise, profile lies along central axis
                    else
                        data.profiles{c} = horzcat(zeros(length(raw{1}), 2), ...
                            raw{1}, raw{2});
                    end
                    
                % Otherwise, if an in-plane profile
                elseif strcmp(data.scan_curvetype{c}, 'INPLANE_PROFILE') && ...
                        isfield(data, 'scan_depth')
                    
                    % If off axis values exist for this scan
                    if isfield(data, 'scan_offaxis_crossplane') && ...
                            data.scan_offaxis_crossplane(c) ~= 0
                        
                        % Store off axis profile
                        data.profiles{c} = horzcat(ones(length(raw{1}), 1) * ...
                            data.scan_offaxis_crossplane(c), ...
                            raw{1}, ones(length(raw{1}), 1) * ...
                            data.scan_depth(c), raw{2});
                    
                    % Otherwise, profile lies along central axis
                    else
                        data.profiles{c} = horzcat(zeros(length(raw{1}), 1), ...
                            raw{1}, ones(length(raw{1}), 1) * ...
                            data.scan_depth(c), raw{2});
                    end
                    
                % Otherwise, if cross-plane
                elseif strcmp(data.scan_curvetype{c}, 'CROSSPLANE_PROFILE') && ...
                        isfield(data, 'scan_depth')
                       
                    % If off axis values exist for this scan
                    if isfield(data, 'scan_offaxis_inplane') && ...
                            data.scan_offaxis_inplane(c) ~= 0
                        
                        % Store off axis profile
                        data.profiles{c} = horzcat(raw{1}, ...
                            ones(length(raw{1}), 1) * ...
                            data.scan_offaxis_inplane(c), ...
                            ones(length(raw{1}), 1) * ...
                            data.scan_depth(c), raw{2});
                    
                    % Otherwise, profile lies along central axis
                    else
                        data.profiles{c} = horzcat(raw{1}, ...
                            zeros(length(raw{1}), 1), ...
                            ones(length(raw{1}), 1) * ...
                            data.scan_depth(c), raw{2});
                    end
                else
                    
                    % Throw an error
                    if exist('Event', 'file') == 2
                        Event(sprintf(['Profile %i type %s is not ', ...
                            'supported'], c, data.scan_curvetype{...
                            length(data.scan_curvetype)}), 'ERROR');
                    else
                        error(['Profile %i type %s is not ', ...
                            'supported'], c, data.scan_curvetype{...
                            length(data.scan_curvetype)});
                    end
                end
                
            else
                
                % Throw an error
                if exist('Event', 'file') == 2
                    Event(sprintf(['Profile %i orientation could not be ', ...
                        'identified'], c), 'ERROR');
                else
                    error(['Profile %i orientation could not be ', ...
                        'identified'], c);
                end
            end
                
            % Clear temporary variables
            clear p n s raw str;
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

% Clear temporary variables
clear i f l c y fid header scan;