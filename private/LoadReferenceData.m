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
machines = natsort({machines.name}); 

% Initialize folder and total counter
m = 0;
c = 0;

% Scan through machine folders
for i = 1:length(machines)
    
    % If the folder content is . or .., skip to next folder in machines
    if strcmp(machines{i}, '.') || strcmp(machines{i}, '..')
        continue

    % Otherwise, if the folder content is a subfolder    
    elseif isdir(fullfile(path, machines{i})) == 1

        % Increment machine counter
        m = m + 1;
        
        % Add folder name to machines list
        reference{m}.machine = machines{i};
        
        % Initialize energy counter
        e = 0;
        
        % Retrieve the subfolder contents
        energies = dir(fullfile(path, machines{i}));
        energies = natsort({energies.name});
        
        % Look through the subfolder contents
        for j = 1:length(energies)
            
            % If the folder content is . or .., skip to next folder in energies
            if strcmp(energies{j}, '.') || strcmp(energies{j}, '..')
                continue

            % Otherwise, if the folder content is a subfolder    
            elseif isdir(fullfile(path, machines{i}, energies{j})) == 1
                
                % Increment energy counter
                e = e + 1;

                % Add folder name to energy list
                reference{m}.energies{e}.energy = energies{j};
        
        		% Initialize SSD counter
        		s = 0;
        
        		% Retrieve the subfolder contents
                ssds = dir(fullfile(path, machines{i}, energies{j}));
                ssds = natsort({ssds.name});
        
        		% Look through the subfolder contents
				for k = 1:length(ssds)
			
					% If the folder content is . or .., skip to next folder in machines
					if strcmp(ssds{k}, '.') || strcmp(ssds{k}, '..')
						continue

					% Otherwise, if the folder content is a subfolder    
					elseif isdir(fullfile(path, machines{i}, ...
                            energies{j}, ssds{k})) == 1
        
        				% Increment SSD counter
        				s = s + 1;
        				
        				% Add folder name to SSD list
                		reference{m}.energies{e}.ssds{s}.ssd = ssds{k};

						% Initialize fieldsize counter
						f = 0;

						% Retrieve the subfolder contents
						files = dir(fullfile(path, machines{i}, ...
                            energies{j}, ssds{k}));
                        files = natsort({files.name});
                
						% Look through the subfolder contents
						for l = 1:length(files)
					
							% Parse file name
							[~, name, ext] = fileparts(files{l});
					
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
