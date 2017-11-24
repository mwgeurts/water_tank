function PlotOutputFactors(varargin)
% PlotOutputFactors is called by WaterTankAnalysis when the user clicks
% "Plot Output Factors". It can also be executed independently. This
% function will scan a provided directory of DICOM RT Dose files and
% calculate the output factors as a function of field size. The file size
% is identified based on the file size (see WaterTankAnalysis wiki
% documentation for more information). The displayed plot includes a table
% to allow the user to type in measred values and calculate the relative 
% difference between TPS and modelled values. This function uses the Image 
% Processing Toolbox dicomread() function to load DICOM data and is 
% required for execution.
% 
% If a path is not provided as the first input argument (varargin{1}), the
% function will prompt the user to select a folder. The type of Output
% Factor may optionally be provided in the second input argument 
% (varargin{2}), and can be either 'dmax' or '10cm'. Finally, if isocenter
% is defined at a point other than DICOM center, the isocenter coordinates
% can be specified in IEC X/Y/Z order in mm in the third input argument
% (varargin{3}).
%
% In addition to plotting output factors, the application will attempt to
% fit an analytical function first proposed by Sauer and Wilbert, 2007, 
% "Measurement of output factors for small photon beams", Med. Phys. 34, 
% 1983?1988. The fitting parameters and their confidence limits are
% displayed on the displayed figure. This fit uses the Curve Fitting
% Toolbox fit() function; if not installed the function will still work but
% not display a fit.
%
% Below are some examples of how to execute this function:
%
% % Execute function using default values, and prompt user to select folder
% PlotOutputFactors();
%
% % Execute function using DICOM data in /path/to/DICOM
% PlotOutputFactors('/path/to/DICOM');
%
% % Execute on same files, but this time compute OF at 10cm depth along CAX
% PlotOutputFactors('/path/to/DICOM', '10cm');
%
% % Execute function but with isocenter at [0 80 0].
% PlotOutputFactors('/path/to/DICOM', [], [0 80 0]);
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

% Check if MATLAB can find dicominfo (Image Processing Toolbox)
if exist('dicominfo', 'file') ~= 2
    
    % If not, throw an error
    if exist('Event', 'file') == 2
        Event(['The Image Processing Toolbox cannot be found and is ', ...
            'required by ProcessReference().'], 'ERROR');
    else
        error(['The Image Processing Toolbox cannot be found and is ', ...
            'required by ProcessReference().']);
    end
end

% If a path was provided
if nargin >= 1 && ~isempty(varargin{1})
    path = varargin{1};
    
% Otherwise ask the user to select one
else
    path = uigetdir('', 'Select directory to scan for RT Dose files');
end

% If a type was provided, otherwise default to dmax
if nargin >= 2 && ~isempty(varargin{2})
    type = varargin{2};
else
    type = 'dmax';
end
    

% If reference isocenter was provided
if nargin >= 3 && ~isempty(varargin{3})
    iso = varargin{3};
else
    iso = [0 0 0];
end

% Retrieve folder contents
list = dir(path);
dicom = cell(0,2);

% Remove isdir entries
for i = 1:length(list)
    if list(i).isdir == 0
        [~, n, ~] = fileparts(list(i).name);
        dicom{size(dicom,1)+1,1} = list(i).name;
        dicom{size(dicom,1),2} = n;
    end
end

% Clear temporary variables
clear i n list;

% Display a message box listing all DICOM files
[s, ok] = listdlg('PromptString', ['Select which field sizes to calculate ', ...
    'output factors:'], 'SelectionMode', 'multiple', 'ListString', dicom(:,2), ...
    'InitialValue', 1:size(dicom,1), 'ListSize', [300 200]);

% If the user clicked cancel, end execution
if ok == 0
    return
end

% Initialize data array for table and equivalent square vector for plotting
data = cell(length(s), 6);
eqsq = zeros(length(s), 1);
ref = 1;

