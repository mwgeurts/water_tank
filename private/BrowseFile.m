function handles = BrowseFile(handles)
% BrowseFile is called when the user clicks the BrowseButton, and prompts
% the user to select a file. It then calls ParseProfile on each input file, 
% then executes ProcessProfiles and UpdateResults.
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

% Retrieve current file type and parse extension tokens
s = get(handles.format, 'String');
t = regexp(s{get(handles.format, 'Value')}, '\((.+)\)', 'tokens');
if ~isempty(t)
    types = strsplit(t{end}{1}, ', ');
    types = ['*', strjoin(horzcat(lower(types), upper(types)), ';*')];
else
    types = '*.*';
end

% Request the user to select the profile
Event('UI window opened to select file');
[name, path] = uigetfile({types, s{get(handles.format, 'Value')}}, ...
    ['Select the ', s{get(handles.format, 'Value')}, 'profiles to load'], ...
    handles.config.DEFAULT_PATH, 'MultiSelect', 'on');
clear s t types;

% If a file was selected
if iscell(name) || sum(name ~= 0)

    % If not cell array, cast as one
    if ~iscell(name)
    
        % Update text box with file name
        set(handles.filepath, 'String', fullfile(path, name));
        
        % Store filenames
        files = cell(1);
        files{1} = name;
    else
    
        % Update text box with first file
        set(handles.filepath, 'String', 'Multiple files selected');
        
        % Store filenames
        files = name;
    end
    
    % Log names
    Event([strjoin(files, ' selected\n'), ' selected']);
    
    % Update default path
    handles.config.DEFAULT_PATH = path;
    Event(['Default file path updated to ', path]);
    
    % Clear processed data cell array
    handles.processed = [];
    
    % Execute ParseProfile
    handles.data = ParseProfile(fullfile(path, files), ...
        get(handles.format, 'Value'));
    
    % Flip measured X/Y if config option is set
    if get(handles.flipaxes, 'Value') == 1
        Event('Flipping measured X/Y dimensions per UI checkbox');
        for i = 1:length(handles.data.profiles)
            handles.data.profiles{i}(:,1:2) = ...
                handles.data.profiles{i}(:,2:-1:1);
        end
    end

    %% Match machine
    % If machines is specified in profiles, find best match
    if handles.config.MATCH_HEADER == 1 && isfield(handles.data, 'machine')
        [a1, ld1] = strnearest(handles.data.machine{1}, ...
            get(handles.machine, 'String'), 'case');
    else
        ld1 = Inf;
    end
    
    % If match filename is enabled, find best match
    if handles.config.MATCH_FILENAME == 1
        if iscell(name)
            parts = strsplit(name{1}, {'-', '_', '.', ' '});
        else
            parts = strsplit(name, {'-', '_', '.', ' '});
        end
        ld2 = Inf;
        for i = 1:length(parts)
            [x, y] = strnearest(parts{i}, ...
                get(handles.machine, 'String'), 'case');
            if y < ld2
                a2 = x;
                ld2 = y;
            end
        end
    else
        ld2 = Inf;
    end
    
    % Update machine with smaller of two Levenshtein distances
    if ld1 <= ld2 && ld1 < handles.config.LEVENSHTEIN_THRESH
        
        % Log result
        Event(sprintf(['Profile header matched machine index %i with ', ...
            'Levenshtein distance of %i'], a1(end), ld1));
        
        % Set machine name
        set(handles.machine, 'Value', a1(end));
        
    elseif ld2 < ld1 && ld2 < handles.config.LEVENSHTEIN_THRESH
        
        % Log result
        Event(sprintf(['File name matched machine index %i with ', ...
            'Levenshtein distance of %i'], a2(end), ld2));
        
        % Set machine name
        set(handles.machine, 'Value', a2(end));
    end
    
    % Update energy list
    str = cell(size(handles.reference{get(handles.machine, 'Value')}...
        .energies));
    for i = 1:length(handles.reference{get(handles.machine, 'Value')}...
            .energies)
        str{i} = handles.reference{get(handles.machine, 'Value')}...
            .energies{i}.energy;
    end
    set(handles.energy, 'String', str);
    
    %% Match energy
    % If energy is specified in profiles, find best match
    if handles.config.MATCH_HEADER == 1 && isfield(handles.data, 'energy')
        [a1, ld1] = strnearest(handles.data.energy{1}, ...
            get(handles.energy, 'String'), 'case');
    else
        ld1 = Inf;
    end
    
    % If match filename is enabled, find best match
    if handles.config.MATCH_FILENAME == 1
        if iscell(name)
            parts = strsplit(name{1}, {'-', '_', '.', ' '});
        else
            parts = strsplit(name, {'-', '_', '.', ' '});
        end
        ld2 = Inf;
        for i = 1:length(parts)
            parts{i} = strrep(parts{i}, 'MV', ' MV');
            parts{i} = strrep(parts{i}, 'MeV', ' MeV');
            parts{i} = strrep(parts{i}, 'X', ' MV');
            parts{i} = strrep(parts{i}, 'E', ' MeV');
            parts{i} = strrep(parts{i}, 'F', ' MV FFF');
            [x, y] = strnearest(parts{i}, ...
                get(handles.energy, 'String'), 'case');
            if y < ld2
                a2 = x;
                ld2 = y;
            end
        end
    else
        ld2 = Inf;
    end
    
    % Update energy with smaller of two Levenshtein distances
    if ld1 <= ld2 && ld1 < handles.config.LEVENSHTEIN_THRESH
        
        % Log result
        Event(sprintf(['Profile header matched energy index %i with ', ...
            'Levenshtein distance of %i'], a1(end), ld1));
        
        % Set energy
        set(handles.energy, 'Value', a1(end));
        
    elseif ld2 < ld1 && ld2 < handles.config.LEVENSHTEIN_THRESH
        
        % Log result
        Event(sprintf(['File name matched energy index %i with ', ...
            'Levenshtein distance of %i'], a2(end), ld2));
        
        % Set energy
        set(handles.energy, 'Value', a2(end));
    end
    
    % Update SSD list
    str = cell(size(handles.reference{get(handles.machine, 'Value')}...
        .energies{get(handles.energy, 'Value')}.ssds));
    for i = 1:length(handles.reference{get(handles.machine, 'Value')}...
            .energies{get(handles.energy, 'Value')}.ssds)
        str{i} = handles.reference{get(handles.machine, 'Value')}...
            .energies{get(handles.energy, 'Value')}.ssds{i}.ssd;
    end
    set(handles.ssd, 'String', str);
    
    %% Match SSD
    % If SSD is specified in profiles, find best match
    if handles.config.MATCH_HEADER == 1 && isfield(handles.data, 'ssd')
        [a1, ld1] = strnearest(sprintf('%0.0f cm', handles.data.ssd(1)), ...
            get(handles.ssd, 'String'), 'case');
    else
        ld1 = Inf;
    end
    
    % If match filename is enabled, find best match
    if handles.config.MATCH_FILENAME == 1
        if iscell(name)
            parts = strsplit(name{1}, {'-', '_', '.', ' '});
        else
            parts = strsplit(name, {'-', '_', '.', ' '});
        end
        ld2 = Inf;
        for i = 1:length(parts)
            parts{i} = strrep(parts{i}, 'cm', ' cm');
            [x, y] = strnearest(parts{i}, ...
                get(handles.ssd, 'String'), 'case');
            if y < ld2
                a2 = x;
                ld2 = y;
            end
        end
    else
        ld2 = Inf;
    end
    
    % Update SSD with smaller of two Levenshtein distances
    if ld1 <= ld2 && ld1 < handles.config.LEVENSHTEIN_THRESH
        
        % Log result
        Event(sprintf(['Profile header matched SSD index %i with ', ...
            'Levenshtein distance of %i'], a1(end), ld1));
        
        % Set SSD
        set(handles.ssd, 'Value', a1(end));
        
    elseif ld2 < ld1 && ld2 < handles.config.LEVENSHTEIN_THRESH
        
        % Log result
        Event(sprintf(['File name matched SSD index %i with ', ...
            'Levenshtein distance of %i'], a2(end), ld2));
        
        % Set SSD
        set(handles.ssd, 'Value', a2(end));
    end
    
    % Update field size list
    str = cell(size(handles.reference{get(handles.machine, 'Value')}...
        .energies{get(handles.energy, 'Value')}...
        .ssds{get(handles.ssd, 'Value')}.fields));
    for i = 1:length(handles.reference{get(handles.machine, 'Value')}...
            .energies{get(handles.energy, 'Value')}...
            .ssds{get(handles.ssd, 'Value')}.fields)
        str{i} = handles.reference{get(handles.machine, 'Value')}...
            .energies{get(handles.energy, 'Value')}...
            .ssds{get(handles.ssd, 'Value')}.fields{i};
    end
    set(handles.fieldsize, 'String', str);
    
    %% Match field size
    % If collimator is specified in profiles, find best match
    if handles.config.MATCH_HEADER == 1 && ...
            isfield(handles.data, 'collimator') && ...
            sum(sum(abs(handles.data.collimator))) > 0
        [a1, ld1] = strnearest(sprintf('%0.0f x %0.0f', ...
            sum(abs(handles.data.collimator(1,1:2))), ...
            sum(abs(handles.data.collimator(1,3:4)))), ...
            get(handles.fieldsize, 'String'), 'case');
    else
        ld1 = Inf;
    end
    
    % If match filename is enabled, find best match
    if handles.config.MATCH_FILENAME == 1
        if iscell(name)
            parts = strsplit(name{1}, {'-', '_', '.', ' '});
        else
            parts = strsplit(name, {'-', '_', '.', ' '});
        end
        ld2 = Inf;
        for i = 1:length(parts)
            %parts{i} = strrep(parts{i}, 'x', ' x ');
            [x, y] = strnearest(parts{i}, ...
                get(handles.fieldsize, 'String'), 'case');
            if y < ld2 && length(x) < 4
                a2 = x;
                ld2 = y;
            end
            if i > 1
                [x, y] = strnearest([parts{i-1}, ' ', parts{i}], ...
                    get(handles.fieldsize, 'String'), 'case');
                if y <= ld2 && length(x) < 4
                    a2 = x;
                    ld2 = y;
                end    
            end
        end
    else
        ld2 = Inf;
    end
    
    % Update field size with smaller of two Levenshtein distances
    if ld1 <= ld2 && ld1 < handles.config.LEVENSHTEIN_THRESH
        
        % Log result
        Event(sprintf(['Profile header matched field size index %i with ', ...
            'Levenshtein distance of %i'], a1(end), ld1));
        
        % Set field size
        set(handles.fieldsize, 'Value', a1(end));
        
    elseif ld2 < ld1 && ld2 < handles.config.LEVENSHTEIN_THRESH
        
        % Log result
        Event(sprintf(['File name matched field size index %i with ', ...
            'Levenshtein distance of %i'], a2(end), ld2));
        
        % Set field size
        set(handles.fieldsize, 'Value', a2(end));
        
    end
    
    %% Match detector 
    % If detector model is included
    if isfield(handles.data, 'detector')
        
        % Match detector to list
        [a1, ld1] = strnearest(handles.data.detector{1}, ...
            get(handles.detector, 'String'), 'case');
        
        % If distance is less than threshold
        if ld1 < handles.config.LEVENSHTEIN_THRESH
            
            % Log result
            Event(sprintf(['Profile header matched detector index %i with ', ...
                'Levenshtein distance of %i'], a1(end), ld1));

            % Set field size
            set(handles.detector, 'Value', a1(end));
        end
    end
    
    % Clear temporary variables
    clear a1 a2 ld1 ld2 i str x y;
    
    %% Continue to ProcessProfiles and UpdateResults
    % Execute ProcessProfiles
    handles = ProcessProfiles(handles);
    
    % Execute UpdateResults
    handles = UpdateResults(handles);
    
    % Enable save button
    set(handles.saveplots, 'Enable', 'on');
end

% Clear temporary variables
clear name path files;