function profile = CalcProfileGamma(profile, percent, dta, local)
% CalcProfileGamma calculates the Gamma profile for a cell array of line
% profiles using the provided criteria.
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

% Log action
if local == 1
    Event(sprintf(['Computing local profile Gamma Index using ', ...
        '%0.2f%%/%0.2f mm criteria'], percent, dta));
else
    Event(sprintf(['Computing global profile Gamma Index using ', ...
        '%0.2f%%/%0.2f mm criteria'], percent, dta));
end

% Check if MATLAB can find CalcGamma
if exist('CalcGamma', 'file') ~= 2
    
    % If not, throw an error
    Event('The CalcGamma submodule does not exist in the search path.', ...
        'ERROR');
end

% Loop through each profile
for i = 1:length(profile)
   
    % If X changes, this is an X profile
    if profile{i}(1,1) ~= profile{i}(2,1)

        % Define CalcGamma reference structure
        reference.start = profile{i}(1,1);
        reference.width = min(diff(profile{i}(:,1)));
        reference.data = interp1(profile{i}(:,1), profile{i}(:,5), ...
            reference.start:reference.width:profile{i}(end,1), 'linear');
        
        % Define CalcGamma target structure
        target.start = reference.start;
        target.width = reference.width;
        target.data = interp1(profile{i}(:,1), profile{i}(:,4), ...
            reference.start:reference.width:profile{i}(end,1), 'linear');
        
        % Execute CalcGamma, appending the result
        profile{i}(:,6) = interp1(reference.start:reference.width:...
            profile{i}(end,1), CalcGamma(reference, target, percent, ...
            dta, 'local', local, 'cpu', 1), profile{i}(:,1), 'linear')';

    % Otherwise, if Y changes, this is an Y profile
    elseif profile{i}(1,2) ~= profile{i}(2,2)

        % Define CalcGamma reference structure
        reference.start = profile{i}(1,2);
        reference.width = min(diff(profile{i}(:,2)));
        reference.data = interp1(profile{i}(:,2), profile{i}(:,5), ...
            reference.start:reference.width:profile{i}(end,2), 'linear');
        
        % Define CalcGamma target structure
        target.start = reference.start;
        target.width = reference.width;
        target.data = interp1(profile{i}(:,2), profile{i}(:,4), ...
            reference.start:reference.width:profile{i}(end,2), 'linear');
        
        % Execute CalcGamma, appending the result
        profile{i}(:,6) = interp1(reference.start:reference.width:...
            profile{i}(end,2), CalcGamma(reference, target, percent, ...
            dta, 'local', local, 'cpu', 1), profile{i}(:,2), 'linear')';
        
    % Otherwise, if Z changes, this is an depth profile
    elseif profile{i}(1,3) ~= profile{i}(2,3)

        % Define CalcGamma reference structure
        reference.start = profile{i}(1,3);
        reference.width = min(diff(profile{i}(:,3)));
        reference.data = interp1(profile{i}(:,3), profile{i}(:,5), ...
            reference.start:reference.width:profile{i}(end,3), 'linear');
        
        % Define CalcGamma target structure
        target.start = reference.start;
        target.width = reference.width;
        target.data = interp1(profile{i}(:,3), profile{i}(:,4), ...
            reference.start:reference.width:profile{i}(end,3), 'linear');
        
        % Execute CalcGamma, appending the result
        profile{i}(:,6) = interp1(reference.start:reference.width:...
            profile{i}(end,3), CalcGamma(reference, target, percent, ...
            dta, 'local', local, 'cpu', 1), profile{i}(:,3), 'linear')';
    end

    % Clear temporary variables
    clear reference target;
end

% Clear temporary variables
clear i;