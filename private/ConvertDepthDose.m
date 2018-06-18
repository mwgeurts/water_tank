function profiles = ConvertDepthDose(varargin)
% CovnertDepthDose converts depth-ionization curves to depth-dose for a 
% cell array of profiles by a specified algorithm. If called with no 
% inputs, it will return a list of available algorithms that can be used. 
% If called with inputs, the first must be the name of the file, the 
% second is an integer corresponding to the algorithm.
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
    'None'
    'AAPM TG-25'
    'AAPM TG-51'
    'DIN 6800-2'
    'IAEA TRS-398'
};

% If no input arguments are provided
if nargin == 0
    
    % Return the options
    profiles = options;
    
    % Stop execution
    return;
end

% Execute code block based on format provided in varargin{2}
switch varargin{2}
    
    % No conversion
    case 1
        
        % Return raw profile
        profiles = varargin{1};
       
    % AAPM TG-25 or TG-51
    case {2, 3}
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action
        if varargin{2} == 2
            Event(['Converting electron beam ionization to dose ', ...
                'according to AAPM TG-25']);
        else
            Event(['Converting electron beam ionization to dose ', ...
                'according to AAPM TG-51']);
        end
        
        % Loop through each profile
        for i = 1:length(profiles)
        
            % If Z changes, this is an depth profile
            if (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1

                % Find the index of Dmax
                uI = find(profiles{i}(:,4) == ...
                    max(profiles{i}(:,4)), 1, 'first');

                % Find the index of 5% of Dmax
                lI = find(profiles{i}(:,4) > 0.05 * ...
                    max(profiles{i}(:,4)), 1, 'first');
                
                % Remove duplicate points (they will cause interp1 to fail)
                [u, idx, ~] = unique(profiles{i}(lI:uI,4));
                Event(sprintf(['Removed %i duplicate signal values for R50 ', ...
                    'interpolation'], uI - lI - length(u) + 1));

                % Calculate I50 in cm
                I50 = interp1(u, profiles{i}(lI+idx-1,3), 0.5 * ...
                    max(profiles{i}(lI:uI,4)), 'linear')/10;
                Event(sprintf('I50 = %0.2f cm', I50));
                
                % Compute R50 in cm
                if I50 <= 100
                    Event('I50 < 10 cm, using 1.029 * I50 - 0.06');
                    R50 = 1.029 * I50 - 0.06;
                else
                    Event('I50 > 10 cm, using 1.059 * I50 - 0.37');
                    R50 = 1.059 * I50 - 0.37;
                end
                Event(sprintf('R50 = %0.2f cm', R50));
                
                % If sufficient data exists to estimate bremsstrahlung tail
                if nargin > 2 && isfield(varargin{3}, 'BREM_METHOD') && ...
                        strcmp('LINEAR_FIT', varargin{3}.BREM_METHOD) && lI > 3

                    % Fit bremsstrahlung tail to linear model
                    b = fit(profiles{i}(1:lI,3), profiles{i}(1:lI,4), 'poly1', ...
                        'Weights', (max(profiles{i}(1:lI,4)) - ...
                        profiles{i}(1:lI,4)) .^ 2);
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
                [~, I] = max(abs(diff(profiles{i}(lI:uI,4)) ./ ...
                    diff(profiles{i}(lI:uI,3))));
                xl = find(profiles{i}(:,3) < ...
                    profiles{i}(lI+I,3) + 2, 1, 'first');
                xr = find(profiles{i}(:,3) < ...
                    profiles{i}(lI+I,3) - 2, 1, 'first');
                p = polyfit(profiles{i}(xl:xr+1,3), ...
                    profiles{i}(xl:xr+1,4), 1);
                Event(sprintf('Rp tangent fit coefficients = [%g %g]', p));
                Rp = roots(p-b);
                Event(sprintf('Rp = %0.2f cm', Rp/10));
                
                % Calculate mean energy for each depth
                Event('Calculating mean energy at depth per AAPM TG-25');
                E = double(2.33 * R50 * (1 - profiles{i}(:,3)/Rp));
                
                % Apply TG-25 stopping power ratios
                if varargin{2} == 2
                    
                    % Specify Table II from TG-25 (0 MeV is extrapolated)
                    tableii = ...
                       [0.902 0.904 0.912 0.928 0.940 0.955 0.961 0.969 0.977 0.986 0.997 1.003 1.011 1.029 1.040 1.059 1.078 1.097 1.116
                        0.902 0.905 0.913 0.929 0.941 0.955 0.962 0.969 0.978 0.987 0.998 1.005 1.012 1.030 1.042 1.061 1.081 1.101 1.124
                        0.903 0.906 0.914 0.930 0.942 0.956 0.963 0.970 0.978 0.988 0.999 1.006 1.013 1.032 1.044 1.064 1.084 1.106 1.131
                        0.904 0.907 0.915 0.931 0.943 0.957 0.964 0.971 0.979 0.989 1.000 1.007 1.015 1.034 1.046 1.067 1.089 1.112 1.135
                        0.904 0.908 0.916 0.932 0.944 0.958 0.965 0.972 0.980 0.990 1.002 1.009 1.017 1.036 1.050 1.071 1.093 1.117 1.136
                        0.905 0.909 0.917 0.933 0.945 0.959 0.966 0.973 0.982 0.991 1.003 1.010 1.019 1.039 1.054 1.076 1.098 1.122 1.136
                        0.906 0.909 0.918 0.934 0.946 0.960 0.967 0.974 0.983 0.993 1.005 1.012 1.021 1.043 1.058 1.081 1.103 1.126 1.136
                        0.907 0.911 0.920 0.936 0.948 0.962 0.969 0.976 0.985 0.996 1.009 1.016 1.026 1.050 1.067 1.090 1.113 1.133 1.136
                        0.908 0.913 0.922 0.938 0.950 0.964 0.971 0.979 0.988 0.999 1.013 1.021 1.031 1.058 1.076 1.099 1.121 1.133 1.136
                        0.909 0.914 0.924 0.940 0.952 0.966 0.973 0.981 0.991 1.002 1.017 1.026 1.037 1.066 1.085 1.108 1.129 1.133 1.136
                        0.910 0.916 0.925 0.942 0.954 0.968 0.976 0.984 0.994 1.006 1.022 1.032 1.044 1.075 1.095 1.117 1.133 1.133 1.136
                        0.912 0.917 0.927 0.944 0.956 0.971 0.978 0.987 0.997 1.010 1.027 1.038 1.050 1.084 1.104 1.124 1.133 1.133 1.136
                        0.913 0.918 0.929 0.945 0.957 0.973 0.981 0.990 1.001 1.014 1.032 1.044 1.057 1.093 1.112 1.130 1.133 1.133 1.136
                        0.914 0.920 0.930 0.947 0.959 0.975 0.983 0.993 1.004 1.018 1.038 1.050 1.065 1.101 1.120 1.133 1.133 1.133 1.136
                        0.917 0.923 0.934 0.952 0.964 0.981 0.990 1.000 1.013 1.030 1.053 1.067 1.083 1.120 1.131 1.133 1.133 1.133 1.136
                        0.919 0.926 0.938 0.956 0.969 0.987 0.997 1.008 1.023 1.042 1.069 1.084 1.102 1.129 1.131 1.133 1.133 1.133 1.136
                        0.922 0.929 0.941 0.960 0.974 0.994 1.004 1.017 1.034 1.056 1.085 1.102 1.118 1.129 1.131 1.133 1.133 1.133 1.136
                        0.924 0.932 0.944 0.964 0.979 1.001 1.012 1.027 1.046 1.071 1.101 1.116 1.126 1.129 1.131 1.133 1.133 1.133 1.136
                        0.927 0.935 0.948 0.969 0.985 1.008 1.021 1.037 1.059 1.086 1.115 1.125 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        0.929 0.938 0.951 0.973 0.990 1.016 1.030 1.049 1.072 1.101 1.123 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        0.931 0.940 0.954 0.978 0.996 1.024 1.040 1.061 1.086 1.113 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        0.934 0.943 0.958 0.983 1.002 1.033 1.051 1.074 1.100 1.121 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        0.938 0.948 0.965 0.993 1.017 1.054 1.075 1.099 1.118 1.122 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        0.943 0.954 0.972 1.005 1.032 1.076 1.098 1.116 1.120 1.122 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        0.947 0.960 0.981 1.018 1.049 1.098 1.114 1.118 1.120 1.122 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        0.952 0.966 0.990 1.032 1.068 1.112 1.116 1.118 1.120 1.122 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        0.962 0.980 1.009 1.062 1.103 1.112 1.116 1.118 1.120 1.122 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        0.973 0.996 1.031 1.095 1.107 1.112 1.116 1.118 1.120 1.122 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        0.986 1.013 1.056 1.103 1.107 1.112 1.116 1.118 1.120 1.122 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        1.000 1.031 1.080 1.103 1.107 1.112 1.116 1.118 1.120 1.122 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        1.016 1.051 1.094 1.103 1.107 1.112 1.116 1.118 1.120 1.122 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        1.032 1.070 1.094 1.103 1.107 1.112 1.116 1.118 1.120 1.122 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        1.048 1.082 1.094 1.103 1.107 1.112 1.116 1.118 1.120 1.122 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        1.062 1.085 1.094 1.103 1.107 1.112 1.116 1.118 1.120 1.122 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        1.071 1.085 1.094 1.103 1.107 1.112 1.116 1.118 1.120 1.122 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136
                        1.075 1.085 1.094 1.103 1.107 1.112 1.116 1.118 1.120 1.122 1.125 1.126 1.127 1.129 1.131 1.133 1.133 1.133 1.136];
                    
                    [meshe, meshd] = meshgrid([60 50 40 30 25 20 18 16 14 12 10 9 8 6 5 4 3 2 1], ...
                        [0:0.1:0.5, 0.6:0.2:2, 2.5:0.5:6, 7:10, 12:2:30]);
                    
                    % Interpolate stopping power ratios and apply to signal
                    Event(['Calculating stopping power ratio from AAPM ', ...
                        'TG-25 Table II']);
                    profiles{i}(:,4) = max(profiles{i}(:,4) - polyval(b, ...
                        profiles{i}(:,3)), 0) .* interp2(meshe, meshd, tableii, ...
                        max(E), double(profiles{i}(:,3)/10), 'linear', 1) + ...
                        polyval(b, profiles{i}(:,3));
                    
                % Apply TG-51 stopping power ratios
                elseif varargin{2} == 3
                    
                    % Find range of indices to apply correction (0.02 to 1.2)
                    lI = find(profiles{i}(:,3) / (10 * R50) < 1.2, 1, 'first');
                    uI = find(profiles{i}(:,3) / (10 * R50) > 0.02, 1, 'last');
                    Event(sprintf('2%% to 120%% R50 index range = [%i %i]', ...
                        lI, uI));

                    % Scale depth profile by Burns et al. empirical stopping
                    % power ratio fit
                    Event('Applying Burns empirical stopping power ratio model');
                    profiles{i}(lI:uI,4) = profiles{i}(lI:uI,4) .* (1.0752 - ...
                        0.50867 * log(R50) + 0.08867 * log(R50)^2 - 0.08402 * ...
                        profiles{i}(lI:uI,3)/(10 * R50)) ./ (1 - 0.42806 * log(R50) ...
                        + 0.064627 * log(R50)^2 + 0.003085 * log(R50)^3 - 0.12460 * ...
                        profiles{i}(lI:uI,3)/(10 * R50));
                end
                
                % Specify Table V from TG-25 (0 MeV is extrapolated)
                tablev = [1 0.975 0.954 0.950 0.943
                          1 0.977 0.962 0.956 0.949
                          1 0.978 0.966 0.959 0.952
                          1 0.982 0.971 0.965 0.960
                          1 0.986 0.977 0.972 0.967
                          1 0.990 0.985 0.981 0.978
                          1 0.995 0.992 0.991 0.990
                          1 0.997 0.996 0.995 0.995];
                [meshr, meshe] = meshgrid([0 3 5 6 7], ...
                    [0 2 3 5 7 10 15 20]);
                      
                % If a cavity radius is provided and within range
                if nargin > 3 && isnumeric(varargin{4}) && ...
                        varargin{4} <= 7
                    
                    % Interpolate Prepl and scale the profile. Note, the
                    % bremsstrahlung component is removed during the
                    % scaling to improve continuity
                    Event('Calculating Prepl from AAPM TG-25 Table V');
                    profiles{i}(:,4) = max(profiles{i}(:,4) - polyval(b, ...
                        profiles{i}(:,3)), 0) .* interp2(meshr, meshe, ...
                        tablev, varargin{4}, E, 'linear', 1) + polyval(b, ...
                        profiles{i}(:,3));
                   
                % Otherwise Rcav is invalid
                else
                    Event(['Rcav is not specified or out of range; ', ...
                        'Prepl will not be applied'], 'WARN');
                end
            end
        end 
        
        % Clear temporary variables
        clear i I50 R50 lI uI u idx b E I meshd meshe meshr p Rp tablev ...
            tableii xl xr;
        
    % DIN 6800-2
    case 4
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action
        Event(['Converting electron beam ionization to dose ', ...
            'according to DIN 6800-2']);
        
        % Loop through each profile
        for i = 1:length(profiles)
        
            % If Z changes, this is an depth profile
            if (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1

                % Find the index of Dmax
                uI = find(profiles{i}(:,4) == ...
                    max(profiles{i}(:,4)), 1, 'first');

                % Find the index of 5% of Dmax
                lI = find(profiles{i}(:,4) > 0.05 * ...
                    max(profiles{i}(:,4)), 1, 'first');
                
                % Remove duplicate points (they will cause interp1 to fail)
                [u, idx, ~] = unique(profiles{i}(lI:uI,4));
                Event(sprintf(['Removed %i duplicate signal values for R50 ', ...
                    'interpolation'], uI - lI - length(u) + 1));

                % Calculate I50 in cm
                I50 = interp1(u, profiles{i}(lI+idx-1,3), 0.5 * ...
                    max(profiles{i}(lI:uI,4)), 'linear')/10;
                Event(sprintf('I50 = %0.2f cm', I50));
                
                % Compute R50 in cm
                if I50 <= 100
                    Event('I50 < 10 cm, using 1.029 * I50 - 0.06');
                    R50 = 1.029 * I50 - 0.06;
                else
                    Event('I50 > 10 cm, using 1.059 * I50 - 0.37');
                    R50 = 1.059 * I50 - 0.37;
                end
                Event(sprintf('R50 = %0.2f cm', R50));
                
                % Find range of indices to apply correction (0.02 to 1.2)
                lI = find(profiles{i}(:,3) / (10 * R50) < 1.2, 1, 'first');
                uI = find(profiles{i}(:,3) / (10 * R50) > 0.02, 1, 'last');
                Event(sprintf('2%% to 120%% R50 index range = [%i %i]', ...
                    lI, uI));

                % Scale depth profile by Burns et al. empirical stopping
                % power ratio fit
                Event('Applying Burns empirical stopping power ratio model');
                profiles{i}(lI:uI,4) = profiles{i}(lI:uI,4) .* (1.0752 - ...
                    0.50867 * log(R50) + 0.08867 * log(R50)^2 - 0.08402 * ...
                    profiles{i}(lI:uI,3)/(10 * R50)) ./ (1 - 0.42806 * log(R50) ...
                    + 0.064627 * log(R50)^2 + 0.003085 * log(R50)^3 - 0.12460 * ...
                    profiles{i}(lI:uI,3)/(10 * R50)); 
                
                % If a cavity radius is provided and within range
                if nargin > 3 && isnumeric(varargin{4})
                
                    % Log action
                    Event(sprintf(['Calculating Prepl assuming cylindrical ', ...
                        'chamber with radius = %0.3f cm'], varargin{4}/10));
                    
                    % Calculate Prepl from fitted equation
                    profiles{i}(:,4) = profiles{i}(:,4) .* (1 - ...
                        0.02155 * varargin{4}/10 * exp(-0.2525 * R50 * ...
                        max(1 - profiles{i}(:,3)/(1.271 * R50 - 0.23), 0)));
                    
                % Otherwise Rcav is invalid
                else
                    Event(['Rcav is not specified or out of range; ', ...
                        'Prepl will not be applied'], 'WARN');
                end
            end
        end
        
        % Clear temporary variables
        clear i I50 R50 lI uI u idx;
        
    % IAEA TRS-398
    case 5
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action
        Event(['Converting electron beam ionization to dose ', ...
            'according to IAEA TRS-398']);
        
        % Loop through each profile
        for i = 1:length(profiles)
        
            % If Z changes, this is an depth profile
            if (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1

                % Find the index of Dmax
                uI = find(profiles{i}(:,4) == ...
                    max(profiles{i}(:,4)), 1, 'first');

                % Find the index of 5% of Dmax
                lI = find(profiles{i}(:,4) > 0.05 * ...
                    max(profiles{i}(:,4)), 1, 'first');
                
                % Remove duplicate points (they will cause interp1 to fail)
                [u, idx, ~] = unique(profiles{i}(lI:uI,4));
                Event(sprintf(['Removed %i duplicate signal values for R50 ', ...
                    'interpolation'], uI - lI - length(u) + 1));

                % Calculate I50 in cm
                I50 = interp1(u, profiles{i}(lI+idx-1,3), 0.5 * ...
                    max(profiles{i}(lI:uI,4)), 'linear')/10;
                Event(sprintf('I50 = %0.2f cm', I50));
                
                % Compute R50 in cm
                if I50 <= 100
                    Event('I50 < 10 cm, using 1.029 * I50 - 0.06');
                    R50 = 1.029 * I50 - 0.06;
                else
                    Event('I50 > 10 cm, using 1.059 * I50 - 0.37');
                    R50 = 1.059 * I50 - 0.37;
                end
                Event(sprintf('R50 = %0.2f cm', R50));
                
                % Find range of indices to apply correction (0.02 to 1.2)
                lI = find(profiles{i}(:,3) / (10 * R50) < 1.2, 1, 'first');
                uI = find(profiles{i}(:,3) / (10 * R50) > 0.02, 1, 'last');
                Event(sprintf('2%% to 120%% R50 index range = [%i %i]', ...
                    lI, uI));

                % Scale depth profile by Burns et al. empirical stopping
                % power ratio fit
                Event('Applying Burns empirical stopping power ratio model');
                profiles{i}(lI:uI,4) = profiles{i}(lI:uI,4) .* (1.0752 - ...
                    0.50867 * log(R50) + 0.08867 * log(R50)^2 - 0.08402 * ...
                    profiles{i}(lI:uI,3)/(10 * R50)) ./ (1 - 0.42806 * log(R50) ...
                    + 0.064627 * log(R50)^2 + 0.003085 * log(R50)^3 - 0.12460 * ...
                    profiles{i}(lI:uI,3)/(10 * R50)); 
                
                % If a cavity radius is provided, this is a cylindrical
                % chamber
                if nargin > 3 && isnumeric(varargin{4}) && varargin{4} > 1
                    Event(['IAEA TRS-398 does not recommend using ', ...
                        'cylindrical chambers for electron beams'], 'WARN');
                end
            end
        end
        
        % Clear temporary variables
        clear i I50 R50 lI uI u idx;
end
