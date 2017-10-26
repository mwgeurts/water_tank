function handles = InitializeMenus(handles)
% InitializeMenus is called by WaterTankAnalysis during startup and
% initializes all static dropdown menu options.
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

% Set profile format options
set(handles.format, 'String', ParseProfile());

% Set initial machine, field size, and energy
str = cell(size(handles.reference));
for i = 1:length(handles.reference)
    str{i} = handles.reference{i}.machine;
end
set(handles.machine, 'String', str);
handles = SelectMachine(handles, 1);
clear i str;

% Set detectors menu
set(handles.detector, 'String', handles.detectors(:,1));

% Set centering menu
set(handles.center, 'String', CenterProfiles());

% Set epom menu
set(handles.epom, 'String', ShiftProfiles());

% Set smooth menu
set(handles.smooth, 'String', SmoothProfiles());

% Set scaling menu
set(handles.normalize, 'String', ScaleProfiles());

% Set pdi menu
set(handles.pdi, 'String', ConvertDepthDose());

% Set convolve menu
set(handles.convolve, 'String', ConvolveProfiles());


