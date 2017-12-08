function data = ExtractSNC(data, raw)
% ExtractSNC is called by ParseProfile when SNC Profiler .txt or .prm files 
% are loaded and returns the appropriate WaterTankAnalysis-compatible 
% structure. See ParseSNCprm and ParseSNCtxt for more details.
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
    data.ssd = data.dssd;
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
for i = 1:size(processed.ydata,1)-1

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

% Loop through positive diagonal profiles
for i = 1:size(processed.pdiag,1)-1

    % Add cell
    data.profiles{length(data.profiles)+1} = ...
        zeros(size(processed.pdiag, 2),4);

    % Add X values
    data.profiles{length(data.profiles)}(:,1) = ...
        10 * processed.pdiag(1,:)' / sqrt(2);

    % Add Y values
    data.profiles{length(data.profiles)}(:,2) = ...
        10 * processed.pdiag(1,:)' / sqrt(2);

    % Set depth to 0.9 cm (Gao et al) plus buildup
    data.profiles{length(data.profiles)}(:,3) = repmat(9 + b, ...
        size(processed.pdiag, 2), 1);

    % Add corrected dose
    data.profiles{length(data.profiles)}(:,4) = ...
        processed.pdiag(1+i,:);
end

% Loop through negative diagonal profiles
for i = 1:size(processed.ndiag,1)-1

    % Add cell
    data.profiles{length(data.profiles)+1} = ...
        zeros(size(processed.ndiag, 2),4);

    % Add X values
    data.profiles{length(data.profiles)}(:,1) = ...
        10 * processed.ndiag(1,:)' / sqrt(2);

    % Add Y values
    data.profiles{length(data.profiles)}(:,2) = ...
        -10 * processed.ndiag(1,:)' / sqrt(2);

    % Set depth to 0.9 cm (Gao et al) plus buildup
    data.profiles{length(data.profiles)}(:,3) = repmat(9 + b, ...
        size(processed.ndiag, 2), 1);

    % Add corrected dose
    data.profiles{length(data.profiles)}(:,4) = ...
        processed.ndiag(1+i,:);
end

% Clear temporary variables
clear f i b processed;