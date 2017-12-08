function profiles = ShiftProfiles(varargin)
% ShiftProfiles shifts a cell array of profiles by a specified EPOM. 
% If called with no inputs, it will return a list of available EPOMs 
% that can be used. If called with inputs, the first must be the
% name of the file while the second is an integer corresponding to the
% option, and the third is the cavity radius.
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

% Persistently store shift
persistent shift;

% Specify options and order
options = {
    'None'
    'Manual'
    '0.6 rcav'
    '0.5 rcav'
};

% If no input arguments are provided
if nargin == 0
    
    % Return the options
    profiles = options;
    
    % Stop execution
    return;
end

% If no cavity is provided, return unshifted data
if varargin{2} > 2 && nargin < 3
    Event('EPOM shift could not be applied because Rcav is not provided', ...
        'WARN');
    varargin{2} = 1;
end

% Execute code block based on format provided in varargin{2}
switch varargin{2}
    
    % No shift
    case 1
        
        % Return raw profile
        profiles = varargin{1};
       
    % Manual
    case 2
        
        % Start raw profile
        profiles = varargin{1};
        
        % If shift is not defined
        if ~exist('shift', 'var') || isempty(shift) || isnan(shift)
            shift = 0;
        end
        
        % Ask user for shift
        shift = str2double(inputdlg('Enter EPOM shift (mm):', ...
            'EPOM Adjustment', 1, {sprintf('%0.1f', shift)}));
        
        % If the user provided a valid value
        if ~isempty(shift) && ~isnan(shift)
            
            % Log action 
            Event(sprintf('Shifting depths by %0.1f mm', shift));

            % Loop through each profile
            for i = 1:length(profiles)

                % Shift depth
                profiles{i}(:,3) = profiles{i}(:,3) - shift;
            end
        end

    % 0.6 rcav
    case 3
        
        % Start raw profile
        profiles = varargin{1};
        
        % Log action 
        Event(sprintf('Shifting depths by 0.6 rcav = %0.1f mm', 0.6 * ...
            varargin{3}));

        % Loop through each profile
        for i = 1:length(profiles)
            
            % Shift depth
            profiles{i}(:,3) = profiles{i}(:,3) - 0.6 * varargin{3};
        end
        
    % 0.5 rcav
    case 4
        
        % Start raw profile
        profiles = varargin{1};
        
        % Log action 
        Event(sprintf('Shifting depths by 0.5 rcav = %0.1f mm', 0.5 * ...
            varargin{3}));

        % Loop through each profile
        for i = 1:length(profiles)
            
            % Shift depth
            profiles{i}(:,3) = profiles{i}(:,3) - 0.5 * varargin{3};
        end
end