% Compute output factors
h = waitbar(0, 'Extracting Output Factors from DICOM data');
for i = 1:size(data,1)

    % Store field size
    data{i,1} = dicom{s(i),2};
    
    % Load DICOM dose
    info = dicominfo(fullfile(path, dicom{s(i),1}));
    dose = permute(double(squeeze(dicomread(info))), [2 1 3]) * ...
        info.DoseGridScaling;
    [meshx, meshy, meshz] = meshgrid(...
        info.ImagePositionPatient(2) + (0:single(info.Rows)-1) * ...
        info.PixelSpacing(2) + iso(3), ...
        info.ImagePositionPatient(1) + (0:single(info.Columns)-1) * ...
        info.PixelSpacing(1) - iso(1), ...
        info.ImagePositionPatient(3) + ...
        single(info.GridFrameOffsetVector) - iso(2));
    
    % Calculate OF based on type
    switch type
        
        % OF defined at dmax along CAX
        case 'dmax'
            d = 0:info.PixelSpacing(2):100;
            pdd = interp3(meshx, meshy, meshz, dose, d, ...
                zeros(1,length(d)), zeros(1,length(d)), '*linear', 0);
            data{i,2} = max(pdd);
        
        % OF defined at 10 cm depth along CAX
        case '10cm'
            data{i,2} = interp3(meshx, meshy, meshz, dose, 100, ...
                0, 0, '*linear', 0);
        
        % Display an error
        otherwise
            if exist('Event', 'file') == 2
                Event('OF type is unknown', 'ERROR');
            else
                error('OF type is unknown');
            end 
    end
    
    % If the file name follows TomoTherapy notation
    if strcmp(dicom{s(i),2}(1), 'J')
        t = regexp(dicom{s(i),2}, '([0-9]+)', 'tokens');
        switch t{1}{1}
            case '42'
                eqsq(i) = 5;
            case '20'
                eqsq(i) = 2.5;
            case '14'
                eqsq(i) = 1.8;
            case '07'
                eqsq(i) = 1;
        end
        
        % If field size is J42, set reference
        if eqsq(i) == 5
            ref = data{i,2};
        end
    else
    
        % Compute equivalent square
        t = regexp(dicom{s(i),2}, '([0-9\.]+)\D+([0-9\.]+)', 'tokens');
        if isempty(t)

            % Display an error
            if exist('Event', 'file') == 2
                Event(['The field size could not be determined from the ', ...
                    'file name. Name the files [] x [].'], 'ERROR');
            else
                error(['The field size could not be determined from the ', ...
                    'file name. Name the files [] x [].']);
            end 

        elseif length(t{1}) == 2 || ~isempty(t{1}{2})
            eqsq(i) = 2 * str2double(t{1}{1}) * str2double(t{1}{2}) / ...
                (str2double(t{1}{1}) + str2double(t{1}{2}));
        else
            eqsq(i) = str2double(t{1}{1});
        end
    
        % If field size is 10x10, set reference
        if eqsq(i) == 10
            ref = data{i,2};
        end
    end
    
    % Update waitbar
    waitbar(i/size(data,1), h);
end

% Close waitbar
close(h);

% Divide by reference and store as formatted value
for i = 1:size(data,1)
    data{i,2} = data{i,2} / ref;
end

% Sort data by equivalent square field size
[eqsq, i] = sort(eqsq);
data = data(i,:);

% Fit Sauer/Wilbert analytical model to output factors
try
    i = [0.75 2.3 0.5 0.34 0.12];
    model = fit(eqsq, cell2mat(data(:,2)), 'a*x^b/(c^b+x^b)+d*(1-exp(-e*x))', ...
        'Start', i, 'Lower', 0.1*i, 'Upper', 10*i, 'Robust','Bisquare');
    for i = 1:size(data,1)
        data{i,3} = feval(model, eqsq(i));
    end
catch
    model = [];
end

% Create new figure to display output factors
fig = figure('Position', [100 100 1020 500], 'MenuBar', 'none', 'Name', ...
    'Output Factors');

% Add data table
data = vertcat(data, cell(1,6));
uitable('Data', data, 'ColumnName', {'Field Size', 'Calculated', ...
    'Fitted', 'Measured', 'Calc Diff', 'Fit Diff'}, 'Position', ...
    [30 155 475 310], 'RowName', [], 'ColumnEditable', [true false false ...
    true false], 'CellEditCallback', @calcDifference, 'Units', 'normalized');

% Add coefficients table
if ~isempty(model)
    uitable('Data', horzcat({'Fitted'; 'Lower 95%'; 'Upper 95%'}, ...
        num2cell(vertcat(coeffvalues(model), confint(model, 0.95)))), ...
        'ColumnName', {'Value', 'P', 'n', 'l', 'S', 'b'}, 'Position', ...
        [30 50 475 80], 'RowName', [], 'ColumnEditable', [false false false ...
        false false], 'Units', 'normalized');
else
    uitable('Data', {['A model could not be fitted to the ', ...
        'provided datasets']}, 'ColumnName', {'Error Message'}, 'Position', ...
        [30 50 475 80], 'RowName', [], 'ColumnEditable', false, 'Units', ...
        'Pixels', 'ColumnWidth', {475-5}); 
end

% Plot calculated output factors
ax = axes('Position', [0.55 0.1 0.41 0.83]);
plotData();

