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

% Persistently store chamber orientation
persistent orient;

% Specify options and order
options = {
    'None'
    'Optimized Gaussian'
    'Optimized Lorentzian'
    'Optimized Parabolic'
    'Fox, 2010'
    'Herrup, 2005'
    'Looe, 2013'
    'Sahoo, 2008'
    'Sibata, 1991'
};

% If no input arguments are provided
if nargin == 0
    
    % Return the options
    profiles = options;
    
    % Reset scan orientations
    orient = zeros(4,1);
    
    % Stop execution
    return;
end

% Initialize persistent variable
if exist('orient', 'var') == 0 || isempty(orient)
    orient = zeros(4,1);
end

% Execute code block based on algorithm provided in varargin{2}
switch varargin{2}
    
    % No deconvolution
    case 1
        
        % Return raw profile
        profiles = varargin{1};
        
    % Optimized functions
    case {2, 3, 4}
        
        % Specify number of iterations and step size
        iters = 100;
        step = 0.1;
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action
        if exist('Event', 'file') == 2
            if varargin{2} == 2
                Event('Computing the optimal Gaussian fit for each profile');
            elseif varargin{2} == 3
                Event('Computing the optimal Lorentzian fit for each profile');
            else
                Event('Computing the optimal Parabolic fit for each profile');
            end
        end
        
        % Verify rcav exists
        if nargin < 4 || ~isnumeric(varargin{4}) || varargin{4} <= 0
            if exist('Event', 'file') == 2
                Event(['A chamber radius was not specified, setting max', ...
                    'search range to default.'], 'WARN');
            end
            varargin{4} = 5;
        end
        
        % Log parameters
        if exist('Event', 'file') == 2
            if varargin{2} == 2
                Event(sprintf(['Sigma search range = [%0.3f %0.3f] mm, ', ...
                    'iterations = %i, step = %0.2f'], 0.001, 2*varargin{4}, ...
                    iters, step));
            elseif varargin{2} == 3
                Event(sprintf(['Lambda search range = [%0.3f %0.3f] mm, ', ...
                'iterations = %i, step = %0.2f'], 0.001, varargin{4}, ...
                iters, step));
            else
                Event(sprintf(['Radius search range = [%0.3f %0.3f] mm, ', ...
                    'iterations = %i, step = %0.2f'], 0.001, 3*varargin{4}, ...
                    iters, step));
            end
        end

        % Loop through each profile
        for i = 1:length(profiles)
            
            % Set starting range of standard deviations
            if varargin{2} == 2
                sigma = [0.001, 2*varargin{4}];
            elseif varargin{2} == 3
                lambda = [0.001, varargin{4}];
            else
                radius = [0.001, 3*varargin{4}];
            end
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
            if varargin{2} == 2
                y = NormConvolve(x, profiles{i}(:,5), sigma(1), 0.1);
            elseif varargin{2} == 3
                y = LorentzConvolve(x, profiles{i}(:,5), lambda(1), 0.1);
            else
                y = ParabolicConvolve(x, profiles{i}(:,5), radius(1), 0.1);
            end
            sumsq(1) = sum((profiles{i}(:,4)/max(profiles{i}(:,4)) - ...
                y/max(y)).^2);
            
            % Convolve the profile at the high end
            if varargin{2} == 2
                y = NormConvolve(x, profiles{i}(:,5), sigma(2), 0.1);
            elseif varargin{2} == 3
                y = LorentzConvolve(x, profiles{i}(:,5), lambda(2), 0.1);
            else
                y = ParabolicConvolve(x, profiles{i}(:,5), radius(2), 0.1);
            end
            sumsq(2) = sum((profiles{i}(:,4)/max(profiles{i}(:,4)) - ...
                y/max(y)).^2);
            
            % Loop through iterations
            for j = 1:iters
                
                % Move range and update sigma, y, and sumsq
                if isnan(sumsq(1)) || sumsq(1) > sumsq(2)
                    if varargin{2} == 2
                        sigma(1) = sigma(1) + (sigma(2)-sigma(1)) * 0.1;
                        y = NormConvolve(x, profiles{i}(:,5), sigma(1), 0.1);
                    elseif varargin{2} == 3
                        lambda(1) = lambda(1) + (lambda(2)-lambda(1)) * 0.1;
                        y = LorentzConvolve(x, profiles{i}(:,5), lambda(1), 0.1);
                    else
                        radius(1) = radius(1) + (radius(2)-radius(1)) * 0.1;
                        y = ParabolicConvolve(x, profiles{i}(:,5), radius(1), 0.1);
                    end
                    sumsq(1) = sum((profiles{i}(:,4)/max(profiles{i}(:,4)) - ...
                        y/max(y)).^2);
                else
                    if varargin{2} == 2
                        sigma(2) = sigma(2) - (sigma(2)-sigma(1)) * 0.1;
                        y = NormConvolve(x, profiles{i}(:,5), sigma(2), 0.1);
                    elseif varargin{2} == 3
                        lambda(2) = lambda(2) - (lambda(2)-lambda(1)) * 0.1;
                        y = LorentzConvolve(x, profiles{i}(:,5), lambda(2), 0.1);
                    else
                        radius(2) = radius(2) - (radius(2)-radius(1)) * 0.1;
                        y = ParabolicConvolve(x, profiles{i}(:,5), radius(2), 0.1);
                    end
                    sumsq(2) = sum((profiles{i}(:,4)/max(profiles{i}(:,4)) - ...
                        y/max(y)).^2);
                end
            end
            
            % Return minimal error
            if exist('Event', 'file') == 2
                if varargin{2} == 2
                    Event(sprintf(['Profile %i optimal Gaussian sigma = %0.3f ', ...
                        'mm +/- %0.3f mm, RMS error = %0.3e, %0.3f seconds'], i, ...
                        (sigma(1)+sigma(2))/2, sigma(2)-sigma(1), ...
                        sqrt((sumsq(1)+sumsq(2))/(2*length(y))), toc(t)));
                elseif varargin{2} == 3
                    Event(sprintf(['Profile %i optimal Lorentz lambda = %0.3f ', ...
                        'mm +/- %0.3f mm, RMS error = %0.3e, %0.3f seconds'], i, ...
                        (lambda(1)+lambda(2))/2, lambda(2)-lambda(1), ...
                        sqrt((sumsq(1)+sumsq(2))/(2*length(y))), toc(t)));
                else
                    Event(sprintf(['Profile %i optimal Parabolic radius = %0.3f ', ...
                        'mm +/- %0.3f mm, RMS error = %0.3e, %0.3f seconds'], i, ...
                        (radius(1)+radius(2))/2, radius(2)-radius(1), ...
                        sqrt((sumsq(1)+sumsq(2))/(2*length(y))), toc(t)));
                end
            end
            
            % Compute final convolution
            if varargin{2} == 2
                profiles{i}(:,5) = NormConvolve(x, profiles{i}(:,5), ...
                    (sigma(1)+sigma(2))/2, 0.1);
            elseif varargin{2} == 3
                profiles{i}(:,5) = LorentzConvolve(x, profiles{i}(:,5), ...
                    (lambda(1)+lambda(2))/2, 0.1);
            else
                profiles{i}(:,5) = ParabolicConvolve(x, profiles{i}(:,5), ...
                    (radius(1)+radius(2))/2, 0.1);
            end
        end
           
    % Looe et al and Fox et al empirical Gaussian approximations
    case {5, 7}
        
        % If Looe is selected
        if varargin{2} == 7
            
            % Define list of standard deviation parameters (6 MV lat, 15 MV
            % lat, 6 MV long, 15 MV long
            parameters = {
                'PTW 31014 PinPoint'        0.99    0.99    1.98    2.02
                'PTW 31015 PinPoint'        1.40    1.49	2.23    2.30
                'PTW 31016 PinPoint 3D'     1.38    1.38	1.78    1.90
                'PTW 31010 SemiFlex'        2.20    2.30	2.28    2.50
                'PTW 31013 SemiFlex'        2.41    2.44	4.87    5.05
                'IBA CC01'                  0.69    0.71	1.18    1.24
                'IBA CC04'                  1.49    1.51	1.49    1.51
                'IBA CC08'                  2.04    2.22	1.73    2.00
                'IBA CC13'                  2.26    2.38	2.26    2.38
                'PTW 23343 Markus'          2.37    2.45    2.37    2.45
                'PTW 34001 Roos'          	5.26    5.31    5.26    5.31
                'PTW 10024 729 2D ARRAY'  	2.27    2.37    2.27    2.37
                'PTW 10032 STARCHECK'       1.63    1.73    1.63    1.73
            };
        
        % Otherwise, Fox is selected
        else
            
            % Define list of Table 1 average parameters (lat, long)
            parameters = {
                'IBA CC01'                  1.72    1.52
                'IBA CC04'                  1.99    1.78
                'IBA CC13'                  2.64    2.57
                'IBA FC65-P'                3.03    7.65
            };
        end
    
        % Start with raw profile
        profiles = varargin{1};
    
        % If inputs were not provided or the chamber doesn't match the
        % above list, inform the user
        if nargin < 5 || ~ismember(varargin{3}, parameters(:,1))
            if exist('Event', 'file') == 2
                Event(['The provided energy and chamber were not provided ', ...
                    'or the chamber is not in the list available for this ', ...
                    'convolution. Profiles will not be convolved.'], ...
                    'WARN');
            else
                warning(['The provided energy and chamber were not provided ', ...
                    'or the chamber is not in the list available for this ', ...
                    'convolution. Profiles will not be convolved.']);
            end
            h = warndlg(['The provided energy and chamber were not provided ', ...
                    'or the chamber is not in the list available for this ', ...
                    'convolution. Profiles will not be convolved.']);
            uiwait(h);
            return;
        end

        % If Looe is selected
        if varargin{2} == 7
            
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
                    'Gaussian empirical model with parameters %0.2f mm, ', ...
                    '%0.2f mm'], latstd, longstd));
            end
            
        % Otherwise Fox is selected    
        else
            latstd = parameters{find(strcmp(varargin{3}, ...
                parameters(:,1)), 1, 'first'), 2};
            longstd = parameters{find(strcmp(varargin{3}, ...
                parameters(:,1)), 1, 'first'), 3};
            
            % Log action
            if exist('Event', 'file') == 2
                Event(sprintf(['Convolving reference profiles using Fox ', ...
                    'Gaussian empirical model with parameters %0.2f mm, ', ...
                    '%0.2f mm'], latstd, longstd));
            end
        end
        
        % Loop through each profile
        for i = 1:length(profiles)
            
            % If X and Y changes, this is a diagonal profile
            if (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1 && ...
                    (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
            
                % Calculate diagonal profile
                x = sqrt(profiles{i}(:,1).^2 + profiles{i}(:,2).^2) .* ...
                    sign(profiles{i}(:,1));
                
                % If chamber orientation is not defined for this direction
                if orient(1) == 0 && latstd ~= longstd

                    % Prompt user to select chamber orientation
                    choice = questdlg(['Choose the orientation of the ', varargin{3}, ...
                        ' cylindrical chamber axis during diagonal profile ', ...
                        'aquisition, relative to scan direction:'], ...
                        'Chamber Orientation', ...
                        'Parallel to scan direction', ...
                        'Perpendicular to scan direction', ...
                        'Perpendicular to scan direction');
                    
                    % Store answer in persistent variable
                    if contains(choice, 'Parallel')
                        orient(1) = 1;
                    else
                        orient(1) = 2;
                    end
                end
                
                % Execute NormConvolve
                if orient(1) == 1
                    profiles{i}(:,5) = NormConvolve(x, profiles{i}(:,5), ...
                        latstd, 0.1);
                else
                    profiles{i}(:,5) = NormConvolve(x, profiles{i}(:,5), ...
                        longstd, 0.1);
                end

            % If only X changes, this is an X profile
            elseif (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1
                
                % If chamber orientation is not defined for this direction
                if orient(2) == 0 && latstd ~= longstd

                    % Prompt user to select chamber orientation
                    choice = questdlg(['Choose the orientation of the ', varargin{3}, ...
                        ' cylindrical chamber axis during IEC X profile ', ...
                        'aquisition, relative to scan direction:'], ...
                        'Chamber Orientation', ...
                        'Parallel to scan direction', ...
                        'Perpendicular to scan direction', ...
                        'Perpendicular to scan direction');
                    
                    % Store answer in persistent variable
                    if contains(choice, 'Parallel')
                        orient(2) = 1;
                    else
                        orient(2) = 2;
                    end
                end
                
                % Execute NormConvolve
                if orient(2) == 1
                    profiles{i}(:,5) = NormConvolve(profiles{i}(:,1), ...
                        profiles{i}(:,5), longstd, 0.1);
                else
                    profiles{i}(:,5) = NormConvolve(profiles{i}(:,1), ...
                        profiles{i}(:,5), latstd, 0.1);
                end
                
            % Otherwise, if only Y changes, this is a Y profile
            elseif (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
                
                % If chamber orientation is not defined for this direction
                if orient(3) == 0 && latstd ~= longstd

                    % Prompt user to select chamber orientation
                    choice = questdlg(['Choose the orientation of the ', varargin{3}, ...
                        ' cylindrical chamber axis during IEC Y profile ', ...
                        'aquisition, relative to scan direction:'], ...
                        'Chamber Orientation', ...
                        'Parallel to scan direction', ...
                        'Perpendicular to scan direction', ...
                        'Perpendicular to scan direction');
                    
                    % Store answer in persistent variable
                    if contains(choice, 'Parallel')
                        orient(3) = 1;
                    else
                        orient(3) = 2;
                    end
                end
                
                % Execute NormConvolve
                if orient(3) == 1
                    profiles{i}(:,5) = NormConvolve(profiles{i}(:,2), ...
                        profiles{i}(:,5), longstd, 0.1);
                else
                    profiles{i}(:,5) = NormConvolve(profiles{i}(:,2), ...
                        profiles{i}(:,5), latstd, 0.1);
                end
                
            % Otherwise, if Z changes, this is a depth profile
            elseif (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1
                
                % If chamber orientation is not defined for this direction
                if orient(4) == 0 && latstd ~= longstd

                    % Prompt user to select chamber orientation
                    choice = questdlg(['Choose the orientation of the ', varargin{3}, ...
                        ' cylindrical chamber axis during depth profile ', ...
                        'aquisition, relative to scan direction:'], ...
                        'Chamber Orientation', ...
                        'Parallel to scan direction', ...
                        'Perpendicular to scan direction', ...
                        'Perpendicular to scan direction');
                    
                    % Store answer in persistent variable
                    if contains(choice, 'Parallel')
                        orient(4) = 1;
                    else
                        orient(4) = 2;
                    end
                end
                
                % Execute NormConvolve
                if orient(4) == 1
                    profiles{i}(:,5) = NormConvolve(profiles{i}(:,3), ...
                        profiles{i}(:,5), longstd, 0.1);
                else
                    profiles{i}(:,5) = NormConvolve(profiles{i}(:,3), ...
                        profiles{i}(:,5), latstd, 0.1);
                end
            end
        end
        
    % Herrup et al analytical truncated Gaussian
    case 6
        
        % Define list of detector heights
        parameters = {
            'PTW 31014 PinPoint'        5.0
            'PTW 31015 PinPoint'        5.0
            'PTW 31016 PinPoint 3D'     2.9
            'PTW 31010 SemiFlex'        6.5
            'PTW 31013 SemiFlex'        16.25
            'IBA CC01'                  3.6
            'IBA CC04'                  3.6
            'IBA CC08'                  4.0
            'IBA CC13'                  5.8
            'Standard Imaging A1'       4.4
            'Standard Imaging A1SL'   	4.4
            'Standard Imaging A2'       8.4
            'Standard Imaging A12'      21.6
            'Standard Imaging A12S'     7.5
            'Standard Imaging A14'      1.5
            'Standard Imaging A16'      1.27
            'Standard Imaging A19'      21.6
            'Standard Imaging A26'      1.78
            'Standard Imaging A28'      6.4
        };
    
        % Start with raw profile
        profiles = varargin{1};
    
        % If inputs were not provided or the chamber doesn't match the
        % above list, ask the user for the chamber radius, height
        if nargin < 4 || ~ismember(varargin{3}, parameters(:,1)) || ...
                ~isnumeric(varargin{4}) || varargin{4} <= 0
            if exist('Event', 'file') == 2
                Event(['The chamber is not in the list available for this ', ...
                    'convolution. Prompting user to provide values.']);
            end

            % Open input dialog box
            a = inputdlg({'Chamber Radius (mm):', 'Chamber Height (mm):'}, ...
                'Dimensions', 1, {'', ''});
            r = str2double(a{1});
            h = str2double(a{2});
            clear a;
        else
            r = varargin{4};
            h = parameters{find(strcmp(varargin{3}, ...
                parameters(:,1)), 1, 'first'), 2};
        end
        
        % Compute sigma
        sigma = (r*h + pi*r^2/4)/(r+h);

        % Log action
        if exist('Event', 'file') == 2
            Event(sprintf(['Convolving reference profiles using Herrup ', ...
                'Gaussian analytical model with sigma = %0.2f mm'], sigma));
        end
        
        % Loop through each profile
        for i = 1:length(profiles)
            
            % If X and Y changes, this is a diagonal profile
            if (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1 && ...
                    (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
            
                % Calculate diagonal profile
                x = sqrt(profiles{i}(:,1).^2 + profiles{i}(:,2).^2) .* ...
                    sign(profiles{i}(:,1));
                
                % Execute truncated NormConvolve
                profiles{i}(:,5) = NormConvolve(x, profiles{i}(:,5), ...
                    sigma, 0.1, 1.75 * sigma);

            % If only X changes, this is an X profile
            elseif (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1
                
                % Execute truncated NormConvolve
                profiles{i}(:,5) = NormConvolve(profiles{i}(:,1), ...
                    profiles{i}(:,5), sigma, 0.1, 1.75 * sigma);
                
            % Otherwise, if only Y changes, this is a Y profile
            elseif (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
                
                % Execute truncated NormConvolve
                profiles{i}(:,5) = NormConvolve(profiles{i}(:,2), ...
                    profiles{i}(:,5), sigma, 0.1, 1.75 * sigma);
                
            % Otherwise, if Z changes, this is a depth profile
            elseif (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1
                
                % Execute truncated NormConvolve
                profiles{i}(:,5) = NormConvolve(profiles{i}(:,3), ...
                    profiles{i}(:,5), sigma, 0.1, 1.75 * sigma);
            end
        end
        
    % Sahoo et al analytical Gaussian
    case 8
        
        % Start with raw profile
        profiles = varargin{1};
    
        % If a cavity radius was not set
        if nargin < 4 || ~isnumeric(varargin{4}) || varargin{4} <= 0
            if exist('Event', 'file') == 2
                Event(['A chamber radius was not specified, which is ', ...
                    'required to compute sigma. Profiles will not be ', ...
                    'convolved.'], 'WARN');
            else
                warning(['A chamber radius was not specified, which is ', ...
                    'required to compute sigma. Profiles will not be ', ...
                    'convolved.']);
            end
            h = warndlg(['A chamber radius was not specified, which is ', ...
                    'required to compute sigma. Profiles will not be ', ...
                    'convolved.']);
            uiwait(h);
            return;
        end
        
        % Log action
        if exist('Event', 'file') == 2
            Event(sprintf(['Convolving reference profiles using Sahoo ', ...
                'Gaussian analytical model with sigma = %0.2f mm'], ...
                varargin{4}));
        end
        
        % Loop through each profile
        for i = 1:length(profiles)
            
            % If X and Y changes, this is a diagonal profile
            if (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1 && ...
                    (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
            
                % Calculate diagonal profile
                x = sqrt(profiles{i}(:,1).^2 + profiles{i}(:,2).^2) .* ...
                    sign(profiles{i}(:,1));
                
                % Execute NormConvolve
                profiles{i}(:,5) = NormConvolve(x, profiles{i}(:,5), ...
                    varargin{4}, 0.1);

            % If only X changes, this is an X profile
            elseif (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1
                
                % Execute NormConvolve
                profiles{i}(:,5) = NormConvolve(profiles{i}(:,1), ...
                    profiles{i}(:,5), varargin{4}, 0.1);
                
            % Otherwise, if only Y changes, this is a Y profile
            elseif (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
                
                % Execute NormConvolve
                profiles{i}(:,5) = NormConvolve(profiles{i}(:,2), ...
                    profiles{i}(:,5), varargin{4}, 0.1);
                
            % Otherwise, if Z changes, this is a depth profile
            elseif (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1
                
                % Execute NormConvolve
                profiles{i}(:,5) = NormConvolve(profiles{i}(:,3), ...
                    profiles{i}(:,5), varargin{4}, 0.1);
            end
        end
        
    % Sibata et al analytical Parabolic
    case 9
        
        % Start with raw profile
        profiles = varargin{1};
    
        % If a cavity radius was not set
        if nargin < 4 || ~isnumeric(varargin{4}) || varargin{4} <= 0
            if exist('Event', 'file') == 2
                Event(['A chamber radius was not specified, which is ', ...
                    'required. Profiles will not be convolved.'], 'WARN');
            else
                warning(['A chamber radius was not specified, which is ', ...
                    'required. Profiles will not be convolved.']);
            end
            h = warndlg(['A chamber radius was not specified, which is ', ...
                    'required. Profiles will not be convolved.']);
            uiwait(h);
            return;
        end
        
        % Log action
        if exist('Event', 'file') == 2
            Event(sprintf(['Convolving reference profiles using Sibata ', ...
                'Parabolic analytical model with radius = %0.2f mm'], ...
                varargin{4}));
        end
        
        % Loop through each profile
        for i = 1:length(profiles)
            
            % If X and Y changes, this is a diagonal profile
            if (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1 && ...
                    (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
            
                % Calculate diagonal profile
                x = sqrt(profiles{i}(:,1).^2 + profiles{i}(:,2).^2) .* ...
                    sign(profiles{i}(:,1));
                
                % Execute NormConvolve
                profiles{i}(:,5) = ParabolicConvolve(x, profiles{i}(:,5), ...
                    varargin{4}, 0.1);

            % If only X changes, this is an X profile
            elseif (max(profiles{i}(:,1)) - min(profiles{i}(:,1))) > 1
                
                % Execute NormConvolve
                profiles{i}(:,5) = ParabolicConvolve(profiles{i}(:,1), ...
                    profiles{i}(:,5), varargin{4}, 0.1);
                
            % Otherwise, if only Y changes, this is a Y profile
            elseif (max(profiles{i}(:,2)) - min(profiles{i}(:,2))) > 1
                
                % Execute NormConvolve
                profiles{i}(:,5) = ParabolicConvolve(profiles{i}(:,2), ...
                    profiles{i}(:,5), varargin{4}, 0.1);
                
            % Otherwise, if Z changes, this is a depth profile
            elseif (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1
                
                % Execute NormConvolve
                profiles{i}(:,5) = ParabolicConvolve(profiles{i}(:,3), ...
                    profiles{i}(:,5), varargin{4}, 0.1);
            end
        end
end