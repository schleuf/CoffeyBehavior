% Title: main_MouseSABehavior_20240429
% Author: Kevin Coffey, Ph.D.
% Affiliation: University of Washington, Psychiatry
% email address: mrcoffey@uw.edu  
% Last revision: 22-May 2024
% On 08/14/24 LKM edited rawVariableExtractor to show PR data
% SS revisions: 11/5/24 - 

% ------------- Description --------------
% This is the main analysis script for Golden Oral Fentanyl SA Behavior.
% ----------------------------------------

%% ------------- BEGIN CODE --------------
% USER INPUTS
close all
clear all

% IMPORT PATHS
main_folder = pwd;
cd(main_folder)
addpath(genpath(main_folder))
masterTable_flnm = '.\data_masterTable.mat'; % the masterTable .mat file loaded in if createNewMasterTable == false
beh_datapath = {'.\All Behavior'}; % Used to generate a new masterTable if createNewMasterTable == true
masterSheet_flnm = '.\Golden R01 Behavior Master Key.xlsx'; % Key describing information specific to each animal
BE_intake_canonical_flnm = '.\2024.12.09.BE Intake Canonical.xlsx'; % Key for drug concentration, dose, and intake only used if runType == 'BE'
experimentKey_flnm = '.\Experiment Key.xlsx'; % Key for

% MISC. SETTINGS
runNum = 'all'; % options: 'all' or desired runs separated by underscores (e.g. '1', '1_3_4', '3_2')
runType = 'all'; % options: 'ER' (Extinction Reinstatement), 'BE' (Behavioral Economics), 'SA' (Self Administration)
createNewMasterTable = false; % true: generates & saves a new master table from medPC files in datapath. false: reads mT in from masterTable_flnm if set to false, otherwise 
firstHour = false; % true: acquire data from the first-hour of data and analyze in addition to the full sessions
excludeData = true; % true: excludes data based on the 'RemoveSession' column of masterSheet
acquisition_thresh = 10; % to be labeled as "Acquire", animal must achieve an average number of infusions in the second weak of Training sessions greater than this threshold
withinSession_analysis = false;
individualSusceptibility_analysis = true;

% FIGURE OPTIONS
% Currently, if figures are generated they are also saved. 
saveTabs = true; % true: save matlab tables of analyzed datasets
dailyFigs = false; % true: generate daily figures from dailySAFigures.m
pubFigs = false; % true: generate publication figures from pubSAFigures.m
indivIntake_figs = false; % true: generate figures for individual animal behavior across & within sessions
groupIntake_figs = false; % true: generate figures grouped by sex, strain, etc. for animal behavior across & within sessions
groupOralFentOutput_figs = true; % true: generate severity figures
% SSnote: add figure save type option

% SAVE PATHS
% Each dataset run (determined by runNum and runType) will have its own
% folder created in the allfig_savefolder. All other paths will be
% subfolders within it designated for the various figure types and matlab
% data saved. 
% Currently only daily & publication figures are saved with current date in
% the file name, so be aware of overwrite risk for other figures.
allfig_savefolder = 'All Figures\';
dailyfigs_savepath = 'Daily Figures\';
pubfigs_savepath = 'Publication Figures\';
indivIntakefigs_savepath = 'Individual Intake Figures\';
groupIntakefigs_savepath ='Group Intake Figures\'; 
groupOralFentOutput_savepath = 'Combined Oral Fentanyl Output\';
tabs_savepath = 'Behavior Tables\';

%% HOUSEKEEPING

dt = char(datetime('today')); % Used for Daily & Publication figure savefile names

runNum = categorical(string(runNum));
runType = categorical(string(runType));
if runType == 'all'
    runType = categorical(["ER", "BE", "SA"]);
end

% Import Master Key
opts = detectImportOptions(masterSheet_flnm);
opts = setvartype(opts,{'TagNumber','ID','Cage','Sex','Strain','TimeOfBehavior'},'categorical'); % Must be variables in the master key
mKey=readtable('Golden R01 Behavior Master Key.xlsx',opts);

% Create subdirectories
toMake = {tabs_savepath, dailyfigs_savepath, pubfigs_savepath, ...
          indivIntakefigs_savepath, groupIntakefigs_savepath, groupOralFentOutput_savepath};
new_dirs = makeSubFolders(allfig_savefolder, runNum, runType, toMake, excludeData, firstHour);
sub_dir = new_dirs{1};
if firstHour
    fH_sub_dir = new_dirs{2};
end

% import experiment key
expKey = readtable(experimentKey_flnm);

%% IMPORT DATA
if createNewMasterTable
    mT = createMasterTable(main_folder, beh_datapath, masterSheet_flnm,experimentKey_flnm);
else
    load(masterTable_flnm)
end


%% FILTER DATA
% exclude data
if excludeData
    mT = removeExcludedData(mT, mKey);
end

% get mT indices with run #s to include
dex = getExperimentIndex(mT, runNum, runType);

%% Determine Acquire vs Non-acquire
Acquire = getAcquire(mT, dex, acquisition_thresh);
mT=[mT table(Acquire)];

%% Get data from the first hour of the session 
if firstHour
    hmT = getFirstHour(mT);
end

%% get group statistics and save tables of data analyzed

groupStats = struct;
if firstHour; hour_groupStats = struct; end
for et = 1:length(runType)
    groupStats.(char(runType(et))) = grpstats(mT(dex.(char(runType(et))),:), ["Sex", "Strain", "Session"], ["mean", "sem"], ...
                          "DataVars",["ActiveLever", "InactiveLever", "EarnedInfusions", "HeadEntries", "Latency", "Intake"]);
    if firstHour
        hour_groupStats.(char(runType(et))) = grpstats(hmT(dex.(char(runType(et))),:),["Sex", "Strain", "Session"], ["mean", "sem"], ...
                                   "DataVars",["ActiveLever", "InactiveLever", "EarnedInfusions", "HeadEntries", "Latency", "Intake"]);
    end
    if saveTabs
        writeTabs(mT(dex.(char(runType(et))),:), [sub_dir, tabs_savepath, 'run_', char(runNum), '_exp_', char(runType(et)), '_inputData'], {'.mat', '.xlsx'})
        writeTabs(groupStats.(char(runType(et))), [sub_dir, tabs_savepath, 'run_', char(runNum), '_exp_', char(runType(et)), '_GroupStats'], {'.mat', '.xlsx'})
        if firstHour
            writeTabs(hmT(dex.(char(runType(et))),:), [fH_sub_dir, tabs_savepath, 'run_', char(runNum), '_exp_', char(runType(et)), '_inputData'], {'.mat', '.xlsx'})
            writeTabs(hour_groupStats.(char(runType(et))), [fH_sub_dir, tabs_savepath, 'run_', char(runNum), '_exp_', char(runType(et)), '_GroupStats', {'.mat', '.xlsx'}])
        end
    end
end

%% Save Master Table and generate figures for daily spot checks

if dailyFigs
    % Save daily copy of the master table in .mat and xlsx format and save groups stats  
    mTname = [sub_dir, tabs_savepath, dt, '_MasterBehaviorTable.mat'];
    %Generate a set of figures to spotcheck data daily
    dailySAFigures(mT, runType, dex, [sub_dir, dailyfigs_savepath]);
    close all
    if firstHour
        dailySAFigures(hmT, runType, dex, [fH_sub_dir, dailyfigs_savepath])
        close all
    end
