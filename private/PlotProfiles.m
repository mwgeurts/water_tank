function handles = PlotProfiles(handles, varargin)
% PlotProfiles plots the X, Y, and Z profiles for WaterTankAnalysis using
% the data contained in handles.processeds. If called with additional
% arguments, PlotProfiles will save the plots to the folder specified by
% varargin{1}.
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

% Define colormap
cmap = [0.0000    0.4470    0.7410
    0.8500    0.3250    0.0980
    0.9290    0.6940    0.1250
    0.4940    0.1840    0.5560
    0.4660    0.6740    0.1880
    0.3010    0.7450    0.9330
    0.6350    0.0780    0.1840];

% If printing the figures
if nargin == 2
    
    % Create a new empty figure
    f = figure('Color', [1 1 1], 'Position', [100 100 1000 500]);
    set(f, 'PaperUnits', 'centimeters');
    set(f, 'PaperPosition', [0 0 25 12]);
end

% Set figure axes colors
set(gcf,'defaultAxesColorOrder',[0 0 0; 0 0 0]);

% Define available GUI plot axes and their respective dropdown menus
plots = {
    'iecx'  'optionx'
    'iecy'  'optiony'
    'iecz'  'optionz'
};

%% IEC X
% Loop through each plot
for p = 1:size(plots, 1)
    
    % If this plot is selected
    if nargin < 2 && get(handles.(plots{p,2}), 'Value') == 1 
        
        % Enable axes and set focus
        set(handles.(plots{p,2}),'visible','on');
        set(allchild(handles.(plots{p,1})),'visible','on'); 
        set(handles.(plots{p,1}),'visible','on');
        axes(handles.(plots{p,1})); %#ok<*LAXES>
        cla reset;
      
    % Otherwise, if this plot was not selected (but still plotting to GUI)
    % then skip ahead
    elseif nargin < 2
        continue
    end

    % Initialize counter
    c = 0;

    % Loop through each profile
    for i = 1:length(handles.processed)

        % If X changes and Y does not, this is an X profile
        if (max(handles.processed{i}(:,1)) - ...
                min(handles.processed{i}(:,1))) > 1 && ...
                (max(handles.processed{i}(:,2)) - ...
                min(handles.processed{i}(:,2))) < 1

            % Increment counter
            c = c + 1;

            % Plot measured profile
            yyaxis left;
            plot(handles.processed{i}(:,1), handles.processed{i}(:,4), '-', ...
                'Color', cmap(mod(c-1, size(cmap,1))+1,:));

            % Hold remaining plots
            if c == 1
                xlim([min(handles.processed{i}(:,1)) ...
                    max(handles.processed{i}(:,1))]);
                ylim([0 ceil(max(handles.processed{i}(:,4)-0.125)/0.25+1)*0.25]);
                hold on;
            end

            % Plot reference profile
            plot(handles.processed{i}(:,1), handles.processed{i}(:,5), '--', ...
                'Color', cmap(mod(c-1, size(cmap,1))+1,:));

            % Plot Gamma
            yyaxis right;
            if c == 1
                hold off;
            end
            plot(handles.processed{i}(:,1), handles.processed{i}(:,6), ':', ...
                'Color', cmap(mod(c-1, size(cmap,1))+1,:));

            % Hold remaining plots
            if c == 1
                hold on;
            end
        end
    end

    % Finish plot and set formatting
    set(gca, 'fontsize', 9);
    hold off;
    grid on;
    box on;
    
    % Add X axis label
    xlabel('IEC X Axis Position (mm)');
    
    % Add left Y axis label
    yyaxis left;
    zoom on;
    if get(handles.normalize, 'Value') > 1
        ylabel('Relative Dose');
    else
        ylabel('Signal');
    end
    
    % Add right Y axis label
    yyaxis right;
    ylabel('Gamma');
    
    % If at least one dataset was plotted
    if c > 0
        
        % Add a legend
        legend('Measured', 'Reference');

        % If saving the plot to a file
        if nargin == 2
            Event(['Saving IECX plot to ', fullfile(varargin{1}, ['IECX.', ...
                lower(handles.config.PLOT_SAVE_FORMAT)])]);
            saveas(f, fullfile(varargin{1}, ['IECX.', ...
                lower(handles.config.PLOT_SAVE_FORMAT)]));
            break
        end
    end
    
    % If file was saved, break to next plot type
    if nargin == 2
        break;
    end
end

