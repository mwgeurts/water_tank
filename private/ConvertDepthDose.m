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
    'AAPM TG-51'
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
       
    % AAPM TG-51
    case 2
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Log action
        Event(['Converting electron beam ionization to dose ', ...
            'according to TG-51']);
        
        % Loop through each profile
        for i = 1:length(profiles)
        
            % If Z changes, this is an depth profile
            if (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1

                % Find index of I50
                I50 = find(profiles{i}(:,4) > 0.5 * ...
                    max(profiles{i}(:,4)), 1, 'first');
                
                % Compute R50 in cm
                R50 = 1.029 * interp1(profiles{i}(I50-1:I50+2,4), ...
                    profiles{i}(I50-1:I50+2,3), 0.5 * max(profiles{i}(:,4)), ...
                    'linear')/10 - 0.06;
                
                % Find range of indices to apply correction (0.02 to 1.2)
                lI = find(profiles{i}(:,3) / (10 * R50) < 1.2, 1, 'first');
                uI = find(profiles{i}(:,3) / (10 * R50) > 0.02, 1, 'last');
                
                % Scale depth profile by Burns et al. empirical stopping
                % power ratio fit
                profiles{i}(lI:uI,4) = profiles{i}(lI:uI,4) .* (1.0752 - ...
                    0.50867 * log(R50) + 0.08867 * log(R50)^2 - 0.08402 * ...
                    profiles{i}(lI:uI,3)/(10 * R50)) ./ (1 - 0.42806 * log(R50) ...
                    + 0.064627 * log(R50)^2 + 0.003085 * log(R50)^3 - 0.12460 * ...
                    profiles{i}(lI:uI,3)/(10 * R50));
            end
        end 
        
        % Clear temporary variables
        clear i I50 R50;
end
