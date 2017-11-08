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

% Update dropdown menu
set(handles.ssd, 'Value', value)

% Reset selected field size
set(handles.fieldsize, 'Value', min(get(handles.fieldsize, 'Value'), ...
    length(handles.reference{m}.energies{e}.ssds{value}.fields)));

% Update field list list
str = cell(size(handles.reference{m}.energies{e}.ssds{value}.fields));
for i = 1:length(handles.reference{m}.energies{e}.ssds{value}.fields)
    str{i} = handles.reference{m}.energies{e}.ssds{value}.fields{i};
end
set(handles.fieldsize, 'String', str);
clear m i str;

% Call SelectFieldSize to update reference dose
handles = SelectFieldSize(handles, get(handles.fieldsize, 'Value'));
