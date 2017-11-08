function handles = SelectEnergy(handles, value)
% SelectEnergy is called by WaterTankAnalysis during tool initialization, 
% when the user clicks Clear All, or when the energy dropdown is changed.
% It updates the SSD options and calls SelectSSD to load the reference 
% dose if a file is selected.
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

% Log selected energy
m = get(handles.machine, 'Value');
Event(sprintf('Energy %s selected', ...
    handles.reference{m}.energies{value}.energy));

% Update dropdown menu
set(handles.energy, 'Value', value)

% Reset selected SSD
set(handles.ssd, 'Value', min(get(handles.ssd, 'Value'), ...
    length(handles.reference{m}.energies{value}.ssds)));

% Update SSD list
str = cell(size(handles.reference{m}.energies{value}.ssds));
for i = 1:length(handles.reference{m}.energies{value}.ssds)
    str{i} = handles.reference{m}.energies{value}.ssds{i}.ssd;
end
set(handles.ssd, 'String', str);
clear m i str;

% Call SelectSSD to update reference dose
handles = SelectSSD(handles, get(handles.ssd, 'Value'));
