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
    'SNC IC Profiler (.prm)'
    'SNC IC Profiler (.txt)'
    'Standard Imaging TEMS (.csv)'
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
switch varargin{2}
    
    % OmniPro RFA300 ASCII BDS
    case 1
        
        % Execute ParseIBAtxt
        data = ParseIBAtxt('', varargin{1});
        
    % IC Profiler PRM
    case 2
        
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
            
            % Set depth to 0.9 cm (Gao et al)
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
            
            % Set depth to 0.9 cm (Gao et al)
            data.profiles{length(data.profiles)}(:,3) = repmat(9 + b, ...
                size(processed.ydata, 2), 1);
            
            % Add corrected dose
            data.profiles{length(data.profiles)}(:,4) = ...
                processed.ydata(1+i,:);
        end
        
        % Clear temporary variables
        clear f i b raw processed;
   
    % IC Profiler TXT
    case 3
        
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
            
            % Set depth to 0.9 cm (Gao et al)
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
            
            % Set depth to 0.9 cm (Gao et al)
            data.profiles{length(data.profiles)}(:,3) = repmat(9 + b, ...
                size(processed.ydata, 2), 1);
            
            % Add corrected dose
            data.profiles{length(data.profiles)}(:,4) = ...
                processed.ydata(1+i,:);
        end
        
        % Clear temporary variables
        clear f i b raw processed;
        
    % Standard Imaging TEMS
    case 4
        
        % Execute ParseSIcsv
        data = ParseSIcsv('', varargin{1});
end

% Log number of profiles
if exist('Event', 'file') == 2
    Event(sprintf('%i profiles loaded in %0.3f seconds\n', ...
        length(data.profiles), toc(t)));
end