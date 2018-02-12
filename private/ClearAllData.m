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

% The data and processed variables store the loaded profiles
handles.data = [];
handles.processed = [];

% The iso and rcav variables are temporary stored input values
handles.iso = [];
handles.rcav = [];

% Clear files
handles.files = [];

% Clear file string
set(handles.filepath, 'String', '');

% Disable export button while data is cleared
set(handles.saveplots, 'Enable', 'off');

% Reset and Hide plot options
set(handles.optionx, 'Value', 1);
set(handles.optionx, 'visible', 'off');
set(handles.optiony, 'Value', 2);
set(handles.optiony, 'visible', 'off');
set(handles.optionz, 'Value', 3);
set(handles.optionz, 'visible', 'off');

% Hide plots
set(allchild(handles.iecx), 'visible', 'off'); 
set(handles.iecx, 'visible', 'off');
legend(handles.iecx,'hide')
set(allchild(handles.iecy), 'visible', 'off'); 
set(handles.iecy, 'visible', 'off');
legend(handles.iecy,'hide')
set(allchild(handles.iecz), 'visible', 'off'); 
set(handles.iecz, 'visible', 'off');
legend(handles.iecz,'hide')

% Clear statistics
set(handles.xystats, 'data', CalcProfileStats());
set(handles.zstats, 'data', CalcDepthStats());

% Reset reference dropdowns
set(handles.machine, 'Value', handles.config.DEFAULT_MACHINE);
set(handles.energy, 'Value', handles.config.DEFAULT_ENERGY);
set(handles.ssd, 'Value', handles.config.DEFAULT_SSD);
set(handles.fieldsize, 'Value', handles.config.DEFAULT_FIELDSIZE);

% Reset processing options
set(handles.epom, 'Value', handles.config.DEFAULT_EPOM);
set(handles.pdi, 'Value', handles.config.DEFAULT_PDI);
set(handles.normalize, 'Value', handles.config.DEFAULT_NORMALIZE);
set(handles.smooth, 'Value', handles.config.DEFAULT_SMOOTH);
set(handles.center, 'Value', handles.config.DEFAULT_CENTER);
set(handles.convolve, 'Value', handles.config.DEFAULT_CONVOLVE);

% Reset chamber orientation
ConvolveProfiles();

% Reset default detector
set(handles.detector, 'Value', handles.config.DEFAULT_DETECTOR);
Event(sprintf('Detector set to %s (Rcav = %0.2f mm)', ...
    handles.detectors{get(handles.detector, 'Value'), 1}, ...
    handles.detectors{get(handles.detector, 'Value'), 2}/2));

% Set Gamma criteria
set(handles.gamma, 'String', handles.config.DEFAULT_GAMMA);
if handles.config.DEFAULT_GAMMALOCAL == 1
    set(handles.radiobutton2, 'Value', 0);
    set(handles.radiobutton3, 'Value', 1);
else
    set(handles.radiobutton2, 'Value', 1);
    set(handles.radiobutton3, 'Value', 0);
end