function pubSAFigures(mT, runType, dt, figFold)
% pubSAFigures Generates Clean Subset of Figures for Publication
% mT = the master behavior table from main_MouseSABehavior
% dt = current date time variable
% figFold = Name of the subfolder to save in (relative, folder name is suffiecient
% SS Note: 
mT.sessionType=categorical(mT.sessionType);
    if strcmp(runType, 'ER')
        titles = {'Self-Administration', 'Days 13-15', 'Extinction', 'Reinstatement'}; % titles of subplots 1-4 for each figure
    elseif strcmp(runType, 'BE')
        titles = {'Self-Administration', 'Days 13-15', 'Behavioral Economics', 'Retraining'};
    elseif strcmp(runType,'SA')
        titles = {'Self-Administration', 'Days 13-15'};
    end
    colorOptions = {'hue_range',[90 450],'lightness_range',[85 35],'chroma_range',[30 70]};
    figType = '.png'; % image save type
    
    %% Active Lever
    fnum = 1;
    figNames{fnum} = fullfile(figFold,[dt, '_ActiveLeverAcquire']);
    subset = {{'Acquire', {'Acquire'}}};
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'ActiveLever';
    yLabs{fnum} = 'Active Lever';
    grammOptions{fnum} = {'color', mT.Sex, 'lightness', mT.Strain};        
    orderOptions{fnum} = {'color', {'Female','Male'}, 'lightness', {'c57', 'CD1'}};
    legendOptions{fnum} = {'x','Sex'};
    donut{fnum} = false; 


    %% C57 Active Lever, Acquirers
    fnum = 2;
    figNames{fnum} = fullfile(figFold,[dt, '_ActiveLeverC57Acquire']);
    subset = {{'Strain', {'c57'}} ...
              {'Acquire', {'Acquire'}} ...
              };
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'ActiveLever';
    yLabs{fnum} = 'Active Lever';
    grammOptions{fnum} = {'color',mT.Sex};        
    orderOptions{fnum} = {'color',{'Female','Male'}};
    legendOptions{fnum} = {'x','Sex'};
    donut{fnum} = false; 

    %% CD1 Active Lever, Acquirers
    fnum = 3;
    figNames{fnum} = fullfile(figFold,[dt, '_ActiveLeverCD1Acquire']);
    subset = {{'Strain', {'CD1'}} ...
              {'Acquire', {'Acquire'}} ...
              };
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'ActiveLever';
    yLabs{fnum} = 'Active Lever';
    grammOptions{fnum} = {'color',mT.Sex};        
    orderOptions{fnum} = {'color',{'Female','Male'}};
    legendOptions{fnum} = {'x','Sex'};
    donut{fnum} = false; 

    %% C57 Active Lever
    % SS note: Bar graph axes being set weird compared to the rest, why? 
    fnum = 4;
    figNames{fnum} = fullfile(figFold,[dt, '_ActiveLeverC57']);
    subset = {{'Strain', {'c57'}}};
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'ActiveLever';
    yLabs{fnum} = 'Active Lever';
    grammOptions{fnum} = {'color',mT.Sex, 'lightness',mT.Acquire};        
    orderOptions{fnum} = {'color',{'Female','Male'}, 'lightness',{'NonAcquire','Acquire'}};
    legendOptions{fnum} = {'x','Sex'};
    donut{fnum} = true; 

    %% CD1 Active Lever
    % SS note: Bar graph axes being set weird compared to the rest, why?
    fnum = 5;
    figNames{fnum} = fullfile(figFold,[dt, '_ActiveLeverCD1']);
    subset = {{'Strain', {'CD1'}}};
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'ActiveLever';
    yLabs{fnum} = 'Active Lever';
    grammOptions{fnum} = {'color',mT.Sex, 'lightness',mT.Acquire};        
    orderOptions{fnum} = {'color',{'Female','Male'}, 'lightness',{'NonAcquire','Acquire'}};
    legendOptions{fnum} = {'x','Sex'};
    donut{fnum} = true; 

    %% C57 Inactive Lever
    % SS note: Bar graph axes being set weird compared to the rest, why?
    fnum = 6; 
    figNames{fnum} = fullfile(figFold,[dt, '_InactiveLeverC57']);
    subset = {{'Strain', {'c57'}}};
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'InactiveLever';
    yLabs{fnum} = 'Inactive Lever';
    grammOptions{fnum} = {'color',mT.Sex, 'lightness',mT.Acquire};        
    orderOptions{fnum} = {'color',{'Female','Male'}, 'lightness',{'NonAcquire','Acquire'}};
    legendOptions{fnum} = {'x','Sex'};
    donut{fnum} = false; 

    %% CD1 Inactive Lever
    % SS note: Bar graph axes being set weird compared to the rest, why?
    fnum = 7;
    figNames{fnum} = fullfile(figFold,[dt, '_InactiveLeverCD1']);
    subset = {{'Strain', {'CD1'}}};
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'InactiveLever';
    yLabs{fnum} = 'Inactive Lever';
    grammOptions{fnum} = {'color',mT.Sex, 'lightness',mT.Acquire};        
    orderOptions{fnum} = {'color',{'Female','Male'}, 'lightness',{'NonAcquire','Acquire'}};
    legendOptions{fnum} = {'x','Sex'};
    donut{fnum} = false; 

    %% C57 Head Entries, Acquirers
    fnum = 8;
    figNames{fnum} = fullfile(figFold,[dt, '_HeadEntriesC57Acquire']);
    subset = {{'Strain', {'c57'}} ...
              {'Acquire', {'Acquire'}} ...
              };
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'HeadEntries';
    yLabs{fnum} = 'Head Entries';
    grammOptions{fnum} = {'color',mT.Sex};        
    orderOptions{fnum} = {'color',{'Female','Male'}};
    legendOptions{fnum} = {'x','Sex'};
    donut{fnum} = false; 

    %% CD1 HeadEntries, Acquirers
    fnum = 9;
    figNames{fnum} = fullfile(figFold,[dt, '_HeadEntriesLeverCD1Acquire']);
    subset = {{'Strain', {'CD1'}} ...
              {'Acquire', {'Acquire'}} ...
              };
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'HeadEntries';
    yLabs{fnum} = 'Head Entries';
    grammOptions{fnum} = {'color',mT.Sex};        
    orderOptions{fnum} = {'color',{'Female','Male'}};
    legendOptions{fnum} = {'x','Sex'};
    donut{fnum} = false; 

    %% C57 Latency, Acquirers
    fnum = 10;
    figNames{fnum} = fullfile(figFold,[dt, '_LatencyC57Acquire']);
    subset = {{'Strain', {'c57'}} ...
              {'Acquire', {'Acquire'}} ...
              };
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'HeadEntries';
    yVars{fnum} = 'Latency';
    yLabs{fnum} = 'Head Entry Latency';
    grammOptions{fnum} = {'color',mT.Sex};        
    orderOptions{fnum} = {'color',{'Female','Male'}};
    legendOptions{fnum} = {'x','Sex'};
    donut{fnum} = false; 

    %% CD1 Latency, Acquirers
    fnum = 11;
    figNames{fnum} = fullfile(figFold,[dt, '_LatencyCD1Acquire']);
    subset = {{'Strain', {'CD1'}} ...
              {'Acquire', {'Acquire'}} ...
              };
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'Latency';
    yLabs{fnum} = 'Head Entry Latency';
    grammOptions{fnum} = {'color',mT.Sex};        
    orderOptions{fnum} = {'color',{'Female','Male'}};
    legendOptions{fnum} = {'x','Sex'};
    donut{fnum} = false; 

    %% C57 Intake, Acquirers
    fnum = 12;
    figNames{fnum} = fullfile(figFold,[dt, '_IntakeC57Acquire']);
    subset = {{'Strain', {'c57'}} ...
              {'Acquire', {'Acquire'}} ...
              };
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'Intake';
    yLabs{fnum} = 'Fentanyl Intake (ug/kg)';
    grammOptions{fnum} = {'color',mT.Sex};        
    orderOptions{fnum} = {'color',{'Female','Male'}};
    legendOptions{fnum} = {'x','Sex'};
    donut{fnum} = false; 

    %% CD1 Intake, Acquirers
    fnum = 13;
    figNames{fnum} = fullfile(figFold,[dt, '_IntakeCD1Acquire']);
    subset = {{'Strain', {'CD1'}} ...
              {'Acquire', {'Acquire'}} ...
              };
    subInds{fnum} = getSubInds(mT, subset);
    yVars{fnum} = 'Intake';
    yLabs{fnum} = 'Fentanyl Intake (ug/kg)';
    grammOptions{fnum} = {'color',mT.Sex};        
    orderOptions{fnum} = {'color',{'Female','Male'}};
    legendOptions{fnum} = {'x','Sex'};
    donut{fnum} = false; 
    

    % %%
    % fnum = 14;
    % figNames{fnum} = fullfile(figFold,[dt, '_Weight_C57_AM']);
    % subset = {{'Strain', {'c57'}} ...
    %           {'TimeOfBehavior', {'Morning'}} ...
    %           };
    % subInds{fnum} = getSubInds(mT, subset);
    % yVars{fnum} = 'Weight';
    % yLabs{fnum} = 'Weight (g)';
    % grammOptions{fnum} = {'color', mT.Chamber, 'lightness', mT.Sex};        
    % orderOptions{fnum} = {'lightness',{'Female','Male'}};
    % legendOptions{fnum} = {'x','Sex'};
    % donut{fnum} = false; 


    % %%
    % fnum = 15;
    % figNames{fnum} = fullfile(figFold,[dt, '_Weight_CD1_AM']);
    % subset = {{'Strain', {'CD1'}} ...
    %           {'TimeOfBehavior', {'Morning'}} ...
    %           };
    % subInds{fnum} = getSubInds(mT, subset);
    % yVars{fnum} = 'Weight';
    % yLabs{fnum} = 'Weight (g)';
    % grammOptions{fnum} = {'color', mT.Chamber, 'lightness', mT.Sex};        
    % orderOptions{fnum} = {'lightness',{'Female','Male'}};
    % legendOptions{fnum} = {'x','Sex'};
    % donut{fnum} = false; 

    % %%
    % fnum = 16;
    % figNames{fnum} = fullfile(figFold,[dt, '_Weight_C57_PM']);
    % subset = {{'Strain', {'c57'}} ...
    %           {'TimeOfBehavior', {'Afternoon'}} ...
    %           };
    % subInds{fnum} = getSubInds(mT, subset);
    % yVars{fnum} = 'Weight';
    % yLabs{fnum} = 'Weight (g)';
    % grammOptions{fnum} = {'color', mT.Chamber, 'lightness', mT.Sex};        
    % orderOptions{fnum} = {'lightness',{'Female','Male'}};
    % legendOptions{fnum} = {'x','Sex'};
    % donut{fnum} = false; 
    % 
    % %%
    % fnum = 17;
    % figNames{fnum} = fullfile(figFold,[dt, '_Weight_CD1_PM']);
    % subset = {{'Strain', {'CD1'}} ...
    %           {'TimeOfBehavior', {'Afternoon'}} ...
    %           };
    % subInds{fnum} = getSubInds(mT, subset);
    % yVars{fnum} = 'Weight';
    % yLabs{fnum} = 'Weight (g)';
    % grammOptions{fnum} = {'color', mT.Chamber, 'lightness', mT.Sex};        
    % orderOptions{fnum} = {'lightness',{'Female','Male'}};
    % legendOptions{fnum} = {'x','Sex'};
    % donut{fnum} = false; 

    %% plotting loop
    
    for y = 1:length(yVars)
        if ~isempty(subInds{y})
            plotPubFig(mT, runType, yVars{y}, yLabs{y}, subInds{y}, titles, figNames{y}, figType, donut{y}, ...
                        'GrammOptions', grammOptions{y}, 'ColorOptions', colorOptions, ...
                        'OrderOptions', orderOptions{y}, 'LegendOptions', legendOptions{y});
        end
    end

end

%%
function [g] = plotPubFig(mT, runType, yVar, yLab, subInd, titles, figName, figType, donut, varargin)
    % try
        % why am I parsing it this way? this is dumb    
        p = inputParser;
        addParameter(p, 'GrammOptions', {});             % For gramm initial options
        addParameter(p, 'ColorOptions', {})
        addParameter(p, 'OrderOptions', {});             % For set_order_options
        addParameter(p, 'LegendOptions', {});
    
        parse(p, varargin{:});
        
        if runType == 'ER'
            sp_subInd = {subInd & (mT.sessionType=='PreTraining' | mT.sessionType=='Training'), ...
                         subInd & (mT.sessionType=='PreTraining' | mT.sessionType=='Training') & mT.Session>12, ...
                         subInd & (mT.sessionType=='Extinction'), ...
                         subInd & mT.sessionType=='Reinstatement'};
            xLim = {[0, 15.5], [0.5 2.5], [15.5 25.5], [0.5 2.5]};
        elseif runType == 'BE'
            sp_subInd = {subInd & (mT.sessionType=='PreTraining' | mT.sessionType=='Training'), ...
                         subInd & (mT.sessionType=='PreTraining' | mT.sessionType=='Training') & mT.Session>12, ...
                         subInd & (mT.sessionType=='BehavioralEconomics'), ...
                         subInd & (mT.sessionType=='ReTraining')};
            xLim = {[0, 15.5], [0.5 2.5], [15.5 20.5], [0.5 2.5]};
        elseif runType == 'SA'
            sp_subInd = {subInd & (mT.sessionType=='PreTraining' | mT.sessionType=='Training'), ...
                         subInd & (mT.sessionType=='PreTraining' | mT.sessionType=='Training') & mT.Session>12};
            xLim = {[0, 15.5], [0.5 2.5]};
        end
    
        stat_set = {{'geom',{'black_errorbar','point','line'},'type','sem','dodge',0,'setylim',1,'width',1}, ...
                    {'geom',{'black_errorbar','bar'},'type','sem','dodge',1.75,'width',1.5}};
        point_set = {{'base_size', 10}, {'base_size', 6}};
    
        f1=figure('Position',[1 300 1100 300]);
        clear g;
        yMax = 0;
        for sp = 1:length(sp_subInd)        
            if mod(sp,2) == 1
                g(1,sp)=gramm('x',mT.Session,'y',mT.(yVar),'subset', sp_subInd{sp}, p.Results.GrammOptions{:});
                g(1,sp).stat_summary(stat_set{1}{:});
                g(1,sp).set_point_options('markers',{'o','s'}, point_set{1}{:});  
                g(1,sp).set_names('x','Session','y', yLab,'color','Sex');
                g(1,sp).no_legend;
            elseif mod(sp,2) == 0
                g(1,sp)=gramm('x', mT.Sex,'y', mT.(yVar), 'subset', sp_subInd{sp}, p.Results.GrammOptions{:});
                g(1,sp).stat_summary(stat_set{2}{:});
                g(1,sp).set_point_options('markers',{'o','s'}, point_set{2}{:});
                g(1,sp).geom_jitter('alpha',.6,'dodge',1.75,'width',0.05);
                g(1,sp).set_names(p.Results.LegendOptions{:});
            end
            g(1,sp).set_text_options('font','Helvetica','base_size',13,'legend_scaling',.75,'legend_title_scaling',.75);
            g(1,sp).set_color_options(p.Results.ColorOptions{:});
            g(1,sp).set_order_options(p.Results.OrderOptions{:});
            g(1,sp).set_title(titles{sp});
        end
    
        g.draw;
        
        for sp = 1:length(sp_subInd)
            for s = 1:length(g(1,sp).results.stat_summary)
                maxStat = nanmax(g(1,sp).results.stat_summary(s).yci(:));
                if maxStat > yMax
                    yMax = maxStat;
                end
            end
        end
        yMax = 1.05 * yMax;
    
        for sp = 1:length(sp_subInd)
            g(1,sp).axe_property('LineWidth', 1.5, 'XLim', xLim{sp}, 'YLim', [0 yMax], 'TickDir','out');
    
            % Title
            set(g(1,sp).title_axe_handle.Children ,'FontSize',12);
            
            if mod(sp,2) == 1
                % Marker Manipulation
                set(g(1,sp).results.stat_summary(1).point_handle,'MarkerEdgeColor',[0 0 0]);  
                set(g(1,sp).results.stat_summary(2).point_handle,'MarkerEdgeColor',[0 0 0]);  
            elseif mod(sp,2) == 0
                % Marker Manipulation
                set(g(1,sp).results.geom_jitter_handle(1),'MarkerEdgeColor',[0 0 0]);  
                set(g(1,sp).results.geom_jitter_handle(2),'MarkerEdgeColor',[0 0 0]);  
                set(g(1,sp).results.stat_summary(1).bar_handle,'EdgeColor',[0 0 0]);
                set(g(1,sp).results.stat_summary(2).bar_handle,'EdgeColor',[0 0 0]);
            end
        end
    
        % Remove & Move Axes
        set(g(1,2).facet_axes_handles,'YColor',[1 1 1]);
        set(g(1,2).facet_axes_handles,'YLabel',[],'YTick',[]);
        pos1=g(1,2).facet_axes_handles.OuterPosition;
        set(g(1,2).facet_axes_handles,'OuterPosition',[pos1(1)-.04,pos1(2),pos1(3)-.04,pos1(4)]);
        pos2=g(1,2).title_axe_handle.OuterPosition;
        set(g(1,2).title_axe_handle,'OuterPosition',[pos2(1)-.05,pos2(2),pos2(3),pos2(4)]);
        % Axes Limits
        set(g(1,1).facet_axes_handles,'YLim',[0 yMax],'XLim',[0 15.5]);
        set(g(1,2).facet_axes_handles,'YLim',[0 yMax],'XTickLabel',{char(9792),char(9794)});
    
        if length(sp_subInd) > 2
            % Remove & Move Axes
            set(g(1,4).facet_axes_handles,'YColor',[1 1 1]);
            set(g(1,4).facet_axes_handles,'YLabel',[],'YTick',[]);
            pos3=g(1,4).facet_axes_handles.OuterPosition;
            set(g(1,4).facet_axes_handles,'OuterPosition',[pos3(1)-.04,pos3(2),pos3(3)-.04,pos3(4)]);
            pos4=g(1,4).title_axe_handle.OuterPosition;
            set(g(1,4).title_axe_handle,'OuterPosition',[pos4(1)-.05,pos4(2),pos4(3),pos4(4)]); 
            pos5=g(1,3).facet_axes_handles.OuterPosition;
            set(g(1,3).facet_axes_handles,'OuterPosition',[pos5(1),pos5(2),pos5(3)-.065,pos5(4)]);
            pos6=g(1,3).title_axe_handle.OuterPosition;
            set(g(1,3).title_axe_handle,'OuterPosition',[pos6(1)+.01,pos6(2),pos4(3),pos4(4)]); 
            % Axes Limits
            if strcmp(runType, 'ER')
                set(g(1,3).facet_axes_handles,'YLim',[0 yMax],'XLim',[15 25.5],'XTick',[16 20 25],'XTickLabel',{'1','5','10'});
            elseif strcmp(runType, 'BE')
                set(g(1,3).facet_axes_handles,'YLim',[0 yMax],'XLim',[15 20.5],'XTick',[16 18 20],'XTickLabel',{'1','3','5'});
            end
            set(g(1,4).facet_axes_handles,'YLim',[0 yMax],'XTickLabel',{char(9792),char(9794)});
        end
       
        % Export Figure
        exportgraphics(f1,[figName, figType],'ContentType','vector');
    
        if donut
            plotDonut(mT, subInd, g, figName, figType)
        end
    % catch
        % disp('oh no! had to skip a figure, wonder why??')
    % end    
end
    
function plotDonut(mT, subInd, g, figName, figType)
    % Donut Chart for Overlay
        groupStats = grpstats(mT(mT.Session==1 & subInd, :),["Sex","Strain","Acquire"],["mean","sem"],"DataVars",'ActiveLever');
        % groupStats = sortrows(groupStats,"Acquire",'descend');
        f2=figure('Position',[1 300 575 575]);
        d=donutchart(groupStats.GroupCount, strrep(groupStats.Properties.RowNames, '_', ' '));
        d.InnerRadius=.45;
        % SS note: can't figure out how to make sure these colors correspond 
        % to the figure when there are groups with no data 
        % for s = 1:length(g(1,1).results.stat_summary)  
        %     d.ColorOrder(s,1:3)=g(1,1).results.stat_summary(s).point_handle.MarkerFaceColor; % SS note: the hell is going on here w/ the stat summary indexing? 
        % end
        d.FontSize=12.5;
        d.FontName='Arial Rounded MT Bold';
    
        % Export Figure
        exportgraphics(f2,[figName, '_Donut', figType],'ContentType','vector');

end