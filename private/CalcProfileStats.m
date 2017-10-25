function data = CalcProfileStats(varargin)
% CalcProfileStats computes a cell array (table) of statistics based on
% a provided set of profiles. If called with no inputs, it will return a 
% an empty table.
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

% Initialize data table
data = {
    'Axis'
    'Depth'
    'Flatness'
    'CAX Point Symmetry'
    'Area Symmetry'
    'FWHM' 
    'Reference FWHM' 
    'Difference'
    'FWHM Center'
    'Local RMS Error'
    'Local Max Error'
    'Mean Gamma'
    'Max Gamma'
    'Gamma Pass Rate'
};

% If no data was passed
if nargin == 0
    return;
else
    profile = varargin{1};
end

% Initialize counter
c = 1;

% Loop through profiles
for i = 1:length(profile)
    
    % If this is an X or Y profile
    if profile{i}(1,1) ~= profile{i}(2,1) || ...
            profile{i}(1,2) ~= profile{i}(2,2)
        
        % Increment counter
        c = c + 1;
        
        % List the axis and store the axis
        if profile{i}(1,1) ~= profile{i}(2,1)
            data{1,c} = 'IEC X';
            x = profile{i}(:,1);
        else
            data{1,c} = 'IEC Y';
            x = profile{i}(:,2);
        end
        
        % List depth
        data{2,c} = sprintf('%0.1f mm', profile{i}(1,3));
        
        % Find index of central value
        [~, I] = min(abs(x));

        % Find highest lower index just below half maximum
        lI = find(profile{i}(1:I,4) < 0.5 * max(profile{i}(:,4)), 1, 'last');

        % Find lowest upper index just above half maximum
        uI = find(profile{i}(I:end,4) < 0.5 * max(profile{i}(:,4)), 1, 'first');

        % Calculate FWHM and offset
        try
            % Interpolate to find lower half-maximum value
            l = interp1(profile{i}(lI-1:lI+2,4), ...
                x(lI-1:lI+2), 0.5 * max(profile{i}(:,4)), 'linear');

            % Interpolate to find upper half-maximum value
            u = interp1(profile{i}(I+uI-3:I+uI,4), ...
                x(I+uI-3:I+uI), 0.5 * max(profile{i}(:,4)), 'linear');

            % Compute FWHM and offset
            fwhm = sprintf('%0.1f mm', sum(abs([l u])));
            offset = sprintf('%0.2f mm', (l+u)/2);
        catch
            Event(sprintf(['Profile %i FWHM could not be computed, ', ...
                'assuming zero shift'], i), 'WARN');

            % Set full range
            lI = 1;
            uI = length(x) - I;
            l = -max(abs(x));
            u = max(abs(x));
            
            % Set FWHM and offset as undefined
            fwhm = 'N/A';
            offset = 'N/A';
        end

        % Compute the range for the central 80%
        range = ceil((lI + I + uI)/2 - abs(I + uI - lI) * 0.4):...
            floor((lI + I + uI)/2 + abs(I + uI - lI) * 0.4);
        
        % Calculate Flatness
        data{3,c} = sprintf('%0.2f%%', (max(profile{i}(range,4)) - ...
            min(profile{i}(range,4)))/(max(profile{i}(range,4)) + ...
            min(profile{i}(range,4))) * 100);
        
        % Calculate CAX Point Symmetry
        data{4,c} = sprintf('%0.2f%%', max((profile{i}(range(1):I,4) - ...
            interp1(x, profile{i}(:,4), -x(range(1):I), 'linear')) / ...
            interp1(x, profile{i}(:,4), 0, 'linear')) * 100);
        
        % Calculate Areal Symmetry
        data{5,c} = sprintf('%0.2f%%', (sum(profile{i}(range(1):I,4)) - ...
            sum(interp1(x, profile{i}(:,4), -x(range(1):I), 'linear'))) / ...
            (sum(profile{i}(range(1):I,4)) + sum(interp1(x, profile{i}(:,4), ...
            -x(range(1):I), 'linear'))) * 200);
        
        % Store FWHM
        data{6,c} = fwhm;
        
        % Find reference highest lower index just below half maximum
        lI = find(profile{i}(1:I,5) < 0.5 * max(profile{i}(:,5)), 1, 'last');

        % Find reference lowest upper index just above half maximum
        uI = find(profile{i}(I:end,5) < 0.5 * max(profile{i}(:,5)), 1, 'first');

        % Calculate reference FWHM
        try
            % Interpolate to find lower half-maximum value
            l = interp1(profile{i}(lI-1:lI+2,5), ...
                x(lI-1:lI+2), 0.5 * max(profile{i}(:,5)), 'linear');

            % Interpolate to find upper half-maximum value
            u = interp1(profile{i}(I+uI-3:I+uI,5), ...
                x(I+uI-3:I+uI), 0.5 * max(profile{i}(:,5)), 'linear');

            % Compute FWHM and offset
            data{7,c} = sprintf('%0.1f mm', sum(abs([l u])));
            
            % Compute FWHM difference
            if ~strcmp(fwhm, 'N/A')
                data{8,c} = sprintf('%0.2f mm', str2double(fwhm(1:end-3)) - ...
                    sum(abs([l u])));
            end
        catch
            Event(sprintf(['Profile %i Reference FWHM could not be computed, ', ...
                'assuming zero shift'], i), 'WARN');

            % Set FWHM as undefined
            data{7,c} = 'N/A';
            data{8,c} = 'N/A';
        end
        
        % Store offset
        data{9,c} = offset;
        
        % Calculate RMS error
        data{10,c} = sprintf('%0.2f%%', sqrt(mean(((profile{i}(range,4) - ...
            profile{i}(range,5)) ./ profile{i}(range,5)).^2)) * 100);
        
        % Calculate Max error
        data{11,c} = sprintf('%0.2f%%', max((profile{i}(range,4) - ...
            profile{i}(range,5)) ./ profile{i}(range,5)) * 100);
        
        % Calculate Mean Gamma
        data{12,c} = sprintf('%0.2f', mean(profile{i}(range,6)));
        
        % Calculate Max Gamma
        data{13,c} = sprintf('%0.2f', max(profile{i}(range,6)));
        
        % Calculate Gamma Pass Rate
        data{14,c} = sprintf('%0.1f%%', sum(profile{i}(range,6) < 1) / ...
            length(range) * 100);
    end
end