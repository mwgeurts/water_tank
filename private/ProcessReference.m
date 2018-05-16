function ProcessReference(varargin)
% ProcessReference requests the user to select a directory then recursively 
% scans it for DICOM RT PLAN and DOSE files. Once found, this function will 
% copy them, optionally with RLE (lossless) compression, to the destination 
% folder. The function can also optionally remove DICOM RT DOSE data away
% from the IEC and/or diagonal axes. Since scan data is not commonly 
% acquired except along other axes, this can significantly reduce the file 
% size (in practice by a factor of 15 to 20).
%
% This function may optionally be called with an input argument structure 
% containing the following fields:
%
%   REFERENCE_PATH: string containing the path to save the processed files
%   COMPRESS_REFERENCE: boolean indicating whether to compress data
%   MASK_REFERENCE: boolean indicating whether to remove data points away
%       from the IEC axes (and diagonals, if set below)
%   ALLOW_DIAGONAL: boolean indicating whether to include diagonal profiles
%       in masked data
%   REFERENCE_ORIGINX: DICOM IEC X position of isocenter, in mm
%   REFERENCE_ORIGINY: DICOM IEC Y position of isocenter, in mm
%   REFERENCE_ORIGINZ: DICOM IEC Z position of isocenter, in mm
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

% Check if MATLAB can find dicominfo (Image Processing Toolbox)
if exist('dicominfo', 'file') ~= 2
    
    % If not, throw an error
    if exist('Event', 'file') == 2
        Event(['The Image Processing Toolbox cannot be found and is ', ...
            'required by ProcessReference().'], 'ERROR');
    else
        error(['The Image Processing Toolbox cannot be found and is ', ...
            'required by ProcessReference().']);
    end
end

% Prompt user to select directory to scan
source = uigetdir('', ...
    'Select directory to scan for water tank reference RT DOSE files');

% If configuration options were provided
if nargin == 1 && isfield(varargin{1}, 'REFERENCE_PATH')
    
    % Store provided compression flag
    compress = varargin{1}.COMPRESS_REFERENCE;
    maskaxis = varargin{1}.MASK_REFERENCE;
    diag = varargin{1}.ALLOW_DIAGONAL;
    
    % Store reference directory
    dest = config.REFERENCE_PATH;
    
    % Store provided origin
    origin = [config.REFERENCE_ORIGINX config.REFERENCE_ORIGINY ...
        config.REFERENCE_ORIGINZ];

% Otherwise, declare default options
else
    
    % Prompt user to select destination directory
    dest = uigetdir('', ...
        'Select destination folder to store processed files');

    % Set default compression options
    compress = 1;
    maskaxis = 1;
    diag = 1;
    
    % Set default origin
    origin = [0 0 0];
end

% Log start and start timer
if exist('Event', 'file') == 2
    Event(['Scanning ', source, ' for DICOM RT PLAN and DOSE files']);
    t = tic;
end

% Retrieve folder contents
list = dir(source);

% Initalize cell array of RTDOSE and RTPLAN files
dose = cell(0);
plan = cell(0);

% Loop through folder contents
for i = 1:length(list)
    
    % Skip . and ..
    if strcmp(list(i).name, '.') || strcmp(list(i).name, '..')
        continue;
    
    % If this is a subfolder
    elseif list(i).isdir
        
        % Append subdirectory contents onto list
        list = vertcat(list, dir(list(i).name)); %#ok<AGROW>
        
    % Otherwise, if file has a .dcm extension
    elseif regexp(list(i).name, '.dcm$')
        
        % Read in DICOM info
        info = dicominfo(fullfile(source, list(i).name));
        
        % If DICOM is RTDOSE
        if strcmp(info.SOPClassUID, '1.2.840.10008.5.1.4.1.1.481.2')
            
            % Append file onto dose cell array
            dose{size(dose,1)+1,1} = fullfile(source, list(i).name);
            
            % Store instance UID
            dose{size(dose,1),2} = info.SOPInstanceUID;
            
            % Store referenced RTPlanSequence
            dose{size(dose,1),3} = info.ReferencedRTPlanSequence.Item_1...
                .ReferencedSOPInstanceUID;
            
            % Store referenced fraction group
            dose{size(dose,1),4} = info.ReferencedRTPlanSequence.Item_1...
                .ReferencedFractionGroupSequence.Item_1...
                .ReferencedFractionGroupNumber;
            
            % Store referenced beam number
            dose{size(dose,1),5} = info.ReferencedRTPlanSequence.Item_1...
                .ReferencedFractionGroupSequence.Item_1...
                .ReferencedBeamSequence.Item_1.ReferencedBeamNumber;
        
        % Otherwise, if file is RTPLAN
        elseif strcmp(info.SOPClassUID, '1.2.840.10008.5.1.4.1.1.481.5')
            
            % Append file onto plan cell array
            plan{size(plan,1)+1,1} = fullfile(source, list(i).name);
            
            % Store instance UID
            plan{size(plan,1),2} = info.SOPInstanceUID;
            
            % Store machine name
            plan{size(plan,1),3} = info.BeamSequence.Item_1...
                .TreatmentMachineName;
            
            % Store beam names
            for j = 1:length(fieldnames(info.BeamSequence))
                 plan{size(plan,1),4}{j} = info.BeamSequence...
                     .(sprintf('Item_%i', j)).BeamName;
            end
            
            % Store isocenter and SSD
        end
    end
