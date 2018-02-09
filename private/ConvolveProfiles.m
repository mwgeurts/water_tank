function profiles = ConvolveProfiles(varargin)
% ConvolveProfiles performs a convolution of each reference profile to 
% account for detector volume.
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
    'Optimized Gaussian'
    'Optimized Lorentzian'
    'Looe Gaussian'
};

% If no input arguments are provided
if nargin == 0
    
    % Return the options
    profiles = options;
    
    % Stop execution
    return;
end

% Execute code block based on algorithm provided in varargin{2}
switch varargin{2}
    
    % No deconvolution
    case 1
        
        % Return raw profile
        profiles = varargin{1};
        
    % Optimized Gaussian
    case 2
        
        % Specify number of iterations and step size
        iters = 100;
        step = 0.1;
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action
        if exist('Event', 'file') == 2
            Event('Computing the optimal Gaussian fit for each profile');
        end
        
        % Verify rcav exists
        if nargin < 4 || ~isnumeric(varargin{4}) || varargin{4} <= 0
            if exist('Event', 'file') == 2
                Event(['A chamber radius was not specified, setting max', ...
                    'sigma to 10 mm.'], 'WARN');
            end
            varargin{4} = 5;
        end
        
        % Log parameters
        if exist('Event', 'file') == 2
            Event(sprintf(['Sigma search range = [%0.3f %0.3f] mm, ', ...
                'iterations = %i, step = %0.2f'], 0.001, 2*varargin{4}, ...
                iters, step));
        end

        % Loop through each profile
        for i = 1:length(profiles)
            
            % Set starting range of standard deviations
            sigma = [0.001, 2*varargin{4}];
            t = tic;
            
            % If X and Y changes, this is a diagonal profile
            if (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1 && ...
                    (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
                x = sqrt(profiles{i}(:,1).^2 + profiles{i}(:,2).^2) .* ...
                    sign(profiles{i}(:,1));
            
            % If only X changes, this is an X profile
            elseif (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1
                x = profiles{i}(:,1);
                
            % Otherwise, if only Y changes, this is a Y profile
            elseif (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
                x = profiles{i}(:,2);
                
            % Otherwise, if Z changes, this is a depth profile
            elseif (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1
                x = profiles{i}(:,3);
            end
            
            % Convolve the profile at the low end
            y = NormConvolve(x, profiles{i}(:,5), sigma(1), 0.1);
            sumsq(1) = sum((profiles{i}(:,4)/max(profiles{i}(:,4)) - ...
                y/max(y)).^2);
            
            % Convolve the profile at the high end
            y = NormConvolve(x, profiles{i}(:,5), sigma(2), 0.1);
            sumsq(2) = sum((profiles{i}(:,4)/max(profiles{i}(:,4)) - ...
                y/max(y)).^2);
            
            % Loop through iterations
            for j = 1:iters
                
                % Move range and update sigma, y, and sumsq
                if isnan(sumsq(1)) || sumsq(1) > sumsq(2)
                    sigma(1) = sigma(1) + (sigma(2)-sigma(1)) * 0.1;
                    y = NormConvolve(x, profiles{i}(:,5), sigma(1), 0.1);
                    sumsq(1) = sum((profiles{i}(:,4)/max(profiles{i}(:,4)) - ...
                        y/max(y)).^2);
                else
                    sigma(2) = sigma(2) - (sigma(2)-sigma(1)) * 0.1;
                    y = NormConvolve(x, profiles{i}(:,5), sigma(2), 0.1);
                    sumsq(2) = sum((profiles{i}(:,4)/max(profiles{i}(:,4)) - ...
                        y/max(y)).^2);
                end
            end
            
            % Return minimal error
            if exist('Event', 'file') == 2
                Event(sprintf(['Profile %i optimal Gaussian sigma = %0.3f ', ...
                    'mm +/- %0.3f mm, RMS error = %0.3e, %0.3f seconds'], i, ...
                    (sigma(1)+sigma(2))/2, sigma(2)-sigma(1), ...
                    sqrt((sumsq(1)+sumsq(2))/(2*length(y))), toc(t)));
            end
            profiles{i}(:,5) = NormConvolve(x, profiles{i}(:,5), ...
                (sigma(1)+sigma(2))/2, 0.1);
        end
        
    % Optimized Lorentzian
    case 3
        
        % Specify number of iterations and step size
        iters = 50;
        step = 0.1;
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action
        if exist('Event', 'file') == 2
            Event('Computing the optimal Lorentz fit for each profile');
        end
        
        % Verify rcav exists
        if nargin < 4 || ~isnumeric(varargin{4}) || varargin{4} <= 0
            if exist('Event', 'file') == 2
                Event(['A chamber radius was not specified, setting max', ...
                    'lambda to 5 mm.'], 'WARN');
            end
            varargin{4} = 5;
        end
        
        % Log parameters
        if exist('Event', 'file') == 2
            Event(sprintf(['Lambda search range = [%0.3f %0.3f] mm, ', ...
                'iterations = %i, step = %0.2f'], 0.001, varargin{4}, ...
                iters, step));
        end

        % Loop through each profile
        for i = 1:length(profiles)
            
            % Set starting range of lambda values
            lambda = [0.001, varargin{4}];
            t = tic;
            
            % If X and Y changes, this is a diagonal profile
            if (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1 && ...
                    (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
                x = sqrt(profiles{i}(:,1).^2 + profiles{i}(:,2).^2) .* ...
                    sign(profiles{i}(:,1));
            
            % If only X changes, this is an X profile
            elseif (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1
                x = profiles{i}(:,1);
                
            % Otherwise, if only Y changes, this is a Y profile
            elseif (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
                x = profiles{i}(:,2);
                
            % Otherwise, if Z changes, this is a depth profile
            elseif (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1
                x = profiles{i}(:,3);
            end
            
            % Convolve the profile at the low end
            y = LorentzConvolve(x, profiles{i}(:,5), lambda(1), 0.1);
            sumsq(1) = sum((profiles{i}(:,4)/max(profiles{i}(:,4)) - ...
                y/max(y)).^2);
            
            % Convolve the profile at the high end
            y = LorentzConvolve(x, profiles{i}(:,5), lambda(2), 0.1);
            sumsq(2) = sum((profiles{i}(:,4)/max(profiles{i}(:,4)) - ...
                y/max(y)).^2);
            
            % Loop through iterations
            for j = 1:iters
                
                % Move range and update sigma, y, and sumsq
                if isnan(sumsq(1)) || sumsq(1) > sumsq(2)
                    lambda(1) = lambda(1) + (lambda(2)-lambda(1)) * 0.1;
                    y = LorentzConvolve(x, profiles{i}(:,5), lambda(1), 0.1);
                    sumsq(1) = sum((profiles{i}(:,4)/max(profiles{i}(:,4)) - ...
                        y/max(y)).^2);
                else
                    lambda(2) = lambda(2) - (lambda(2)-lambda(1)) * 0.1;
                    y = LorentzConvolve(x, profiles{i}(:,5), lambda(2), 0.1);
                    sumsq(2) = sum((profiles{i}(:,4)/max(profiles{i}(:,4)) - ...
                        y/max(y)).^2);
                end
            end
            
            % Return minimal error
            if exist('Event', 'file') == 2
                Event(sprintf(['Profile %i optimal Lorentz lambda = %0.3f ', ...
                    'mm +/- %0.3f mm, RMS error = %0.3e, %0.3f seconds'], i, ...
                    (lambda(1)+lambda(2))/2, lambda(2)-lambda(1), ...
                    sqrt((sumsq(1)+sumsq(2))/(2*length(y))), toc(t)));
            end
            profiles{i}(:,5) = LorentzConvolve(x, profiles{i}(:,5), ...
                (lambda(1)+lambda(2))/2, 0.1);
        end
        
    % Looe et al Gaussian approximation
    case 4
        
        % Define list of standard deviation parameters (6 MV lat, 15 MV
        % lat, 6 MV long, 15 MV long
        parameters = {
            'PTW 31014 PinPoint'	0.99    0.99    1.98    2.02
            'PTW 31015 PinPoint'    1.40    1.49	2.23    2.30
            'PTW 31016 PinPoint 3D'	1.38    1.38	1.78    1.90
            'PTW 31010 SemiFlex'    2.20    2.30	2.28    2.50
            'PTW 31013 SemiFlex'    2.41    2.44	4.87    5.05
            'IBA CC01'              0.69    0.71	1.18    1.24
            'IBA CC04'              1.49    1.51	1.49    1.51
            'IBA CC08'              2.04    2.22	1.73    2.00
            'IBA CC13'              2.26    2.38	2.26    2.38
        };
    
        % Start with raw profile
        profiles = varargin{1};
    
        % If inputs were not provided or the chamber doesn't match the
        % above list, inform the user
        if nargin < 5 || ~ismember(varargin{3}, parameters(:,1))
            if exist('Event', 'file') == 2
                Event(['The provided energy and chamber were not provided ', ...
                    'or the chamber is not in the list available for this ', ...
                    'deconvolution. Profiles will not be deconvolved.'], ...
                    'WARN');
            else
                warning(['The provided energy and chamber were not provided ', ...
                    'or the chamber is not in the list available for this ', ...
                    'deconvolution. Profiles will not be deconvolved.']);
            end
            h = warndlg(['The provided energy and chamber were not provided ', ...
                    'or the chamber is not in the list available for this ', ...
                    'deconvolution. Profiles will not be deconvolved.']);
            uiwait(h);
            return;
        end
        
        % Parse out energy
        energy = regexp(varargin{5}, '(\d+)[ ]?(e)?', 'tokens');
        
        % Retrieve parameters based on chamber and energy
        if str2double(energy{1}{1}) <= 10.5
            latstd = parameters{find(strcmp(varargin{3}, ...
                parameters(:,1)), 1, 'first'), 2};
            longstd = parameters{find(strcmp(varargin{3}, ...
                parameters(:,1)), 1, 'first'), 4};
        else
            latstd = parameters{find(strcmp(varargin{3}, ...
                parameters(:,1)), 1, 'first'), 3};
            longstd = parameters{find(strcmp(varargin{3}, ...
                parameters(:,1)), 1, 'first'), 5};
        end
        
        % Log action
        if exist('Event', 'file') == 2
            Event(sprintf(['Convolving reference profiles using Looe ', ...
                'Gaussian analytical model with parameters %0.2f mm, ', ...
                '%0.2f mm'], latstd, longstd));
        end
        
        % Loop through each profile
        for i = 1:length(profiles)
            
            % If X and Y changes, this is a diagonal profile
            if (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1 && ...
                    (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
            
                % Calculate diagonal profile
                x = sqrt(profiles{i}(:,1).^2 + profiles{i}(:,2).^2) .* ...
                    sign(profiles{i}(:,1));
                
                % Execute NormConvolve using lateral model (assumes 
                % detector cylinder is perpendicular to scan direction)
                profiles{i}(:,5) = NormConvolve(x, profiles{i}(:,5), ...
                    latstd, 0.1);

            % If only X changes, this is an X profile
            elseif (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1
                
                % Execute NormConvolve using lateral model (assumes 
                % detector cylinder is perpendicular to scan direction)
                profiles{i}(:,5) = NormConvolve(profiles{i}(:,1), ...
                    profiles{i}(:,5), latstd, 0.1);
                
            % Otherwise, if only Y changes, this is a Y profile
            elseif (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
                
                % Execute NormConvolve using longitudinal model (assumes 
                % detector cylinder is perpendicular to scan direction)
                profiles{i}(:,5) = NormConvolve(profiles{i}(:,2), ...
                    profiles{i}(:,5), longstd, 0.1);
                
            % Otherwise, if Z changes, this is a depth profile
            elseif (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1
                
                % Execute NormConvolve using lateral model (assumes 
                % detector cylinder is perpendicular to scan direction)
                profiles{i}(:,5) = NormConvolve(profiles{i}(:,3), ...
                    profiles{i}(:,5), latstd, 0.1);
            end
        end
end