end

%% Generate Clean Subset of Figures for Publication

if pubFigs %  && strcmp(runType, 'ER')
    pubSAFigures(mT, runType, dex, [sub_dir, pubfigs_savepath]);
    if firstHour 
        pubSAFigures(hmT, runType, dex, [fH_sub_dir, pubfigs_savepath]); 
    end
    close all;
end

%% Behavioral Economics Analysis 

if ismember(runType, 'BE')
    BE_processes(mT(dex.BE, :), expKey, BE_intake_canonical_flnm, sub_dir, indivIntake_figs, groupIntake_figs, saveTabs, indivIntakefigs_savepath, groupIntakefigs_savepath, tabs_savepath);
    if firstHour
        BE_processes(hmT(dex.BE, :), expKey, BE_intake_canonical_flnm, fH_sub_dir, indivIntake_figs, groupIntake_figs, saveTabs, indivIntakefigs_savepath, groupIntakefigs_savepath, tabs_savepath);
    end
end

%% Within Session Behavioral Analysis 

if withinSession_analysis
    [mTDL, mPressT, mDrugsLT] = WithinSession_Processes(mT, dex, sub_dir, indivIntake_figs, indivIntakefigs_savepath, groupIntake_figs, groupIntakefigs_savepath, saveTabs, tabs_savepath)
end

%% Statistic Linear Mixed Effects Models

statsname=[sub_dir, tabs_savepath, 'Oral SA Group Stats '];

% Training
data = mT(mT.sessionType == 'Training',:);
dep_var = ["Intake", "EarnedInfusions", "HeadEntries", "Latency", "ActiveLever", "InactiveLever"];
lme_form = " ~ Sex*Session + (1|TagNumber)";
Training_LMEstats = getLMEstats(data, dep_var, lme_form);
if saveTabs
    save([statsname, 'SA'], 'Training_LMEstats');
end

if any(ismember(runType,'ER'))

    % Extinction
    data = mT(mT.sessionType=='Extinction',:);
    dep_var = ["HeadEntries", "Latency", "ActiveLever", "InactiveLever"];
    lme_form = " ~ Sex*Session + (1|TagNumber)";
    Extinction_LMEstats = getLMEstats(data, dep_var, lme_form);
    
    % Reinstatement
    data = mT(mT.sessionType=='Reinstatement',:);
    dep_var = ["HeadEntries", "Latency", "ActiveLever", "InactiveLever"];
    lme_form = " ~ Sex + (1|TagNumber)";
    Reinstatement_LMEstats = getLMEstats(data, dep_var, lme_form);
    
    if saveTabs
        save([statsname, 'ER'], 'Extinction_LMEstats', 'Reinstatement_LMEstats');
    end

elseif any(ismember(runType,'BE'))

    % BehavioralEconomics
    data = mT(mT.sessionType=='BehavioralEconomics',:);
    dep_var = ["HeadEntries", "Latency", "ActiveLever", "InactiveLever"];
    lme_form = " ~ Sex + (1|TagNumber)";
    BehavioralEconomics_LMEstats = getLMEstats(data, dep_var, lme_form);
    if saveTabs
        save([statsname, 'BE'], 'BehavioralEconomics_LMEstats');
    end
end

%% Individual Variability Suseptibility Modeling
% INDIVIDUAL VARIABLES
% Intake = total fentanyl consumption in SA (ug/kg)
% Seeking = total head entries in SA
% Cue Association = HE Latency in SA (Invert?) SS note: Could, but it would need to be inverted again for the Severity score
% Escalation = Slope of intake in SA
% Extinction = total active lever presses during extinction
% Persistance = slope of extinction active lever presses
% Flexibility = total inactive lever presses during extinction (Invert?)
% Relapse = total presses during reinstatement
% Cue Recall = HE Latency in reinstatement (invert?)tmpT
if individualSusceptibility_analysis
    % SSnote: come up with a smarter way to do send different subsets of
    % data through for metric calcs and correlations, this current way is
    % dumb and involves a ton of redundancy
    % SSnote: Currently missing first hour
    [ivT] = GetMetrics(mT(dex.all, :));

    if saveTabs
        save([sub_dir, tabs_savepath, 'IndividualVariabilityMetrics', '.mat'], 'ivT');
    end

    % run Z scores separately for animals that lack ER sessions & associated metrics
    if ~any(ismember(runType, 'ER'))
        zGroups = {ones([height(ivT), 1])};
        includeER = false;
        z_suff = {'_noER'};
    elseif (length(runType) > 1) & any(ismember(runType, 'ER'))
        ER_IDs =  unique(mT.TagNumber(dex.ER));
        ivT_ER_ind = ismember(unique(mT.TagNumber(dex.all)), ER_IDs);
        zGroups = {ones([height(ivT), 1]), ivT_ER_ind};
        includeER = [false, true];
        z_suff = {'_noER', '_withER'};
    else % only 'ER' in runType
        zGroups = {ones([height(ivT), 1])};
        includeER = true;
        z_suff = {'_withER'};
    end
    
    % subgroups of z-scored data to run correlatins across
    corrGroups = {{{'all'}}, ...
                  {{'Strain', 'c57'}}, ...
                  {{'Strain', 'CD1'}}, ...
                  {{'Sex', 'Male'}}, ...
                  {{'Sex', 'Female'}}, ...
                  {{'Strain', 'c57'}, {'Sex', 'Male'}}, ...
                  {{'Strain', 'c57'}, {'Sex', 'Female'}}, ...
                  {{'Strain', 'CD1'}, {'Sex', 'Male'}}, ...
                  {{'Strain', 'CD1'}, {'Sex', 'Female'}}}; 

    % violin groups
    violSubsets = {{'all'}, {'all'}, {'Strain', 'c57'}, {'Strain', 'CD1'}};
    violGroups = {'Strain', 'Sex', 'Sex', 'Sex'};
    violLabels = {'Strain', 'Sex', 'c57 Sex', 'CD1 Sex'};
    
    for zg = 1:length(zGroups)
        [ivZT] = SeverityScore(ivT(find(zGroups{zg}),:), includeER(zg));
        if saveTabs
            save([sub_dir, tabs_savepath, 'IndividualVariabilityZscores', char(z_suff{zg}), '.mat'], 'ivZT');
        end
        %% SSnote: correlation figure is currently getting double the number of tickmarks and labels as it should be in the nonER condition....why
        [correlations] = GetCorr(ivZT, z_suff{zg}, corrGroups, sub_dir, groupOralFentOutput_figs, groupOralFentOutput_savepath);
        if groupOralFentOutput_figs     
            for vg = 1:length(violSubsets)
                thistab = ivT(find(zGroups{zg}),:);
                thistab.Severity = ivZT.Severity;
                subset = ones([height(thistab), 1]);
                if ~strcmp(violSubsets{vg}{1}, 'all')
                    subset = subset & (thistab.(violSubsets{vg}{1}) == violSubsets{vg}{2});
                end
                ViolinFig(thistab(find(subset), :), violGroups{vg}, [z_suff{zg}, '_', violLabels{vg}], includeER(zg), sub_dir, groupOralFentOutput_savepath)
            end
            PCA_fig(ivZT, correlations.([z_suff{zg}(2:end),'_all']).prednames, ...
                    sub_dir, groupOralFentOutput_savepath, z_suff{zg});
        end
    end
