function handles = SelectMachine(handles, value)
% SelectMachine is called by WaterTankAnalysis during tool initialization, 
% when the user clicks Clear All, or when the machine dropdown is changed.
% It updates the energy options and calls SelectEnergy to update the field
% size options.
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

% Log selected machine
Event(sprintf('Machine %s selected', handles.reference{value}.machine));

% Update dropdown menu
set(handles.machine, 'Value', value)

% Reset selected energy
set(handles.energy, 'Value', 1);

% Update energy list
str = cell(size(handles.reference{value}.energies));
for i = 1:length(handles.reference{value}.energies)
    str{i} = handles.reference{value}.energies{i}.energy;
end
set(handles.energy, 'String', str);
clear i str;

% Call SelectEnergy to update field size list
handles = SelectEnergy(handles, 1);
