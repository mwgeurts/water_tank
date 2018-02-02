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
if nargin == 0 || ~contains(varargin{1}, 'e', 'IgnoreCase', true)

    % Initialize data table
    if nargin > 0
        Event(sprintf('Depth statistics configured for %s photons', ...
            varargin{1}));
    else
        Event('Depth statistics configured for photon');
    end
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
    Event(sprintf('Depth statistics configured for %s electrons', ...
        varargin{1}));
    data = {
        'Dmax'
        'Reference Dmax'
        'R50' 
        'Reference R50'
        'Difference'
        'Rp'
        'Rq'
        'G'
        'Ep0'
        'E0'
        'Contamination'
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
    if (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1
        
        % Increment counter
        c = c + 1;
        Event(sprintf('Computing depth statistics for profile %i', i));
        
        % Calculate Dmax
        data{1,c} = sprintf('%0.1f mm', mean(profiles{i}(profiles{i}(:,4) ...
            == max(profiles{i}(:,4)),3)));
        Event(['Dmax = ', data{1,c}]);
        
        % Calculate Reference Dmax
        data{2,c} = sprintf('%0.1f mm', profiles{i}(find(profiles{i}(:,5) == ...
            max(profiles{i}(:,5)), 1, 'first'),3));
        Event(['Reference Dmax = ', data{2,c}]);
        
        % Find the index of Dmax
        uI = find(profiles{i}(:,4) == max(profiles{i}(:,4)), 1, 'first');

        % Find the index of 5% of Dmax
        lI = find(profiles{i}(:,4) > 0.05 * ...
            max(profiles{i}(:,4)), 1, 'first');
        
        % If zero reference values exist, cap end
        if ~isempty(find(profiles{i}(1:uI,5) == 0, 1))
            lI = find(profiles{i}(1:uI,5) == 0, 1, 'last')+1;
        end
        
        % If a photon energy is selected
        if ~contains(varargin{1}, 'e', 'IgnoreCase', true)
            
            % Calculate the PDD10
            M = interp1(profiles{i}(lI:uI,3), ...
                profiles{i}(lI:uI,4), 100, 'linear') * 100;
            data{3,c} = sprintf('%0.1f%%', M);
            Event(['PDD10 = ', data{3,c}]);
            
            % Find the index of Dmax
            uIr = find(profiles{i}(:,5) == ...
                max(profiles{i}(:,5)), 1, 'first');

            % Find the index of 5% of Dmax
            lIr = find(profiles{i}(:,5) > 0.05 * ...
                max(profiles{i}(:,5)), 1, 'first');
            
            % Calculate the Reference PDD10
            R = interp1(profiles{i}(lIr:uIr,3), ...
                profiles{i}(lIr:uIr,5), 100, 'linear') * 100;
            data{4,c} = sprintf('%0.1f%%', R);
            Event(['Reference PDD10 = ', data{4,c}]);
            
            % Calculate the PDD difference
            data{5,c} = sprintf('%0.2f%%', M - R);
            Event(['PDD10 difference = ', data{5,c}]);
            
            % Calculate the PDD 20/10
            data{6,c} = sprintf('%0.3f', interp1(profiles{i}(lI:uI,3), ...
                profiles{i}(lI:uI,4), 200, 'linear') / ...
                interp1(profiles{i}(lI:uI,3), profiles{i}(lI:uI,4), ...
                100, 'linear'));
            Event(['PDD 20/10 ratio = ', data{6,c}]);
            
            % Set index for remaining rows
            a = 6;
        else

            % Remove duplicate points (they will cause interp1 to fail)
            [u, idx, ~] = unique(profiles{i}(lI:uI,4));
            Event(sprintf(['Removed %i duplicate signal values for R50 ', ...
                'interpolation'], uI - lI - length(u) + 1));
            
            % Calculate the R50
            M = interp1(u, profiles{i}(lI+idx-1,3), 0.5 * ...
                max(profiles{i}(lI:uI,4)), 'linear');
            data{3,c} = sprintf('%0.1f mm', M);
            Event(['R50 = ', data{3,c}]);
            
            % Find the index of Dmax
            uIr = find(profiles{i}(:,5) == ...
                max(profiles{i}(:,5)), 1, 'first');

            % Find the index of 5% of Dmax
            lIr = find(profiles{i}(:,5) > 0.05 * ...
                max(profiles{i}(lI:uI,5)), 1, 'first');
            
            % Calculate the Reference R50
            R = interp1(profiles{i}(lIr:uIr,5), ...
                profiles{i}(lIr:uIr,3), 0.5 * ...
                max(profiles{i}(lIr:uIr,5)), 'linear');
            data{4,c} = sprintf('%0.1f mm', R);
            Event(['Ref R50 = ', data{4,c}]);
            
            % Calculate the R50 difference
            data{5,c} = sprintf('%0.1f mm', M - R);
            Event(['R50 diff = ', data{5,c}]);
            
            % If sufficient data exists to estimate bremsstrahlung tail
            if nargin > 2 && isfield(varargin{3}, 'BREM_METHOD') && ...
                    strcmp('LINEAR_FIT', varargin{3}.BREM_METHOD) && lIr > 3
                
                % Fit bremsstrahlung tail to linear model
                b = fit(profiles{i}(1:lIr,3), profiles{i}(1:lIr,4), 'poly1', ...
                    'Weights', max(profiles{i}(1:lIr,4)) - ...
                    profiles{i}(1:lIr,4));
                b = coeffvalues(b);
                Event(sprintf(['Bremsstrahlung modeled from ', ...
                    'linear fit = [%g %g]'], b));
            
            % Otherwise, assume bremsstrahlung equals the last datapoint
            else
                b = [0 profiles{i}(1,4)];
                Event(sprintf(['Bremsstrahlung modeled from ', ...
                    'last datapoint = [%g %g]'], b));
            end
            
            % Calculate Rp (the tangent slope is averaged over +/- 1 mm to
            % reduce the dependence on noise)
            [~, I] = max(abs(diff(profiles{i}(lIr:uIr,4)) ./ ...
                diff(profiles{i}(lIr:uIr,3))));
            xl = find(profiles{i}(:,3) < ...
                profiles{i}(lIr+I,3) + 2, 1, 'first');
            xr = find(profiles{i}(:,3) < ...
                profiles{i}(lIr+I,3) - 2, 1, 'first');
            p = polyfit(profiles{i}(xl:xr+1,3), profiles{i}(xl:xr+1,4), 1);
            Event(sprintf('Rp tangent fit coefficients = [%g %g]', p));
            Rp = roots(p-b);
            data{6,c} = sprintf('%0.1f mm', Rp);
            Event(['Rp = ', data{6,c}]);
            
            % Calculate Rq
            Rq = roots(p - [0 max(profiles{i}(lI:uI,4))]);
            data{7,c} = sprintf('%0.1f mm', Rq);
            Event(['Rq = ', data{7,c}]);
            
            % Calculate G
            data{8,c} = sprintf('%0.2f', Rp/(Rp-Rq));
            Event(['G = ', data{8,c}]);
            
            % Calculate Ep0
            data{9,c} = sprintf('%0.2f MeV', ...
                polyval([0.0025 1.98 0.22], Rp/10));
            Event(['Ep0 = ', data{9,c}]);
            
            % Calculate E0
            data{10,c} = sprintf('%0.2f MeV', 2.33 * M/10);
            Event(['E0 = ', data{10,c}]);
            
            % Calculate bremsstrahlung contamination at R10 + 10cm
            R10 = interp1(u, profiles{i}(lI+idx-1,3), 0.1 * ...
                max(profiles{i}(lI:uI,4)), 'linear');
            Event(sprintf('R10 identified at %0.1f mm', R10));
            if max(profiles{i}(:,3)) > R10+100
                Event(sprintf(['Extracting bremsstrahlung contamination ', ...
                    'at %0.1f mm depth (R10 + 10 cm)'], R10+100));
                data{11,c} = sprintf('%0.2f%%', interp1(profiles{i}(:,3), ...
                    profiles{i}(:,4), R10+100, 'linear') / ...
                    max(profiles{i}(lI:uI,4)) * 100);   
            else
                Event(sprintf(['Extrapolating bremsstrahlung tail ', ...
                    'contamination to %0.1f mm depth (R10 + 10 cm)'], ...
                    R10+100));
                data{11,c} = sprintf('%0.2f%%', polyval(b, R10+100) / ...
                    max(profiles{i}(lI:uI,4)) * 100);
            end
            Event(['Contamination = ', data{11,c}]);
            
            % Update lower index to use Rp
            [~, lI] = min(abs(profiles{i}(:,3) - Rp));
            
            % Set index for remaining rows
            a = 11;
        end

        % Calculate RMS error
        data{a+1,c} = sprintf('%0.2f%%', sqrt(mean(((profiles{i}(lI:uI,4) - ...
            profiles{i}(lI:uI,5)) ./ profiles{i}(lI:uI,5)).^2)) * 100);
        Event(['Local RMS error = ', data{a+1,c}]);
        
        % Calculate Max error
        data{a+2,c} = sprintf('%0.2f%%', max((profiles{i}(lI:uI,4) - ...
            profiles{i}(lI:uI,5)) ./ profiles{i}(lI:uI,5)) * 100);
        Event(['Local Max error = ', data{a+2,c}]);
        
        % Calculate Mean Gamma
        data{a+3,c} = sprintf('%0.2f', mean(profiles{i}(lI:uI,6)));
        Event(['Mean Gamma index = ', data{a+3,c}]);
        
        % Calculate Max Gamma
        data{a+4,c} = sprintf('%0.2f', max(profiles{i}(lI:uI,6)));
        Event(['Max Gamma index = ', data{a+4,c}]);
        
        % Calculate Gamma Pass Rate
        data{a+5,c} = sprintf('%0.1f%%', sum(profiles{i}(lI:uI,6) < 1) / ...
            length(lI:uI) * 100);
        Event(['Gamma pass rate = ', data{a+5,c}]);
        
    end
end
