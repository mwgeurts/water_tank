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
    'OmniPro RFA300 ASCII BDS (.txt, .asc)'
    'OmniPro V6 RFB (.rfb)'
    'RayStation Physics Export (.csv)'
    'SNC IC Profiler (.prm)'
    'SNC IC Profiler (.txt)'
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
                s = sprintf('IEC X %0.1f cm depth', data.profiles{i}(1,3));
            elseif data.profiles{i}(2,2) ~= data.profiles{i}(1,2)
                s = sprintf('IEC Y %0.1f cm depth', data.profiles{i}(1,3));
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
                'SelectionMode', 'multiple', 'ListString',str, ...
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
        
    % IC Profiler PRM
    case 'SNC IC Profiler (.prm)'
        
        % Execute ParseSNCprm
        raw = ParseSNCprm('', varargin{1});
        
        % Correct profiles using AnalyzeProfilerFields
        processed = AnalyzeProfilerFields(raw);
        
        % Merge raw and processed data into return structure
        f = fieldnames(raw);
        for i = 1:length(f)
            data.(f{i}) = raw.(f{i});
        end
        f = fieldnames(processed);
        for i = 1:length(f)
            data.(f{i}) = processed.(f{i});
        end
        
        % Store machine as combination of model, S/N
        if isfield(data, 'mmodel')
            if iscell(data.mmodel)
                data.machine{1} = data.mmodel{1};
            else
                data.machine{1} = data.mmodel;
            end
        else
            data.machine{1} = '';
        end
        if isfield(data, 'mserial')
            if iscell(data.mserial)
                data.machine{1} = [data.machine{1}, ' ', data.mserial{1}];
            else
                data.machine{1} = [data.machine{1}, ' ', data.mserial];
            end
        end
        
        % Store energy
        if isfield(data, 'menergy')
            if iscell(data.mmodel)
                data.energy{1} = data.menergy{1};
            else
                data.energy{1} = data.menergy;
            end
        end
        
        % Store SSD
        if isfield(data, 'dssd')
            if iscell(data.dssd)
                data.ssd{1} = data.dssd{1};
            else
                data.ssd{1} = data.dssd;
            end
        end
        
        % Ask user for buildup
        b = str2double(inputdlg(['Enter additional buildup on ', ...
            'IC Profiler (inherent 9 mm is already added) in mm:'], ...
            'Enter Buildup', 1, {sprintf('%0.1f', 10 * data.dbuildup(1))}));
        
        % If user clicked cancel, default back to zero
        if isempty(b)
            b = 0;
        end
        
        % Loop through IEC X profiles
        for i = 1:size(processed.xdata,1)-1
            
            % Add cell
            data.profiles{length(data.profiles)+1} = ...
                zeros(size(processed.xdata, 2),4);
            
            % Add X values
            data.profiles{length(data.profiles)}(:,1) = ...
                10 * processed.xdata(1,:)';
            
            % Set depth to 0.9 cm (Gao et al) plus buildup
            data.profiles{length(data.profiles)}(:,3) = repmat(9 + b, ...
                size(processed.xdata, 2), 1);
            
            % Add corrected dose
            data.profiles{length(data.profiles)}(:,4) = ...
                processed.xdata(1+i,:)';
        end
        
        % Loop through IEC Y profiles
        for i = 1:size(processed.xdata,1)-1
            
            % Add cell
            data.profiles{length(data.profiles)+1} = ...
                zeros(size(processed.ydata, 2),4);
            
            % Add Y values
            data.profiles{length(data.profiles)}(:,2) = ...
                10 * processed.ydata(1,:)';
            
            % Set depth to 0.9 cm (Gao et al) plus buildup
            data.profiles{length(data.profiles)}(:,3) = repmat(9 + b, ...
                size(processed.ydata, 2), 1);
            
            % Add corrected dose
            data.profiles{length(data.profiles)}(:,4) = ...
                processed.ydata(1+i,:);
        end
        
        % Clear temporary variables
        clear f i b raw processed;
   
    % IC Profiler TXT
    case 'SNC IC Profiler (.txt)'
        
        % Execute ParseSNCtxt
        raw = ParseSNCtxt('', varargin{1});
        
        % Correct profiles using AnalyzeProfilerFields
        processed = AnalyzeProfilerFields(raw);
        
        % Merge raw and processed data into return structure
        f = fieldnames(raw);
        for i = 1:length(f)
            data.(f{i}) = raw.(f{i});
        end
        f = fieldnames(processed);
        for i = 1:length(f)
            data.(f{i}) = processed.(f{i});
        end
        
        % Store machine as combination of model, S/N
        if isfield(data, 'mmodel')
            if iscell(data.mmodel)
                data.machine{1} = data.mmodel{1};
            else
                data.machine{1} = data.mmodel;
            end
        else
            data.machine{1} = '';
        end
        if isfield(data, 'mserial')
            if iscell(data.mserial)
                data.machine{1} = [data.machine{1}, ' ', data.mserial{1}];
            else
                data.machine{1} = [data.machine{1}, ' ', data.mserial];
            end
        end
        
        % Store energy
        if isfield(data, 'menergy')
            if iscell(data.mmodel)
                data.energy{1} = data.menergy{1};
            else
                data.energy{1} = data.menergy;
            end
        end
        
        % Store SSD
        if isfield(data, 'dssd')
            if iscell(data.dssd)
                data.ssd{1} = data.dssd{1};
            else
                data.ssd{1} = data.dssd;
            end
        end
        
        % Ask user for buildup
        b = str2double(inputdlg(['Enter additional buildup on ', ...
            'IC Profiler (inherent 9 mm is already added) in mm:'], ...
            'Enter Buildup', 1, {sprintf('%0.1f', 10 * data.dbuildup(1))}));
        
        % If user clicked cancel, default back to zero
        if isempty(b)
            b = 0;
        end
        
        % Loop through IEC X profiles
        for i = 1:size(processed.xdata,1)-1
            
            % Add cell
            data.profiles{length(data.profiles)+1} = ...
                zeros(size(processed.xdata, 2),4);
            
            % Add X values
            data.profiles{length(data.profiles)}(:,1) = ...
                10 * processed.xdata(1,:)';
            
            % Set depth to 0.9 cm (Gao et al) plus buildup
            data.profiles{length(data.profiles)}(:,3) = repmat(9 + b, ...
                size(processed.xdata, 2), 1);
            
            % Add corrected dose
            data.profiles{length(data.profiles)}(:,4) = ...
                processed.xdata(1+i,:)';
        end
        
        % Loop through IEC Y profiles
        for i = 1:size(processed.xdata,1)-1
            
            % Add cell
            data.profiles{length(data.profiles)+1} = ...
                zeros(size(processed.ydata, 2),4);
            
            % Add Y values
            data.profiles{length(data.profiles)}(:,2) = ...
                10 * processed.ydata(1,:)';
            
            % Set depth to 0.9 cm (Gao et al) plus buildup
            data.profiles{length(data.profiles)}(:,3) = repmat(9 + b, ...
                size(processed.ydata, 2), 1);
            
            % Add corrected dose
            data.profiles{length(data.profiles)}(:,4) = ...
                processed.ydata(1+i,:);
        end
        
        % Clear temporary variables
        clear f i b raw processed;
        
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
end

% Log number of profiles
if exist('Event', 'file') == 2
    Event(sprintf('%i profiles loaded in %0.3f seconds\n', ...
        length(data.profiles), toc(t)));
end