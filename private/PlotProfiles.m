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

%% IEC X
if nargin < 2
    
    % Enable axes and set focus
    set(allchild(handles.iecx),'visible','on'); 
    set(handles.iecx,'visible','on');
    axes(handles.iecx);
    cla reset;
end

% Initialize counter
c = 0;

% Loop through each profile
for i = 1:length(handles.processed)
    
    % If X changes, this is an X profile
    if handles.processed{i}(1,1) ~= handles.processed{i}(2,1)
    
        % Increment counter
        c = c + 1;
        
        % Plot measured profile
        yyaxis left;
        plot(handles.processed{i}(:,1), handles.processed{i}(:,4), '-', ...
            'Color', cmap(c,:));

        % Hold remaining plots
        if c == 1
            xlim([min(handles.processed{i}(:,1)) ...
                max(handles.processed{i}(:,1))]);
            hold on;
        end
        
        % Plot reference profile
        plot(handles.processed{i}(:,1), handles.processed{i}(:,5), '--', ...
            'Color', cmap(c,:));
        
        % Plot Gamma
        yyaxis right;
        if c == 1
            hold off;
        end
        plot(handles.processed{i}(:,1), handles.processed{i}(:,6), ':', ...
            'Color', cmap(c,:));
        
        % Hold remaining plots
        if c == 1
            hold on;
        end
    end
end

% Finish plot and set formatting
hold off;
grid on;
box on;
xlabel('IEC X Axis Position (mm)');
yyaxis left;
zoom on;
if get(handles.normalize, 'Value') > 1
    ylabel('Relative Dose');
    ylim([0 1.2]);
else
    ylabel('Signal');
end
yyaxis right;
ylabel('Gamma');
if c > 0
    legend('Measured', 'Reference');
    
    % If saving the plot to a file
    if nargin == 2
        Event(['Saving IECX plot to ', fullfile(varargin{1}, ['IECX.', ...
            lower(handles.config.PLOT_SAVE_FORMAT)])]);
        saveas(f, fullfile(varargin{1}, ['IECX.', ...
            lower(handles.config.PLOT_SAVE_FORMAT)]));
    end
end

%% IEC Y
if nargin < 2
    
    % Enable axes and set focus
    set(allchild(handles.iecy),'visible','on'); 
    set(handles.iecy,'visible','on');
    axes(handles.iecy);
    cla reset;
end

% Initialize counter
c = 0;

% Loop through each profile
for i = 1:length(handles.processed)
    
    % If Y changes, this is an Y profile
    if handles.processed{i}(1,2) ~= handles.processed{i}(2,2)
    
        % Increment counter
        c = c + 1;
        
        % Plot measured profile
        yyaxis left;
        plot(handles.processed{i}(:,2), handles.processed{i}(:,4), '-', ...
            'Color', cmap(c,:));
        
        % Hold remaining plots
        if c == 1
            xlim([min(handles.processed{i}(:,2)) ...
                max(handles.processed{i}(:,2))]);
            hold on;
        end

        % Plot reference profile
        plot(handles.processed{i}(:,2), handles.processed{i}(:,5), '--', ...
            'Color', cmap(c,:));
        
        % Plot Gamma
        yyaxis right;
        if c == 1
            hold off;
        end
        plot(handles.processed{i}(:,2), handles.processed{i}(:,6), ':', ...
            'Color', cmap(c,:));
        
        % Hold remaining plots
        if c == 1
            hold on;
        end
    end
end

% Finish plot and set formatting
hold off;
grid on;
box on;
xlabel('IEC Y Axis Position (mm)');
yyaxis left;
zoom on;
if get(handles.normalize, 'Value') > 1
    ylabel('Relative Dose');
    ylim([0 1.2]);
else
    ylabel('Signal');
end
yyaxis right;
ylabel('Gamma');
if c > 0
    legend('Measured', 'Reference');
    
    % If saving the plot to a file
    if nargin == 2
        Event(['Saving IECY plot to ', fullfile(varargin{1}, ['IECY.', ...
            lower(handles.config.PLOT_SAVE_FORMAT)])]);
        saveas(f, fullfile(varargin{1}, ['IECY.', ...
            lower(handles.config.PLOT_SAVE_FORMAT)]));
    end
end

%% IEC Z
if nargin < 2

    % Enable axes and set focus
    set(allchild(handles.iecz),'visible','on'); 
    set(handles.iecz,'visible','on');
    axes(handles.iecz);
    cla reset;
end

% Initialize counter
c = 0;

% Loop through each profile
for i = 1:length(handles.processed)
    
    % If Z changes, this is a depth profile
    if handles.processed{i}(1,3) ~= handles.processed{i}(2,3)
    
        % Increment counter
        c = c + 1;
        
        % Plot measured profile
        yyaxis left;
        plot(handles.processed{i}(:,3), handles.processed{i}(:,4), '-', ...
            'Color', cmap(c,:));
        
        % Hold remaining plots
        if c == 1
            xlim([min(handles.processed{i}(:,3)) ...
                max(handles.processed{i}(:,3))]);
            hold on;
        end

        % Plot reference profile
        plot(handles.processed{i}(:,3), handles.processed{i}(:,5), '--', ...
            'Color', cmap(c,:));
        
        % Plot Gamma
        yyaxis right;
        if c == 1
            hold off;
        end
        plot(handles.processed{i}(:,3), handles.processed{i}(:,6), ':', ...
            'Color', cmap(c,:));
        
        % Hold remaining plots
        if c == 1
            hold on;
        end
    end
end

% Finish plot and set formatting
hold off;
grid on;
box on;
xlabel('Depth (mm)');
yyaxis left;
zoom on;
if get(handles.normalize, 'Value') > 1
    ylabel('Relative Dose');
    ylim([0 1.2]);
else
    ylabel('Signal');
end
yyaxis right;
ylabel('Gamma');
if c > 0
    legend('Measured', 'Reference');
    
    % If saving the plot to a file
    if nargin == 2
        Event(['Saving IECZ plot to ', fullfile(varargin{1}, ['IECZ.', ...
            lower(handles.config.PLOT_SAVE_FORMAT)])]);
        saveas(f, fullfile(varargin{1}, ['IECZ.', ...
            lower(handles.config.PLOT_SAVE_FORMAT)]));
    end
end

% Close save figure
if nargin == 2
    close(f);
end