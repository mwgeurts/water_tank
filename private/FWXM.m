function varargout = FWXM(x, y, f)
% FWXM calculates the full width at fractional value f for a provided x/y
% array, where x are positions and y is the signal. The value of f should
% be between 0 and 1.
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

% Find index of max value
[~, I] = max(y);

% Find highest lower index just below fractional maximum
lI = find(y(1:I) < f * max(y), 1, 'last');

% Find lowest upper index just above fractional maximum
uI = find(y(I:end) < f * max(y), 1, 'first');

try
    % Interpolate to find lower fractional-maximum value
    l = interp1(y(lI-1:lI+2), x(lI-1:lI+2), f * max(y), 'linear');

    % Interpolate to find upper fractional-maximum value
    u = interp1(y(I+uI-3:I+uI), x(I+uI-3:I+uI), f * max(y), 'linear');
    
    % Return offset and fwxm
    varargout{1} = (l+u)/2;
    if nargout >= 2
        varargout{2} = abs(l-u);
    end
    
    % If nargout is 3, interpolate new y values
    if nargout >= 3
        varargout{3} = interp1(x, y, x+(l+u)/2, 'spline', 0);
    end
    
% If FWXM could not be computed, throw a warning   
catch
    if exist('Event', 'file') == 2
        Event('FWXM could not be computed for profile', 'WARN');
    else
        warning('FWHM could not be computed for profile');
    end
    
    % Return null values
    if nargout >= 1
        varargout{1} = 0;
    end
    if nargout >= 2
        varargout{2} = NaN;
    end
    if nargout >= 3
        varargout{3} = y;
    end
end