function data = ParseProfile(varargin)
% ParseProfile extracts a water tank file into a cell array of individual 
% profiles. If called with no inputs, it will return a list of available
% formats that can be parsed. If called with inputs, the first must be the
% name of the file while the second is an integer corresponding to the
% format. It will return a structure containing the following fields (at
% minimum, some file types will include additional fields):
%
%   profiles:   cell array of 4 x n profile matrices, where the first 
%               column is IEC X, the second IEC Y, the third IEC Z/Depth 
%               (positive values are down), and the fourth is signal
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

% Specify options and order
options = {
    'Eclipse w2CAD (.asc)'
    'Eclipse Line Profile Export (.txt)'
    'OmniPro RFA300 ASCII BDS (.txt, .asc)'
    'OmniPro V6 RFB (.rfb)'
    'PTW MEPHYSTO ASCII (.mcc)'
    'RayStation Physics Export (.csv)'
    'SNC IC Profiler (.prm)'
    'SNC IC Profiler (.txt)'
    'SNC Water Tank (.sncxml)'
    'Standard Imaging TEMS (.csv)'
    'Standard Imaging DV1D (.csv)'
};

% If no input arguments are provided
if nargin == 0
    
    % Return the options
    data = options;
    
    % Stop execution
    return;
end

% Start timer
t = tic;

% Initialize return structure
data.profiles = cell(0);

