function handles = ProcessProfiles(handles)
% ProcessProfiles is called by WaterTankAnalysis and subfunctions and
% applies each data processing technique to the provided raw profiles.
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

% If raw data exists
if isfield(handles, 'profile') && ~isempty(handles.profile)
    
    % Shift by EPOM
    handles.profile = ShiftProfiles(handles.profile, ...
        get(handles.epom, 'Value'));
    
    % Center profiles
    handles.profile = CenterProfiles(handles.profile, ...
        get(handles.center, 'Value'));
    
    % Convert to depth dose
    handles.profile = ConvertDepthDose(handles.profile, ...
        get(handles.pdi, 'Value'), handles.reference{get(handles.machine, ...
        'Value')}.energies{get(handles.energy, 'Value')}.energy);
    
    % Smooth profiles
    handles.profile = SmoothProfiles(handles.profile, ...
        get(handles.smooth, 'Value'));

    % Normalize profiles
    handles.profile = ScaleProfiles(handles.profile, ...
        get(handles.normalize, 'Value'));
end