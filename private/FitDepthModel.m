function FitDepthModel(varargin)
% FitDepthModel is called by WaterTankAnalysis and fits exponential models 
% to water tank data. The models are from J. Welleweerd and Theo van Soest.
% The models consist of a fourth-degree polynomial exponential with
% separate buildup exponential.
%
% This function can also be executed independently. When executed without 
% any inputs, the function will prompt the user to load a profile dataset 
% (of any type supported by ParseProfile), ask whether to apply a Photon or 
% Electron model, and then display the results in a new figure. Note that 
% this assumes that the profile data is already corrected for EPOM, depth 
% ionization to dose, etc. Alternatively, executed from within 
% WaterTankAnalysis, the currently loaded dataset will be used with all
% processing corrections (EPOM, depth ionization to dose, smoothing, etc.) 
% applied.
%
% When executed from within WaterTankAnalysis, the energy modality is 
% automatically determined from the currently selected energy. In addition,
% the config.txt BUILUP_DAMPER is applied.
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
if exist('Event', 'file') == 2
    Event('Fitting analytical PDD models to depth profiles');
end

% Turn off warnings
warning off;

% Define colormap
cmap = [0.0000    0.4470    0.7410
    0.8500    0.3250    0.0980
    0.9290    0.6940    0.1250
    0.4940    0.1840    0.5560
    0.4660    0.6740    0.1880
    0.3010    0.7450    0.9330
    0.6350    0.0780    0.1840];

%% Load data
% If profiles were provided
if nargin >= 1 && ~isempty(varargin{1})
    
    profiles = varargin{1};

% Otherwise, prompt the user to select the file
else
    
    % Log action
    if exist('Event', 'file') == 2
        Event('Prompting user to select file type');
    end
    
    % Get list of available file selection options
    types = ParseProfile();
    
    % Prompt user to select a type
    [s,ok] = listdlg('PromptString','Select a file type to load:', ...
        'SelectionMode', 'single', 'ListString',types, ...
        'ListSize', [300 100]);
    
    % If user clicked cancel, return
    if ok == 0
        
        % Log action
        if exist('Event', 'file') == 2
            Event('The user clicked cancel');
        end
        
        return;
    end
    
    % Retrieve current file type and parse extension tokens
    t = regexp(types{s}, '\((.+)\)', 'tokens');
    if ~isempty(t)
        ext = strsplit(t{end}{1}, ', ')';
    else
        ext = '*.*';
    end
    
    % Log action
    if exist('Event', 'file') == 2
        Event('Prompting user to select files');
    end
       
    % Request the user to select the profile
    [name, path] = uigetfile(ext, ['Select the ', types{s}, ...
        'profiles to load'], userpath, 'MultiSelect', 'on');
    
    % If a file was selected
    if iscell(name) || sum(name ~= 0)

        % If not cell array, cast as one
        if ~iscell(name)
           
            % Store filenames
            files = cell(1);
            files{1} = name;
        else

            % Store filenames
            files = name;
        end
        
        % Execute ParseProfile
        data = ParseProfile(fullfile(path, files), s);
        profiles = data.profiles;
    else
        
        % Log action
        if exist('Event', 'file') == 2
            Event('The user clicked cancel');
        end
        
        return;
    end
    
    % Clear temporary variables
    clear types s ok t ext name path files data; 
end

% If an energy parameter was provided
if nargin >= 2
    
    % Parse beam type from energy
    if contains(varargin{2}, 'e', 'IgnoreCase', true)
        energy = 'Electron';
    else
        energy = 'Photon';
    end
    
% Otherwise, ask the user    
else
    energy = questdlg('What type of model should be applied?', ...
        'Energy Menu', 'Photon', 'Electron', 'Photon');
end

% Log action
if exist('Event', 'file') == 2
    Event(['Model type set to ', energy]);
end

% If configuration options were provided
if nargin >= 3 && isstruct(varargin{3}) && isfield(varargin{3}, ...
        'BUILDUP_DAMPER') && isfield(varargin{3}, ...
        'LEVENBERG_ITERS')
    
    % Use provided damper
    d = varargin{3}.BUILDUP_DAMPER;
    iter = varargin{3}.LEVENBERG_ITERS;
else
    
    % Otherwise use default damper value of 1.15 and 500 iterations
    d = 1.15;
    iter = 500;
end

% Log action
if exist('Event', 'file') == 2
    Event(sprintf('Buildup damper set to %0.3f', d));
    Event(sprintf('Number of pertubation iterations set to %i', iter));
end

%% Fit models
% Initialize counter
c = 0;

% Initialize figure data
models = {};
results = {};
names = {'Parameters'};

% Start progress bar
h = waitbar(0, 'Computing model for profile 0');