end


%% ------------------------FUNCTIONS---------------------------------

function PCA_fig(ivZT, prednames, sub_dir, subfolder, suffix)
    [coeff,score,latent] = pca(ivZT{:,prednames});
    PC1=score(:,1);
    PC2=score(:,2);

    f1=figure('color','w','position',[100 100 800 650]);
    h1 = biplot(coeff(:,1:3),'Scores',score(:,1:3),...
        'Color','b','Marker','o','VarLabels',prednames);
    % set metric vectors' appearance
    for i = 1:length(prednames) 
        h1(i).Color=[.5 .5 .5];    
        h1(i).LineWidth=1.5;
        h1(i).LineStyle=':';
        h1(i).MarkerSize=4;
        h1(i).MarkerFaceColor=[.0 .0 .0];
        h1(i).MarkerEdgeColor=[0 .0 0];
    end
    % remove extra line objects (not sure why these exist) 
    for i = length(prednames) + 1 : length(prednames) * 2
        h1(i).Marker='none';
    end
    % format text for metric vector labels
    for i = 1 + (length(prednames) * 2) : 3 * length(prednames)
        h1(i).FontSize = 11;
        h1(i).FontWeight = 'bold';
    end
    data_ind1 = length(h1) - height(ivZT);
    R = rescale(ivZT.Severity,4,18);
    for i=data_ind1:length(h1)-1
        h1(i).MarkerEdgeColor=[0 .0 0];
        h1(i).MarkerSize=R(i-data_ind1 + 1);
        if ivZT.Sex(i - data_ind1 + 1) == 'Male' % SSnote: the heck is this part for
            h1(i).MarkerFaceColor = [.46 .51 1];
        else
            h1(i).MarkerFaceColor = [.95 .39 .13];
        end
        if ivZT.Strain(i - data_ind1 + 1) == 'c57' % SSnote: the heck is this part for
            h1(i).Marker='o';
        else
            h1(i).Marker='s';
        end

    end
    pbaspect([1,1,1])
    set(gca,'LineWidth',1.5,'TickDir','in','FontSize',14);
    grid off
    saveas(f1,[sub_dir, subfolder 'PCA_Vectors', suffix]);
    
    pcTable = [ivZT, table(PC1, PC2)];
    f1 = figure('color','w','position',[100 100 800 650]);
    g = gramm('x', pcTable.PC1, 'y', pcTable.PC2, 'color', pcTable.Sex, 'marker', pcTable.Strain, 'lightness', pcTable.Class);
    g.set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
    g.geom_point();
    g.set_names('x','PC1','y','PC2','color','Sex', 'marker', 'Strain', 'lightness', 'Class');
    g.axe_property('FontSize',12,'LineWidth',1.5,'TickDir','out');
    g.set_order_options('lightness',{'High','Mid','Low'});
    g.set_point_options('base_size',8);
    g.draw;
    for i = 1:height(g.results.geom_point_handle)
        g.results.geom_point_handle(i)
       g.results.geom_point_handle(i).MarkerEdgeColor = [0 0 0];
    end
    exportgraphics(f1,[sub_dir, subfolder, 'PC1_PC2', suffix, '.png'],'ContentType','vector');
end


function [f] = plotViolins(ivT, yVars, yLabs, group)
    clear g
    f = figure('units','normalized','outerposition',[0 0 1 .5]);
    numDat = length(ivT.Intake); 
    x = nan([1,numDat]);
    groupsets = unique(ivT.(group));
    
    if length(groupsets) > 1
        x(ivT.(group) == categorical(groupsets(1))) = .8;
        x(ivT.(group) == categorical(groupsets(2))) = 1.2; 
    
        for y = 1:length(yVars)
            g(1,y)=gramm('x',x,'y',ivT.(yVars{y}),'color',ivT.(group));
            g(1,y).set_order_options('color', groupsets)
            g(1,y).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
            g(1,y).stat_violin('normalization', 'width', 'fill', 'transparent'); %'extra_y', 0, 'half', 1, 
            g(1,y).geom_jitter('width',.05,'dodge',-.5,'alpha',.75);
            g(1,y).axe_property('LineWidth',1.5,'FontSize',14,'Font','Helvetica','XLim',[0.5 1.5],'TickDir','out'); %'YLim',[0 1200]
            g(1,y).set_names('x','','y', yLabs{y},'color', '');
            g(1,y).set_point_options('base_size', 6);
            if y~=1
                g(1,y).no_legend();
            end
            % g(1,y).set_title('');
        end
        
         g.draw;
    
        for i=1:width(g)
           g(1,i).results.geom_jitter_handle(1).MarkerEdgeColor = [0 0 0]; 
           g(1,i).results.geom_jitter_handle(2).MarkerEdgeColor = [0 0 0];
        end

    else
        disp(['only one value for grouping "', group, '", skipping violin plots...'])
    end

end


function ViolinFig(ivT, group, label, includeER, sub_dir, groupOralFentOutput_savepath)
    % Violin plots
    

    if includeER
        yVars = {'Intake', 'Seeking', 'Association', 'Escalation', 'Extinction', 'Relapse', 'Recall', 'Severity'};
        yLabs = {' Fentanyl Intake (mg/kg)', 'Seeking (Head Entries)', 'Association (Latency)', ...
                 'Escalation (slope Training Intake)', 'Extinction Responses', 'Relapse (Reinstatement Responses)', 'Recall (Reinstatement Latency)', 'Severity'};
    else
        yVars = {'Intake', 'Seeking', 'Association', 'Escalation',  'Severity'};
        yLabs = {' Fentanyl Intake (mg/kg)', 'Seeking (Head Entries)', 'Association (Latency)', ...
                 'Escalation (slope Training Intake)', 'Severity' };
    end

    f = plotViolins(ivT, yVars, yLabs, group);
    exportgraphics(f,[sub_dir, groupOralFentOutput_savepath, label, '.png'],'ContentType','vector');
    close(f)
end



function CorrFig(ct, prednames, sub_dir, subfolder, suffix)

    f = figure('Position',[1 1 700 600]);
    imagesc(ct,[-1 1]); % Display correlation matrix as an image
    colormap(brewermap([],'Spectral'));
    a = colorbar();
    a.Label.String = 'Rho';
    a.Label.FontSize = 12;
    a.FontSize = 12;
    set(gca, 'XTickLabel', prednames, 'XTickLabelRotation',45, 'FontSize', 12); % set x-axis labels
    set(gca, 'YTickLabel', prednames, 'YTickLabelRotation',45, 'FontSize', 12); % set x-axis labels
    box off
    set(gca,'LineWidth',1.5,'TickDir','out')
    title(strrep(suffix(2:end), '_', ' '))
    exportgraphics(f,[sub_dir, subfolder, 'Correlation_table', suffix, '.png'],'ContentType','vector');
    close(f)
end


