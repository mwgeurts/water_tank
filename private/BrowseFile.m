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

% Request the user to select the profile
Event('UI window opened to select file');
[name, path] = uigetfile('*.*', 'Select the profiles to load', ...
    handles.config.DEFAULT_PATH, 'MultiSelect', 'on');

% If a file was selected
if iscell(name) || sum(name ~= 0)
    

    % If not cell array, cast as one
    if ~iscell(name)
    
        % Update text box with file name
        set(handles.filepath, 'String', fullfile(path, name));
        
        % Store filenames
        handles.files = cell(1);
        handles.files{1} = name;
    else
    
        % Update text box with first file
        set(handles.filepath, 'String', 'Multiple files selected');
        
        % Store filenames
        handles.files = name;
    end
    
    % Log names
    Event([strjoin(handles.files, ' selected\n'), ' selected']);
    
    % Update default path
    handles.config.DEFAULT_PATH = path;
    Event(['Default file path updated to ', path]);
    
    % Initialize raw profile cell array
    handles.raw = cell(0);
    handles.profile = [];
    
    % Loop through files
    for i = 1:length(handles.files)
        
        % Execute ParseProfile, concatenating results
        handles.raw = horzcat(handles.raw, ParseProfile(fullfile(path, ...
            handles.files{i}), get(handles.format, 'Value')));
    end
    
    % Ask user for isocenter
    if handles.config.ASK_REFERENCE_ISO == 1
        iso = str2double(inputdlg({'Isocenter IEC X (mm):', ...
            'Isocenter IEC Y (mm):', 'Isocenter IEC Z (mm):'}, ...
            'Enter Isocenter', 1, {sprintf('%0.1f', ...
            handles.config.REFERENCE_ISOX), sprintf('%0.1f', ...
            handles.config.REFERENCE_ISOY), sprintf('%0.1f', ...
            handles.config.REFERENCE_ISOY)}));
    else
        iso = [handles.config.REFERENCE_ISOX handles.config.REFERENCE_ISOY ...
        handles.config.REFERENCE_ISOZ];
    end

    % Check input file(s) for machine, energy, and field size
    
    % Find closest match for file name
    [a, b, c] = MatchFileName(name, handles.reference);
   
    % Log selection
    Event(['Reference dataset ', handles.reference{a}.machine, ', ', ...
        handles.reference{a}.energies{b}.energy, ', ', handles.reference{a}...
        .energies{b}.fields{c}, ' found as most likely matching profile']);  
    
    % Update energy list
    str = cell(size(handles.reference{a}.energies));
    for i = 1:length(handles.reference{a}.energies)
        str{i} = handles.reference{a}.energies{i}.energy;
    end
    set(handles.energy, 'String', str);
    clear i str;
    
    % Update field list list
    str = cell(size(handles.reference{a}.energies{b}.fields));
    for i = 1:length(handles.reference{a}.energies{b}.fields)
        str{i} = handles.reference{a}.energies{b}.fields{i};
    end
    set(handles.fieldsize, 'String', str);
    clear m i str;
    
    % Update selection
    set(handles.machine, 'Value', a);
    set(handles.energy, 'Value', b);
    set(handles.fieldsize, 'Value', c);

    
    % Execute ExtractRefProfile
    handles.profile = ExtractRefProfile(handles.raw, ...
        fullfile(pwd, handles.config.REFERENCE_PATH, ...
        handles.reference{get(handles.machine, 'Value')}.machine, ...
        handles.reference{get(handles.machine, 'Value')}...
        .energies{get(handles.energy, 'Value')}.energy, ...
        [handles.reference{get(handles.machine, 'Value')}...
        .energies{get(handles.energy, 'Value')}...
        .fields{get(handles.fieldsize, 'Value')}, '.dcm']), iso);
      
    % Clear temporary variables
    clear i iso;
    
    % Execute ProcessProfiles
    handles = ProcessProfiles(handles);
    
    % Execute UpdateResults
    handles = UpdateResults(handles);
end

% Clear temporary variables
clear name path;