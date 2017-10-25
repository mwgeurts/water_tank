function handles = ClearAllData(handles)
% ClearAllData is called by WaterTankAnalysis during application 
% initialization and if the user presses "Clear All" to reset the UI and 
% initialize all runtime data storage variables. Note that all checkboxes 
% will get updated to their configuration default settings.
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

% Log action
if isfield(handles, 'reference')
    Event('Clearing data from memory');
else
    Event('Initializing data variables');
end

% The raw and profile variables store the loaded profiles
handles.raw = [];
handles.profile = [];

% Clear files
handles.files = [];

% Clear file string
set(handles.filepath, 'String', '');

% Disable export button while data is cleared
set(handles.saveplots, 'Enable', 'off');

% Hide plots
set(allchild(handles.iecx), 'visible', 'off'); 
set(handles.iecx, 'visible', 'off');
set(allchild(handles.iecy), 'visible', 'off'); 
set(handles.iecy, 'visible', 'off');
set(allchild(handles.iecz), 'visible', 'off'); 
set(handles.iecz, 'visible', 'off');

% Clear statistics
set(handles.xystats, 'data', CalcProfileStats());
set(handles.zstats, 'data', CalcDepthStats());

% Clear processing options
set(handles.epom, 'Value', str2double(handles.config.DEFAULT_EPOM));
set(handles.pdi, 'Value', str2double(handles.config.DEFAULT_PDI));
set(handles.normalize, 'Value', str2double(handles.config.DEFAULT_NORMALIZE));
set(handles.smooth, 'Value', str2double(handles.config.DEFAULT_SMOOTH));
set(handles.center, 'Value', str2double(handles.config.DEFAULT_CENTER));

% Set Gamma criteria
set(handles.gamma, 'String', handles.config.DEFAULT_GAMMA);
if str2double(handles.config.DEFAULT_GAMMALOCAL) == 1
    set(handles.radiobutton2, 'Value', 0);
    set(handles.radiobutton3, 'Value', 1);
else
    set(handles.radiobutton2, 'Value', 1);
    set(handles.radiobutton3, 'Value', 0);
end