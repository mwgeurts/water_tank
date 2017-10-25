function handles = SelectFieldSize(handles, value)
% SelectFieldSize is called by WaterTankAnalysis during tool initialization, 
% when the user clicks Clear All, or when the energy dropdown is changed.
% It updates reference dose, plots, and statistics if a file is selected.
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

% Log selected field size
m = get(handles.machine, 'Value');
e = get(handles.energy, 'Value');
Event(sprintf('Field Size %s selected', ...
    handles.reference{m}.energies{e}.fields{value}));

% If profile data exists
if isfield(handles, 'raw') && ~isempty(handles.raw)
    
    % Ask user for isocenter
    if handles.config.ASK_REFERENCE_ISO == 1
        iso = str2double(inputdlg({'Isocenter IEC X (mm):', ...
            'Isocenter IEC Y (mm):', 'Isocenter IEC Z (mm):'}, ...
            'Enter Isocenter', 1, {'0', '0', '0'}));
    else
        iso = [handles.config.REFERENCE_ISOX handles.config.REFERENCE_ISOY ...
        handles.config.REFERENCE_ISOZ];
    end
    
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
end

% Execute ProcessProfiles
handles = ProcessProfiles(handles);

% Execute UpdateResults
handles = UpdateResults(handles);