% Update GUI data
guidata(fig, data);

% Clear temporary variables
clear i s t info dose dicom ok path ref tab pos;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function plotData()
    % plotData is called by PlotOutputFactors and updates the output factor
    % plot with calculated data, measured data, and the fitted model. No
    % input or output arguments are needed as this is a nested function.
        
        % Plot calculated values
        j = find(~cellfun(@isempty,data(:,2))); 
        plot(eqsq(j), cell2mat(data(:,2)), 's', 'Color', 'blue', ...
            'MarkerFaceColor', 'blue'); %#ok<*FNDSB>
        xlim([0 max(eqsq)]);
        clear j;
        
        % Plot fitted model
        hold on;
        if ~isempty(model)
            plot(model); 
        end
        
        % Plot measured data
        if ~isempty(cell2mat(data(:, 4)))
            j = find(~cellfun(@isempty,data(:,4)));
            plot(eqsq(j), cell2mat(data(:,4)), 'o', 'Color', 'black', ...
                'MarkerFaceColor', 'black');
            clear j;
        end
        
        % Format plot
        hold off;
        xlabel('Side of Equivalent Square (cm)');
        ylabel('Output Factor');
        legend({'Calculated', 'Fit', 'Measured'}, 'Location', 'Southeast');
        grid on;
        box on;
        zoom on;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function calcDifference(hObject, eventdata)
    % calcDifference is called when the user enters output factor data, and
    % will update the plot and table with the provided values.
    
    % If a field size was edited/added
    if eventdata.Indices(2) == 1

        % If calculated data exists, revert to previous value
        if ~isempty(data{eventdata.Indices(1),2})
            set(hObject, 'Data', data);
        
        % Otherwise, add value
        else
            
            % Try to match [] x [] format
            t = regexp(eventdata.NewData, ...
                '([0-9\.]+)\D*([0-9\.]*)', 'tokens');
            if ~isempty(t{1}{2})
                eqsq(eventdata.Indices(1)) = 2 * str2double(t{1}{1}) * ...
                    str2double(t{1}{2}) / (str2double(t{1}{1}) + ...
                    str2double(t{1}{2}));
                data{eventdata.Indices(1),1} = sprintf('%g x %g', ...
                    str2double(t{1}{1}), str2double(t{1}{2}));
            elseif ~isempty(t{1}{1})
                eqsq(eventdata.Indices(1)) = str2double(t{1}{1});
                data{eventdata.Indices(1),1} = sprintf('%g x %g', ...
                    str2double(t{1}{1}), str2double(t{1}{1}));
            else
                set(hObject, 'Data', data);
                return;
            end
            
            % Calculate new fitted value
            if ~isempty(model)
                data{eventdata.Indices(1),3} = feval(model, ...
                    eqsq(eventdata.Indices(1)));
            end
            
            % Sort data by equivalent square field size
            [eqsq, j] = sort(eqsq);
            data = data(j,:);
            
            % Update table, with a new value
            data = vertcat(data, cell(1,6));
            set(hObject, 'Data', data);
            
            % Clear temporary variables
            clear j;
        end
    end
    
    % If a measured data was edited/added
    if eventdata.Indices(2) == 4
        
        % If data was invalid
        if ~isnumeric(eventdata.NewData) && ...
                isnan(str2double(eventdata.NewData))
            set(hObject, 'Data', data);
        
        % Otherwise, compute differences
        else
            
            % Store numerical value
            if ~isnumeric(eventdata.NewData)
                data{eventdata.Indices(1), 4} = ...
                    str2double(eventdata.NewData);
            else 
                data{eventdata.Indices(1), 4} = eventdata.NewData;
            end
            
            % If calculated data exists, compute difference
            if ~isempty(data{eventdata.Indices(1), 2})
                data{eventdata.Indices(1), 5} = sprintf('%0.3f%%', ...
                    (data{eventdata.Indices(1), 4} - ...
                    data{eventdata.Indices(1), 2}) / ...
                    data{eventdata.Indices(1), 2} * 100);
            end
            
            % Compute difference from fitted
            if ~isempty(data{eventdata.Indices(1), 3})
                data{eventdata.Indices(1), 6} = sprintf('%0.3f%%', ...
                    (data{eventdata.Indices(1), 4} - ...
                    data{eventdata.Indices(1), 3}) / ...
                    data{eventdata.Indices(1), 3} * 100);
            end
            
            % Update table
            set(hObject, 'Data', data);
        end
    end
 
    % Update plot
    axes(ax);
    plotData();
    
    % Update GUI data
    guidata(fig, data);
    
    end
end

