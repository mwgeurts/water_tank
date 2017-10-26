function handles = PlotProfiles(handles)
% PlotProfiles plots the X, Y, and Z profiles for WaterTankAnalysis using
% the data contained in handles.profiles.
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

% Set figure axes colors
set(gcf,'defaultAxesColorOrder',[0 0 0; 0 0 0]);

%% IEC X
% Enable axes and set focus
set(allchild(handles.iecx),'visible','on'); 
set(handles.iecx,'visible','on');
axes(handles.iecx);

% Initialize counter
c = 0;

% Loop through each profile
for i = 1:length(handles.profile)
    
    % If X changes, this is an X profile
    if handles.profile{i}(1,1) ~= handles.profile{i}(2,1)
    
        % Increment counter
        c = c + 1;
        
        % Plot measured profile
        yyaxis left;
        plot(handles.profile{i}(:,1), handles.profile{i}(:,4), '-', ...
            'Color', cmap(c,:));

        % Hold remaining plots
        if c == 1
            xlim([min(handles.profile{i}(:,1)) ...
                max(handles.profile{i}(:,1))]);
            hold on;
        end
        
        % Plot reference profile
        plot(handles.profile{i}(:,1), handles.profile{i}(:,5), '--', ...
            'Color', cmap(c,:));
        
        % Plot Gamma
        yyaxis right;
        if c == 1
            hold off;
        end
        plot(handles.profile{i}(:,1), handles.profile{i}(:,6), ':', ...
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
legend('Measured', 'Reference');

%% IEC Y
% Enable axes and set focus
set(allchild(handles.iecy),'visible','on'); 
set(handles.iecy,'visible','on');
axes(handles.iecy);

% Initialize counter
c = 0;

% Loop through each profile
for i = 1:length(handles.profile)
    
    % If Y changes, this is an Y profile
    if handles.profile{i}(1,2) ~= handles.profile{i}(2,2)
    
        % Increment counter
        c = c + 1;
        
        % Plot measured profile
        yyaxis left;
        plot(handles.profile{i}(:,2), handles.profile{i}(:,4), '-', ...
            'Color', cmap(c,:));
        
        % Hold remaining plots
        if c == 1
            xlim([min(handles.profile{i}(:,2)) ...
                max(handles.profile{i}(:,2))]);
            hold on;
        end

        % Plot reference profile
        plot(handles.profile{i}(:,2), handles.profile{i}(:,5), '--', ...
            'Color', cmap(c,:));
        
        % Plot Gamma
        yyaxis right;
        if c == 1
            hold off;
        end
        plot(handles.profile{i}(:,2), handles.profile{i}(:,6), ':', ...
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
legend('Measured', 'Reference');

%% IEC Z
% Enable axes and set focus
set(allchild(handles.iecz),'visible','on'); 
set(handles.iecz,'visible','on');
axes(handles.iecz);

% Initialize counter
c = 0;

% Loop through each profile
for i = 1:length(handles.profile)
    
    % If Z changes, this is a depth profile
    if handles.profile{i}(1,3) ~= handles.profile{i}(2,3)
    
        % Increment counter
        c = c + 1;
        
        % Plot measured profile
        yyaxis left;
        plot(handles.profile{i}(:,3), handles.profile{i}(:,4), '-', ...
            'Color', cmap(c,:));
        
        % Hold remaining plots
        if c == 1
            xlim([min(handles.profile{i}(:,3)) ...
                max(handles.profile{i}(:,3))]);
            hold on;
        end

        % Plot reference profile
        plot(handles.profile{i}(:,3), handles.profile{i}(:,5), '--', ...
            'Color', cmap(c,:));
        
        % Plot Gamma
        yyaxis right;
        if c == 1
            hold off;
        end
        plot(handles.profile{i}(:,3), handles.profile{i}(:,6), ':', ...
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
legend('Measured', 'Reference');