%% IEC Y
% Loop through each plot
for p = 1:size(plots, 1)
    
    % If this plot is selected
    if nargin < 2 && get(handles.(plots{p,2}), 'Value') == 2 
        
        % Enable axes and set focus
        set(handles.(plots{p,2}),'visible','on');
        set(allchild(handles.(plots{p,1})),'visible','on'); 
        set(handles.(plots{p,1}),'visible','on');
        axes(handles.(plots{p,1}));
        cla reset;
      
    % Otherwise, if this plot was not selected (but still plotting to GUI)
    % then skip ahead
    elseif nargin < 2
        continue
    end

    % Initialize counter
    c = 0;

    % Loop through each profile
    for i = 1:length(handles.processed)

        % If Y changes and X does not, this is a Y profile
        if (max(handles.processed{i}(:,1)) - ...
                min(handles.processed{i}(:,1))) < 1 && ...
                (max(handles.processed{i}(:,2)) - ...
                min(handles.processed{i}(:,2))) > 1

            % Increment counter
            c = c + 1;

            % Plot measured profile
            yyaxis left;
            plot(handles.processed{i}(:,2), handles.processed{i}(:,4), '-', ...
                'Color', cmap(mod(c-1, size(cmap,1))+1,:));

            % Hold remaining plots
            if c == 1
                xlim([min(handles.processed{i}(:,2)) ...
                    max(handles.processed{i}(:,2))]);
                ylim([0 ceil(max(handles.processed{i}(:,4)-0.125)/0.25+1)*0.25]);
                hold on;
            end

            % Plot reference profile
            plot(handles.processed{i}(:,2), handles.processed{i}(:,5), '--', ...
                'Color', cmap(mod(c-1, size(cmap,1))+1,:));

            % Plot Gamma
            yyaxis right;
            if c == 1
                hold off;
            end
            plot(handles.processed{i}(:,2), handles.processed{i}(:,6), ':', ...
                'Color', cmap(mod(c-1, size(cmap,1))+1,:));

            % Hold remaining plots
            if c == 1
                hold on;
            end
        end
    end

    % Finish plot and set formatting
    set(gca, 'fontsize', 9);
    hold off;
    grid on;
    box on;
    
    % Add X axis label
    xlabel('IEC Y Axis Position (mm)');
    
    % Add left Y axis label
    yyaxis left;
    zoom on;
    if get(handles.normalize, 'Value') > 1
        ylabel('Relative Dose');
    else
        ylabel('Signal');
    end
    
    % Add right Y axis label
    yyaxis right;
    ylabel('Gamma');
    
    % If at least one dataset was plotted
    if c > 0
        
        % Add a legend
        legend('Measured', 'Reference');

        % If saving the plot to a file
        if nargin == 2
            Event(['Saving IECY plot to ', fullfile(varargin{1}, ['IECY.', ...
                lower(handles.config.PLOT_SAVE_FORMAT)])]);
            saveas(f, fullfile(varargin{1}, ['IECY.', ...
                lower(handles.config.PLOT_SAVE_FORMAT)]));
            break
        end
    end
    
    % If file was saved, break to next plot type
    if nargin == 2
        break;
    end
end

%% IEC Z
% Loop through each plot
for p = 1:size(plots, 1)
    
    % If this plot is selected
    if nargin < 2 && get(handles.(plots{p,2}), 'Value') == 3
        
        % Enable axes and set focus
        set(handles.(plots{p,2}),'visible','on');
        set(allchild(handles.(plots{p,1})),'visible','on'); 
        set(handles.(plots{p,1}),'visible','on');
        axes(handles.(plots{p,1}));
        cla reset;
      
    % Otherwise, if this plot was not selected (but still plotting to GUI)
    % then skip ahead
    elseif nargin < 2
        continue
    end

    % Initialize counter
    c = 0;

    % Loop through each profile
    for i = 1:length(handles.processed)

        % If Z changes, this is a depth profile
        if (max(handles.processed{i}(:,3)) - ...
                min(handles.processed{i}(:,3))) > 1

            % Increment counter
            c = c + 1;

            % Plot measured profile
            yyaxis left;
            plot(handles.processed{i}(:,3), handles.processed{i}(:,4), '-', ...
                'Color', cmap(mod(c-1, size(cmap,1))+1,:));

            % Hold remaining plots
            if c == 1
                xlim([min(handles.processed{i}(:,3)) ...
                    max(handles.processed{i}(:,3))]);
                ylim([0 ceil(max(handles.processed{i}(:,4)-0.125)/0.25+1)*0.25]);
                hold on;
            end

            % Plot reference profile
            plot(handles.processed{i}(:,3), handles.processed{i}(:,5), '--', ...
                'Color', cmap(mod(c-1, size(cmap,1))+1,:));

            % Plot Gamma
            yyaxis right;
            if c == 1
                hold off;
            end
            plot(handles.processed{i}(:,3), handles.processed{i}(:,6), ':', ...
                'Color', cmap(mod(c-1, size(cmap,1))+1,:));

            % Hold remaining plots
            if c == 1
                hold on;
            end
        end
    end

    % Finish plot and set formatting
    set(gca, 'fontsize', 9);
    hold off;
    grid on;
    box on;
    
    % Add X axis label
    xlabel('Depth (mm)');
    
    % Add left Y axis label
    yyaxis left;
    zoom on;
    if get(handles.normalize, 'Value') > 1
        ylabel('Relative Dose');
    else
        ylabel('Signal');
    end
    
    % Add right Y axis label
    yyaxis right;
    ylabel('Gamma');
    
    % If at least one dataset was plotted
    if c > 0
        
        % Add a legend
        legend('Measured', 'Reference');

        % If saving the plot to a file
        if nargin == 2
            Event(['Saving IECZ plot to ', fullfile(varargin{1}, ['IECZ.', ...
                lower(handles.config.PLOT_SAVE_FORMAT)])]);
            saveas(f, fullfile(varargin{1}, ['IECZ.', ...
                lower(handles.config.PLOT_SAVE_FORMAT)]));
            break
        end
    end
    
    % If file was saved, break to next plot type
    if nargin == 2
        break;
    end
