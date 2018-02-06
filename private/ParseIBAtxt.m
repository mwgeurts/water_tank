function data = ParseIBAtxt(path, names)
% ParseIBAtxt extracts water tank profiles from IBA OmniPro RFA300 ASCII 
% BDS formatted text files. Each profile is returned an array of position
% and signal values. This function has been tested with OmniPro 6 and 7
% exported ASCII files.
%
% The following variables are required for proper execution:
%   path: string containing the path to the TXT/ASC files
%   names: string or cell array of strings containing the file(s) to be 
%       loaded
%
% The following structure fields are returned upon successful completion:
%   msr: integer, number of profiles (n)
%   bds: string, beam data scanning system number
%   version: 1 x n cell array, ASCII dump format
%   profiletype: 1 x n cell array, profile type such as 'CDepthDoseCurv'
%   dtype: 1 x n cell array, detector type such as 'Ion Chamber'
%   modified: 1 x n datenum vector, modified timestamps
%   modality: 1 x n cell array, beam modality such as 'Photon', 'Electron'
%   energy: 1 x n cell array, beam energy of format ## MV/MeV or ## MV FFF
%   ssd: 1 x n vector, SSD in cm
%   buildup: 1 x n vector, buildup in cm
%   refdist: 1 x n vector, beam reference distance in cm
%   shape: 1 x n cell array, field shape such as 'Circular' or 'Irregular'
%   accessory: 1 x n cell array, accessory number
%   wangle: 1 x n vector, wedge angle in degrees
%   gangle: 1 x n vector, gantry angle in degrees
%   cangle: 1 x n vector, collimator angle in degrees
%   meastype: 1 x n cell array, measurement type such as 'Open Depth'
%   depth: 1 x n vector, profile depth in mm
%   start: n x 3 array, profile start IEC X/Y/Z coordinates in mm
%   end: n x 3 array, profile end IEC X/Y/Z coordinates in mm
%   mcomment: 1 x n cell array, operator comments
%   profiles: cell array of profiles, where each cell contains a n x 4
%       array of IEC X, IEC Y, IEC Z (depth), and signal.
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

% If not cell array, cast as one
if ~iscell(names); names = cell({names}); end

% Log start of file load and start timer
if exist('Event', 'file') == 2
    Event(['Loading ASCII file ', strjoin(names, '\nLoading ASCII file ')]);
    tim = tic;
end

% Initialize return structure
data.profiles = cell(0);

% Initialize counters
i = 0;
j = 0;

