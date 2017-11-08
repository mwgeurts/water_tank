function data = ParseSIcsv(path, names)
% ParseSIcsv extracts water tank profiles from IBA OmniPro RFA300 ASCII 
% BDS formatted text files. Each profile is returned an array of position
% and signal values. If two or more channels exist in the data, the 
% function will try to identify which channel is reference and prompt the
% user whether they want to normalize by it.
%
% The following variables are required for proper execution:
%   path: string containing the path to the TXT files
%   names: string or cell array of strings containing the file(s) to be 
%       loaded
%
% The following structure fields are returned upon successful completion:
%   timestamp: array of date/time each file was saved, as an integer
%   version: cell array of file version strings
%   orientation: array of tank orientation flags, where 1 is longitudinal
%       and 0 is lateral
%   pdd: array of flags indicating whether file contains PDD/SPDD data
%   channels: cell array of strings indicating which channels are active
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

        % If line is a comment
        if length(l) > 1 && strcmp(l(1), '#')

            % If comment refers to SAVED, store it
            if length(l) > 8 && strcmp(l(1:8), '# SAVED:')

                % Parse out date and time integers
                c = textscan(l(9:end), ...
                    'date %f/%f/%f time %f:%f:%f');

                % Store serial date number
                data.timestamp(f) = datenum(c{3}, c{1}, ...
                    c{2}, c{4}, c{5}, c{6});
                
                % Log event
                if exist('Event', 'file') == 2
                    Event(['File saved on ', datestr(data.timestamp(f))]);
                end
            end

        % If line is a header
        elseif length(l) > 1 && strcmp(l(1), '*')

            % If header is version, store value
            if length(l) > 9 && strcmp(l(1:9), '*VERSION*')

                % Store version 
                data.version{f} = strtrim(l(10:end));
                
                % Log event
                if exist('Event', 'file') == 2
                    Event(['File version is ', data.version{f}]);
                end

            % If header is orientation, store value
            elseif length(l) > 13 && ...
                    strcmp(l(1:13), '*ORIENTATION*')

                % Store orientation 
                data.orientation(f) = ...
                    str2double(strtrim(l(14:end)));
                
                % Log event
                if exist('Event', 'file') == 2 && data.orientation(f) == 1
                    Event('Tank orientation is longitudinal');
                elseif exist('Event', 'file') == 2 && ...
                        data.orientation(f) == 0
                    Event('Tank orientation is lateral');
                end

            % If header is channels, store value
            elseif length(l) > 10 && strcmp(l(1:10), '*CHANNELS*')

                % Store orientation 
                data.channels{f} = strtrim(l(11:end));
                
                % Log event
                if exist('Event', 'file') == 2
                    Event(['Active channels: ', data.channels{f}]);
                end

            % If header is pdd, store value
            elseif length(l) > 5 && strcmp(l(1:5), '*PDD*')

                % Store pdd 
                data.pdd(f) = str2double(strtrim(l(6:end)));
                
                % Log event
                if exist('Event', 'file') == 2 && data.pdd(f) == 1
                    Event('PDD flag enabled');
                end

            % If header contains data columns, parse data
            elseif length(l) > 9 && strcmp(l(1:9), '*abs time')

                % Scan remainder of file
                raw = textscan(fid, ['%f,%f,%f,%f,', ...
                    strrep(strrep(data.channels{f}, '1', '%f,'), ...
                    '0', '-,')]);
                break;
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
        Event(sprintf('%i data points parsed across %i channels', ...
            length(raw{1}), length(raw)-4));
    end
    
    % If two channels exist, look for channel with less variation
    if length(raw) == 6
        
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
            if std(raw{5})/mean(raw{5}) > std(raw{6})/mean(raw{6})
                
                % Log event
                if exist('Event', 'file') == 2
                    c = strfind(data.channels{f}, '1');
                    Event(sprintf('Normalizing by reference channel %i', ...
                        c(end)));
                end
                
                % Divide by reference channel, normalized to mean
                raw{5} = raw{5} ./ raw{6} .* mean(raw{6});
            else
                
                % Log event
                if exist('Event', 'file') == 2
                    c = strfind(data.channels{f}, '1');
                    Event(sprintf('Normalizing by reference channel %i', ...
                        c(1)));
                end
                
                % Divide by reference channel, normalized to mean
                raw{5} = raw{6} ./ raw{5} .* mean(raw{5});
            end
            
        % Otherwise the user clicked no or cancel    
        else
            
            % Move channel with greater variation to raw{5}
            if std(raw{5})/mean(raw{5}) < std(raw{6})/mean(raw{6}) 
                raw{5} = raw{6};
            end
        end
        
    % Otherwise, if more than two channels exist
    elseif length(raw) > 6
        
        % Prompt the user to select which channels to laod
        if ~exist('a', 'var') || ~exist('b', 'var')
            
            % If a GUI exists
            if usejava('jvm') && feature('ShowFigureWindows')
                [a, ~] = listdlg('PromptString', ...
                    'Select which channel is the signal:', 'SelectionMode', ...
                    'single', 'ListString', sprintfc('Channel %i', ...
                    strfind(data.channels{f}, '1')), 'ListSize', [200 100]);        
                [b, ~] = listdlg('PromptString', ...
                    'Select which channel is the reference:', 'SelectionMode', ...
                    'single', 'ListString', horzcat('Do not normalize', ...
                    sprintfc('Channel %i', strfind(data.channels{f}, '1'))), ...
                    'ListSize', [200 100]);
            else
                a = input('Which channel is the signal? ');
                b = input(['Which channel is the reference ', ...
                    '(enter 0 for no reference)? ']);
                b = b + 1;
            end
        end
        
        % If the user chose a reference
        if a > 0 && b > 1
         
            % Log event
            if exist('Event', 'file') == 2
                Event('Normalizing by selected reference channel');
            end
            
            % Normalize signal by reference, storing in raw{5}
            raw{5} = raw{4+a} ./ raw{3+a} .* mean(raw{3+a});
            
        % Otherwise, if a signal was chosen
        elseif a > 0 
            
            % Store the signal in raw{5}
            raw{5} = raw{4+a};
        end
    end
    
    % If this profile contains a PDD/SPDD
    if data.pdd(f) == 1

        % If processed data exists, use it
        if max(raw{4}) > 900
            
            % Log event
            if exist('Event', 'file') == 2
                Event('Storing processed PDD profile');
            end
            
            % Initialize profiles entry
            data.profiles{length(data.profiles)+1} = ...
                zeros(sum(raw{4} == 900.1), 4);

            % Store the IEC Z data
            data.profiles{length(data.profiles)}(:,3) = ...
                raw{3}(raw{4} == 900.1);
            
            % Store the signal
            data.profiles{length(data.profiles)}(:,4) = ...
                raw{5}(raw{4} == 900.1);
        
        % If the X/Y positions change, assume this is an SPDD
        elseif raw{3}(2) ~= raw{3}(1)
            
            % Log event
            if exist('Event', 'file') == 2
                Event('Storing SPDD profile');
            end
            
            % Initialize profiles entry
            data.profiles{length(data.profiles)+1} = ...
                zeros(length(unique(raw{4}))-1, 4);
            
            % Initialize start depth, index, and counter
            d = raw{4}(1);
            i = 1;
            c = 0;
            
            % Append EOF flag onto raw{4}
            raw{4}(length(raw{4})+1) = 9999;

            % Loop through depth array
            for j = 2:length(raw{4})

                % If the depth differs, store the maximum value
                if raw{4}(j) ~= d
           
                    % Increment counter
                    c = c + 1;
                    
                    % Store the IEC Z data
                    data.profiles{length(data.profiles)}(c,3) = ...
                        raw{4}(i);

                    % Store the signal normalized by time
                    data.profiles{length(data.profiles)}(c,4) = ...
                        max(raw{5}(i:j-1));
                    
                    % Update indices
                    d = raw{4}(j);
                    i = j;
                end
            end
            
        % Otherwise, assume this is a PDD
        else
            
            % Log event
            if exist('Event', 'file') == 2
                Event('Storing PDD profile');
            end
            
            % Initialize profiles entry
            data.profiles{length(data.profiles)+1} = ...
                zeros(length(raw{4}), 4);
            
            % Store IEC X data
            if data.orientation(f) == 0
                data.profiles{length(data.profiles)}(:,1) = raw{3};

            % Store the IEC Y data
            else
                data.profiles{length(data.profiles)}(:,2) = raw{3};
            end 
            
            % Store the IEC Z data
            data.profiles{length(data.profiles)}(:,3) = raw{4};
            
            % Store the signal
            data.profiles{length(data.profiles)}(:,4) = raw{5};
        end

    % Otherwise, if this is a set of IEC X or Y profiles
    else

        % Initialize start depth and index
        d = raw{4}(1);
        i = 1;
        
        % Append EOF flag onto raw{4}
        raw{4}(length(raw{4})+1) = 9999;
        
        % Loop through depth array
        for j = 2:length(raw{4})

            % If the depth differs, store the profile
            if raw{4}(j) ~= d
               
                % Initialize profiles entry
                data.profiles{length(data.profiles)+1} = zeros(j-i, 4);
                
                % Store IEC X data
                if data.orientation(f) == 0
                    
                    % Log event
                    if exist('Event', 'file') == 2
                        Event(sprintf(['Storing IEC X profile at depth', ...
                            '%0.1f mm'], raw{4}(i)));
                    end
                    
                    data.profiles{length(data.profiles)}(:,1) = ...
                        raw{3}(i:j-1);
                
                % Store the IEC Y data
                else
                    
                    % Log event
                    if exist('Event', 'file') == 2
                        Event(sprintf(['Storing IEC Y profile at depth', ...
                            '%0.1f mm'], raw{4}(i)));
                    end
                    
                    data.profiles{length(data.profiles)}(:,2) = ...
                        raw{3}(i:j-1);
                end
                
                % Store the IEC Z data
                data.profiles{length(data.profiles)}(:,3) = raw{4}(i:j-1);
                
                % Store the signal data
                data.profiles{length(data.profiles)}(:,4) = raw{5}(i:j-1);
                
                % Update indices
                d = raw{4}(j);
                i = j;
            end
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
    
    % If signal is negative (positive bias), invert the signal
    if mean(data.profiles{i}(:,4)) < 0
        
        % Log event
        if exist('Event', 'file') == 2
            Event('Inverting negative signal');
        end
        
        % Store negative value
        data.profiles{i}(:,4) = -data.profiles{i}(:,4);
    end
end

% Clear temporary file
clear f i j c d y a b l fid raw;
