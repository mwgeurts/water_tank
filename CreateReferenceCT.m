% Create Reference CT DICOM Dataset
%
% This script generates a homogeneous phantom CT (0 HU) padded by empty 
% voxels. The DICOM origin is set to the top (anterior) center of the
% image. The image size and dimensions are specified below. The resulting
% DICOM images are saved to the current directory using the format
% ct_###.dcm.
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

% Turn off warnings
warning('off','all')

% Declare image size and resolution (in mm), IEC [X;Z;Y]
size = [651;401;651];
res = [1;1;1];

% Create DICOM info
info.FileMetaInformationVersion = [0;1];
info.TransferSyntaxUID = '1.2.840.10008.1.2';
info.ImplementationClassUID = '1.2.40.0.13.1.1';
info.ImplementationVersionName = 'dcm4che-2.0';
info.SpecificCharacterSet = 'ISO_IR 100';
info.MediaStorageSOPClassUID = '1.2.840.10008.5.1.4.1.1.2';
info.Modality = 'CT';
info.SOPClassUID = info.MediaStorageSOPClassUID;
info.RescaleIntercept = -1024;
info.RescaleSlope = 1;
info.InstanceCreationDate = datestr(now, 'yyyymmdd');
info.InstanceCreationTime = datestr(now, 'HHMMSS');
info.StudyDate = datestr(now, 'yyyymmdd');
info.StudyTime = datestr(now, 'HHMMSS');
info.AcquisitionDate = datestr(now, 'yyyymmdd');
info.AcquisitionTime = datestr(now, 'HHMMSS');
info.ImageType = 'ORIGINAL\PRIMARY\AXIAL';
info.Manufacturer = ['MATLAB ', version];
info.ManufacturerModelName = 'CreateReferenceCT';
info.SoftwareVersion = '1.0';
info.SeriesDescription = 'Uniform Phantom';
info.PatientName = 'Water Phantom';
info.PatientID = datestr(now, 'yyyymmdd');
info.SliceThickness = res(3);
info.StudyInstanceUID = dicomuid;
info.SeriesInstanceUID = dicomuid;
info.FrameOfReferenceUID = dicomuid;
info.PatientPosition = 'HFS';
info.ImageOrientationPatient = [1;0;0;0;1;0];
info.ImagePositionPatient = [   -((size(1)-1)*res(1))/2;
                                -res(2)/2;
                                ((size(3)-1)*res(3))/2];
info.ImagesInAcquisition = size(3);
info.SamplesPerPixel = 1;
info.PhotometricInterpretation = 'MONOCHROME2';
info.Rows = size(2);
info.Columns = size(1);
info.PixelSpacing = [res(1);res(2)];
info.BitsAllocated = 16;
info.BitsStored = 16;
info.HighBit = 15;
info.PixelRepresentation = 0;

% Loop through CT Images
for i = 1:info.ImagesInAcquisition
    
    % Generate unique IDs
    info.MediaStorageSOPInstanceUID = dicomuid;
    info.SOPInstanceUID = info.MediaStorageSOPInstanceUID;
    
    % Set position info for this image
    info.SliceLocation = -((size(3)-1)*res(3))/2 + (i - 1) * res(3);
    info.ImagePositionPatient(3) = -info.SliceLocation;
    info.InstanceNumber = i;
    
    % Write CT image
    dicomwrite(uint16(padarray(ones(size(2)-2, size(1)-2) * 1024, [1 1], ...
        0, 'both')),  sprintf('./ct_%03i.dcm', i), info, 'CompressionMode', ...
        'None', 'CreateMode', 'Create', 'Endian', 'ieee-le');
end