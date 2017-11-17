function handles = SelectSSD(handles, value)
% SelectSSD is called by WaterTankAnalysis during tool initialization, 
% when the user clicks Clear All, or when the SSD dropdown is changed.
% It updates the field size options and calls SelectFieldSize to load the
% reference dose if a file is selected.
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

% Log selected SSD
m = get(handles.machine, 'Value');
e = get(handles.energy, 'Value');
Event(sprintf('SSD %s selected', ...
    handles.reference{m}.energies{e}.ssds{value}.ssd));

% Retrieve current field size values
f = get(handles.fieldsize, 'String');

% Initialize new field size
c = min(get(handles.fieldsize, 'Value'), ...
    length(handles.reference{m}.energies{e}.ssds{value}.fields));

% Loop through new field sizes
str = cell(size(handles.reference{m}.energies{e}.ssds{value}.fields));
for i = 1:length(handles.reference{m}.energies{e}.ssds{value}.fields)
    
    % If current field size value matches a new value
    if iscell(f) && strcmp(f{get(handles.fieldsize, 'Value')}, ...
            handles.reference{m}.energies{e}.ssds{value}.fields{i})
        c = i;
    end
    
    % Store new field size
    str{i} = handles.reference{m}.energies{e}.ssds{value}.fields{i};
end

% Update field size list
set(handles.fieldsize, 'Value', c);
set(handles.fieldsize, 'String', str);
clear m e i f str;

% Call SelectFieldSize to update reference dose
handles = SelectFieldSize(handles, c);
