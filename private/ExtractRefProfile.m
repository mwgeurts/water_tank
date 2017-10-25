function profile = ExtractRefProfile(profile, file, iso)
% ExtractRefProfile reads in a DICOM dose file specified by file and
% extracts the corresponding line profile to match each profile in the cell
% array provided by profile.
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

% Log start of reference file read
Event(['Parsing reference dose file ', file]);
    
% Load in the reference dose header
info = dicominfo(file);

% Read in DICOM dose  
ref = permute(single(squeeze(dicomread(file))), [2 1 3]) * ...
    info.DoseGridScaling;

% Generate meshgrid from DICOM header
[meshx, meshy, meshz] = meshgrid(...
    info.ImagePositionPatient(2) + (0:single(info.Rows)-1) * ...
    info.PixelSpacing(2) + iso(3), ...
    info.ImagePositionPatient(1) + (0:single(info.Columns)-1) * ...
    info.PixelSpacing(1) - iso(1), ...
    info.ImagePositionPatient(3) + ...
    single(info.GridFrameOffsetVector) - iso(2));

% Loop through each profile
for i = 1:length(profile)
    
    % Interpolate reference profile to same coordinates as profile
    profile{i} = horzcat(profile{i}, interp3(meshx, meshy, meshz, ref, ...
        profile{i}(:,3), profile{i}(:,1), profile{i}(:,2), 'linear', 0) / ...
        max(max(max(ref))));
end

% Clear temporary variables
clear i info ref meshx meshy meshz;