% Loop through each file
for f = 1:length(names)

    % Open file to provided filename 
    fid = fopen(fullfile(path, names{f}), 'r');

    % Verify file handle is valid
    if fid >= 3
        if exist('Event', 'file') == 2
            Event(['Read handle successful for ', names{f}]);
        end
    else
        if exist('Event', 'file') == 2
            Event(['Read handle not successful for ', names{f}], 'ERROR');
        else
            error(['Read handle not successful for ', names{f}]);
        end
    end
    
    % Loop through file contents
    while ~feof(fid)

        % Get line
        l = fgetl(fid);

        % Parse header contents
        if length(l) > 1 && strcmp(l(1), ':')
            
            % Store MSR, SYS flags
            t = regexp(l, '^:(\w+)\s*(\w*)\s*(\w*)', 'tokens');
            switch t{1}{1}
                case 'MSR'
                    data.msr = str2double(t{1}{2});
                    data.profiles = cell(1, data.msr);
                case 'SYS'
                    data.bds = t{1}{3};
            end
            
        % Parse labels
        elseif length(l) > 1 && strcmp(l(1), '%')
            
            % Store labels
            t = regexp(l, '^%(\w+)\s*(\S*)\s*(\S*)\s*(\S*)', 'tokens');
            switch t{1}{1}
                
                % Store file version
                case 'VNR'
                    i = i + 1;
                    j = 0;
                    if length(t{1}) > 1 
                        data.version{i} = t{1}{2};
                    end
                
                % Store measured quantity
                case 'MOD'
                    if length(t{1}) > 1 && strcmp(t{1}{2}, 'FLM')
                        data.quantity{i} = 'Film';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, 'RAT')
                        data.quantity{i} = 'Relative Dose';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, 'ABS')
                        data.quantity{i} = 'Absolute Dose';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, 'INT')
                        data.quantity{i} = 'Integrated';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, 'UDF')
                        data.quantity{i} = 'Undefined';
                    end
                    
                % Store profile type    
                case 'SCN'
                    if length(t{1}) > 1 && strcmp(t{1}{2}, 'DPT')
                        data.profiletype{i} = 'CDepthDoseCurv';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, 'PRO')
                        data.profiletype{i} = 'CProfileCurv';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, 'MTX')
                        data.profiletype{i} = 'Matrix';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, 'DIA')
                        data.profiletype{i} = 'Diagonal';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, 'UDF')
                        data.quantity{i} = 'Undefined';
                    end
                    
                % Store detector type    
                case 'FLD'
                    if length(t{1}) > 1 && strcmp(t{1}{2}, 'ION')
                        data.dtype{i} = 'Ion Chamber';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, 'SEM')
                        data.dtype{i} = 'Semiconductor';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, 'UDF')
                        data.dtype{i} = 'Undefined';
                    end
                    
                % Store modified date    
                case 'DAT'
                    if length(t{1}) > 1
                        data.modified{i} = t{1}{2};
                    end
                    
                % Store modified time    
                case 'TIM'
                    if length(t{1}) > 1
                        data.modified{i} = datenum([data.modified{i}, ...
                            ' ', t{1}{2}], 'mm-dd-yyyy HH:MM:SS');
                    end
                    
                % Store modality and energy    
                case 'BMT'
                    
                    % If cobalt
                    if length(t{1}) > 1 && strcmp(t{1}{2}, 'COB')
                        data.modality{i} = 'Cobalt';
                        if length(t{1}) > 2
                            data.energy{i} = ...
                                [regexprep(t{1}{3}, '\.0', ''), ' MeV'];
                        end
                        
                    % If photons    
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, 'PHO')
                        data.modality{i} = 'Photon';
                        if length(t{1}) > 2
                            data.energy{i} = ...
                                [regexprep(t{1}{3}, '\.0', ''), ' MV'];
                        end
                        
                    % If electrons    
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, 'ELE')
                        data.modality{i} = 'Electron';
                        if length(t{1}) > 2
                            data.energy{i} = ...
                                [regexprep(t{1}{3}, '\.0', ''), ' MeV'];
                        end
                        
                    % If undefined    
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, 'UDF')
                        data.modality{i} = 'Undefined';
                    end
                    
                    % If an FFF energy was provided
                    if isfield(data, 'energy') && ...
                            contains(data.energy{i}, '666')
                        data.energy{i} = [regexprep(data.energy{i}, ...
                            '666', ''), ' FFF'];
                    end
                    
                % Store SSD in cm    
                case 'SSD'
                    if length(t{1}) > 1
                        data.ssd(i) = str2double(t{1}{2})/10;
                    end
                    
                % Store buildup in cm    
                case 'BUP'
                    if length(t{1}) > 1
                        data.buildup(i) = str2double(t{1}{2})/100;
                    end
                    
                % Store beam reference distance    
                case 'BRD'
                    if length(t{1}) > 1
                        data.refdist(i) = str2double(t{1}{2})/10;
                    end
                    
                % Store field size    
                case 'FSZ'
                    if length(t{1}) > 2 
                        data.field(i,1:2) = [str2double(t{1}{2})/10
                            str2double(t{1}{2})/10];
                    end
                    
                % Store field shape    
                case 'FSH'
                    if length(t{1}) > 1 && strcmp(t{1}{2}, '-1')
                        data.shape{i} = 'Undefined';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, '0')
                        data.shape{i} = 'Circular';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, '1')
                        data.shape{i} = 'Rectangular';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, '2')
                        data.shape{i} = 'Irregular';
                    end
                    
                % Store accessory number    
                case 'ASC'
                    if length(t{1}) > 1
                        data.accessory{i} = t{1}{2};
                    end
                    
                % Store wedge angle    
                case 'WEG'
                    if length(t{1}) > 1
                        data.wangle(i) = str2double(t{1}{2});
                    end
                    
                % Store gantry angle    
                case 'GPO'
                    if length(t{1}) > 1
                        data.gangle(i) = str2double(t{1}{2});
                    end
                    
                % Store collimator angle    
                case 'CPO'
                    if length(t{1}) > 1
                        data.cangle(i) = str2double(t{1}{2});
                    end
                    
                % Store measurement type    
                case 'MEA'
                    if length(t{1}) > 1 && strcmp(t{1}{2}, '-1')
                        data.meastype{i} = 'Undefined';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, '0')
                        data.meastype{i} = 'Absolute Dose';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, '1')
                        data.meastype{i} = 'Open Depth';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, '2')
                        data.meastype{i} = 'Open Profile';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, '4')
                        data.meastype{i} = 'Wedge';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, '5')
                        data.meastype{i} = 'Wedge Depth';
                    elseif length(t{1}) > 1 && strcmp(t{1}{2}, '6')
                        data.meastype{i} = 'Wedge Profile';
                    end
                    
                % Store profile depth    
                case 'PRD'
                    if length(t{1}) > 1
                        data.depth(i) = str2double(t{1}{2})/10;
                    end
                    
                % Set profile array size using number of points   
                case 'PTS'
                    if length(t{1}) > 1
                        data.profiles{i} = zeros(str2double(t{1}{2}), 4);
                    end
                    
                % Store start coordinates in mm
                case 'STS'
                    if length(t{1}) > 1
                        data.start(i,1) = str2double(t{1}{2});
                    end
                    if length(t{1}) > 2
                        data.start(i,2) = str2double(t{1}{3});
                    end
                    if length(t{1}) > 3
                        data.start(i,3) = str2double(t{1}{4});
                    end
                    
                % Store end coordinates in mm
                 case 'EDS'
                    if length(t{1}) > 1
                        data.end(i,1) = str2double(t{1}{2});
                    end
                    if length(t{1}) > 2
                        data.end(i,2) = str2double(t{1}{3});
                    end
                    if length(t{1}) > 3
                        data.end(i,3) = str2double(t{1}{4});
                    end
            end
        
        % Parse comments
        elseif length(l) > 1 && strcmp(l(1), '!') 
            
            % Store comment lines separated by \n
            if ~isfield(data, 'mcomment') || length(data.mcomment) < i
                data.mcomment{i} = strtrim(l(2:end));
            else
                data.mcomment{i} = sprintf('%s\n%s', data.mcomment{i}, ...
                    strtrim(l(2:end)));
            end            
        
        % Parse data
        elseif length(l) > 1 && strcmp(l(1), '=')
            j = j + 1;
            data.profiles{i}(j,:) = cell2mat(textscan(l(2:end), ...
                '%f %f %f %f'));
        end
    end

    % Close file
    fclose(fid);
end

% Remove empty profiles
data.profiles = data.profiles(~cellfun('isempty',data.profiles));

% Loop through each profile
for i = 1:length(data.profiles)

    % If depth is negative (given by a negative mean value), flip
    % the dimension so that depths are down
    if mean(data.profiles{i}(:,3)) < 0
        
        % Log event
        if exist('Event', 'file') == 2
            Event('Flipping IEC Z axis (positive down)');
        end
        
        % Store negative value
        data.profiles{i}(:,3) = -data.profiles{i}(:,3);
    end
    
    % If depth changes (i.e. PDD), sort descending
    if (max(data.profiles{i}(:,3)) - min(data.profiles{i}(:,3))) > 1
        
        % Log event
        if exist('Event', 'file') == 2
            Event('Sorting depth profile by descending IEC Z value');
        end
        
        % Store sorted table in descending order
        data.profiles{i} = flip(sortrows(data.profiles{i}, 3), 1);
    end
end

% Log event
if exist('Event', 'file') == 2
    Event(sprintf('%i data profiles extracted successfully in %0.3f seconds', ...
        length(data.profiles), toc(tim)));
end

% Clear temporary variables
clear f fid i j l t;