function data = CalcDepthStats(varargin)
% CalcDepthStats computes a cell array (table) of statistics based on
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

% If this is an electron energy, return R50s
if nargin == 0 || isempty(regexpi(varargin{1}, 'e'))

    % Initialize data table
    data = {
        'Dmax'
        'Reference Dmax'
        'PDD 10' 
        'Reference PDD 10'
        'PDD10 Difference'
        'PDD 20/10 Ratio'
        'Local RMS Error'
        'Local Max Error'
        'Mean Gamma'
        'Max Gamma'
        'Gamma Pass Rate'
    };

else
    
    % Initialize data table
    data = {
        'Dmax'
        'Reference Dmax'
        'R50' 
        'Reference R50'
        'Difference'
        'Rp'
        'Local RMS Error'
        'Local Max Error'
        'Mean Gamma'
        'Max Gamma'
        'Gamma Pass Rate'
    };
end

% If no data was passed
if nargin < 2
    return;
else
    profiles = varargin{2};
end

% Initialize counter
c = 1;

% Loop through profiles
for i = 1:length(profiles)
    
    % If this is a Z profile
    if profiles{i}(1,3) ~= profiles{i}(2,3)
        
        % Increment counter
        c = c + 1;
        
        % Calculate Dmax
        data{1,c} = sprintf('%0.1f mm', profiles{i}(find(profiles{i}(:,4) == ...
            max(profiles{i}(:,4)), 1, 'first'),3));
        
        % Calculate Reference Dmax
        data{2,c} = sprintf('%0.1f mm', profiles{i}(find(profiles{i}(:,5) == ...
            max(profiles{i}(:,5)), 1, 'first'),3));
        
         % Find the index of Dmax
        uI = find(profiles{i}(:,4) == max(profiles{i}(:,4)), 1, 'first');

        % Find the index of 5% of Dmax
        lI = find(profiles{i}(:,4) > 0.05 * max(profiles{i}(:,4)), 1, 'first');
        
        % If a photon energy is selected
        if isempty(regexpi(varargin{1}, 'e'))
            
            % Calculate the PDD10
            M = interp1(profiles{i}(lI:uI,3), ...
                profiles{i}(lI:uI,4), 100, 'linear') * 100;
            data{3,c} = sprintf('%0.1f%%', M);
            
            % Find the index of Dmax
            uIr = find(profiles{i}(:,5) == max(profiles{i}(:,5)), 1, 'first');

            % Find the index of 5% of Dmax
            lIr = find(profiles{i}(:,5) > 0.05 * ...
                max(profiles{i}(:,5)), 1, 'first');
            
            % Calculate the Reference PDD10
            R = interp1(profiles{i}(lIr:uIr,3), ...
                profiles{i}(lIr:uIr,5), 100, 'linear') * 100;
            data{4,c} = sprintf('%0.1f%%', R);
            
            % Calculate the PDD difference
            data{5,c} = sprintf('%0.2f%%', M - R);
            
            % Calculate the PDD 20/10
            data{6,c} = sprintf('%0.3f', interp1(profiles{i}(lI:uI,3), ...
                profiles{i}(lI:uI,4), 200, 'linear') / ...
                interp1(profiles{i}(lI:uI,3), profiles{i}(lI:uI,4), ...
                100, 'linear'));
        else
            
            % Calculate the R50
            M = interp1(profiles{i}(lI:uI,4), ...
                profiles{i}(lI:uI,3), 0.5 * max(profiles{i}(lI:uI,4)), 'linear');
            data{3,c} = sprintf('%0.1f mm', M);
            
            % Find the index of Dmax
            uIr = find(profiles{i}(:,5) == max(profiles{i}(:,5)), 1, 'first');

            % Find the index of 5% of Dmax
            lIr = find(profiles{i}(:,5) > 0.05 * ...
                max(profiles{i}(:,5)), 1, 'first');
            
            % Calculate the Reference R50
            R = interp1(profiles{i}(lIr:uIr,5), ...
                profiles{i}(lIr:uIr,3), 0.5 * max(profiles{i}(lIr:uIr,5)), 'linear');
            data{4,c} = sprintf('%0.1f mm', R);
            
            % Calculate the R50 difference
            data{5,c} = sprintf('%0.1f mm', M - R);
            
            % Calculate Rp
            I = find(profiles{i}(lI:uI,4) < 0.5 * max(profiles{i}(:,4)), 1, 'last');
            Rp = interp1(profiles{i}(lI:uI,4), profiles{i}(lI:uI,3), 0.5 * ...
                max(profiles{i}(lI:uI,4))) - (0.5 * max(profiles{i}(:,4)) - ...
                min(profiles{i}(:,4))) ...
                * mean(diff(profiles{i}(lI+I-3:lI+I+3,3))) / ...
                mean(diff(profiles{i}(lI+I-3:lI+I+3,4)));
            [~, lI] = min(abs(profiles{i}(:,3) - Rp));
            data{6,c} = sprintf('%0.1f mm', Rp);
        end

        % Calculate RMS error
        data{7,c} = sprintf('%0.2f%%', sqrt(mean(((profiles{i}(lI:uI,4) - ...
            profiles{i}(lI:uI,5)) ./ profiles{i}(lI:uI,5)).^2)) * 100);
        
        % Calculate Max error
        data{8,c} = sprintf('%0.2f%%', max((profiles{i}(lI:uI,4) - ...
            profiles{i}(lI:uI,5)) ./ profiles{i}(lI:uI,5)) * 100);
        
        % Calculate Mean Gamma
        data{9,c} = sprintf('%0.2f', mean(profiles{i}(lI:uI,6)));
        
        % Calculate Max Gamma
        data{10,c} = sprintf('%0.2f', max(profiles{i}(lI:uI,6)));
        
        % Calculate Gamma Pass Rate
        data{11,c} = sprintf('%0.1f%%', sum(profiles{i}(lI:uI,6) < 1) / ...
            length(lI:uI) * 100);
        
    end
end
