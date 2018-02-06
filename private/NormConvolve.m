function y = NormConvolve(x, y, s, r)
% NormConvolve performs a normal-distribution convolution on a dataset
% using Fourier Transforms. The provided x/y data is first re-sampled to
% the resolution provided by r, then convolved against a normal
% distribution centered on x with standard deviation s. The inputs s and r
% are optional; s will default to 1 and r will default to the average
% resolution across x.
%
% The following examples illustrate use of this function:
%
% % Define input data
% x = 1:10;
% y = rand(1, 10);
%
% % Convolve y with a normal distribution
% y2 = NormConvolve(x, y);
%
% % Re-convolve using a standard deviation of 2
% y2 = NormConvolve(x, y, 2);
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

% If at least two args are not provided, fail
if nargin < 2
    if exist('Event', 'file') == 2
        Event('NormConvolve requires at least two inputs, x and y', 'ERROR');
    else
        error('NormConvolve requires at least two inputs, x and y');
    end
    
% Otherwise, if s is not provided    
elseif nargin == 2
    s = 1;
end
    
% If r is not provided, use minimum difference
if nargin < 4
    r = min(abs(diff(x)));
end

% Perform in try-catch statement, returning original value if error occurs
try

    % Re-sample data to be equally spaced at resolution r
    xi = x(1)-2*s*sign(x(end)-x(1)):r*sign(x(end)-x(1)):...
        x(end)+2*s*sign(x(end)-x(1));
    p = interp1(x, y, xi, 'linear', 'extrap');

    % Calculate Gaussian distribution given standard deviation s and 
    % centered on x data
    g = 1/(s * sqrt(2 * pi)) * exp(-(xi-mean(xi)).^2 / ...
        (2 * s ^ 2));

    % Convolve data
    z = ifft(fft(p, length(xi)*2+1) .* fft(g, length(xi)*2+1), ...
        length(xi)*2+1);

    % Extract the data from the convolved, padded result
    y = interp1(xi, z(floor(length(xi)/2):length(xi) ...
        + floor(length(xi)/2)-1) * max(p)/max(z), ...
        x, 'linear', 0) .* single(y > 0);
    
catch

    % Log error
    if exist('Event', 'file') == 2
        Event('Convolution failed, returning original value', 'WARN');
    else
        warning('Convolution failed, returning original value');
    end
    
end

% Clear temporary variables
clear xi p g z;
