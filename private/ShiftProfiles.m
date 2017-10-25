function profile = ShiftProfiles(varargin)
% ShiftProfiles shifts a cell array of profiles by a specified EPOM. 
% If called with no inputs, it will return a list of available EPOMs 
% that can be used. If called with inputs, the first must be the
% name of the file while the second is an integer corresponding to the
% EPOM.
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
    '0.6 rcav'
    '0.5 rcav'
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
    
    % No shift
    case 1
        
        % Return raw profile
        profile = varargin{1};
        
end