% Loop through each profile
for i = 1:length(profiles)
    
    % Update waitbar
    waitbar((i-1)/length(profiles), h, ...
        sprintf('Computing model for profile %i', i));
    
    % If Z changes, this is a depth profile
    if (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1
        
        % Log action
        if exist('Event', 'file') == 2
            Event(sprintf('Profile %i identified as depth profile', i));
        end
        
        % Increment counter
        c = c + 1;
        names{c+1} = sprintf('Curve %i', c);
        
        % Normalize profile to max value
        profiles{i}(:,4) = profiles{i}(:,4) / max(profiles{i}(:,4));
                
        % Fit model according to energy
        switch energy
            
            % Photon model
            case 'Photon'
            
                % Set parameter list
                results(:,1) = {
                    'I1'
                    'mu1'
                    'mu2'
                    'mu3'
                    'mu4'
                    'Ib'
                    'mub'
                    'RMS Error'
                    'Adj. R^2'
                };
                
                % Find range of depths greater than 1
                lI = find(profiles{i}(:,3) > 0, 1, 'first');
                uI = find(profiles{i}(:,3) > 0, 1, 'last');
            
                % Define initial values
                source = [1.087 3.3e-3 -1.6e-5 5.9e-8 -7.7e-11 0.65 0.14];
                
                % Set optimization options
                opts = statset('nlinfit');
                opts.RobustWgtFun = '';
                opts.MaxIter = 100;

                % Initialize return array
                models{c} = [];
                
                % Loop through random source pertubation iterations
                for j = 1:iter
                    
                    % Update waitbar
                    waitbar((i-1)/length(profiles) + j/(iter * ...
                        length(profiles)), h);
                    
                    % Pertubate source values
                    if j == 1
                        s = source;
                    else
                        s = source + source .* ...
                            (rand(1, length(source)) - 0.5) * 2;
                    end
                    
                    % Execute fitting in try/catch in case Inf/NaN is found
                    try
                        % Fit Welleweerd/van Soest analytical model to PDD
                        fit = fitnlm(profiles{i}(lI:uI,3), ...
                            profiles{i}(lI:uI,4), ['y~a*exp((-b+(c+(d+e*x)', ...
                            '*x)*x)*x) - f*exp(-g*x^', sprintf('%0.2f', d), ...
                            ')'],  s, 'CoefficientNames', {'a', 'b', 'c', ...
                            'd', 'e', 'f', 'g'}, 'Options', opts);
                        
                        % If this fit is better than previous, use it
                        if isempty(models{c}) || fit.RMSE < models{c}.RMSE
                            
                            % Log action
                            if exist('Event', 'file') == 2
                                Event(sprintf('Iteration %i RMSE = %0.4f', ...
                                    j, fit.RMSE));
                            end
                            
                            % Store fit
                            models{c} = fit;
                        end
                        
                        % If the RMS error is less than 0.002, break
                        if fit.RMSE < 0.003
                            
                            % Log action
                            if exist('Event', 'file') == 2
                                Event(sprintf(['Iterations stopped at %i ', ...
                                    'due to RMSE threshold'], j));
                            end
                            
                            % Continue to next profile
                            break;
                        end
                    catch
                        
                    end
                end

                % If a valid model was returned
                if ~isempty(models{c})

                    % Set values
                    results(1:7,1+c) = ...
                        num2cell(models{c}.Coefficients.Estimate); 

                    % Store additional statistics
                    results{8,1+c} = models{c}.RMSE; %#ok<*AGROW>
                    results{9,1+c} = models{c}.Rsquared.Adjusted;
                end
                
            % Electron model
            case 'Electron'
                
                % Set parameter list
                results(:,1) = {
                    'I0'
                    'I1'
                    'mu1'
                    'mu2'
                    'mu3'
                    'mu4'
                    'd0'
                    'Ib'
                    'mub'
                    'Ix'
                    'mx1'
                    'mx2'
                    'RMS Error'
                    'Adj. R^2'
                };
            
                % Find range of depths greater than 1
                lI = find(profiles{i}(:,3) > 0, 1, 'first');
                uI = find(profiles{i}(:,3) > 0, 1, 'last');
                [~ ,d0] = max(profiles{i}(lI:uI,4));
                
                % Define initial values
                source = [2 2 0.05 0.0014 0.000016 0.00000025 ...
                    profiles{i}(d0,3) -8.4 0.12 1.4 2 2];
                
                % Set optimization options
                opts = statset('nlinfit');
                opts.RobustWgtFun = '';
                opts.MaxIter = 100;

                % Initialize return array
                models{c} = [];
                
                % Loop through random source pertubation iterations
                for j = 1:iter
                    
                    % Update waitbar
                    waitbar((i-1)/length(profiles) + j/(iter * ...
                        length(profiles)), h);
                    
                    % Pertubate source values
                    if j == 1
                        s = source;
                    else
                        s = source + source .* (rand(1, ...
                            length(source)) - 0.5) * 4;
                    end
                    
                    % Execute fitting in try/catch in case Inf/NaN is found
                    try
                        % Fit Welleweerd/van Soest analytical model to PDD
                        fit = fitnlm(profiles{i}(lI:uI,3), ...
                            profiles{i}(lI:uI,4), ...
                            ['y ~ a/(1+b*exp((-c+(d+(e+f*(x-g))*(x-g))', ...
                            '*(x-g))*(x-g))+h*exp(-i*x))+j*exp((-k+l*x', ...
                            '/100)*x/100)'],  s, 'CoefficientNames', ...
                            {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', ...
                            'j', 'k', 'l'}, 'Options', opts);
                        
                        % If this fit is better than previous, use it
                        if isempty(models{c}) || fit.RMSE < models{c}.RMSE
                            
                            % Log action
                            if exist('Event', 'file') == 2
                                Event(sprintf('Iteration %i RMSE = %0.4f', ...
                                    j, fit.RMSE));
                            end
                            
                            % Store fit
                            models{c} = fit;
                        end
                        
                        % If the RMS error is less than 0.003, break
                        if fit.RMSE < 0.003
                            
                            % Log action
                            if exist('Event', 'file') == 2
                                Event(sprintf(['Iterations stopped at %i ', ...
                                    'due to RMSE threshold'], j));
                            end
                            
                            % Continue to next profile
                            break;
                        end
                    catch
                        
                    end
                end
            
                % If a valid model was returned
                if ~isempty(models{c})

                    % Set values
                    results(1:12,1+c) = ...
                        num2cell(models{c}.Coefficients.Estimate);

                    % Store additional statistics
                    results{13,1+c} = models{c}.RMSE;
                    results{14,1+c} = models{c}.Rsquared.Adjusted;
                end
        end
    end 
end

% Close waitbar
close(h);
clear h;

%% Display results
% Log action
if exist('Event', 'file') == 2
    Event('Opening figure to display model results');
end
                            
% Create new figure to display PDD models
fig = figure('Position', [100 100 1020 500], 'MenuBar', 'none', 'Name', ...
    'PDD Models');

% Create results table
if isempty(results)
    results{1,1} = 'No depth profiles were identified';
end
uitable('Data', results, 'ColumnName', names, 'Position', ...
    [30 125 475 340], 'RowName', [], 'ColumnEditable', logical(zeros(1, ...
    size(results,2))), 'Units', 'normalized'); %#ok<LOGL>

% Create extrapolation table
uitable('Data', horzcat({'Depth (mm)';'Predicted'}, ...
        cell(2, size(results,2)-1)), 'ColumnName', names, 'Position', ...
        [30 30 475 70], 'RowName', [], 'ColumnEditable', logical([0, ones(1, ...
        size(results,2)-1)]), 'Units', 'normalized', 'CellEditCallback', ...
        @calcModel);
    
% Plot calculated output factors
axes('Position', [0.55 0.13 0.41 0.8]);

% Reset counter
c = 0;

% Loop through each profile
for i = 1:length(profiles)
    
    % If Z changes, this is a depth profile
    if (max(profiles{i}(:,3)) - min(profiles{i}(:,3))) > 1
        
        % Increment counter
        c = c + 1;
        
        % Plot calculated values
        plot(profiles{i}(:,3), profiles{i}(:,4), 's', 'Color', cmap(c,:), ...
            'MarkerFaceColor', cmap(c,:), 'MarkerSize', 2);
        xlim([0 max(profiles{i}(:,3))]);
        hold on;

        % Plot predicted values
        if ~isempty(models{c})
            plot(profiles{i}(:,3), feval(models{c}, profiles{i}(:,3)), ...
                '-', 'Color', cmap(c,:));
        end
    end
end

% Finish plot
ylim([0 1.05]);
hold off;
xlabel('Depth (mm)');
ylabel('Relative Dose');
legend({'Measured', 'Predicted'});
grid on;
box on;
zoom on;

% Clear temporary data
clear c cmap d d0 energy fit i iter j lI names opts profiles results s ...
    source uI;

% Update GUI data
guidata(fig, models);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function calcModel(hObject, eventdata)
    % calcDifference is called when the user enters output factor data, and
    % will update the plot and table with the provided values.

        % Get current tabular data
        t = get(hObject, 'Data');
    
        % If a depth was edited/added and model data exists
        if eventdata.Indices(1) == 1 && ...
                ~isempty(models{eventdata.Indices(2)-1})
            
            % Parse depth as number
            if ischar(eventdata.NewData)
                t{1, eventdata.Indices(2)} = str2double(eventdata.NewData);
            end
            
            % Evaluate model
            t{2, eventdata.Indices(2)} = ...
                feval(models{eventdata.Indices(2)-1}, ...
                t{1, eventdata.Indices(2)});
        end
        
        % Set current tabular data
        set(hObject, 'Data', t);
        
        % Clear temporary variables
        clear t;
    end
end