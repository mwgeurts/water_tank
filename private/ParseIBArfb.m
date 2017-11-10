function data = ParseIBArfb(path, names)



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
    
        % If the header type is full (0)
        if header == 0
            
            % Store machine
            n = fread(fid, 1, 'uint8');
            data.machine = fread(fid, n, '*char')';
    
            % Store energy and type
            fseek(fid, 2, 0);
            data.energy = sprintf('%g', fread(fid, 1, 'float64'));
            switch fread(fid, 1, 'uint8')
                case 0
                    data.energy = [data.energy, ' MV'];
                    data.modality = 'Photon';
                case 1
                    data.energy = [data.energy, ' MeV'];
                    data.modality = 'Electron';
                case 2
                    data.energy = [data.energy, ' MeV'];
                    data.modality = 'Proton';
                case 3
                    data.energy = [data.energy, ' MeV'];
                    data.modality = 'Neutron';
                case 4
                    data.energy = [data.energy, ' MeV'];
                    data.modality = 'Cobalt';
                case 5
                    data.energy = [data.energy, ' MeV'];
                    data.modality = 'Isotope';
            end
            
            % If FFF flag exists, update energy
            if regexp(data.energy, '666')
                data.energy = [regexprep(data.energy, '666', ''), ' FFF'];
            end
            
            % Store wedge type and angle
            fseek(fid, 1, 0);
            switch fread(fid, 1, 'uint8')
                case 255
                    data.wtype = 'No Wedge';
                    fseek(fid, 4, 0);
                    data.wangle = 0;
                case 0
                    data.wtype = 'Hard';
                    fseek(fid, 3, 0);
                    data.wangle = fread(fid, 1, 'uint8');
                case 1
                    data.wtype = 'Dynamic';
                    fseek(fid, 3, 0);
                    data.wangle = fread(fid, 1, 'uint8');
                case 2
                    data.wtype = 'Enhanced';
                    fseek(fid, 3, 0);
                    data.wangle = fread(fid, 1, 'uint8');
                case 3
                    data.wtype = 'Virtual';
                    fseek(fid, 3, 0);
                    data.wangle = fread(fid, 1, 'uint8');
                case 4
                    data.wtype = 'Soft';
                    fseek(fid, 3, 0);
                    data.wangle = fread(fid, 1, 'uint8');
            end
            
            % Store gantry angle
            fseek(fid, 3, 0);
            data.gangle = fread(fid, 1, 'uint8');
            
            % Store collimator angle
            fseek(fid, 3, 0);
            data.cangle = fread(fid, 1, 'uint8');
            
            % Store SSD in cm
            fseek(fid, 3, 0);
            data.ssd = fread(fid, 1, 'float64')/10;
            
            % Store SAD in cm
            fseek(fid, 2, 0);
            data.sad = fread(fid, 1, 'float64')/10;
            
            % Store applicator
            n = fread(fid, 1, 'uint8');
            data.applicator = fread(fid, n, '*char')';
            
            % Store medium
            fseek(fid, 1, 0);
            switch fread(fid, 1, 'uint8')
                case 0
                    data.medium = 'Air';
                case 1
                    data.medium = 'Water';
                case 2
                    data.medium = 'Film';
            end
            
            % Store clinic
            n = fread(fid, 1, 'uint8');
            data.clinic = fread(fid, n, '*char')';
            
            % Store address
            n = fread(fid, 1, 'uint8');
            data.address = fread(fid, n, '*char')';
            
            % Store phone
            n = fread(fid, 1, 'uint8');
            data.phone = fread(fid, n, '*char')';
            
            % Store email
            n = fread(fid, 1, 'uint8');
            data.email = fread(fid, n, '*char')';
            
            % Store inline field size
            fseek(fid, 2, 0);
            data.collimator(1) = fread(fid, 1, 'float64');
            fseek(fid, 2, 0);
            data.collimator(2) = fread(fid, 1, 'float64');
            
            % Store crossline field size
            fseek(fid, 2, 0);
            data.collimator(3) = fread(fid, 1, 'float64');
            fseek(fid, 2, 0);
            data.collimator(4) = fread(fid, 1, 'float64');
            
            % Store gantry orientation
            switch fread(fid, 1, 'uint8')
                case 0
                    data.orientation = '0 deg up, CW';
                case 1
                    data.orientation = '0 deg up, CCW';
                case 2
                    data.orientation = '180 deg up, CW';
                case 3
                    data.orientation = '180 deg up, CCW';
            end

            % Jump to profile type
            b = fread(fid, 1, 'uint8');
            while (b == 0)
                b = fread(fid, 1, 'uint8');
            end
            fseek(fid, 1, 0);
        end
        
        % Increment counter
        i = i + 1;
        
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
                    data.detectortype{i} = 'Single Diode';
                case 2
                    data.detectortype{i} = 'LDA-11';
                case 3
                    data.detectortype{i} = 'LDA-25';
                case 4
                    data.detectortype{i} = 'Ion Chamber (cylindrical)';
                case 5
                    data.detectortype{i} = 'Ion Chamber (plane parallel)';
                case 6
                    data.detectortype{i} = 'Stereotactic';
                case 7
                    data.detectortype{i} = 'Film';
                case 8
                    data.detectortype{i} = 'CA24';
                case 9
                    data.detectortype{i} = 'BIS-2G';
            end
            
            % Store operator
            n = fread(fid, 1, 'uint8');
            data.operator{i} = fread(fid, n, '*char')';
            
            % Store comment
            n = fread(fid, 1, 'uint8');
            data.meascomment{i} = fread(fid, n, '*char')';
            
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
            data.measurements(i) = fread(fid, 1, 'int16');
            
            % Store scan speed
            data.scanspeed(i) = fread(fid, 1, 'float64');
            
            % Store origin
            fseek(fid, 4, 0);
            data.origin(i,1:3) = fread(fid, 3, 'int16') * 0.1;
            
            % Store isocenter
            data.isocenter(i,1:3) = fread(fid, 3, 'float64');
            
            % Store normalization position
            data.normposition(i,1:3) = fread(fid, 3, 'float64');
            
            % Store normalization values
            data.normalization(i,1:2) = fread(fid, 2, 'float64');
            
            % Store dark current values
            data.darkcurrent(i,1:2) = fread(fid, 2, 'float64');
            
            % Store voltage values
            data.voltage(i,1:2) = fread(fid, 2, 'float64');
            
            % Store gain values
            data.gain(i,1:2) = fread(fid, 2, 'int16');
            
            % Store range strings
            n = fread(fid, 1, 'uint8');
            data.range{i}{1} = fread(fid, n, '*char')';
            n = fread(fid, 1, 'uint8');
            data.range{i}{2} = fread(fid, n, '*char')';
            
            % Store water surface
            data.surface(i) = fread(fid, 1, 'float64');
            
            % Store reference min/max/avg
            fseek(fid, 4, 0);
            data.reference(i,1:3) = fread(fid, 3, 'float64');
            
            % Store sampling time
            fseek(fid, 8, 0);
            data.sampletime(i) = fread(fid, 1, 'uint16');
            
            % Store renormalization value
            data.renormalization(i) = fread(fid, 1, 'float64');
            
            % Store curveoffset value
            data.curveoffset(i) = fread(fid, 1, 'float64');
            
            % Store setup comment
            n = fread(fid, 1, 'uint8');
            data.setupcomment{i} = fread(fid, n, '*char')';
            
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