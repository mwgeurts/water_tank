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

% Unset iso
handles.iso = [];

% Execute ProcessProfiles
handles = ProcessProfiles(handles);

% Execute UpdateResults
handles = UpdateResults(handles);
