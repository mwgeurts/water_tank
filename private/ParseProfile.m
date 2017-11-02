function profile = ParseProfile(varargin)
% ParseProfile extracts a water tank file into a cell array of individual 
% profiles. If called with no inputs, it will return a list of available
% formats that can be parsed. If called with inputs, the first must be the
% name of the file while the second is an integer corresponding to the
% format.
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

% Declare persistent buildup option
persistent buildup;

% Specify options and order
options = {
    'OmniPro RFA300 ASCII BDS (.txt)'
    'SNC IC Profiler (.prm)'
};

% If no input arguments are provided
if nargin == 0
    
    % Return the options
    profile = options;
    
    % Stop execution
    return;
end

% Execute code block based on format provided in varargin{2}
switch varargin{2}
    
    % OmniPro RFA300 ASCII BDS
    case 1
        
        % Open file to provided filename 
        fid = fopen(varargin{1});
        
        % Initialize counter and return variable
        i = 0;
        profile = cell(0);

        % Loop through file contents
        while ~feof(fid)

            % Get line
            l = fgetl(fid);

            % If line matches format
            if length(l) > 1 && strcmp(l(1), '=')
                if length(profile) == i
                    profile{i} = vertcat(profile{i}, ...
                        cell2mat(textscan(l(2:end), '%f %f %f %f')));
                else
                    profile{i} = cell2mat(textscan(l(2:end), '%f %f %f %f'));
                end

            else
                i = i + 1;
            end
        end

        % Close file
        fclose(fid);

        % Remove empty cells
        profile = profile(~cellfun('isempty', profile));
        
        % Loop through each profile
        for i = 1:length(profile)
            
            % If depth is negative (given by a negative mean value), flip
            % the dimension so that depths are down
            if mean(profile{i}(:,3)) < 0
                profile{i}(:,3) = -profile{i}(:,3);
            end
        end
        
        % Clear temporary variables
        clear fid i l;
        
    % IC Profiler PRM
    case 2
        
        % Define default buildup
        if ~exist('buildup', 'var')
            buildup = 0;
        end
        
        % Execute ParseSNCprm
        raw = ParseSNCprm('', varargin{1});
        
        % Correct profiles using AnalyzeProfilerFields
        processed = AnalyzeProfilerFields(raw);
        
        % Initialize return cell array
        profile = cell(0);
        
        % Ask user for buildup
        buildup = str2double(inputdlg(['Enter additional buildup on ', ...
            'IC Profiler (inherent 9 mm is already added) in mm:'], ...
            'Enter Buildup', 1, {sprintf('%0.1f', buildup)}));
        
        % If user clicked cancel, default back to zero
        if isempty(buildup)
            buildup = 0;
        end
        
        % Loop through IEC X profiles
        for i = 1:size(processed.xdata,1)-1
            
            % Add cell
            profile{length(profile)+1} = zeros(size(processed.xdata, 2),4);
            
            % Add X values
            profile{length(profile)}(:,1) = 10 * processed.xdata(1,:)';
            
            % Set depth to 0.9 cm (Gao et al)
            profile{length(profile)}(:,3) = repmat(9 + buildup, ...
                size(processed.xdata, 2), 1);
            
            % Add corrected dose
            profile{length(profile)}(:,4) = processed.xdata(1+i,:)';
        end
        
        % Loop through IEC Y profiles
        for i = 1:size(processed.xdata,1)-1
            
            % Add cell
            profile{length(profile)+1} = zeros(size(processed.ydata, 2),4);
            
            % Add Y values
            profile{length(profile)}(:,2) = 10 * processed.ydata(1,:)';
            
            % Set depth to 0.9 cm (Gao et al)
            profile{length(profile)}(:,3) = repmat(9 + buildup, ...
                size(processed.ydata, 2), 1);
            
            % Add corrected dose
            profile{length(profile)}(:,4) = processed.ydata(1+i,:);
        end
end

% Log number of profiles
if exist('Event', 'file') == 2
    Event(sprintf('%i profiles loaded from %s\n', length(profile), ...
        varargin{1}));
end