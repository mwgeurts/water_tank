function profiles = SmoothProfiles(varargin)
% SmoothProfiles smooths a cell array of profiles by a specified algorithm. 
% If called with no inputs, it will return a list of available algorithms 
% that can be used. If called with inputs, the first must be the
% name of the file while the second is an integer corresponding to the
% algorithm, and the third is a structure array containing configuration
% options.
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
    'Moving Average'
    'Robust LOESS 2° Poly Fit' 
    'Savitzky-Golay'
};

% If no input arguments are provided
if nargin == 0
    
    % Return options (return only 'None' if smoothdata() is not available)
    if exist('smoothdata', 'file') == 2
        profiles = options;
    else
        profiles = {'None'};
    end
    
    % Stop execution
    return;
end

% Execute code block based on format provided in varargin{2}
switch varargin{2}
    
    % No smoothing
    case 1
        
        % Return raw profile
        profiles = varargin{1};
       
    % Moving average filter
    case 2
        
        % If no configuration options exist, define default values
        if nargin >= 3
            config = varargin{3};
        else
            config.SMOOTH_SPAN = 15;
        end
        
        % Log action
        if exist('Event', 'file') == 2
            Event(sprintf(['Smoothing profiles using moving average ', ...
                'filter with span %i'], config.SMOOTH_SPAN));
        end
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Loop through each profile
        for i = 1:length(profiles)
            
            % Smooth data, limiting span
            profiles{i}(:,4) = smoothdata(profiles{i}(:,4), 'movmean', ...
                round((max(3, min(config.SMOOTH_SPAN, floor(0.05 * ...
                size(profiles{i},1))))-1)/2)*2+1);
            
            % Smooth reference too if set
            if config.SMOOTH_REFERENCE == 1 && size(profiles{i},2) > 4
                profiles{i}(:,5) = smoothdata(profiles{i}(:,5), 'movmean', ...
                    round((max(3, min(config.SMOOTH_SPAN, floor(0.05 * ...
                    size(profiles{i},1))))-1)/2)*2+1);
            end
        end
        
    % Robust 2nd degree Polynomial Regression filter
    case 3
        
        % If no configuration options exist, define default values
        if nargin >= 3
            config = varargin{3};
        else
            config.SMOOTH_SPAN = 15;
        end
        
        % Log action
        if exist('Event', 'file') == 2
            Event(sprintf(['Smoothing profiles using 2nd degree polynomial ', ...
                'regression filter with span %i'], config.SMOOTH_SPAN));
        end
        
        % Start with raw profile
        profiles = varargin{1};
        
        
        % Loop through each profile
        for i = 1:length(profiles)

            % Smooth the measured data
            profiles{i}(:,4) = smoothdata(profiles{i}(:,4), 'rloess', ...
                min(config.SMOOTH_SPAN/size(profiles{i},1), 0.02));
            
            % Smooth reference too if set
            if config.SMOOTH_REFERENCE == 1 && size(profiles{i},2) > 4
                 profiles{i}(:,5) = smoothdata(profiles{i}(:,5), 'rloess', ...
                    min(config.SMOOTH_SPAN/size(profiles{i},1), 0.02));
            end
        end
        
    % Savitzky-Golay filter
    case 4
        
        % If no configuration options exist, define default values
        if nargin >= 3
            config = varargin{3};
        else
            config.SMOOTH_SPAN = 15;
            config.SGOLAY_DEGREE = 3;
        end
        
        % Log action
        if exist('Event', 'file') == 2
            Event(sprintf(['Smoothing profiles using Savitzky-Golay filter', ...
                ' with span %i and degree %i'], config.SMOOTH_SPAN, ...
                config.SGOLAY_DEGREE));
        end
        
        % Start with raw profile
        profiles = varargin{1};
        
        % Loop through each profile
        for i = 1:length(profiles)
            
            % Smooth the measured data
            profiles{i}(:,4) = smoothdata(profiles{i}(:,4), 'sgolay', ...
                round((max(config.SGOLAY_DEGREE+1, min(config.SMOOTH_SPAN, ...
                floor(0.02 * size(profiles{i},1))))-1)/2)*2+1, 'Degree', ...
                config.SGOLAY_DEGREE);
            
            % Smooth reference too if set
            if config.SMOOTH_REFERENCE == 1 && size(profiles{i},2) > 4
                profiles{i}(:,5) = smoothdata(profiles{i}(:,5), 'sgolay', ...
                    round((max(config.SGOLAY_DEGREE+1, min(config.SMOOTH_SPAN, ...
                    floor(0.02 * size(profiles{i},1))))-1)/2)*2+1, 'Degree', ...
                    config.SGOLAY_DEGREE);
            end
        end
end