% Execute code block based on format provided in varargin{2}
switch options{varargin{2}}
    
    % OmniPro RFA300 ASCII BDS
    case 'OmniPro RFA300 ASCII BDS (.txt, .asc)'
        
        % Execute ParseIBAtxt
        data = ParseIBAtxt('', varargin{1});
        
        % Loop through profiles and generate selection menu
        str = cell(1, length(data.profiles));
        def = [];
        for i = 1:length(data.profiles)
            
            % If profile type is CProfileCurv or CDepthDoseCurv, select it 
            % by default
            if isfield(data, 'profiletype') && ...
                    strcmp(data.profiletype{i}, 'CProfileCurv') || ...
                    strcmp(data.profiletype{i}, 'CDepthDoseCurv')
                def(length(def)+1) = i; %#ok<AGROW>
            end
            
            % Set description based on orientation, depth
            if data.profiles{i}(2,1) ~= data.profiles{i}(1,1)
                s = sprintf('IEC X %0.1f cm depth', data.profiles{i}(1,3)/10);
            elseif data.profiles{i}(2,2) ~= data.profiles{i}(1,2)
                s = sprintf('IEC Y %0.1f cm depth', data.profiles{i}(1,3)/10);
            elseif data.profiles{i}(2,3) ~= data.profiles{i}(1,3)
                s = 'IEC Z (depth dose)';
            end
            if isfield(data, 'field')
                str{i} = sprintf('%s: %s %s %0.0fx%0.0f %s', ...
                    data.profiletype{i}, data.energy{i}, data.modality{i}, ...
                    data.field(i,1), data.field(i,2), s);
                
                % Create collimator field based on field values
                data.collimator(i,1:4) = [-data.field(i, 1)/2 
                                           data.field(i, 1)/2  
                                          -data.field(i, 2)/2  
                                           data.field(i, 2)/2];
            else
                str{i} = sprintf('%s: %s %s %s', data.profiletype{i}, ...
                    data.energy{i}, data.modality{i}, s);
            end
            
            
        end
        
         % Open dialog box to allow user to select files
        [sel, ok] = listdlg('PromptString','Select which profiles to load:',...
                'SelectionMode', 'multiple', 'ListString', str, ...
                'InitialValue', def, 'Name', 'Select Profiles', ...
                'ListSize', [400 300]);
        
        % If user clicked cancel, select default
        if ok == 0
            sel = def;
        end
        
        % Remove unselected profiles
        n = fieldnames(data);
        for i = 1:length(n)
            if size(data.(n{i}),1) == length(str)
                data.(n{i}) = data.(n{i})(sel,:);
            elseif size(data.(n{i}),2) == length(str)
                data.(n{i}) = data.(n{i})(:,sel);
            end
        end
        
    % OmniPro RFB
    case 'OmniPro V6 RFB (.rfb)'
        
        % Execute ParseIBArfb
        data = ParseIBArfb('', varargin{1});  
        
        % Loop through profiles and generate selection menu
        str = cell(1, length(data.profiles));
        def = [];
        for i = 1:length(data.profiles)
            
            % If profile type is CProfileCurv or CDepthDoseCurv, select it 
            % by default
            if strcmp(data.profiletype{i}, 'CProfileCurv') || ...
                    strcmp(data.profiletype{i}, 'CDepthDoseCurv')
                def(length(def)+1) = i; %#ok<AGROW>
            end
            
            % Set description based on orientation, depth
            if data.profiles{i}(2,1) ~= data.profiles{i}(1,1)
                s = sprintf('IEC X %0.1f cm depth', data.profiles{i}(1,3)/10);
            elseif data.profiles{i}(2,2) ~= data.profiles{i}(1,2)
                s = sprintf('IEC Y %0.1f cm depth', data.profiles{i}(1,3)/10);
            elseif data.profiles{i}(2,3) ~= data.profiles{i}(1,3)
                s = 'IEC Z (depth dose)';
            end
            str{i} = sprintf('%s: %s %s %0.0fx%0.0f %s', ...
                data.profiletype{i}, data.energy{i}, data.modality{i}, ...
                sum(abs(data.collimator(i, 1:2))), ...
                sum(abs(data.collimator(i, 3:4))), s);
        end
        
        % Open dialog box to allow user to select files
        [sel, ok] = listdlg('PromptString','Select which profiles to load:',...
                'SelectionMode', 'multiple', 'ListString', str, ...
                'InitialValue', def, 'Name', 'Select Profiles', ...
                'ListSize', [400 300]);
        
        % If user clicked cancel, use defaults
        if ok == 0
            sel = def;
        end
        
        % Remove unselected profiles
        n = fieldnames(data);
        for i = 1:length(n)
            if size(data.(n{i}),1) == length(str)
                data.(n{i}) = data.(n{i})(sel,:);
            elseif size(data.(n{i}),2) == length(str)
                data.(n{i}) = data.(n{i})(:,sel);
            end
        end
        
    % PTW mcc
    case 'PTW MEPHYSTO ASCII (.mcc)'
        
        % Execute ParsePTWmcc
        data = ParsePTWmcc('', varargin{1});
        
        % Store linac to machine
        if isfield(data, 'linac')
            data.machine = data.linac;
        end
        
        % Update SSD to be in cm
        if isfield(data, 'ssd')
            data.ssd = data.ssd / 10;
        end
        
        % Update energy to be a cell, based on modality
        if isfield(data, 'energy') && isfield(data, 'modality')
            if contains(data.modality{1}, 'X')
                data.energy = cell({sprintf('%0.0f MV', data.energy(1))});
            else
                data.energy = cell({sprintf('%0.0f MeV', data.energy(1))});
            end
        end
        
        % Create collimator based on field values
        if isfield(data, 'field_inplane') && isfield(data, 'field_crossplane')
            data.collimator(1,1:4) = [-data.field_crossplane(1)/20 
                data.field_crossplane(1)/20  
                -data.field_inplane(1)/20  
                data.field_inplane(1)/20 ] * 10;
        end
        
    % SNC Water Tank XML
    case 'SNC Water Tank (.sncxml)'
        
        % Execute ParseSNCxml
        data = ParseSNCxml('', varargin{1});
        
        % Sort scans
        [~, I] = sort(cellfun(@(s) s.MeasurementDate, data.Scans));
        data.Scans = data.Scans(I);
        
        % Loop through profiles and generate selection menu (if < 1)
        str = cell(1, length(data.Scans));
        for i = 1:length(data.Scans)
            
            % Set description based on orientation, depth
            str{i} = [strtrim(data.Scans{i}.Layers{1}.Scan), ', ', ...
                data.Scans{i}.Layers{1}.Details];
        end
        
        % Open dialog box to allow user to select files
        if length(data.Scans) > 1
            [sel, ok] = listdlg('PromptString','Select which profiles to load:',...
                    'SelectionMode', 'multiple', 'ListString',str, ...
                    'InitialValue', 1:length(str), 'Name', 'Select Profiles', ...
                    'ListSize', [400 300]);

            % If user clicked cancel, use defaults
            if ok == 0
                sel = 1:length(str);
            end
        else
            sel = 1:length(str);
        end
        sel = 1:length(str);
        
        % Create profiles array of selected results, converting to mm
        data.profiles = cell(1, length(sel));
        for i = 1:length(sel)
            data.profiles{i} = horzcat(...
                data.Scans{sel(i)}.Layers{1}.Readings.X * 10, ...
                data.Scans{sel(i)}.Layers{1}.Readings.Y * 10, ...
                data.Scans{sel(i)}.Layers{1}.Readings.Z * 10, ...
                data.Scans{sel(i)}.Layers{1}.Readings.RelativeDose);
        end
        
        % Set machine, energy, etc. using Radiation Device and first
        % selected scan (these fields are used later to match with the
        % correct reference dose volume)
        for i = 1:length(data.RadiationDevices)
            if strcmp(data.RadiationDevices{i}.UniqueId, ...
                    data.Scans{sel(1)}.RadiationDevice)
                data.machine{1} = char(data.RadiationDevices{i}.SerialNumber);
                break;
            end
        end
        if isfield(data.Scans{sel(1)}, 'EnergyForDisplay')
            data.Scans{sel(1)}.Energy = data.Scans{sel(1)}.EnergyForDisplay;
        end
        data.energy{1} = data.Scans{sel(1)}.Energy;
        data.ssd(1) = data.Scans{sel(1)}.SourceSurfaceDistance;
        
        % Set collimator size based on MLC (if set), otherwise Jaws,
        % otherwise assume symmetric field size based on X/Y
        if ~isnan(data.Scans{sel(1)}.FieldSize.MultiLeafCollimatorX1)
            data.collimator(1,1:4) = ...
                [data.Scans{sel(1)}.FieldSize.MultiLeafCollimatorX1
                data.Scans{sel(1)}.FieldSize.MultiLeafCollimatorX2 
                data.Scans{sel(1)}.FieldSize.MultiLeafCollimatorY1 
                data.Scans{sel(1)}.FieldSize.MultiLeafCollimatorY2];
        elseif ~isnan(data.Scans{sel(1)}.FieldSize.JawsX1)
            data.collimator(1,1:4) = [data.Scans{sel(1)}.FieldSize.JawsX1
                data.Scans{sel(1)}.FieldSize.JawsX2 
                data.Scans{sel(1)}.FieldSize.JawsY1
                data.Scans{sel(1)}.FieldSize.JawsY2];
        elseif ~isnan(data.Scans{sel(1)}.FieldSize.X)
            data.collimator(1,1:4) = [-data.Scans{sel(1)}.FieldSize.X/2 
                data.Scans{sel(1)}.FieldSize.X/2 
                -data.Scans{sel(1)}.FieldSize.Y/2 
                data.Scans{sel(1)}.FieldSize.Y/2];
        end
        
        % Loop through each profile
        for i = 1:length(data.profiles)

            % If signal is negative (negative bias), flip it
            if mean(data.profiles{i}(:,4)) < 0

                % Log event
                if exist('Event', 'file') == 2
                    Event('Inverting negative signal (positive bias)');
                end

                % Store negative value
                data.profiles{i}(:,4) = -data.profiles{i}(:,4);
            end

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
            if (max(data.profiles{i}(:,3)) - min(data.profiles{i}(:,3))) > 1

                % Log event
                if exist('Event', 'file') == 2
                    Event('Sorting depth profile by descending IEC Z value');
                end

                % Store sorted table in descending order
                data.profiles{i} = flip(sortrows(data.profiles{i}, 3), 1);
            end
        end
        
    % IC Profiler PRM
    case 'SNC IC Profiler (.prm)'
        
        % Execute ParseSNCprm
        raw = ParseSNCprm('', varargin{1});
        
        % Execute ExtractSNC subfunction
        data = ExtractSNC(data, raw);
        
        % Clear temporary variable
        clear raw;
   
    % IC Profiler TXT
    case 'SNC IC Profiler (.txt)'
        
        % Execute ParseSNCtxt
        raw = ParseSNCtxt('', varargin{1});
        
        % Execute ExtractSNC subfunction
        data = ExtractSNC(data, raw);
        
        % Clear temporary variable
        clear raw;
        
    % Standard Imaging TEMS
    case 'Standard Imaging TEMS (.csv)'
        
        % Execute ParseTEMScsv
        data = ParseTEMScsv('', varargin{1});
        
        % Assume machine is Tomo
        data.machine{1} = 'TomoTherapy';
        
    % Standard Imaging TEMS
    case 'Standard Imaging DV1D (.csv)'
        
        % Execute ParseDV1Dcsv
        data = ParseDV1Dcsv('', varargin{1});
        
    % RayStation
    case 'RayStation Physics Export (.csv)'
        
        % Execute ParseRScsv
        data = ParseRScsv('', varargin{1});
        
        % Loop through profiles and generate selection menu
        str = cell(1, length(data.profiles));
        for i = 1:length(data.profiles)
            
            % Set description based on orientation, depth
            str{i} = sprintf('%s: %s %s %0.0fx%0.0f', ...
                data.profiletype{i}, ...
                data.energy{i}, data.modality{i}, ...
                sum(abs(data.collimator(i, 1:2))), ...
                sum(abs(data.collimator(i, 3:4))));
        end
        
        % Open dialog box to allow user to select files
        [sel, ok] = listdlg('PromptString','Select which profiles to load:',...
                'SelectionMode', 'multiple', 'ListString',str, ...
                'InitialValue', 1:length(str), 'Name', 'Select Profiles', ...
                'ListSize', [400 300]);
        
        % If user clicked cancel, use defaults
        if ok == 0
            sel = 1:length(str);
        end
        
        % Remove unselected profiles
        n = fieldnames(data);
        for i = 1:length(n)
            if size(data.(n{i}),1) == length(str)
                data.(n{i}) = data.(n{i})(sel,:);
            elseif size(data.(n{i}),2) == length(str)
                data.(n{i}) = data.(n{i})(:,sel);
            end
        end
     
    % Eclipse Export
    case 'Eclipse Line Profile Export (.txt)'
        
        % Execute ParseW2CAD
        data = ParseEclipse('', varargin{1});
        
    % Eclipse w2CAD
    case 'Eclipse w2CAD (.asc)'
        
        % Execute ParseW2CAD
        data = ParseW2CAD('', varargin{1});
        
        % Loop through profiles and generate selection menu
        str = cell(1, length(data.profiles));
        for i = 1:length(data.profiles)
            
            % If axis, field, and depth exists
            if isfield(data, 'axis') && length(data.axis) >= i && ...
                    isfield(data, 'field') && size(data.field,1) >= i && ...
                    isfield(data, 'depth') && length(data.depth) >= i && ...
                    data.depth(i) > 0
                
                % Set description based on orientation, depth, field size
                str{i} = sprintf('%s Profile: %0.1f cm, %0.0fx%0.0f', ...
                    data.axis{i}, data.depth(i), data.field(i,1), ...
                    data.field(i,2));
             
            % If only axis and field exists
            elseif isfield(data, 'axis') && length(data.axis) >= i && ...
                    isfield(data, 'field') && size(data.field,1) >= i
                
                % Set description based on orientation, field size
                str{i} = sprintf('%s Profile: %0.0fx%0.0f', ...
                    data.axis{i}, data.field(i,1), ...
                    data.field(i,2));
               
            % If type and field exists
            elseif isfield(data, 'type') && length(data.type) >= i && ...
                    isfield(data, 'field') && size(data.field,1) >= i
                
                % Set description based on orientation, field size
                str{i} = sprintf('%s: %0.0fx%0.0f', ...
                    data.type{i}, data.field(i,1), ...
                    data.field(i,2));
              
            % Otherwise, use a generic name
            else
                str{i} = sprintf('Profile %i', i);
            end
            
            % Create collimator field based on field values
            data.collimator(i,1:4) = [-data.field(i, 1)/2 
                                       data.field(i, 1)/2  
                                      -data.field(i, 2)/2  
                                       data.field(i, 2)/2];
        end
        
        % Open dialog box to allow user to select files
        [sel, ok] = listdlg('PromptString','Select which profiles to load:',...
                'SelectionMode', 'multiple', 'ListString',str, ...
                'InitialValue', 1:length(str), 'Name', 'Select Profiles', ...
                'ListSize', [400 300]);
        
        % If user clicked cancel, use defaults
        if ok == 0
            sel = 1:length(str);
        end
        
        % Remove unselected profiles
        n = fieldnames(data);
        for i = 1:length(n)
            if size(data.(n{i}),1) == length(str)
                data.(n{i}) = data.(n{i})(sel,:);
            elseif size(data.(n{i}),2) == length(str)
                data.(n{i}) = data.(n{i})(:,sel);
            end
        end
end

% Log number of profiles
if exist('Event', 'file') == 2
    Event(sprintf('%i profiles loaded in %0.3f seconds\n', ...
        length(data.profiles), toc(t)));
end