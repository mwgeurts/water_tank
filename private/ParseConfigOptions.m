function config = ParseConfigOptions(filename)
% ParseConfigOptions is executed by WaterTankAnalysis to open the config 
% file and update the application settings. The configuration filename is 
% passed to this function, and a config structure containing the loaded 
% configuration options is returned.
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

% Loop through textscan array, separating key/value pairs into array
for i = 1:2:length(c{1})
    config.(strtrim(c{1}{i})) = strtrim(c{1}{i+1});
end

% Clear temporary variables
clear c i fid;

% Log completion
Event(['Read ', filename, ' to end of file']);

% Default folder path when selecting input files
if strcmpi(config.DEFAULT_PATH, 'userpath')
    config.DEFAULT_PATH = userpath;
end
Event(['Default file path set to ', config.DEFAULT_PATH]);

% Parse default reference options
config.DEFAULT_MACHINE = str2double(config.DEFAULT_MACHINE);
config.DEFAULT_ENERGY = str2double(config.DEFAULT_ENERGY);
config.DEFAULT_SSD = str2double(config.DEFAULT_SSD);
config.DEFAULT_FIELDSIZE = str2double(config.DEFAULT_FIELDSIZE);

% Parse default UI options
config.DEFAULT_EPOM = str2double(config.DEFAULT_EPOM);
config.DEFAULT_PDI = str2double(config.DEFAULT_PDI);
config.DEFAULT_NORMALIZE = str2double(config.DEFAULT_NORMALIZE);
config.DEFAULT_SMOOTH = str2double(config.DEFAULT_SMOOTH);
config.DEFAULT_CENTER = str2double(config.DEFAULT_CENTER);
config.DEFAULT_CONVOLVE = str2double(config.DEFAULT_CONVOLVE);
config.DEFAULT_GAMMALOCAL = str2double(config.DEFAULT_GAMMALOCAL);

% Parse stat options
config.FWXM_STAT = str2double(config.FWXM_STAT);

% Parse measurement options
config.FLIPXYAXES = str2double(config.FLIPXYAXES);

% Parse origin values as doubles
config.REFERENCE_ORIGINX = str2double(config.REFERENCE_ORIGINX);
config.REFERENCE_ORIGINY = str2double(config.REFERENCE_ORIGINY);
config.REFERENCE_ORIGINZ = str2double(config.REFERENCE_ORIGINZ);
config.ASK_REFERENCE_ORIGIN = str2double(config.ASK_REFERENCE_ORIGIN);

% Parse Detector Rcav options
config.ASK_RCAV = str2double(config.ASK_RCAV);
config.DEFAULT_DETECTOR = str2double(config.DEFAULT_DETECTOR);

% Parse smoothing options
config.SMOOTH_SPAN = str2double(config.SMOOTH_SPAN);
config.SGOLAY_DEGREE = str2double(config.SGOLAY_DEGREE);

% Parse header/file matching flags
config.MATCH_FILENAME = str2double(config.MATCH_FILENAME);
config.MATCH_HEADER = str2double(config.MATCH_HEADER);
config.LEVENSHTEIN_THRESH = str2double(config.LEVENSHTEIN_THRESH);

% Parse reference processing flags
config.SMOOTH_REFERENCE = str2double(config.CENTER_REFERENCE);
config.CENTER_REFERENCE = str2double(config.CENTER_REFERENCE);

% Parse compression options
config.COMPRESS_REFERENCE = str2double(config.COMPRESS_REFERENCE);
config.MASK_REFERENCE = str2double(config.MASK_REFERENCE);
config.ALLOW_DIAGONAL = str2double(config.ALLOW_DIAGONAL);

% Parse PDD model options
config.BUILDUP_DAMPER = str2double(config.BUILDUP_DAMPER);
config.LEVENBERG_ITERS = str2double(config.LEVENBERG_ITERS);
config.RMSE_FIT_THRESH = str2double(config.RMSE_FIT_THRESH);
