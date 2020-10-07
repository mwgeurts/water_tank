function handles = UpdateResults(handles)
% UpdateResults is called by WaterTankAnalysis and subfunctions and
% re-computes/displays the results, if data exists
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

% If processed profile data exists
if isfield(handles, 'processed') && ~isempty(handles.processed)
    
    % Retrieve Gamma criteria
    c = strsplit(get(handles.gamma,'String'), '/');

    % If the user didn't include a /
    if length(c) < 2

        % Throw a warning
        Event(['Gamma criteria must be provided using the ', ...
            'format ##%/## mm'], 'ERROR');  
    else

        % Parse values
        percent = str2double(regexprep(c{1}, '[^\d\.]', ''));
        dta = str2double(regexprep(c{2}, '[^\d\.]', ''));
    end 
    
    % Execute CalcProfileGamma()
    handles.processed = CalcProfileGamma(handles.processed, percent, dta, ...
            get(handles.radiobutton3, 'Value'));

    % Execute PlotProfiles()
    handles = PlotProfiles(handles);

    % Execute CalcProfileStats()
    set(handles.xystats, 'data', CalcProfileStats(handles.processed, ...
        handles.config.FWXM_STAT));

    % Execute CalcDepthStats()
    set(handles.zstats, 'data', CalcDepthStats(handles.reference{...
        get(handles.machine, 'Value')}.energies{get(handles.energy, ...
        'Value')}.energy, handles.processed, handles.config));
    
end