end

%% Positive Diagonal
% Loop through each plot
for p = 1:size(plots, 1)
    
    % If this plot is selected
    if nargin < 2 && get(handles.(plots{p,2}), 'Value') == 4
        
        % Enable axes and set focus
        set(handles.(plots{p,2}),'visible','on');
        set(allchild(handles.(plots{p,1})),'visible','on'); 
        set(handles.(plots{p,1}),'visible','on');
        axes(handles.(plots{p,1}));
        cla reset;
      
    % Otherwise, if this plot was not selected (but still plotting to GUI)
    % then skip ahead
    elseif nargin < 2
        continue
    end

    % Initialize counter
    c = 0;

    % Loop through each profile
    for i = 1:length(handles.processed)

        % If X and Y both change and their product is positive
        if (max(handles.processed{i}(:,1)) - ...
                min(handles.processed{i}(:,1))) > 1 && ...
                (max(handles.processed{i}(:,2)) - ...
                min(handles.processed{i}(:,2))) > 1 && ...
                mean(handles.processed{i}(:,1) .* ...
                handles.processed{i}(:,2)) > 0

            % Increment counter
            c = c + 1;

            % Plot measured profile
            yyaxis left;
            plot(sqrt(handles.processed{i}(:,1).^2 + ...
                handles.processed{i}(:,2).^2) .* ...
                sign(handles.processed{i}(:,1)), ...
                handles.processed{i}(:,4), '-', 'Color', cmap(mod(c-1, size(cmap,1))+1,:));

            % Hold remaining plots
            if c == 1
                xlim([min(sqrt(handles.processed{i}(:,1).^2 + ...
                    handles.processed{i}(:,2).^2) .* ...
                    sign(handles.processed{i}(:,1))) ...
                    max(sqrt(handles.processed{i}(:,1).^2 + ...
                    handles.processed{i}(:,2).^2) .* ...
                    sign(handles.processed{i}(:,1)))]);
                ylim([0 ceil(max(handles.processed{i}(:,4)-0.125)/0.25+1)*0.25]);
                hold on;
            end

            % Plot reference profile
            plot(sqrt(handles.processed{i}(:,1).^2 + ...
                handles.processed{i}(:,2).^2) .* ...
                sign(handles.processed{i}(:,1)), ...
                handles.processed{i}(:,5), '--', 'Color', cmap(mod(c-1, size(cmap,1))+1,:));

            % Plot Gamma
            yyaxis right;
            if c == 1
                hold off;
            end
            plot(sqrt(handles.processed{i}(:,1).^2 + ...
                handles.processed{i}(:,2).^2) .* ...
                sign(handles.processed{i}(:,1)), ...
                handles.processed{i}(:,6), ':', 'Color', cmap(mod(c-1, size(cmap,1))+1,:));

            % Hold remaining plots
            if c == 1
                hold on;
            end
        end
    end

    % Finish plot and set formatting
    set(gca, 'fontsize', 9);
    hold off;
    grid on;
    box on;
    
    % Add X axis label
    xlabel('Positive Diagonal Position (mm)');
    
    % Add left Y axis label
    yyaxis left;
    zoom on;
    if get(handles.normalize, 'Value') > 1
        ylabel('Relative Dose');
    else
        ylabel('Signal');
    end
    
    % Add right Y axis label
    yyaxis right;
    ylabel('Gamma');
    
    % If at least one dataset was plotted
    if c > 0
        
        % Add a legend
        legend('Measured', 'Reference');

        % If saving the plot to a file
        if nargin == 2
            Event(['Saving Positive Diagonal plot to ', ...
                fullfile(varargin{1}, ['PDIAG.', ...
                lower(handles.config.PLOT_SAVE_FORMAT)])]);
            saveas(f, fullfile(varargin{1}, ['PDIAG.', ...
                lower(handles.config.PLOT_SAVE_FORMAT)]));
            break
        end
    end
    
    % If file was saved, break to next plot type
    if nargin == 2
        break;
    end
