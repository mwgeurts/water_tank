function reference = LoadReferenceData(path)
% LoadReferenceData scans a folder for a folder hierarchy of machines >
% energies, containing DICOM files for each field size. A cell array of
% structures is returned.
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

% Log and start timer
Event(['Scanning ', path, ' for reference DICOM files']);
t = tic;

% Initialize return variable
reference = cell(0);

% Retrieve folder contents of provided path
machines = dir(path);

% Initialize folder and total counter
m = 0;
c = 0;

% Scan through machine folders
for i = 1:length(machines)
    
    % If the folder content is . or .., skip to next folder in machines
    if strcmp(machines(i).name, '.') || strcmp(machines(i).name, '..')
        continue

    % Otherwise, if the folder content is a subfolder    
    elseif machines(i).isdir == 1

        % Increment machine counter
        m = m + 1;
        
        % Add folder name to machines list
        reference{m}.machine = machines(i).name;
        
        % Initialize energy counter
        e = 0;
        
        % Retrieve the subfolder contents
        energies = dir(fullfile(path, machines(i).name));
        
        % Look through the subfolder contents
        for j = 1:size(energies, 1)
            
            % If the folder content is . or .., skip to next folder in energies
            if strcmp(energies(j).name, '.') || strcmp(energies(j).name, '..')
                continue

            % Otherwise, if the folder content is a subfolder    
            elseif energies(j).isdir == 1
                
                % Increment energy counter
                e = e + 1;

                % Add folder name to energy list
                reference{m}.energies{e}.energy = energies(j).name;
        
        		% Initialize SSD counter
        		s = 0;
        
        		% Retrieve the subfolder contents
                ssds = dir(fullfile(path, machines(i).name, energies(j).name));
        
        		% Look through the subfolder contents
				for k = 1:size(ssds, 1)
			
					% If the folder content is . or .., skip to next folder in machines
					if strcmp(ssds(k).name, '.') || strcmp(ssds(k).name, '..')
						continue

					% Otherwise, if the folder content is a subfolder    
					elseif ssds(k).isdir == 1
        
        				% Increment SSD counter
        				s = s + 1;
        				
        				% Add folder name to SSD list
                		reference{m}.energies{e}.ssds{s}.ssd = ssds(k).name;

						% Initialize fieldsize counter
						f = 0;

						% Retrieve the subfolder contents
						files = dir(fullfile(path, machines(i).name, energies(j).name, ...
							ssds(k).name));
                
						% Look through the subfolder contents
						for l = 1:size(files, 1)
					
							% Parse file name
							[~, name, ext] = fileparts(files(l).name);
					
							% If file is a .dcm file
							if strcmpi(ext, '.dcm')
						
								% Increment field size counter
								f = f + 1;
								c = c + 1;
						
								% Add field size to the machines
								reference{m}.energies{e}.ssds{s}.fields{f} = name;
							end
						end
					end
				end
            end
        end
    end
end

% If no files were found, throw an error
if c == 0
    Event(['At least one DICOM (.dcm) file must be stored within the ', ...
        'reference folder ', path, '. See documentation for more ', ...
        'information.'], 'ERROR');
end

% Log completion
Event(sprintf('%i files loaded into reference data from %s in %0.3f seconds', c, path, ...
	toc(t)));

% Clear temporary variables
clear i j k l c m e s f t machines energies ssds files;
