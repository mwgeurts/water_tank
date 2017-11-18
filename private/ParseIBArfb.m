function data = ParseIBArfb(path, names)
% ParseIBArfb extracts water tank profiles from IBA OmniPro 6 RFB binary 
% files. The header contents and profiles are returned as a structure. The
% file format was adapted from IDL code provided by Christoffer Lervåg. It
% has been tested with .rfb files from version 6.6.26, but should work on 
% all RFB files from version 6.3 or later (a version check is included that
% warns users if a prior version is found.
%
% The following variables are required for proper execution:
%   path: string containing the path to the TXT/ASC files
%   names: string or cell array of strings containing the file(s) to be 
%       loaded
%
% The following header fields are returned upon successful completion. The 
% length (vectors) or size(*,1) of each field equals the number of 
% profiles (n).
%   version: 1 x n cell string, OmniPro version
%   machine: 1 x n cell string, treatment system
%   energy: 1 x n cell string, beam energy, ## MV/MeV or ## MV FFF
%   modality: 1 x n cell string, 'Photon' or 'Electron'
%   wtype: 1 x n cell string, wedge type, or 'No Wedge' if none specified
%   wangle: 1 x n vector, wedge angle in degrees, 0 if none specified
%   gangle: 1 x n vector, gantry angle in degrees
%   cangle: 1 x n vector, collimator angle in degrees
%   ssd: 1 x n vector, source to surface distance in cm
%   sad: 1 x n vector, source to axis distance in cm
%   applicator: 1 x n cell string, applicator name, or 'No Applicator'
%   medium: 1 x n cell string, 'Water' or 'Air'
%   clinic: 1 x n cell string, clinic name
%   address: 1 x n cell string, address
%   phone: 1 x n cell string, telephone number
%   email: 1 x n cell string, email address
%   collimator: n x 4 array of collimator settings in cm [X1 X2 Y1 Y2]
%   orientation: 1 x n cell string, gantry specification, such as 
%       '0 deg up, CW'

% The above values are not always specified for each profile, so are copied
% from one profile to the next. The following fields are always profile 
% specific. Where specified, I/C/D refers to Inline/Crossline/Depth.
%   profiletype: 1 x n cell string, 'CProfileCurv' or 'CDepthDoseCurv'
%   measured: 1 x n datenum vector, measured timestamps
%   modified: 1 x n datenum vector, modified timestamps
%   quantity: 1 x n cell string, description of profile signal such as
%       'Relative Dose'
%   radius: 1 x n vector, detector radius in mm
%   calfactor: 1 x n vector, detector calibration factor
%   temperature: 1 x n vector, temperature
%   pressure: 1 x n vector, pressure
%   caldate: 1 x n cell string, calibration date
%   offset: 1 x n vector, detector offset applied in mm
%   detector: 1 x n cell string, detector model
%   dtype: 1 x n cell string, detector type such as 
%       'Ion Chamber (cylindrical)'
%   operator: 1 x n cell string, operator name
%   mcomment: 1 x n cell string, measurement comment
%   mapping: n x 3 cell array, I/C/D orientation mapping
%   meas: 1 x n vector, number of measurements per point
%   speed: 1 x n vector, scan speed in mm/sec
%   origin: n x 3 array, I/C/D origin tank positions in mm
%   isocenter: n x 3 array, isocenter I/C/D position in mm
%   nposition: n x 3 array, normalization I/C/D position in mm
%   nvalue: n x 2 array, field and reference normalization values
%   dark: n x 2 array, field and reference dark current
%   voltage: n x 2 array, field and reference voltage potential in V
%   gain: n x 2 array, field and reference gain values
%   range: n x 2 cell string, field and reference range setting ('HIGH')
%   surface: 1 x n vector, water surface scan position
%   reference: n x 3 array, reference signal min/max/avg
%   sample: 1 x n vector, sample time in msec
%   renorm: 1 x n vector, renormalization value
%   coffset: 1 x n vector, curve offset
%   scomment: 1 x n cell string, setup comment
%   posA: n x 3 array, position A I/C/D value in mm
%   posB: n x 3 array, position A I/C/D value in mm
%   posC: n x 3 array, position A I/C/D value in mm
%   posD: n x 3 array, position A I/C/D value in mm
%   profiles: 1 x n cell array of profiles, where each cell contains a 
%       n x 4 array of IEC X, IEC Y, IEC Z (depth), and signal
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


% If not cell array, cast as one
if ~iscell(names); names = cell({names}); end

% Log start of file load and start timer
if exist('Event', 'file') == 2
    Event(['Loading binary file ', strjoin(names, '\nLoading binary file ')]);
    t = tic;
end

% Initialize return structure
data.profiles = cell(0);

% Initialize counter
i = 0;

% Loop through each file
for f = 1:length(names)

    % Get file size
    info = dir(fullfile(path, names{f}));
    s = info.bytes;
    
    % Open file to provided filename 
    fid = fopen(fullfile(path, names{f}), 'r', 'l');
    
    % Skip first byte
    fseek(fid, 1, 0);
    
    % If file does not start with "Version:", throw an error
    if ~strcmp(fread(fid, 8, '*char')', 'Version:')
        if exist('Event', 'file') == 2
            Event(['The format of file ', names{f}, ...
                ' is unexpected, parsing cannot continue'], 'ERROR');
        else
            error(['The format of file ', names{f}, ...
                ' is unexpected, parsing cannot continue']);
        end
    end
    
    % Store version
    c = cell(0);
    b = fread(fid, 1, 'uint8');
    while b ~= 1
        c{length(c)+1} = char(b);
        b = fread(fid, 1, 'uint8');
    end
    data.version = horzcat(c{:});
    
    % Verify that version is 63 or greater, warn the user
    if str2double(strrep(data.version(1:3), '.', '')) < 63
        if exist('Event', 'file') == 2
            Event(['The RFP version ', data.version, ...
                ' is earlier than 6.3 and may not parse correctly']);
        else
            warning(['The RFP version ', data.version, ...
                ' is earlier than 6.3 and may not parse correctly']);
        end
    end
 
    % Skip ahead 8 bytes, these values are unknown
    % 00 ff ff 01 00 05 00 43
    fseek(fid, 8, 0);

    % Initialize flag for header type
    header = 0;
    
    % Skip over 'CBeam'
    fseek(fid, 4, 0);
    
    % Start while loop to look for header data
    while ~feof(fid) && (ftell(fid) + 100) < s
    
        % Increment counter
        i = i + 1;
        
        % If the header type is full (0)
        if header == 0
            
            % Store machine
            n = fread(fid, 1, 'uint8');
            data.machine{i} = fread(fid, n, '*char')';
    
            % Store energy and type
            fseek(fid, 2, 0);
            data.energy{i} = sprintf('%g', fread(fid, 1, 'float64'));
            switch fread(fid, 1, 'uint8')
                case 0
                    data.energy{i} = [data.energy{i}, ' MV'];
                    data.modality{i} = 'Photon';
                case 1
                    data.energy{i} = [data.energy{i}, ' MeV'];
                    data.modality{i} = 'Electron';
                case 2
                    data.energy{i} = [data.energy{i}, ' MeV'];
                    data.modality{i} = 'Proton';
                case 3
                    data.energy{i} = [data.energy{i}, ' MeV'];
                    data.modality{i} = 'Neutron';
                case 4
                    data.energy{i} = [data.energy{i}, ' MeV'];
                    data.modality{i} = 'Cobalt';
                case 5
                    data.energy{i} = [data.energy{i}, ' MeV'];
                    data.modality{i} = 'Isotope';
            end
            
            % If FFF flag exists, update energy
            if regexp(data.energy{i}, '666')
                data.energy{i} = [regexprep(data.energy{i}, ...
                    '666', ''), ' FFF'];
            end
            
            % Store wedge type and angle
            fseek(fid, 1, 0);
            switch fread(fid, 1, 'uint8')
                case 255
                    data.wtype{i} = 'No Wedge';
                    fseek(fid, 4, 0);
                    data.wangle{i} = 0;
                case 0
                    data.wtype{i} = 'Hard';
                    fseek(fid, 3, 0);
                    data.wangle(i) = fread(fid, 1, 'uint8');
                case 1
                    data.wtype{i} = 'Dynamic';
                    fseek(fid, 3, 0);
                    data.wangle(i) = fread(fid, 1, 'uint8');
                case 2
                    data.wtype{i} = 'Enhanced';
                    fseek(fid, 3, 0);
                    data.wangle(i) = fread(fid, 1, 'uint8');
                case 3
                    data.wtype{i} = 'Virtual';
                    fseek(fid, 3, 0);
                    data.wangle(i) = fread(fid, 1, 'uint8');
                case 4
                    data.wtype{i} = 'Soft';
                    fseek(fid, 3, 0);
                    data.wangle(i) = fread(fid, 1, 'uint8');
            end
            
            % Store gantry angle
            fseek(fid, 3, 0);
            data.gangle(i) = fread(fid, 1, 'uint8');
            
            % Store collimator angle
            fseek(fid, 3, 0);
            data.cangle(i) = fread(fid, 1, 'uint8');
            
            % Store SSD in cm
            fseek(fid, 3, 0);
            data.ssd(i) = fread(fid, 1, 'float64')/10;
            
            % Store SAD in cm
            fseek(fid, 2, 0);
            data.sad(i) = fread(fid, 1, 'float64')/10;
            
            % Store applicator
            n = fread(fid, 1, 'uint8');
            data.applicator{i} = fread(fid, n, '*char')';
            
            % Store medium
            fseek(fid, 1, 0);
            switch fread(fid, 1, 'uint8')
                case 0
                    data.medium{i} = 'Air';
                case 1
                    data.medium{i} = 'Water';
                case 2
                    data.medium{i} = 'Film';
            end
            
            % Store clinic
            n = fread(fid, 1, 'uint8');
            data.clinic{i} = fread(fid, n, '*char')';
            
            % Store address
            n = fread(fid, 1, 'uint8');
            data.address{i} = fread(fid, n, '*char')';
            
            % Store phone
            n = fread(fid, 1, 'uint8');
            data.phone{i} = fread(fid, n, '*char')';
            
            % Store email
            n = fread(fid, 1, 'uint8');
            data.email{i} = fread(fid, n, '*char')';
            
            % Store inline field size
            fseek(fid, 2, 0);
            data.collimator(i,1) = fread(fid, 1, 'float64')/10;
            fseek(fid, 2, 0);
            data.collimator(i,2) = fread(fid, 1, 'float64')/10;
            
            % Store crossline field size
            fseek(fid, 2, 0);
            data.collimator(i,3) = fread(fid, 1, 'float64')/10;
            fseek(fid, 2, 0);
            data.collimator(i,4) = fread(fid, 1, 'float64')/10;
            
            % Store gantry orientation
            switch fread(fid, 1, 'uint8')
                case 0
                    data.orientation{i} = '0 deg up, CW';
                case 1
                    data.orientation{i} = '0 deg up, CCW';
                case 2
                    data.orientation{i} = '180 deg up, CW';
                case 3
                    data.orientation{i} = '180 deg up, CCW';
            end

            % Jump to profile type
            b = fread(fid, 1, 'uint8');
            while (b == 0)
                b = fread(fid, 1, 'uint8');
            end
            fseek(fid, 1, 0);
        else
            
            % Otherwise, copy header from previous value
            data.machine{i} = data.machine{i-1};
            data.energy{i} = data.energy{i-1};
            data.modality{i} = data.modality{i-1};
            data.wtype{i} = data.wtype{i-1};
            data.gangle(i) = data.gangle(i-1);
            data.cangle(i) = data.cangle(i-1);
            data.ssd(i) = data.ssd(i-1);
            data.sad(i) = data.sad(i-1);
            data.applicator{i} = data.applicator{i-1};
            data.medium{i} = data.medium{i-1};
            data.clinic{i} = data.clinic{i-1};
            data.address{i} = data.address{i-1};
            data.phone{i} = data.phone{i-1};
            data.email{i} = data.email{i-1};
            data.collimator(i,:) = data.collimator(i-1,:);
            data.orientation{i} = data.orientation{i-1}; 
        end
        
        % If header flag is full or reduced
        if header == 0 || header == 1
            
            % If profile type is specified
            if isequal(fread(fid, 4, 'uint8'), [255;255;1;0])
                n = fread(fid, 1, 'uint8');
                data.profiletype{i} = ...
                    regexprep(fread(fid, n, '*char')', '\W', '');
            
            % If not specified, copy from previous
            else
                data.profiletype{i} = data.profiletype{i-1};
                fseek(fid, -5, 0);
            end
            
            % Store measurement and modification timestamps
            fseek(fid, 1, 0);
            data.measured(i) = fread(fid, 1, 'long')/86400 + ...
                datenum(1970,1,1,0,0,0);
            data.modified(i) = fread(fid, 1, 'long')/86400 + ...
                datenum(1970,1,1,0,0,0);
            
            % Store signal quantity
            switch fread(fid, 1, 'uint8')
                case 1
                    data.quantity{i} = 'Relative Optical Density';
                case 2
                    data.quantity{i} = 'Relative Dose';
                case 3
                    data.quantity{i} = 'Relative Ionization';
                case 4  
                    data.quantity{i} = 'Absolute Dose';
                case 5  
                    data.quantity{i} = 'Charge';
            end
            
            % Store the detector radius
            data.radius(i) = fread(fid, 1, 'float64');
            
            % Store calibration factor
            data.calfactor(i) = fread(fid, 1, 'float64');
            
            % Store temperature
            data.temperature(i) = fread(fid, 1, 'float64');
            
            % Store pressure
            data.pressure(i) = fread(fid, 1, 'float64');
            
            % Store calibration date
            n = fread(fid, 1, 'uint8');
            data.caldate{i} = fread(fid, n, '*char')';
            
            % Store offset
            data.offset(i) = fread(fid, 1, 'float64');
            
            % Store detector
            n = fread(fid, 1, 'uint8');
            data.detector{i} = fread(fid, n, '*char')';
            
            % Store detector type
            switch fread(fid, 1, 'uint16')
                case 1
                    data.dtype{i} = 'Single Diode';
                case 2
                    data.dtype{i} = 'LDA-11';
                case 3
                    data.dtype{i} = 'LDA-25';
                case 4
                    data.dtype{i} = 'Ion Chamber (cylindrical)';
                case 5
                    data.dtype{i} = 'Ion Chamber (plane parallel)';
                case 6
                    data.dtype{i} = 'Stereotactic';
                case 7
                    data.dtype{i} = 'Film';
                case 8
                    data.dtype{i} = 'CA24';
                case 9
                    data.dtype{i} = 'BIS-2G';
            end
            
            % Store operator
            n = fread(fid, 1, 'uint8');
            data.operator{i} = fread(fid, n, '*char')';
            
            % Store comment
            n = fread(fid, 1, 'uint8');
            data.mcomment{i} = fread(fid, n, '*char')';
            
            % Store mapping
            m = fread(fid, 3, 'int16');
            for j = 1:3
                switch m(j)
                    case -3
                        data.mapping{i,j} = '-z';
                    case -2
                        data.mapping{i,j} = '-y';
                    case -1
                        data.mapping{i,j} = '-x';
                    case 1
                        data.mapping{i,j} = 'x';
                    case 2
                        data.mapping{i,j} = 'y';
                    case 3
                        data.mapping{i,j} = 'z';
                end
            end
            
            % Store measurements per point
            fseek(fid, 2, 0);
            data.meas(i) = fread(fid, 1, 'int16');
            
            % Store scan speed
            data.speed(i) = fread(fid, 1, 'float64');
            
            % Store origin
            fseek(fid, 4, 0);
            data.origin(i,1:3) = fread(fid, 3, 'int16') * 0.1;
            
            % Store isocenter
            data.isocenter(i,1:3) = fread(fid, 3, 'float64');
            
            % Store normalization position
            data.nposition(i,1:3) = fread(fid, 3, 'float64');
            
            % Store normalization values
            data.nvalue(i,1:2) = fread(fid, 2, 'float64');
            
            % Store dark current values
            data.dark(i,1:2) = fread(fid, 2, 'float64');
            
            % Store voltage values
            data.voltage(i,1:2) = fread(fid, 2, 'float64');
            
            % Store gain values
            data.gain(i,1:2) = fread(fid, 2, 'int16');
            
            % Store range strings
            n = fread(fid, 1, 'uint8');
            data.range{i,1} = fread(fid, n, '*char')';
            n = fread(fid, 1, 'uint8');
            data.range{i,2} = fread(fid, n, '*char')';
            
            % Store water surface
            data.surface(i) = fread(fid, 1, 'float64');
            
            % Store reference min/max/avg
            fseek(fid, 4, 0);
            data.reference(i,1:3) = fread(fid, 3, 'float64');
            
            % Store sampling time
            fseek(fid, 8, 0);
            data.sample(i) = fread(fid, 1, 'uint16');
            
            % Store renormalization value
            data.renorm(i) = fread(fid, 1, 'float64');
            
            % Store curveoffset value
            data.coffset(i) = fread(fid, 1, 'float64');
            
            % Store setup comment
            n = fread(fid, 1, 'uint8');
            data.scomment{i} = fread(fid, n, '*char')';
            
            % Store positions A, B, C, and D
            fseek(fid, 2, 0);
            data.posA(i,1:3) = fread(fid, 3, 'float64');
            data.posB(i,1:3) = fread(fid, 3, 'float64');
            data.posC(i,1:3) = fread(fid, 3, 'float64');
            data.posD(i,1:3) = fread(fid, 3, 'float64');
            
            % Store water offset
            data.offset(i) = fread(fid, 1, 'float64');
            
            % Store start and end scan positions
            fseek(fid, 2, 0);
            data.start(i,1:3) =  fread(fid, 3, 'float64');
            data.end(i,1:3) =  fread(fid, 3, 'float64');
            
            % Read in number of data points
            n = fread(fid,1,'uint16');
            
            % Initialize profile array
            data.profiles{i} = zeros(n, 4);
            
            % Loop through data points
            for j = 1:n

                % Read values
                pts = fread(fid, 2, 'float64');
                
                % If the IEC X position is changing, store as X profile
                if data.start(i,1) ~= data.end(i,1)
                    data.profiles{i}(j,:) = [pts(1), ...
                        data.start(i,2), data.start(i,3), pts(2)];
                
                % Otherwise, if IEC Y is changing
                elseif data.start(i,2) ~= data.end(i,2)
                    data.profiles{i}(j,:) = [data.start(i,1), pts(1), ...
                        data.start(i,3), pts(2)];
                    
                % Otherwise, if IEC Z is changing
                elseif data.start(i,3) ~= data.end(i,3)
                    data.profiles{i}(j,:) = [data.start(i,1), ...
                        data.start(i,2), pts(1), pts(2)];
                end
            end
            
            % Skip over any null bytes between this and next header
            b = fread(fid, 1, 'uint8');
            while ~feof(fid) && b ~= 128 && b ~= 255
                b = fread(fid, 1, 'uint8');
            end
            
            % If next two characters are hex 01 80, keep header type at 0.
            % Otherwise, if they are 03 80, set header type to 1.
            fseek(fid, -2, 0);
            b = fread(fid, 2, 'uint8');
            if isequal(b, [1;128])
                header = 0;
            elseif isequal(b, [3;128])
                header = 1;
            elseif b(2) == 255
                header = 1;
                fseek(fid, -1, 0);
            end
        end
    end
    
    % Close file handle
    fclose(fid);
end

% Clear temporary variables
clear b c f fid header info j m n pts s;

% Loop through each profile
for i = 1:length(data.profiles)

    % If depth is negative (given by a negative mean value), flip
    % the dimension so that depths are down
    if mean(data.profiles{i}(:,3)) < 0
        
        % Log event
        if exist('Event', 'file') == 2
            Event('Flipping IEC Z axis (positive down)');
        end
        
        % Store negative value
        data.profiles{i}(:,3) = -data.profiles{i}(:,3);
    end
    
    % If depth changes (i.e. PDD), sort descending
    if data.profiles{i}(2,3) ~= data.profiles{i}(1,3)
        
        % Log event
        if exist('Event', 'file') == 2
            Event('Sorting depth profile by descending IEC Z value');
        end
        
        % Store sorted table in descending order
        data.profiles{i} = flip(sortrows(data.profiles{i}, 3), 1);
    end
end

% Log event
if exist('Event', 'file') == 2
    Event(sprintf(['%i data profiles extracted successfully in ', ...
        '%0.3f seconds'], length(data.profiles), toc(t)));
end

% Clear temporary variables
clear i t;