function detectors = ParseDetectorFile(filename)
% ParseDetectorFile is executed by WaterTankAnalysis to open the detector 
% file and retrieve the detector names and diameters. The filename is 
% passed to this function, and a cell array of detectors and diameters (in
% mm, as strings) is returned.
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

% Log event
Event(['Opening file handle to ', filename]);

% Open file handle to config.txt file
fid = fopen(filename, 'r');

% Verify that file handle is valid
if fid < 3
    
    % If not, throw an error
    Event(['The ', filename, ' file could not be opened. Verify that this ', ...
        'file exists in the working directory. See documentation for ', ...
        'more information.'], 'ERROR');
end

% Scan config file contents
c = textscan(fid, '%s', 'Delimiter', '=', 'CommentStyle', '%');

% Close file handle
fclose(fid);

% Initialize return array
detectors = cell(length(c{1})/2, 2);

% Loop through textscan array, separating key/value pairs into array
for i = 1:2:length(c{1})
    detectors{(i+1)/2, 1} = strtrim(c{1}{i});
    detectors{(i+1)/2, 2} = str2double(strtrim(c{1}{i+1}));
end

% Clear temporary variables
clear c i fid;

% Log completion
Event(['Read ', filename, ' to end of file']);