end

% Initialize empty info structure
prev = struct('Rows', 0, 'Columns', 0, 'PixelSpacing', [0 0], ...
    'ImagePositionPatient', [0 0 0], 'GridFrameOffsetVector', 0);

% Loop through each dose file
for i = 1:size(dose, 1)
   
    % Initialize machine and name
    machine = '';
    name = '';
    
    % Loop through plans
    for j = 1:size(plan, 1)
        
        % If this plan matches the UID
        if strcmp(dose{i,3}, plan{j,2})
        
            % Store machine and name
            machine = plan{j,3};
            name = plan{j,4}{dose{i,5}};
            break;
        end
    end
    
    % If a name was not found, error
    if isempty(name)
        if exist('Event', 'file') == 2
            Event(['The RTDOSE file ', dose{i,1}, ...
                ' does not have a matching RT PLAN in ', source], 'ERROR');
        else
            error(['The RTDOSE file ', dose{i,1}, ...
                ' does not have a matching RT PLAN in ', source]);
        end
    end
    
    % Parse energy, SSD, and field size
    parts = strsplit(name, '_');
    
    % If subfolders do not exist in destination folder, create them
    if ~isdir(fullfile(dest, machine))
        mkdir(fullfile(dest, machine));
    end
    if ~isdir(fullfile(dest, machine, parts{1}))
        mkdir(fullfile(dest, machine, parts{1}));
    end
    if ~isdir(fullfile(dest, machine, parts{1}, parts{2}))
        mkdir(fullfile(dest, machine, parts{1}, parts{2}));
    end
    
    % If compression is enabled
    if compress == 1
        
        % Read in DICOM header
        info = dicominfo(dose{i,1});
        
        % Read in DICOM dose
        rtdose = squeeze(dicomread(info));
        
        % If info differs from previous value
        if maskaxis == 1 && (~isequal(prev.Rows, info.Rows) || ...
                ~isequal(prev.Columns, info.Columns) || ...
                ~isequal(prev.PixelSpacing, info.PixelSpacing) || ...
                ~isequal(prev.ImagePositionPatient, ...
                info.ImagePositionPatient) || ...
                ~isequal(prev.GridFrameOffsetVector, ...
                info.GridFrameOffsetVector))
        
            % Calculate position meshgrids
            [meshx, meshy, meshz] = meshgrid(...
                info.ImagePositionPatient(2) + (0:single(info.Rows)-1) * ...
                info.PixelSpacing(1) + origin(3), ...
                info.ImagePositionPatient(1) + (0:single(info.Columns)-1) * ...
                info.PixelSpacing(2) - origin(1), ...
                info.ImagePositionPatient(3) + ...
                single(info.GridFrameOffsetVector) - origin(2));
            
            % If diagonal profiles are allowed
            if diag == 1

                % Calculate mask for all values greater than 10 mm from an 
                % IEC orthogonal axis or along an X/Y diagonal
                mask = uint16(min((abs(meshx) < 10) + (abs(meshy) < 10) + ...
                    (abs(meshz) < 10) + (abs(meshx - meshy) < 10), 1));
            else
               
                % Calculate mask for all values greater than 10 mm from an 
                % IEC orthogonal axis
                mask = uint16(min((abs(meshx) < 10) + (abs(meshy) < 10) + ...
                    (abs(meshz) < 10), 1));
            end
            
            % Store info
            prev = info;
        else
            
           % Otherwise do not mask data
           mask = uint16(ones(size(rtdose)));
        end
        
        % Write masked DICOM dose to the destination directory
        s = dicomwrite(reshape(rtdose .* mask, info.Rows, info.Columns, ...
            1, []), fullfile(dest, machine, parts{1}, parts{2}, ...
            [parts{3}, '.dcm']), info, 'CompressionMode', 'RLE', ...
            'CreateMode', 'Copy', 'MultiframeSingleFile', true);
   
        % If dicomwrite failed, throw a warning
        if ~isempty(s) && exist('Event', 'file') == 2
            Event(['A warning occurred writing the file to ', ...
                fullfile(dest, machine, parts{1}, parts{2}, ...
                [parts{3}, '.dcm'])], 'WARN');
        elseif ~isempty(s)
            warning(['A warning occurred writing the file to ', ...
                fullfile(dest, machine, parts{1}, parts{2}, ...
                [parts{3}, '.dcm'])]);
        end
        
    % Otherwise, if compression is disabled
    else
        
        % Attempt to copy the reference file
        [s, msg, ~] = copyfile(dose{i,1}, fullfile(dest, machine, ...
            parts{1}, parts{2}, [parts{3}, '.dcm']));
        
        % If copy failed, throw a warning
        if s == 0 && exist('Event', 'file') == 2
            Event(msg, 'WARN');
        elseif s == 0
            warning(msg);
        end
    end
end

% Log completion
if exist('Event', 'file') == 2
    Event(sprintf(['%i RT DOSE files successfully saved to %s in %0.3f ', ...
        'seconds'], size(dose,1), dest, toc(t)));
end

% Clear temporary variables
clear i j s t list dose plan source dest info prev name rtdose mask meshx ...
    meshy meshz msg parts iso compress maskaxis;
