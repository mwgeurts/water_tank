function profile = ParseProfile(varargin)
% ParseProfile extracts a water tank file into a cell array of individual 
% profiles. If called with no inputs, it will return a list of available
% formats that can be parsed. If called with inputs, the first must be the
% name of the file while the second is an integer corresponding to the
% format.
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
    'OmniPro RFA300 ASCII BDS (.txt)'
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
    
    % OmniPro RFA300 ASCII BDS
    case 1
        
        fid = fopen(varargin{1});
        j = 0;
        profile = cell(0);

        % Loop through file contents
        while ~feof(fid)

            % Get line
            l = fgetl(fid);

            % If line matches format
            if length(l) > 1 && strcmp(l(1), '=')
                if length(profile) == j
                    profile{j} = vertcat(profile{j}, ...
                        cell2mat(textscan(l(2:end), '%f %f %f %f')));
                else
                    profile{j} = cell2mat(textscan(l(2:end), '%f %f %f %f'));
                end

            else
                j = j + 1;
            end
        end

        % Close file
        fclose(fid);
        clear fid j l;

        % Remove empty cells
        profile = profile(~cellfun('isempty', profile));
        
end

% Log number of profiles
if exist('Event', 'file') == 2
    Event(sprintf('%i profiles loaded from %s\n', length(profile), ...
        varargin{1}));
end