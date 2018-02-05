function SaveStatistics(handles, file)
% SaveStatistics is called when "Export Results" is clicked and saves the
% UI content to a spreadsheet or text file. The dropdown menu values are
% included with the statistics tables to resemble a report. The filetype is
% determined from the extension of the file input argument; if the filetype
% is a spreadsheet, the raw processed data (position, measured, reference, 
% and gamma) are also exported to subsequent tabs.
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

% Store statistics tables temporarily
xy = get(handles.xystats, 'Data');
z = get(handles.zstats, 'Data');

% Create cell array to store report
arr = cell(size(xy,1)+size(z,1)+23, max(size(xy,2), size(z,2)));

% Store input data to cell array
arr{1,1} = 'Input Data';
arr{2,1} = 'Water Tank Profile:';
arr{2,2} = get(handles.filepath, 'String');
arr{3,1} = 'Reference Profile:';
arr{3,2} = fullfile(pwd, handles.config.REFERENCE_PATH, ...
    handles.reference{get(handles.machine, 'Value')}.machine, ...
    handles.reference{get(handles.machine, 'Value')}...
    .energies{get(handles.energy, 'Value')}.energy, ...
    handles.reference{get(handles.machine, 'Value')}...
    .energies{get(handles.energy, 'Value')}...
    .ssds{get(handles.ssd, 'Value')}.ssd, ...
    [handles.reference{get(handles.machine, 'Value')}...
    .energies{get(handles.energy, 'Value')}...
    .ssds{get(handles.ssd, 'Value')}.fields{...
    get(handles.fieldsize, 'Value')}, '.dcm']);
arr{4,1} = 'Profile Format:';
o = get(handles.format, 'String');
arr{4,2} = o{get(handles.format, 'Value')};
arr{5,1} = 'Treatment System:';
arr{5,2} = handles.reference{get(handles.machine, 'Value')}.machine;
arr{6,1} = 'Beam Energy:';
arr{6,2} = handles.reference{get(handles.machine, 'Value')}...
    .energies{get(handles.energy, 'Value')}.energy;
arr{7,1} = 'SSD/Medium:';
arr{7,2} = handles.reference{get(handles.machine, 'Value')}...
    .energies{get(handles.energy, 'Value')}...
    .ssds{get(handles.ssd, 'Value')}.ssd;
arr{8,1} = 'Field/Applicator:';
arr{8,2} = handles.reference{get(handles.machine, 'Value')}...
    .energies{get(handles.energy, 'Value')}...
    .ssds{get(handles.ssd, 'Value')}.fields{...
    get(handles.fieldsize, 'Value')};
arr{9,1} = 'Detector Model:';
arr{9,2} = handles.detectors{get(handles.energy, 'Value'), 1};
arr{10,1} = 'Rcav:';
arr{10,2} = sprintf('%0.2f mm', ...
    handles.detectors{get(handles.energy, 'Value'), 2}/2);

% Store data processing options
arr{12,1} = 'Data Processing';
arr{13,1} = 'Shift by EPOM:';
o = get(handles.epom, 'String');
arr{13,2} = o{get(handles.epom, 'Value')};
arr{14,1} = 'Convert PDI to PDD:';
o = get(handles.pdi, 'String');
arr{14,2} = o{get(handles.pdi, 'Value')};
arr{15,1} = 'Normalize Data:';
o = get(handles.normalize, 'String');
arr{15,2} = o{get(handles.normalize, 'Value')};
arr{16,1} = 'Center Profiles:';
o = get(handles.center, 'String');
arr{16,2} = o{get(handles.center, 'Value')};
arr{17,1} = 'Smooth Data:';
o = get(handles.smooth, 'String');
arr{17,2} = o{get(handles.smooth, 'Value')};
arr{18,1} = 'Convolve Reference:';
o = get(handles.convolve, 'String');
arr{18,2} = o{get(handles.convolve, 'Value')};
arr{18,1} = 'Gamma Criteria:';
arr{18,2} = get(handles.gamma, 'String');
if get(handles.radiobutton3, 'Value') == 0
    arr{18,2} = [arr{18,2}, ' global'];
else
    arr{18,2} = [arr{18,2}, ' local'];
end

% Store statistics
arr{20,1} = 'Statistics';
arr{21,1} = 'IEC X/Y Profiles:';
arr(22:21+size(xy,1),1:size(xy,2)) = xy;
arr{23+size(xy,1),1} = 'Depth Profiles:';
arr(24+size(xy,1):23+size(xy,1)+size(z,1),1:size(z,2)) = z;

% Execute writetable depending on format
Event(['Saving statistics report to ', file]);
if endsWith(file, 'txt', 'IgnoreCase', true)
    writetable(cell2table(arr), file, 'WriteVariableNames', false, ...
        'Delimiter', '\t');
elseif endsWith(file, 'dat', 'IgnoreCase', true)
    writetable(cell2table(arr), file, 'WriteVariableNames', false, ...
        'Delimiter', ';');
elseif endsWith(file, 'csv', 'IgnoreCase', true)
    writetable(cell2table(arr), file, 'WriteVariableNames', false, ...
        'Delimiter', ',');
else
    writetable(cell2table(arr), file, 'WriteVariableNames', false, ...
        'Sheet', 1);
    
    % Also write plot data to spreadsheet
    for i = 1:length(handles.processed)
        Event(sprintf('Writing profile %i processed data to sheet %i', ...
            i, i+1));
        writetable(array2table(handles.processed{i}, 'VariableNames', ...
            {'IECX', 'IECY', 'IECZ', 'Measured', 'Reference', 'Gamma'}), ...
            file, 'Sheet', i+1);
    end
end