function [correlations] = GetCorr(ivZT, z_suff, corrGroups, sub_dir, groupOralFentOutput_figs, groupOralFentOutput_savepath)
    correlations = struct; 
    for cg = 1:length(corrGroups)
        use_inds = ones([height(ivZT), 1]);
        if strcmp(corrGroups{cg}{1}{1}, 'all')
            suff_str = [z_suff, '_all']; 
        else
            suff_str = z_suff;
            for cat = 1:length(corrGroups{cg})
                suff_str = [suff_str, '_', corrGroups{cg}{cat}{2}];
                use_inds = use_inds & (ivZT.(corrGroups{cg}{cat}{1})==(corrGroups{cg}{cat}{2}));
            end
        end
        correlations.(suff_str(2:end)) = struct;
        correlations.(suff_str(2:end)).ivZT_inds = find(use_inds);   
        prednames = ivZT.Properties.VariableNames;
        prednames = prednames(~ismember(prednames, {'ID', 'Strain', 'Sex', 'Severity', 'Class'}));
        correlations.(suff_str(2:end)).ct = corr(ivZT{find(use_inds),prednames},Type='Pearson');
        correlations.(suff_str(2:end)).prednames = prednames;
        if groupOralFentOutput_figs
            CorrFig(correlations.(suff_str(2:end)).ct, prednames, sub_dir, groupOralFentOutput_savepath, suff_str)
        end
    end
end