end

%% Negative Diagonal
% Loop through each plot
for p = 1:size(plots, 1)
    
    % If this plot is selected
    if nargin < 2 && get(handles.(plots{p,2}), 'Value') == 5
        
        % Enable axes and set focus
        set(handles.(plots{p,2}),'visible','on');
        set(allchild(handles.(plots{p,1})),'visible','on'); 
        set(handles.(plots{p,1}),'visible','on');
        axes(handles.(plots{p,1}));
        cla reset;
      
    % Otherwise, if this plot was not selected (but still plotting to GUI)
    % then skip ahead
    elseif nargin < 2
        continue
    end

    % Initialize counter
    c = 0;

    % Loop through each profile
    for i = 1:length(handles.processed)

        % If X and Y both change and their product is negative
        if (max(handles.processed{i}(:,1)) - ...
                min(handles.processed{i}(:,1))) > 1 && ...
                (max(handles.processed{i}(:,2)) - ...
                min(handles.processed{i}(:,2))) > 1 && ...
                mean(handles.processed{i}(:,1) .* ...
                handles.processed{i}(:,2)) < 0

            % Increment counter
            c = c + 1;

            % Plot measured profile
            yyaxis left;
            plot(sqrt(handles.processed{i}(:,1).^2 + ...
                handles.processed{i}(:,2).^2) .* ...
                sign(handles.processed{i}(:,1)), ...
                handles.processed{i}(:,4), '-', 'Color', cmap(mod(c-1, size(cmap,1))+1,:));

            % Hold remaining plots
            if c == 1
                xlim([min(sqrt(handles.processed{i}(:,1).^2 + ...
                    handles.processed{i}(:,2).^2) .* ...
                    sign(handles.processed{i}(:,1))) ...
                    max(sqrt(handles.processed{i}(:,1).^2 + ...
                    handles.processed{i}(:,2).^2) .* ...
                    sign(handles.processed{i}(:,1)))]);
                ylim([0 ceil(max(handles.processed{i}(:,4)-0.125)/0.25+1)*0.25]);
                hold on;
            end

            % Plot reference profile
            plot(sqrt(handles.processed{i}(:,1).^2 + ...
                handles.processed{i}(:,2).^2) .* ...
                sign(handles.processed{i}(:,1)), ...
                handles.processed{i}(:,5), '--', 'Color', cmap(mod(c-1, size(cmap,1))+1,:));

            % Plot Gamma
            yyaxis right;
            if c == 1
                hold off;
            end
            plot(sqrt(handles.processed{i}(:,1).^2 + ...
                handles.processed{i}(:,2).^2) .* ...
                sign(handles.processed{i}(:,1)), ...
                handles.processed{i}(:,6), ':', 'Color', cmap(mod(c-1, size(cmap,1))+1,:));

            % Hold remaining plots
            if c == 1
                hold on;
            end
        end
    end

    % Finish plot and set formatting
    set(gca, 'fontsize', 9);
    hold off;
    grid on;
    box on;
    
    % Add X axis label
    xlabel('Negative Diagonal Position (mm)');
    
    % Add left Y axis label
    yyaxis left;
    zoom on;
    if get(handles.normalize, 'Value') > 1
        ylabel('Relative Dose');
    else
        ylabel('Signal');
    end
    
    % Add right Y axis label
    yyaxis right;
    ylabel('Gamma');
    
    % If at least one dataset was plotted
    if c > 0
        
        % Add a legend
        legend('Measured', 'Reference');

        % If saving the plot to a file
        if nargin == 2
            Event(['Saving Negative Diagonal plot to ', ...
                fullfile(varargin{1}, ['NDIAG.', ...
                lower(handles.config.PLOT_SAVE_FORMAT)])]);
            saveas(f, fullfile(varargin{1}, ['NDIAG.', ...
                lower(handles.config.PLOT_SAVE_FORMAT)]));
            break
        end
    end
    
    % If file was saved, break to next plot type
    if nargin == 2
        break;
    end
end

% Close save figure
if nargin == 2
    close(f);
end