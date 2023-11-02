function profile = ExtractRefProfile(profile, file, origin)
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

% Persistently store DICOM data
persistent storedfile info ref meshx meshy meshz;

% Check if MATLAB can find dicominfo (Image Processing Toolbox)
if exist('dicominfo', 'file') ~= 2
    
    % If not, throw an error
    if exist('Event', 'file') == 2
        Event(['The Image Processing Toolbox cannot be found and is ', ...
            'required by ExtractRefProfile().'], 'ERROR');
    else
        error(['The Image Processing Toolbox cannot be found and is ', ...
            'required by ExtractRefProfile().']);
    end
end

% Log start of reference file read and start timer
if exist('Event', 'file') == 2
    t = tic;
    Event(['Parsing reference dose file ', file]);
end

% If storedfile is not set, or differs from the current file
if exist('storedfile', 'var') == 0 || ~strcmp(storedfile, file)

    % Load in the reference dose header
    info = dicominfo(file);

    % Read in DICOM dose  
    ref = permute(single(squeeze(dicomread(file))), [2 1 3]) * ...
        info.DoseGridScaling;

    % Generate meshgrid from DICOM header
    [meshx, meshy, meshz] = meshgrid(...
        info.ImagePositionPatient(2) + (0:single(info.Rows)-1) * ...
        info.PixelSpacing(1) + origin(3), ...
        info.ImagePositionPatient(1) + (0:single(info.Columns)-1) * ...
        info.PixelSpacing(2) - origin(1), ...
        info.ImagePositionPatient(3) + ...
        single(info.GridFrameOffsetVector) - origin(2));

    % Normalize data to Dmax along CAX
    ref = ref ./ max(interp3(meshx, meshy, meshz, ref, ...
        info.ImagePositionPatient(2) + (0:single(info.Rows)-1) * ...
        info.PixelSpacing(1), single(zeros(1, info.Rows)), ...
        single(zeros(1, info.Rows)), '*linear', 0));
    
    % Persistently store name of current file
    storedfile = file;
end

% Loop through each profile
for i = 1:length(profile)
    
    % Attempt to use GPU
%     try
%         
%         % Clear and initialize GPU memory.  If CUDA is not enabled, or if the
%         % Parallel Computing Toolbox is not installed, this will error, and the
%         % function will automatically revert to CPU computation via the catch
%         % statement
%         gpuDevice(1);
%     
%         % Interpolate reference profile to same coordinates as profile
%         profile{i} = horzcat(profile{i}, gather(interp3(gpuArray(meshx), ...
%             gpuArray(meshy), gpuArray(meshz), gpuArray(ref), ...
%             gpuArray(profile{i}(:,3)), gpuArray(profile{i}(:,1)), ...
%             gpuArray(profile{i}(:,2)), 'linear', 0)));
%      
%     % If GPU fails, revert to CPU computation
%     catch
        
        % Interpolate reference profile to same coordinates as profile
        profile{i} = horzcat(profile{i}, interp3(meshx, meshy, meshz, ref, ...
            profile{i}(:,3), profile{i}(:,1), profile{i}(:,2), '*linear', 0));
%     end
end

% Log completion
if exist('Event', 'file') == 2
    Event(sprintf(['%i reference profiles extracted successfully in ', ...
        '%0.3f seconds'], i, toc(t)));
end

% Clear temporary variables
clear i t;