function [ivZT] = SeverityScore(ivT, includeER)
    % Z-Score & Severity Score
    ivZT = ivT(:, {'ID', 'Sex', 'Strain'});
    ivZT.Intake=zscore(ivT.Intake);
    ivZT.Seeking=zscore(ivT.Seeking);
    ivZT.Association=zscore(nanmax(ivT.Association)-ivT.Association);
    ivZT.Escalation=zscore(ivT.Escalation);
    if includeER
        ivZT.Extinction=zscore(ivT.Extinction);
        ivZT.Relapse=zscore(ivT.Relapse);
        ivZT.Recall(~isnan(ivT.Recall)) = zscore(nanmax(ivT.Recall) - ivT.Recall(~isnan(ivT.Recall)));
    end

    varnames = ivZT.Properties.VariableNames;
    prednames = varnames(varnames ~= "ID" & varnames ~= "Sex" & varnames ~= "Strain");

    % Severity
    Severity = sum(ivZT{:, prednames}')';
    Class = cell([height(Severity) 1]);
    Class(Severity>1.5) = {'High'};
    Class(Severity>-1.5 & Severity<1.5) = {'Mid'};
    Class(Severity<-1.5) = {'Low'};
    Class = categorical(Class);
    ivZT.Severity = Severity;
    ivZT.Class = Class;
end


function [ivT] = GetMetrics(mT)
    
    IVmetrics = ["ID", "Sex", "Strain", "Intake", "Seeking", "Association", "Escalation"...
                 "Extinction", "Persistence", "Flexibility", "Relapse", "Recall"];  
    numNonMets = 3; % refers to the first 3 elements of IVmetrics being labels rather than numeric metrics
    ID = unique(mT.TagNumber);

    % Individual Variable Table
    ivT = table('Size', [length(ID), length(IVmetrics)], 'VariableTypes', ...
               [repmat({'categorical'}, [1,numNonMets]), repmat({'double'}, [1, length(IVmetrics) - numNonMets])], ...
                'VariableNames', IVmetrics);
    ivT{:, IVmetrics(numNonMets + 1:end)} = nan;
    
    for i=1:length(ID)
        this_ID = mT.TagNumber == ID(i);
        ivT.ID(i) = ID(i);
        ivT.Sex(i) = unique(mT.Sex(this_ID));
        ivT.Strain(i) = unique(mT.Strain(this_ID));
        ivT.Intake(i) = nanmean(mT.Intake(this_ID & mT.sessionType == 'Training'));
        ivT.Seeking(i) = nanmean(mT.HeadEntries(this_ID &  mT.sessionType =='Training'));
        ivT.Association(i)= log(nanmean(mT.Latency(this_ID & mT.sessionType == 'Training'))); 
        e = polyfit(double(mT.Session(this_ID & mT.sessionType == 'Training')), ...
                           mT.TotalInfusions(this_ID & mT.sessionType =='Training'),1);
        ivT.Escalation(i)=e(1);

        includeER = ~isempty(find(this_ID & (mT.sessionType == 'Extinction')));

        if includeER
            ivT.Extinction(i)= nanmean(mT.ActiveLever(this_ID & mT.sessionType == 'Extinction'));
            p = polyfit(double(mT.Session(this_ID & mT.sessionType == 'Extinction')), ...
                               mT.ActiveLever(this_ID & mT.sessionType == 'Extinction'),1);
            ivT.Persistence(i) = 0 - p(1);
            ivT.Flexibility(i) = nanmean(mT.InactiveLever(this_ID & mT.sessionType == 'Extinction'));
            ivT.Relapse(i) = mT.ActiveLever(this_ID & mT.sessionType == 'Reinstatement');
            ivT.Recall(i) = log(mT.Latency(this_ID & mT.sessionType == 'Reinstatement'));
        end
    end   
end


function [LME_stats] = getLMEstats(data, dep_var, lme_form)
    LME_stats = struct;
    for dv = 1:length(dep_var)
        LME_stats.(strcat(dep_var(dv), "LME")) = fitlme(data, strcat(dep_var(dv), lme_form));
        LME_stats.(strcat(dep_var(dv), "F")) = anova(LME_stats.(strcat(dep_var(dv), "LME")) ,'DFMethod','satterthwaite');
    end
end


function [mTDL, mPressT, mDrugsLT] = WithinSession_Processes(mT, dex, sub_dir, indivIntake_figs, indivIntakefigs_savepath, groupIntake_figs, groupIntakefigs_savepath, saveTabs, tabs_savepath)
    % Analyze Rewarded Lever Pressing Across the Session
    % 97 = rewarded lever presses followed by head entry
    % 99 = rewarded head entries (preceded by lever press)

    mTDL = mT(dex.all,:);
    mTDL = mTDL(mTDL.EarnedInfusions>10, :);
    mPressT = table;
    mDrugLT = table;
    
    disp(['Running individual within-session intake analysis for ' num2str(height(mTDL)) ' sessions...']);  
    for i=1:height(mTDL)
        ET = mTDL.eventTime{i};
        EC = mTDL.eventCode{i};
        doseHE = mTDL.doseHE{i};
        cumulDoseHE = cumsum(doseHE);
        rewHE = ET(EC==99);
        adj_rewLP = ET(EC==97);
        conc = mTDL.Concentration(i);
    
        TagNumber=repmat([mTDL.TagNumber(i)],length(adj_rewLP),1);
        Session=repmat([mTDL.Session(i)],length(adj_rewLP),1);
        Sex =repmat([mTDL.Sex(i)],length(adj_rewLP),1);
        Strain =repmat([mTDL.Strain(i)],length(adj_rewLP),1);
    
        if i==1
            mPressT=table(TagNumber, Session, adj_rewLP, cumulDoseHE, Sex, Strain);
        else
            mPressT=[mPressT; table(TagNumber, Session, adj_rewLP, cumulDoseHE, Sex, Strain)];
        end
        
        infDur = 4; % duration of infusion in seconds
        sessDur = 180; % duration of sessionin minutes
        [DL, DLTime] = pharmacokineticsMouseOralFent('infusions',[rewHE*1000 (rewHE+(doseHE*infDur*1000))],'duration',sessDur,'type',4,'weight',mT.Weight(i)./1000,'mg_mL',conc/100,'mL_S',mT.DoseVolume(i)/infDur);
        DL = imresize(DL', [length(DLTime),1]);
        DLTime = DLTime';
    
        TagNumber = repmat([mTDL.TagNumber(i)],length(DL),1);
        Session = repmat([mTDL.Session(i)],length(DL),1);
        Sex = repmat([mTDL.Sex(i)],length(DL),1);
        Strain = repmat([mTDL.Strain(i)],length(DL),1);
        sessionType = repmat([mTDL.sessionType(i)],length(DL),1);
    
        if i==1
            mDrugLT = table(TagNumber, Session, DL, DLTime, Sex, Strain, sessionType);
        else
            mDrugLT = [mDrugLT; table(TagNumber, Session, DL, DLTime, Sex, Strain, sessionType)];
        end
        
        if indivIntake_figs 
            figpath = [sub_dir, indivIntakefigs_savepath, 'Tag', char(mTDL.TagNumber(i)), '_Session', char(string(mTDL.Session(i))), '_cumolDose_and_estBrainFent.pdf'];
            indiv_sessionIntakeBrainFentFig({adj_rewLP/60, DLTime}, {cumulDoseHE, DL(:)*1000}, figpath);
        end
    end

    if saveTabs
        writeTabs(mPressT, [sub_dir, tabs_savepath, 'Within_Session_Responses'], {'.mat'})
        writeTabs(mDrugLT, [sub_dir, tabs_savepath, 'Within_Session_DrugLevel'], {'.mat'})
    end

    if indivIntake_figs
        IDs=unique(mPressT.TagNumber);
        for j=1:length(IDs)
            figpath = [sub_dir, indivIntakefigs_savepath, 'Tag', char(IDs(j)), '_allSessionCumulDose.png'];
            indiv_allSessionFig(mPressT, mPressT.TagNumber==IDs(j), 'adj_rewLP', "Time (m)", ...
                                'cumulDoseHE', "Cumulative Responses", ...
                                 ['ID: ' char(IDs(j))], 'Session', figpath);
    
            figpath = [sub_dir, indivIntakefigs_savepath, 'Tag', char(IDs(j)), '_allSessionEstBrainFent.png'];
            indiv_allSessionFig(mDrugLT, mPressT.TagNumber==IDs(j), 'DLTime', "Time (m)", ...
                                'DL', "Estimated Brain Fentanyl (pMOL)", ...
                                 ['ID: ' char(IDs(j))], 'Session', figpath);
        end
    end
    
    if groupIntake_figs    
        % Drug Level by Strain and Sex 
        figpath = [sub_dir, groupIntakefigs_savepath, 'Drug Level Grouped by Sex and Strain.png'];
        group_allSessionFig(mDrugLT, logical(ones([height(mDrugLT),1])), 'DLTime', 'Time (m)', 'DL', 'Estimated Brain Fentanyl (pMOL)', ...
                            'Strain', 'Sex', 'Session', 'Group Drug Level', figpath, 'area');
    
        % Drug Level by Strain and Sex during Training
        figpath = [sub_dir,groupIntakefigs_savepath, 'Drug Level Grouped by Sex and Strain during Training.png'];
        group_allSessionFig(mDrugLT, mDrugLT.sessionType=='Training', 'DLTime', 'Time (m)', 'DL', 'Estimated Brain Fentanyl (pMOL)', ...
                            'Strain', 'Sex', 'Session', 'Group Drug Level (Training)', figpath, 'area');
    
        % Drug Level by Sex and Session during Training Sessions 5, 10, 15
        figpath = [sub_dir, groupIntakefigs_savepath, 'Drug Level Grouped by Sex and Session 5 10 15.png'];
        subset = (mDrugLT.Session==5 | mDrugLT.Session==10 | mDrugLT.Session==15);
        group_allSessionFig(mDrugLT, subset, 'DLTime', 'Time (m)', 'DL', 'Estimated Brain Fentanyl (pMOL)', ...
                            'Sex', 'Session', 'none', 'Average Group Drug Level (Sessions 5, 10, 15)', figpath, 'line');
    
        % Cumulative responses (rewarded head entries) by Sex and Session during Training Sessions 5, 10, 15
        figpath = [sub_dir, groupIntakefigs_savepath, 'Mean Responses Grouped by Sex and Session 5 10 15.png'];
        subset = (mPressT.Session==5 | mPressT.Session==10 | mPressT.Session==15);
        group_allSessionFig(mPressT, subset, 'adj_rewLP', 'Time (m)', 'cumulDoseHE', 'Cumulative Responses', ...
                            'Sex', 'Session', 'none', 'Mean Cumulative Responses (Sessions 5, 10, 15)', figpath, 'cumbin');
    end
end


function [g] = BE_subplot(xvar, yvar, colorGroup, colorLab, lightGroup, lightLab, subset, xlab, ylab, leg)
    ymax = getYmax(yvar(subset));
    g(1,1)=gramm('x',xvar,'y',yvar,'color',colorGroup, 'lightness', lightGroup, 'subset', subset);
    g(1,1).set_color_options('hue_range',[0 360],'lightness_range',[85 35],'chroma_range',[30 70]);
    g(1,1).stat_summary('geom',{'black_errorbar','point','line'},'type','sem','dodge',0,'setylim',1,'width',1);
    % g(1,1).geom_jitter();
    g(1,1).set_point_options('markers',{'o','s'},'base_size',10);
    g(1,1).set_text_options('font','Helvetica','base_size',13,'legend_scaling',.75,'legend_title_scaling',.75);
    g(1,1).axe_property('LineWidth',1.5,'XLim',[1.5 6],'YLim',[0 ymax],'tickdir','out');
    g(1,1).set_names('x',xlab,'y',ylab,'color', colorLab, 'lightness', lightLab);
    if ~leg
        g(1,1).no_legend();
    end
end


function group_allSessionFig(tab, subset, xvar, xlab, yvar, ylab, colorGroup, lightGroup, facetwrap, figtitle, figpath, stat_type)
    x = tab.(xvar);
    y = tab.(yvar); 
    cg = tab.(colorGroup);
    lg = tab.(lightGroup);
    if strcmp(xvar,'adj_rewLP')
        x = x/60;
    end

    f = figure('units','normalized','outerposition',[0 0 .5 1]);
    g=gramm('x',x(subset),'y',y(subset),'color',cg(subset),'lightness',lg(subset));
    g.set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
    if ~strcmp(facetwrap,'none')
        fw = tab.(facetwrap);
        g.facet_wrap(fw(subset),'scale','independent','ncols',3,'force_ticks',1,'column_labels',1);
        g.set_names('column','Session');
    end
    
    if strcmp(stat_type, 'cumbin')
        g.stat_bin('normalization','cumcount','geom','stairs','edges',0:1:180);
    else
        g.stat_summary('geom', stat_type,'setylim',1);
    end
    
    g.axe_property('LineWidth',1.5,'FontSize',10,'XLim',[0 180],'tickdir','out');
    g.set_names('x', xlab, 'y',ylab, 'color', colorGroup, 'lightness', lightGroup);
    g.set_title(figtitle);
    g.draw;
    
    yMax = 0;
    
    if strcmp(stat_type, 'cumbin')
        for ss = 1:length(g.results.stat_bin)
            yMax = max([yMax;g.results.stat_bin(ss).counts]);
        end
    else
        for ss = 1:length(g.results.stat_summary)
            if strcmp(stat_type, 'area')
                yMax = max([yMax;g.results.stat_summary(ss).yci(:,2)]);
            elseif strcmp(stat_type, 'line')
                yMax = max([yMax;g.results.stat_summary(ss).y]);
            end
        end
    end
    yMax = yMax + (.05 * yMax);

    for i=1:length(g.facet_axes_handles)
        g.facet_axes_handles(i).YLim=[0 yMax];
    end

    exportgraphics(f, figpath);
    close(f)
end


function indiv_allSessionFig(tab, subset, xvar, xlab, yvar, ylab, figtitle, facetwrap, figpath)
    x = tab.(xvar);
    y = tab.(yvar);
    fw = tab.(facetwrap);
    if strcmp(xvar,'adj_rewLP')
        x = x/60;
    end

    f=figure('Position',[1 1 1920 1080]);
    g=gramm('x', x(subset), 'y', y(subset));
    g.set_color_options('hue_range',[-65 265],'chroma',80,'lightness',70,'n_color',2);
    g.facet_wrap(fw(subset),'scale','independent','ncols',4,'force_ticks',1);
    g.stat_bin('normalization','cumcount','geom','stairs','edges',0:1:180);
    g.axe_property('LineWidth',1.5,'FontSize',12,'XLim',[0 180],'tickdir','out');
    g.set_names('x', xlab,'y',ylab);
    g.set_title(figtitle);
    g.draw;
    for i=1:length(g.facet_axes_handles)
        g.facet_axes_handles(i).Title.FontSize=12;
        set(g.facet_axes_handles(i),'XTick',[0 90 180]);
    end
    exportgraphics(f, figpath);
    close(f)
end


function indiv_sessionIntakeBrainFentFig(xvar, yvar, figpath)
    f=figure('Position',[100 100 400 800]);
    clear g
    g(1,1)=gramm('x',xvar{1}, 'y', yvar{1}); 
    g(1,1).stat_bin('normalization','cumcount','geom','stairs','edges',0:1:180);
    g(2,1)=gramm('x',xvar{2}, 'y', yvar{2}); % SS note: what's this *1000 for?
    g(2,1).geom_line();
    g(1,1).axe_property('LineWidth',1.5,'FontSize',13,'XLim',[0 180],'tickdir','out');
    g(1,1).set_names('x','Session Time (m)','y','Cumulative Infusions');
    g(2,1).axe_property('LineWidth',1.5,'FontSize',13,'XLim',[0 180],'tickdir','out');
    g(2,1).set_names('x','Session Time (m)','y','Brain Fentanyl Concentration pMOL');
    g.draw();
    exportgraphics(f,figpath,'ContentType','vector');
    close(f);
end


function BE_GroupFig(tab, yvar, ylab, subset, figpath)
    xvar = log2(tab.unitPrice);
    xlab = 'Fentanyl Concentration (ug/mL)';
    xticks = log2([4.5 8 14.3 25 45.5]);
    xticklabs = {'220','125','70','40','10'};

    f=figure('Position',[100, 100, 500*length(yvar), 500],'Color',[1 1 1]);
    clear g
    for col = 1:length(yvar)
        leg = col == 1;
        % [g] = groupBE_subplot(xvar, yvar, colorGroup, colorLab, lightGroup, lightLab, subset, xlab, ylab, row, col, leg)
        g(1,col) = BE_subplot(xvar, yvar{col}, tab.Sex, 'Sex', tab.Strain, 'Strain', subset, xlab, ylab(col), leg);
    end
    g.draw
    for col = 1:length(yvar)
       set(g(1,col).facet_axes_handles,'Xtick',xticks,'XTickLabel',xticklabs);
       for ss = 1:length(g(1,col).results.stat_summary)
           set(g(1,col).results.stat_summary(ss).point_handle,'MarkerEdgeColor',[0 0 0]);  
       end
    end
    exportgraphics(f,figpath,'ContentType','vector');
    close(f);
end


function BE_IndivFig(TagNumber, aT, sub_dir, indivIntakefigs_savepath)
    IDs = unique(TagNumber);
    xrange = 1:50;
    for i = 1:length(IDs) 
        if height(aT.fitY{i}) > 1
            f1=figure;
            plot(log(xrange), aT.modY{i});
            hold on;
            scatter(log(aT.fitX{i}),log(aT.fitY{i}),10);
            plot([log(aT.Beta(i)) log(aT.Beta(i))],[min(aT.modY{i}) max(aT.modY{i})],'--k');
            xlim([-1 5]);
            title(IDs(i))
            exportgraphics(f1,[sub_dir, indivIntakefigs_savepath, 'Tag', char(IDs(i)), '_BE_curvefit.png']);
            hold off
            close(f1);
        end
    end
end


function [beT, beiT, aT] = BE_Analysis(mT, expKey, BE_intake_canonical_flnm)
    
    % Note: This section is pulling intake data from '2024.12.09.BE Intake Canonical.xlsx.' 
    %       The daily & publication figures above pull intake data from 'Experiment Key.xlsx'
    beT=mT(mT.sessionType=='BehavioralEconomics',:); % Initialize Master Table 
    beT.ID = beT.TagNumber;
    IDs=unique(beT.TagNumber);  
    BE_sess = unique(expKey.Session(strcmp(expKey.SessionType,'BehavioralEconomics')));


    % Import Dose and Measured Intake Data
    opts = detectImportOptions(BE_intake_canonical_flnm); 
    beiT=readtable(BE_intake_canonical_flnm, opts);
    beiT.TagNumber = categorical(beiT.TagNumber);
    beiT = beiT(ismember(beiT.TagNumber, beT.TagNumber),:);

    % remove sessions with missing data from beiT
    missing_days = cell([length(IDs), 1]);
    for i = 1:length(IDs)
        this_sess = beT.Session(beT.TagNumber == IDs(i));
        md = find(~ismember(BE_sess, this_sess));
        missing_days{i} = md;
        remove_ind = logical((beiT.TagNumber==IDs(i)) .* ismember(beiT.Day, missing_days{i}));
        beiT(remove_ind,:) = [];
    end
    unitPrice=(1000./beiT.Dose__g_ml_);
    beT = [beT, table(beiT.Day, beiT.measuredIntake, beiT.Dose__g_ml_, unitPrice)];
    beT = renamevars(beT, ["Var1", "Var2", "Var3", "Var4"], ["Day", "measuredIntake", "Dose", "unitPrice"]);

    % Curve Fit Each Animals Intake over Dose
    Sex = nan([length(IDs), 1]);
    Strain = nan([length(IDs), 1]);
    fitY = cell([length(IDs), 1]);
    fitX = cell([length(IDs), 1]);
    modY = cell([length(IDs), 1]);
    Alpha = nan([length(IDs) 1]);
    Beta = nan([length(IDs) 1]);
    Elastic = nan([length(IDs) 1]);
    
    for i=1:height(IDs)
        Sex(i,1)=unique(beT.Sex(beT.TagNumber==IDs(i)));
        Strain(i,1)=unique(beT.Strain(beT.TagNumber==IDs(i)));
    
        in=beT.measuredIntake(beT.TagNumber==IDs(i));
        price=beT.unitPrice(beT.TagNumber==IDs(i));
        price(in == 0) = [];
        in(in == 0) = []; 
        price=price-min(price)+1;
        
        if height(in) > 1
            myfittype = fittype('log(b)*(exp(1)^(-1*a*x))',...
            'dependent',{'y'},'independent',{'x'},...
            'coefficients',{'a','b'});
            f=fit(price,log(in),myfittype,'StartPoint', [.003, 200],'lower',[.0003 100],'upper',[.03 1500]);
            Alpha(i,1)=f.a;
            Beta(i,1) = f.b;
            fitX{i} = price;
            fitY{i} = in;
            modY{i} = f(1:50);
            [res_x, idx_x]=knee_pt(log(1:500),f(1:500));
            Elastic(i,1)=idx_x;
        end  
    end

    aT=table(IDs, Sex, Strain, Alpha, Beta, Elastic, fitX, fitY, modY);

    BE_LME = fitlme(beT,'EarnedInfusions ~ Concentration + (1|ID)');

    BE_F = anova(BE_LME,'DFMethod','satterthwaite');
    statsna=fullfile('Statistics','Oral SA BE Stats.mat');
    % save(statsna,'BE_F');

    % Group BE Demand Curve
    % myfittype = fittype('log(b)*(exp(1)^(-1*a*x))',...
    %     'dependent',{'y'},'independent',{'x'},...
    %     'coefficients',{'a','b'});

    % SSnote: what had been plotted here? Group demand curve breaks here
    % because of it

    % x=g.results.stat_summary.x;
    % [y, z] = g.results.stat_summary.y;
    % x = x-x(1)+exp(1);

    % ff=fit(x,log(y),myfittype,'StartPoint', [.003, 200],'lower',[.0003 100],'upper',[.03 1500]);
    % fm=fit(x,log(z),myfittype,'StartPoint', [.003, 200],'lower',[.0003 100],'upper',[.03 1500]);
    % 
    % f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
    % hold on;
    % plot(log(1:50),ff(1:50),'LineWidth',1.5,'Color',[.95 .39 .13]);
    % plot(log(1:50),fm(1:50),'LineWidth',1.5,'Color',[.46 .51 1]);
    % scatter(log(x),log(y),36,[.95 .39 .13],'filled');
    % scatter(log(x),log(z),36,[.46 .51 1],'filled');
    % xlim([-.25 4.25]);
    % set(gca,'LineWidth',1.5,'tickdir','out','FontSize',16,'box',0);
    % xt=log([2.71 5 10 25 50]);
    % set(gca,'XTick',[0 xt],'XTickLabels',{'0' '1' '5' '10' '25' '50'});
    % xlabel('Cost (Response/Unit Dose)');
    % set(gca,'YTick',[5 5.85843 6.28229],'YTickLabels',{'148' '350' '535'});
    % ylabel('Fentanyl Intake (μg/kg)');
    % 
    % fAlpha=ff.a;
    % fQ0=exp(ff(1));
    % mAlpha=fm.a;
    % mQ0=exp(fm(1));
    % % exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','True BE Figure.pdf'),'ContentType','vector');
    % % save('Statistics\BE_Stats.m','fAlpha','mAlpha','fQ0','mQ0');
    % 
    % clear g
    % g(1,1)=gramm('x',beT.unitPrice,'y',beT.responses,'color',beT.Sex);
    % g(1,1).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
    % g(1,1).stat_summary('geom',{'area','point'},'type','sem','setylim',1);
    % g.set_text_options('font','Helvetica','base_size',16,'legend_scaling',.75,'legend_title_scaling',.75);
    % g.axe_property('LineWidth',1.5,'tickdir','out');
    % g(1,1).set_names('x','Unit Price (responses/mg)','y','Responses','color','Sex');
    % f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
    % g(1,1).no_legend();
    % g.draw;
    % set(g.facet_axes_handles,'XScale','log')
    % set(g.facet_axes_handles,'XTick',[1 10 20 40])
    % % exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','Unit Price Response.pdf'),'ContentType','vector');
    % 
    % close all;

end

function BE_processes(mT, expKey, BE_intake_canonical_flnm, sub_dir, indivIntake_figs, groupIntake_figs, saveTabs, indivIntakefigs_savepath, groupIntakefigs_savepath, tabs_savepath)
    [beT, beiT, aT] = BE_Analysis(mT, expKey, BE_intake_canonical_flnm);
    
    if saveTabs
        writeTabs(beT, [sub_dir, tabs_savepath], 'BE_data', {'.mat', '.xlsx'})
        writeTabs(beiT, [sub_dir, tabs_savepath], 'BE_allIntake', {'.mat', '.xlsx'})
        writeTabs(aT, [sub_dir, tabs_savepath], 'BE_indivCurveFit', {'.mat', '.xlsx'})
    end
    
    if indivIntake_figs
        BE_IndivFig(beT.TagNumber, aT, sub_dir, indivIntakefigs_savepath);
    end

    if groupIntake_figs
        subset = beT.Acquire=='Acquire';

        figpath = [sub_dir, groupIntakefigs_savepath, 'BE Intake and Active Lever Grouped by Sex and Strain Acquirers.png'];
        BE_GroupFig(beT, {beT.measuredIntake, beT.ActiveLever}, ["Fentanyl Intake (μg/kg)", "Active Lever Presses"], subset, figpath);
        
        figpath = [sub_dir, groupIntakefigs_savepath, 'BE Latency and Rewards Grouped by Sex and Strain Acquirers.png'];
        BE_GroupFig(beT, {beT.Latency, beT.Latency}, ["Head Entry Latency", "Rewards"], subset, figpath);

        subset = beT.Acquire=='NonAcquire';

        figpath = [sub_dir, groupIntakefigs_savepath, 'BE Intake and Active Lever Grouped by Sex and Strain NonAcquirers.png'];
        BE_GroupFig(beT, {beT.measuredIntake, beT.ActiveLever}, ["Fentanyl Intake (μg/kg)", "Active Lever Presses"], subset, figpath);
        
        figpath = [sub_dir, groupIntakefigs_savepath, 'BE Latency and Rewards Grouped by Sex and Strain NonAcquirers.png'];
        BE_GroupFig(beT, {beT.Latency, beT.Latency}, ["Head Entry Latency", "Rewards"], subset, figpath);

    end
end

function [hmT] = getFirstHour(mT)
    % active lever 22
    % inactive lever 23
    % head entries 95
    % rewarded lever presses  96
    % rewarded lever presses followed by head entry 97
    % rewarded head entries (preceded by lever press) 99
    % head entries following rewarded lever presses 98
    % rewarded lever presses preceding head entries 96
    % earned infusions 17
    
    copyVars = {'TagNumber', 'Session', 'sessionType', 'slideSession', ...
               'Strain', 'Sex', 'TimeOfBehavior', 'Chamber', 'Acquire'};
    hmT = mT(:, copyVars);

    hourVars = {'ActiveLever', 'InactiveLever', 'HeadEntries', 'EarnedInfusions' ...
                'RewardedHeadEntries', 'RewardedLeverPresses'}; %SSnote: don't love the ambiguity of column ame "RewardedLeverPresses"
    hourCodes = [22, 23, 95, 96, 99, 97]; % codes for items in hourVars
    allEC = cell([height(mT), 1]);
    allET = cell([height(mT), 1]);
    for hv = 1:length(hourVars)
        dat = nan([height(mT), 1]);
        for fl = 1:height(mT)
            EC = mT.eventCode{fl};
            ET = mT.eventTime{fl};
            EC = EC(ET <= 3600);
            ET = ET(ET <= 3600); 

            if strcmp(hourVars{hv}, 'EarnedInfusions')
                % calculate earned and total infusions 
                if mT.sessionType(fl) == categorical("Reinstatement")
                    dat(fl) = 0;
                elseif mT.TotalInfusions(fl) == 0
                    dat(fl) = 0;
                else
                    dat(fl) = length(find(EC==hourCodes(hv)));
                end
            else
                dat(fl) = length(find(EC==hourCodes(hv)));
            end
            
            % disp(length(find(EC==hourCodes(hv))))
            if strcmp(hourVars{hv}, 'InactiveLever') & (dat(fl) == 0)
                % SS hack for absent inactive lever event codes in some sessions...
                % HARDCODED TO READ RIGHT LEVER AS INACTIVE LEVER
                dat(fl) = length(find(EC==1));
            end
    
            if hv == 1
                allEC{fl} = EC;
                allET{fl} = ET;
            end
        end
        hmT = [hmT, table(dat)];
        hmT = renamevars(hmT, 'dat', hourVars{hv});
    end
    hmT = [hmT, table(allEC, allET)];
    hmT = renamevars(hmT, {'allEC', 'allET'}, {'eventCode', 'eventTime'});
    
    allLatency = cell([height(mT), 1]);
    Latency = nan([height(mT), 1]);
    doseHE = cell([height(mT), 1]);
    Intake = nan([height(mT), 1]);
    totalIntake = nan([height(mT), 1]);

    for fl = 1:height(mT)
        ET = hmT.eventTime{fl};
        EC = hmT.eventCode{fl};
        
        rewHE = ET(EC==99);
        doseHE{fl} = mT.doseHE{fl}(1:length(rewHE)); 

        if hmT.sessionType(fl) == 'Extinction'
            EC = hmT.eventCode{fl};
            ET = hmT.eventTime{fl};
            actLP = ET(EC==22);
            HE = ET(EC==95);
            seekHE = arrayfun(@(x) find(HE > x, 1, 'first'), actLP, 'UniformOutput', false);
            seekHE = HE(unique(cell2mat(seekHE(~cellfun(@isempty, seekHE)))));
            seekLP = arrayfun(@(x) find(actLP < x, 1, 'last'), seekHE, 'UniformOutput', false);
            seekLP = actLP(unique(cell2mat(seekLP(~cellfun(@isempty, seekLP)))));
            allLatency{fl} = seekHE-seekLP;
        else  
            allLatency{fl} = mT.allLatency{fl}(1:length(rewHE));
        end

        Latency(fl) = mean(allLatency{fl});
     
        if mT.TotalInfusions(fl) == 0
            totalIntake(fl) = 0;
            Intake(fl) = 0;
        else
            conc = mT.Concentration(fl);
            doseVol = mT.DoseVolume(fl);
            totalIntake(fl) = mT.TotalInfusions(fl) * doseVol * conc;
            Intake(fl) = mT.EarnedInfusions(fl) * doseVol * conc;
        end
    end
    hmT = [hmT, table(allLatency, Latency, doseHE, Intake, totalIntake)];
end


function [Acquire] = getAcquire(mT, dex, acquisition_thresh)
    IDs=unique(mT.TagNumber(dex.all));
    mT = sortrows(mT,'TagNumber','ascend');
    Acq = nan(size(IDs));
    Acquire = categorical(nan([height(mT), 1]));
    for id=1:height(IDs)
        % SSnote: this should be using sessionType instead of the Session#
        idx = mT.TagNumber==IDs(id) & mT.Session>9 & mT.Session <16;
        Acq(id,1) = mean(mT.EarnedInfusions(idx)) > acquisition_thresh;
        if Acq(id) == 0 && sum(idx) ~= 0
            status = 'NonAcquire';
        else
            status = 'Acquire';
        end
        tmp=repmat(categorical({status}), sum(mT.TagNumber == IDs(id)), 1);
        Acquire(mT.TagNumber == IDs(id)) = tmp;
    end
end


function [dex] = getExperimentIndex(mT, runNum, runType)
    if runNum == 'all'
        runNum_inds = ones([height(mT), 1]);
    else
        nums = strsplit(char(runNum),'_');
        runNum_inds = zeros([height(mT),1]);
        for n = 1:length(nums)
            runNum_inds = runNum_inds | (mT.Run == str2double(nums{n}));
        end
    end
    
    % Create indexing structure for 'ER', 'BE', and 'SA' data of the desired run #(s)
    dex = struct;
    dex.all = [];
    for e = 1:length(runType)
        if runType(e) == 'SA'
            dex.SA = find(((mT.sessionType == 'Training') | (mT.sessionType == 'PreTraining')) & runNum_inds);
        else
            dex.(string(runType(e))) = find((mT.Experiment == runType(e)) & runNum_inds);
        end
        dex.all = union(dex.all, dex.(string(runType(e))));
    end
end


function writeTabs(data, flnm, fltypes)
    for ft = 1:length(fltypes)
        if strcmp(fltypes(ft), '.mat')
            % MatLab .mat
            save(flnm, 'data');
            varNm = data.Properties.VariableNames;
        elseif strcmp(fltypes(ft), '.xlsx')
            % Excel .xlsx (remove any cell data from table)
            remove_inds = arrayfun(@(x) (class(data.(varNm{x}))=="cell"), 1:length(varNm));
            sub_data = removevars(data,varNm(remove_inds));
            writetable(sub_data, [flnm, '.xlsx'], 'Sheet', 1);
        else
            disp(['Table format "', ftips(ft), '" not recognized, table not saved.'])
        end
    end
end


function [new_dirs] = makeSubFolders(allfig_savefolder, runNum, runType, toMake, excludeData, firstHour)
    if length(runType) > 1
        runTypeStr = 'all';
    else
        runTypeStr = char(string(runType));
    end
    
    if length(runNum) > 1
        runNumStr = 'all';
    else
        runNumStr = char(string(runNum));
    end
    
    sub_dir = ['Run_', runNumStr, '_', runTypeStr];
    if excludeData
        sub_dir = [sub_dir, '_exclusions'];
    end
    sub_dir = [allfig_savefolder, sub_dir, '\'];

    new_dirs = {sub_dir};
    if firstHour
        fH_sub_dir = [sub_dir(1:length(sub_dir)-1), '_firstHour', '\'];
        new_dirs = {new_dirs{1}, fH_sub_dir};
    end
    
    for tm = 1:length(toMake)
        mkdir([sub_dir, toMake{tm}])
        if firstHour
            mkdir([fH_sub_dir, toMake{tm}])
        end
    end
end



function [mT] = removeExcludedData(mT, mKey)
    % SS added
    RemoveSession = zeros([length(mT.Chamber),1]);
    sub_RemSess = mKey.RemoveSession;
    for sub = 1:length(sub_RemSess)
        sess = sub_RemSess{sub}(2:end-1);
        if ~isempty(sess)
            sess = strsplit(sess, ' ');
            tag = mKey.TagNumber(sub);
            for s = 1:length(sess)
                ind = find((mT.TagNumber == tag) .* (mT.Session == str2double(sess{1})));
                RemoveSession(ind) = 1;
            end
        end      
    end
    mT(find(RemoveSession),:) = [];
    % mT=[mT table(RemoveSession)];
end

