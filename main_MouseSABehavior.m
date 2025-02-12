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
masterTable_flnm = '.\06-Feb-2025_masterTable.mat'; % the masterTable .mat file loaded in if createNewMasterTable == false
beh_datapath = {'.\All Behavior'}; % Used to generate a new masterTable if createNewMasterTable == true
masterSheet_flnm = '.\Golden R01 Behavior Master Key.xlsx'; % Key describing information specific to each animal
BE_intake_canonical_flnm = '.\2024.12.09.BE Intake Canonical.xlsx'; % Key for drug concentration, dose, and intake only used if runType == 'BE'
experimentKey_flnm = '.\Experiment Key.xlsx'; % Key for

% MISC. SETTINGS
runNum = -1; % options: -1 for all runs, otherwise single runs 1, 2, 3, or 4
runType = 'BE'; % options: 'ER' (Extinction Reinstatement), 'BE' (Behavioral Economics), 'SA' (Self Administration)
createNewMasterTable = false; % true: generates & saves a new master table from medPC files in datapath. false: reads mT in from masterTable_flnm if set to false, otherwise 
firstHour = true; % true: acquire data from the first-hour of data and analyze in addition to the full sessions
excludeData = true; % true: excludes data based on the 'RemoveSession' column of masterSheet
acquisition_thresh = 10; % to be labeled as "Acquire", animal must achieve an average number of infusions in the second weak of Training sessions greater than this threshold

% FIGURE OPTIONS
% Currently, if figures are generated they are also saved. 
dailyFigs = true; % true: generate daily figures from dailySAFigures.m
pubFigs = true; % true: generate publication figures from pubSAFigures.m
indivIntake_figs = true; % true: generate figures for individual animal behavior across & within sessions
groupIntake_figs = true; % true: generate figures grouped by sex, strain, etc. for animal behavior across & within sessions
groupOralFentOutput_figs = false; % true: generate severity figures
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

% sessTypes lists experiment types for logical indexing in mKey to determine which data is consistent with 'runType'.
% the mKey columns listed in sessTypes must be equal to 1 for a given animal for its data to be included in the analysis
% 'ER' -> {'SelfAdministration', 'Extinction', 'Reinstatement'}
% 'BE' -> {'SelfAdministration','BehavioralEconomics'} 
% 'SA' -> {'SelfAdministration};
% SSnote: this system doesn't work well now that we want to include Run 2 BE data while 
%         excluding its extinction and ProgressiveRatio data. Will be best to revise
%         this to use the Experiment Key to filter mKey based on runType
sessTypes = getSessTypes(runType); % returns empty if runType == 'all', won't be needed downstream in this case


%% IMPORT DATA

if createNewMasterTable
    mT = createMasterTable(main_folder, beh_datapath, masterSheet_flnm,experimentKey_flnm);
else
    load(masterTable_flnm)
end

%% FILTER DATA ACCORDING TO runNum & runType SETTINGS
% SSnote: whole section needs overhauled

% pull specific data to analyze
mT_tags = getMTtags(runNum, runType, sessTypes, mKey);
mT_ind = find(ismember(mT.TagNumber, mT_tags));
mT = mT(mT_ind,:);
if strcmp(runType, 'SA')
    remove_inds = find(mT.sessionType ~= categorical("Training") & mT.sessionType ~= categorical("PreTraining"));
% elseif strcmp(runType, 'BE')
%     remove_inds = find(mT.sessionType == categorical("Extinction") | mT.sessionType == categorical("ProgressiveRatio") | isundefined(mT.sessionType));
else
    remove_inds = [];
end
mT(remove_inds, :) = [];


% pull specific chunks of experiment key needed
if ~runNum == -1
    expRunNum = (expKey.Run == runNum);
else
    expRunNum = ones([height(expKey), 1]);
end

if strcmp(runType, 'all')
    expRunType = ones([height(expKey), 1]);
elseif strcmp(runType, 'SA')
    expRunType = strcmp(expKey.SessionType, 'Training') | strcmp(expKey.SessionType, 'PreTraining');
else
    expRunType = strcmp(expKey.Experiment,runType);
end

expKey_inds = find(expRunNum & expRunType);
expKey = expKey(expKey_inds,:);

% exclude data
if excludeData
    mT = removeExcludedData(mT, mKey);
end

%% Determine Acquire vs Non-acquire

ids=unique(mT.TagNumber);
Acquire=table; 
mT = sortrows(mT,'TagNumber','ascend');
Acq = nan(size(ids));

for l=1:height(ids)
    % SSnote: this should be using sessionType instead of the Session#
    idx = mT.TagNumber==ids(l) & mT.Session>9 & mT.Session <16;
    Acq(l,1) = mean(mT.EarnedInfusions(idx)) > acquisition_thresh;
    if Acq(l) == 0 && sum(idx) ~= 0
        tmp = repmat(categorical({'NonAcquire'}), sum(mT.TagNumber == ids(l)), 1);
        Acquire = [Acquire; table(tmp)];
    else
        tmp=repmat(categorical({'Acquire'}), sum(mT.TagNumber == ids(l)), 1);
        Acquire = [Acquire; table(tmp)];
    end
end

Acquire.Properties.VariableNames{'tmp'} = 'Acquire';
mT=[mT Acquire];

%% FIRST HOUR
if firstHour
    hmT = getFirstHour(mT);
end

%% check # data files per group
% numtab is a table that shows the number of data files for C57 and CD1 males and females
numtab = numFilesPerGroup(mT);

%% Save Master Table and generate figures for daily spot checks
if dailyFigs
    % Save daily copy of the master table in .mat and xlsx format and save groups stats  
    mTname = [sub_dir, tabs_savepath, dt, '_MasterBehaviorTable.mat'];
    sub_mT = removevars(mT,{'eventCode', 'eventTime'});
    writetable(sub_mT,[sub_dir, tabs_savepath, dt, '_MasterBehaviorTable.xlsx'], 'Sheet', 1);
    groupStats = grpstats(mT,["Sex", "Strain", "Session"], ["mean", "sem"], ...
        "DataVars",["ActiveLever", "InactiveLever", "EarnedInfusions", "HeadEntries", "Latency", "Intake"]);
    writetable(groupStats, [sub_dir, tabs_savepath, dt, '_GroupStats.xlsx'], 'Sheet', 1);
    save(mTname,'mT');
    %Generate a set of figures to spotcheck data daily
    dailySAFigures(mT, runType, dt,[sub_dir, dailyfigs_savepath]);
    close all
    if firstHour
        dailySAFigures(hmT, runType, dt,[fH_sub_dir, dailyfigs_savepath])
        close all
    end
end

%% Generate Clean Subset of Figures for Publication

if pubFigs %  && strcmp(runType, 'ER')
    pubSAFigures(mT, runType, dt, [sub_dir, pubfigs_savepath]);
    if firstHour 
        pubSAFigures(hmT, runType, dt, [fH_sub_dir, pubfigs_savepath]); 
    end
    close all;
   
% elseif pubFigs && strcmp(runType, 'BE')
%     pubSAFiguresBEAnimals(mT, dt, [sub_dir, pubfigs_savepath]);
%     if firstHour
%         pubSAFiguresBEAnimals(hmT, dt, [fH_sub_dir, pubfigs_savepath]); 
%     end
%     close all;
    
end

%% ********** Behavioral Economics Analysis *************************************

if strcmp(runType, 'BE')
    % SSnote: this section is pulling intake data from '2024.12.09.BE Intake Canonical.xlsx.' 
    % The daily & publication figures above pull intake data from 'Experiment Key.xlsx'
    beT=mT(mT.sessionType=='BehavioralEconomics',:); % Initialize Master Table
    IDs=unique(beT.TagNumber);  
    BE_sess = unique(expKey.Session(strcmp(expKey.SessionType,'BehavioralEconomics')));


    % Import Dose and Measured Intake Data
    opts = detectImportOptions(BE_intake_canonical_flnm); 
    beiT=readtable(BE_intake_canonical_flnm, opts);
    beiT.TagNumber = categorical(beiT.TagNumber);
    beiT = beiT(ismember(beiT.TagNumber, beT.TagNumber),:);
    BE_days = unique(beiT.Day);
    % remove sessions with missing data from beiT
    % SSnote: this method of removing missing sessions from beiT won't work if there are multiple BE runs in the dataset
    missing_days = cell([length(IDs), 1]);
    for i = 1:length(IDs)
        this_sess = beT.Session(beT.TagNumber == IDs(i));
        md = find(~ismember(BE_sess, this_sess));
        missing_days{i} = md;
        remove_ind = find((beiT.TagNumber==IDs(i)) .* ismember(beiT.Day, missing_days{i}));
        beiT(remove_ind,:) = [];
    end
    unitPrice=(1000./beiT.Dose__g_ml_);
    beT = [beT, table(beiT.Day, beiT.measuredIntake, beiT.Dose__g_ml_, unitPrice)];
    beT = renamevars(beT, ["Var1", "Var2", "Var3", "Var4"], ["Day", "measuredIntake", "Dose", "unitPrice"]);

    % Curve Fit Each Animals Intake over Dose
    Sex = nan([length(IDs), 1]);
    Strain = nan([length(IDs), 1]);
    Alpha = nan([length(IDs) 1]);

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
            [res_x, idx_x]=knee_pt(log(1:500),f(1:500));
            Elastic(i,1)=idx_x;
            
            if indivIntake_figs
                f1=figure;
                plot(log(1:50),f(1:50));
                hold on;
                scatter(log(price),log(in),10);
                
                plot([log(idx_x) log(idx_x)],[min(f(1:50)) max(f(1:50))],'--k');
                xlim([-1 5]);
                title(IDs(i))
                exportgraphics(f1,[sub_dir, indivIntakefigs_savepath, 'Tag', char(IDs(i)), '_BE_curvefit.png']);
                hold off
                close(f1);
            end
        end  
    end

    aT=table(IDs,Sex,Strain,Alpha,Elastic);
    
    if groupIntake_figs
        subset = beT.Acquire=='Acquire';

        figpath = [sub_dir, groupIntakefigs_savepath, 'BE Intake and Active Lever Grouped by Sex and Strain.png'];
        BE_GroupFig(beT, {beT.measuredIntake, beT.ActiveLever}, ["Fentanyl Intake (μg/kg)", "Active Lever Presses"], subset, figpath);
        
        figpath = [sub_dir, groupIntakefigs_savepath, 'BE Latency and Rewards Grouped by Sex and Strain.png'];
        BE_GroupFig(beT, {beT.Latency, beT.Latency}, ["Head Entry Latency", "Rewards"], subset, figpath);
    end
end

%% Within Session Behavioral Analysis 
% Analyze Rewarded Lever Pressing Across the Session

% Event Codes
% 3 = Rewarded Press
% 13 = Tone On
% 97 = ITI Press
% 23 = Inactive Press
% 96 = rewarded lever presses, not necessarily followed by head entry
% 97 = rewarded lever presses followed by head entry
% 98 = head entries following infusion
% 99 = rewarded head entries (preceded by lever press)


mTDL = mT(mT.EarnedInfusions>10, :);%(mT.Acquire=='Acquire' & mT.EarnedInfusions>10, :); % SS note: - why are we limiting the analysis here to sessions w/ >10 infusions
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

    TagNumber=repmat([mTDL.TagNumber(i)],length(adj_rewLP),1);
    Session=repmat([mTDL.Session(i)],length(adj_rewLP),1);
    Sex =repmat([mTDL.Sex(i)],length(adj_rewLP),1);
    Strain =repmat([mTDL.Strain(i)],length(adj_rewLP),1);

    if i==1
        mPressT=table(TagNumber, Session, adj_rewLP, cumulDoseHE, Sex, Strain);
    else
        mPressT=[mPressT; table(TagNumber, Session, adj_rewLP, cumulDoseHE, Sex, Strain)];
    end
    
    % % SSnote: hard-coded drug intake, need to update
    [DL, DLTime] = pharmacokineticsMouseOralFent('infusions',[rewHE*1000 (rewHE+(4*doseHE))*1000],'duration',180,'type',4,'weight',mT.Weight(i)./1000,'mg_mL',0.07,'mL_S',.005);
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

%

if indivIntake_figs
    IDs=unique(mPressT.TagNumber);
    for j=1:length(IDs)
        %indiv_allSessionFig(tab, subset, xvar, xlab, yvar, ylab, figtitle, facetwrap, subpstring, figpath)

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


%% Grouped intake-across-session figures
if groupIntake_figs
    % group_allSessionFig(tab, xvar, xlab, yvar, ylab, colorGroup lightGroup, facetwrap, figpath, stat_type, set_yMax)

    % Drug Level by Strain and Sex 
    figpath = [sub_dir, groupIntakefigs_savepath, 'Drug Level Grouped by Sex and Strain.png'];
    group_allSessionFig(mDrugLT, logical(ones([height(mDrugLT),1])), 'DLTime', 'Time (m)', 'DL', 'Estimated Brain Fentanyl (pMOL)', ...
                        'Strain', 'Sex', 'Session', 'Group Drug Level', figpath, 'area');

    % Drug Level by Strain and Sex during Training
    figpath = [sub_dir,groupIntakefigs_savepath, 'Drug Level Grouped by Sex and Strain.pdf'];
    group_allSessionFig(mDrugLT, mDrugLT.sessionType=='Training', 'DLTime', 'Time (m)', 'DL', 'Estimated Brain Fentanyl (pMOL)', ...
                        'Strain', 'Sex', 'Session', 'Group Drug Level (Training)', figpath, 'area');

    % Drug Level by Sex and Session during Training Sessions 5, 10, 15
    figpath = [sub_dir, groupIntakefigs_savepath, 'Drug Level Grouped by Sex and Session 5 10 15.pdf'];
    subset = (mDrugLT.Session==5 | mDrugLT.Session==10 | mDrugLT.Session==15);
    group_allSessionFig(mDrugLT, subset, 'DLTime', 'Time (m)', 'DL', 'Estimated Brain Fentanyl (pMOL)', ...
                        'Sex', 'Session', 'none', 'Average Group Drug Level (Sessions 5, 10, 15)', figpath, 'line');

    % Cumulative responses (rewarded head entries) by Sex and Session during Training Sessions 5, 10, 15
    figpath = [sub_dir, groupIntakefigs_savepath, 'Mean Responses Grouped by Sex and Session 5 10 15.pdf'];
    subset = (mPressT.Session==5 | mPressT.Session==10 | mPressT.Session==15);
    group_allSessionFig(mPressT, subset, 'adj_rewLP', 'Time (m)', 'cumulDoseHE', 'Cumulative Responses', ...
                        'Sex', 'Session', 'none', 'Mean Cumulative Responses (Sessions 5, 10, 15)', figpath, 'cumbin');
end

%% Statistic Linear Mixed Effects Models
statsname=[sub_dir, tabs_savepath, 'Oral SA Group Stats.mat'];

% Training
data = mT(mT.sessionType == 'Training',:);
dep_var = ["Intake", "EarnedInfusions", "HeadEntries", "Latency", "ActiveLever", "InactiveLever"];
lme_form = " ~ Sex*Session + (1|TagNumber)";
Training_LMEstats = getLMEstats(data, dep_var, lme_form);

if strcmp(runType,'ER')

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
    
    save(statsname, 'Training_LMEstats', 'Extinction_LMEstats', 'Reinstatement_LMEstats');

elseif strcmp(runType,'BE')

    % BehavioralEconomics
    data = mT(mT.sessionType=='BehavioralEconomics',:);
    dep_var = ["HeadEntries", "Latency", "ActiveLever", "InactiveLever"];
    lme_form = " ~ Sex + (1|TagNumber)";
    BehavioralEconomics_LMEstats = getLMEstats(data, dep_var, lme_form);
    
    save(statsname, 'Training_LMEstats', 'BehavioralEconomics_LMEstats');

else
    save(statsname, 'Training_LMEstats');
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

% SSnote: NOTHING BEYOND THIS POINT WILL WORK UNLESS runType is 'ER' AND
% MAYBE NOT THEN EITHER??? HAVEN'T TESTED

ID = unique(mT.TagNumber);
[Dummy, Intake, Seeking, Association, Escalation, Extinction,  ...
 Persistence, Flexibility, Relapse, Recall] = deal([]);

Sex = categorical([]);

for i=1:length(ID)
    Dummy(i,1)=1;       
    Intake(i,1)= mean(mT.Intake(mT.TagNumber==ID(i) & mT.Session>5 & mT.sessionType=='Training'));
    Seeking(i,1)= mean(mT.filteredHeadEntries(mT.TagNumber==ID(i) & mT.Session>5 & mT.sessionType=='Training'));
    Association(i,1)= nanmean(mT.lastLatency(mT.TagNumber==ID(i) & mT.Session>5 & mT.sessionType=='Training')); 
    e = polyfit(double(mT.Session(mT.TagNumber==ID(i) & mT.sessionType=='Training')),mT.TotalInfusions(mT.TagNumber==ID(i) & mT.Session>5 & mT.sessionType=='Training'),1);
    Escalation(i,1)=e(1);
    Extinction(i,1)= nanmean(mT.ActiveLever(mT.TagNumber==ID(i) & mT.sessionType=='Extinction'));
    p = polyfit(double(mT.Session(mT.TagNumber==ID(i) & mT.sessionType=='Extinction')),mT.ActiveLever(mT.TagNumber==ID(i) & mT.sessionType=='Extinction'),1);
    Persistence(i,1)=0-p(1);
    Flexibility(i,1)=mean(mT.InactiveLever(mT.TagNumber==ID(i) & mT.sessionType=='Extinction'));
    Relapse(i,1)=mT.ActiveLever(mT.TagNumber==ID(i) & mT.sessionType=='Reinstatement');
    Recall(i,1)=mT.Latency(mT.TagNumber==ID(i) & mT.sessionType=='Reinstatement');
    s=mT.Sex(mT.TagNumber==ID(i) & mT.sessionType=='Training');
    Sex(i,1)=s(1);
end

% SS note: why log? 
Association=log(Association);
Recall=log(Recall);

% SS note: sup with this bit? overwrite self, just for side checks? 
% % Tests of Normality vs Bimodal
% [hIn pIn]=kstest(zscore(Intake));
% [hIn pIn]=kstest(zscore(Seeking));
% [hIn pIn]=kstest(zscore(Association));
% [hIn pIn]=kstest(zscore(Escalation));
% [hIn pIn]=kstest(zscore(Extinction));
% [hIn pIn]=kstest(zscore(Relapse));

% SS note: what is this showing
% figure
% hold on
% cdfplot(zscore(Extinction))
% x_values = linspace(min(zscore(Extinction)),max(zscore(Extinction)));
% plot(x_values,normcdf(x_values,0,1),'r-')
% legend('Empirical CDF','Standard Normal CDF','Location','best')
% hold off

% Individual Variable Table
ivT=table(ID,Sex,Intake,Seeking,Association,Escalation,Extinction,Relapse);

% SS note: what was ivT? what is .S? keeping commented for now..
% corrMat=corr([ivT.Intake,ivT.S]); % Slope Calculation & IV Extraction

% % Z-Score & Severity Score
ivZT=ivT;
ivZT.Intake=zscore(ivZT.Intake);
ivZT.Seeking=zscore(ivZT.Seeking);
ivZT.Association=zscore(nanmax(ivZT.Association)-ivZT.Association);
ivZT.Escalation=zscore(ivZT.Escalation);
ivZT.Extinction=zscore(ivZT.Extinction);
ivZT.Relapse=zscore(ivZT.Relapse);

% % Correlations
varnames = ivZT.Properties.VariableNames;
prednames = varnames(varnames ~= "ID" & varnames ~= "Sex");
ct=corr(ivZT{:,prednames},Type='Pearson');

if groupOralFentOutput_figs
    f=figure('Position',[1 1 700 600]);
    imagesc(ct,[0 1]); % Display correlation matrix as an image
    colormap('hot');
    a = colorbar();
    a.Label.String = 'Rho';
    a.Label.FontSize = 12;
    a.FontSize = 12;
    set(gca, 'XTickLabel', prednames, 'XTickLabelRotation',45, 'FontSize', 12); % set x-axis labels
    set(gca, 'YTickLabel', prednames, 'YTickLabelRotation',45, 'FontSize', 12); % set x-axis labels
    box off
    set(gca,'LineWidth',1.5,'TickDir','out')
    % SS commented out bc I don't hav corrplotKC.m
    % [corrs,~,h2] = corrplotKC(ivZT,DataVariables=prednames,Type="Spearman",TestR="on");
    exportgraphics(f,[sub_dir, groupOralFentOutput_savepath, 'Individual Differences_Correlations.pdf'],'ContentType','vector');
    close(f)
end

Severity = sum(ivZT{:, prednames}')';
Class = cell([height(Severity) 1]);
Class(Severity>1.5) = {'High'};
Class(Severity>-1.5 & Severity<1.5) = {'Mid'};
Class(Severity<-1.5) = {'Low'};
Class = categorical(Class);
ivT=[ivT table(Severity, Class)];

[hIn, pIn] = kstest(zscore(Severity));

save(".\Behavior Tables\Master Behavior Table.mat","mT",'ivT','ivZT');

yVars = {'Intake', 'Seeking', 'Association', 'Escalation', 'Extinction', 'Relapse', 'Severity'};
yLabs = {' Fentanyl Intake (mg/kg)', 'Seeking (Head Entries)', 'Association (Latency)', ...
         'Escalation (slope Training Intake)', 'Extinction Responses', 'Relapse (Reinstatement Responses)', 'Severity' };
f = plotViolins(ivT, yVars, yLabs);
exportgraphics(f,[sub_dir, groupOralFentOutput_savepath, 'Individual Differences_Violin.pdf'],'ContentType','vector');
close(f)

%% TSNE
varnames = ivZT.Properties.VariableNames;
prednames = varnames(varnames ~= "ID" & varnames ~= "Sex" & varnames ~= "Class");
Y = tsne(ivZT{:,prednames},'Algorithm','exact','Distance','cosine','Perplexity',15);
[coeff,score,latent] = pca(ivZT{:,prednames});
PC1=score(:,1);
PC2=score(:,2);

f1=figure('color','w','position',[100 100 400 325]);
h1 = biplot(coeff(:,1:3),'Scores',score(:,1:3),...
    'Color','b','Marker','o','VarLabels',prednames);
for i=1:6
    h1(i).Color=[.5 .5 .5];    
    h1(i).LineWidth=1.5;
    h1(i).LineStyle=':';
    h1(i).Marker='o';
    h1(i).MarkerSize=4;
    h1(i).MarkerFaceColor=[.5 .5 .5];
    h1(i).MarkerEdgeColor=[0 .0 0];
end
for i=7:12
    h1(i).Marker='none';
end

R = rescale(Severity,4,18);
for i=19:40
    if Sex(i-18)=='Male'
        h1(i).MarkerFaceColor=[.46 .51 1];
        h1(i).MarkerEdgeColor=[0 .0 0];
        h1(i).MarkerSize=R(i-18);
    else
        h1(i).MarkerFaceColor=[.95 .39 .13];
        h1(i).MarkerEdgeColor=[0 .0 0];
        h1(i).MarkerSize=R(i-18);
    end
end
for i=13:18
h1(i).FontSize=11;
h1(i).FontWeight='bold';
end
h1(13).Position=[.535 .185];
h1(14).Position=[.435 .625];
h1(15).Position=[.4 -.265];
h1(16).Position=[.485 .285];
h1(17).Position=[.435 -.41];
h1(18).Position=[.435 -.515];
set(gca,'LineWidth',1.5,'TickDir','in','FontSize',14);
grid off
xlabel('');
ylabel('');
zlabel('');
exportgraphics(f1,[sub_dir, groupOralFentOutput_savepath, 'Individual Differences PCA Vectors.pdf'],'ContentType','vector');

% SS commented, don't have the CaptureFigVid function and am not needing this with code currently uncommented...
% % Set up recording parameters (optional), and record
% OptionX.FrameRate=30;OptionX.Duration=20;OptionX.Periodic=true;
% CaptureFigVid([-180,0;0,90], 'PCA',OptionX)

pcTable=table(Class,PC1,PC2);
f1=figure('color','w','position',[100 100 300 225]);
g=gramm('x',pcTable.PC1,'y',pcTable.PC2,'color',ivT.Sex,'marker',ivT.Class);
g.set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
g.geom_point();
g.set_names('x','PC1','y','PC2','color','Class');
g.axe_property('FontSize',12,'LineWidth',1.5,'TickDir','out');
g.set_order_options('marker',{'High','Mid','Low'});
g.set_point_options('base_size',8);
g.draw;
for i=1:height(g.results.geom_point_handle)
   g.results.geom_point_handle(i).MarkerEdgeColor = [0 0 0];
end
exportgraphics(f1,[sub_dir, groupOralFentOutput_savepath, 'Individual Differences TSNE.pdf'],'ContentType','vector');




%% ------------------------FUNCTIONS---------------------------------
function [LME_stats] = getLMEstats(data, dep_var, lme_form)
    LME_stats = struct;
    for dv = 1:length(dep_var)
        LME_stats.(strcat(dep_var(dv), "LME")) = fitlme(data, strcat(dep_var(dv), lme_form));
        LME_stats.(strcat(dep_var(dv), "F")) = anova(LME_stats.(strcat(dep_var(dv), "LME")) ,'DFMethod','satterthwaite');
    end
end


function [f] = plotViolins(ivT, yVars, yLabs)
    % SS added
    clear g
    f = figure('units','normalized','outerposition',[0 0 1 .4]);
    numDat = length(ivT.Intake); 
    x = nan([1,numDat]);
    x(ivT.Sex == categorical({'Female'})) = .8;
    x(ivT.Sex == categorical({'Male'})) = 1.2; 

    for y = 1:length(yVars)
        g(1,y)=gramm('x',x,'y',ivT.(yVars{y}),'color',ivT.Sex);
        g(1,y).set_order_options('color', {'Female', 'Male'})
        g(1,y).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
        g(1,y).stat_violin('normalization', 'width', 'fill', 'transparent'); %'extra_y', 0, 'half', 1, 
        g(1,y).geom_jitter('width',.05,'dodge',-.5,'alpha',.75);
        g(1,y).axe_property('LineWidth',1.5,'FontSize',14,'Font','Helvetica','XLim',[0.5 1.5],'TickDir','out'); %'YLim',[0 1200]
        g(1,y).set_names('x','','y', yLabs{y},'color','');
        g(1,y).set_point_options('base_size',6);
        % g(1,y).no_legend();
        g(1,y).set_title(' ');
    end
    
     g.draw;

    for i=1:width(g)
       g(1,i).results.geom_jitter_handle(1).MarkerEdgeColor = [0 0 0]; 
       g(1,i).results.geom_jitter_handle(2).MarkerEdgeColor = [0 0 0];
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
    % close(f)
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


function [new_dirs] = makeSubFolders(allfig_savefolder, runNum, runType, toMake, excludeData, firstHour)
    sub_dir = ['Run_', num2str(runNum), '_', runType];
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


function sessTypes = getSessTypes(runType) % returns empty if runType == 'all', won't be needed
    % EXPERIMENT TYPE DEFINITIONS FOR LOGICAL INDEXING
    ER_types = {'SelfAdministration', 'Extinction', 'Reinstatement'};
    BE_types = {'SelfAdministration', 'BehavioralEconomics'};
    SA_types = {'SelfAdministration'};
    
    % determine session types to use for logical indexing
    % (only if runType ~= 'all')
    sessTypes = {};
    if strcmp(runType, 'ER')
        sessTypes = ER_types;
    end
    if strcmp(runType, 'BE')
        sessTypes = BE_types;
    end
    if strcmp(runType, 'SA')
        sessTypes = SA_types; 
    end
end


function [mT_tags] = getMTtags(runNum, runType, sessTypes, mKey)

    % indexing of data to include in checks
    if runNum ~= -1
        runInd = mKey.Run == runNum;
    else
        runInd = ones([length(mKey.Run), 1]); 
    end
    %SSnote: change this to use the experiment column in the master table
    if ~strcmp(runType, 'all')
        expInd = ones([length(runInd), 1]);
        for typ = 1:length(sessTypes)
            expInd = expInd .* mKey.(sessTypes{typ});
        end
        
    else
        expInd = ones([length(mKey.Run), 1]);
    end
    mT_tags = mKey.TagNumber(find(runInd .* expInd));
    
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

            % if strcmp(hourVars{hv}, 'EarnedInfusions')
            %     % calculate earned and total infusions 
            %     if mT.sessionType(fl) == categorical("Reinstatement")
            %         dat(fl) = NaN;
            %     elseif mT.TotalInfusions(fl) == 0
            %         dat(fl) = NaN;
            %     else
            %         dat(fl) = length(find(EC==hourCodes(hv)));
            %     end
            % else
            %     dat(fl) = length(find(EC==hourCodes(hv)));
            % end
            
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
        allLatency{fl} = mT.allLatency{fl}(1:length(rewHE));
        Latency(fl) = mean(allLatency{fl});
        doseHE{fl} = mT.doseHE{fl}(1:length(rewHE)); 
     
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

%% BE Battery & Hot Plate
% 
% % Hot Plate
% % clear all;
% opts = detectImportOptions('2022.02.28 LHb Oral Fentanyl\2022.09.29 Oral SA Round 4 BE Battery\HP Master Sheet.xlsx');
% opts = setvartype(opts,{'ID','Sex'},'categorical');
% hpT=readtable('2022.02.28 LHb Oral Fentanyl\2022.09.29 Oral SA Round 4 BE Battery\HP Master Sheet.xlsx'),opts;
% hpT.ID = categorical(hpT.ID);
% hpT.Sex = categorical(hpT.Sex);
% hpT.Session = categorical(hpT.Session);
% 
% clear g
% g(1,1)=gramm('x',hpT.Session,'y',hpT.Latency,'color',hpT.Sex);
% g(1,1).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
% g(1,1).stat_violin('normalization','width','half',0,'fill','transparent','dodge',.75)
% g(1,1).geom_jitter('width',.1,'dodge',.75,'alpha',.5);
% g(1,1).stat_summary('geom',{'black_errorbar'},'type','sem','dodge',.75);
% g(1,1).axe_property('LineWidth',1.5,'FontSize',16,'Font','Helvetica','YLim',[20 80],'XLim',[.5 2.5],'TickDir','out');
% g(1,1).set_order_options('x',{'Pre' 'Post'});
% g(1,1).set_names('x',[],'y','Paw Lick Latency (s)','color','Sex');
% f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
% g(1,1).no_legend();
% g.draw;
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','Hot Plate.pdf'),'ContentType','vector');
% 
% HP_LME = fitlme(hpT,'Latency ~ Sex*Session + (1|ID)');
% HP_F = anova(HP_LME,'DFMethod','satterthwaite');
% statsna=fullfile('Statistics','Oral SA Hoteplate Stats.mat');
% save(statsna,'HP_F');
% 
% % Behavioral Economics (Dose Response)
% % Hot Plate
% % clear all;
% opts = detectImportOptions('2022.02.28 LHb Oral Fentanyl\2022.09.29 Oral SA Round 4 BE Battery\Oral Fentanyl Behavioral Economics Data.xlsx');
% opts = setvartype(opts,{'ID','Sex'},'categorical');
% beT=readtable('2022.02.28 LHb Oral Fentanyl\2022.09.29 Oral SA Round 4 BE Battery\Oral Fentanyl Behavioral Economics Data.xlsx'),opts;
% beT.Sex = categorical(beT.Sex);
% beT.ID = categorical(beT.ID);
% responses=ceil((beT.mLTaken./.05));
% unitPrice=(1000./beT.Dose__g_ml_);
% beT=[beT table(responses,unitPrice)];
% 
% % Curve Fit Each Animals Intake over Dose
% IDs = unique(beT.ID);
% for i=1:height(IDs)
%     tmp=beT(beT.ID==IDs(i),2);
%     Sex(i,1)=tmp{1,1};
%     in=beT{beT.ID==IDs(i),10};
%     in=in(1:5);
%     price=beT{beT.ID==IDs(i),12};
%     price=price(1:5);
%     price=price-price(1)+1;
% 
%     myfittype = fittype('log(b)*(exp(1)^(-1*a*x))',...
%     'dependent',{'y'},'independent',{'x'},...
%     'coefficients',{'a','b'})
% 
%     f=fit(price,log(in),myfittype,'StartPoint', [.003, 200],'lower',[.0003 100],'upper',[.03 1500]);
%     
%     figure;
%     plot(log(1:50),f(1:50));
%     hold on;
%     scatter(log(price),log(in),10);
%     [res_x, idx_x]=knee_pt(log(1:50),f(1:50));
%     plot([log(idx_x) log(idx_x)],[min(f(1:50)) max(f(1:50))],'--k')
%     xlim([-1 5]);
%     title(IDs(i))
%     
%     Alpha(i,1)=f.a;
%     Elastic(i,1)=idx_x
% end
% 
% aT=table(IDs,Sex,Alpha,Elastic);
% clear g
% g(1,1)=gramm('x',aT.Sex,'y',aT.Alpha,'color',aT.Sex);
% g(1,1).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
% g(1,1).stat_violin('normalization','width','half',0,'fill','transparent','dodge',.75)
% g(1,1).geom_jitter('width',.1,'dodge',.75,'alpha',.5);
% g(1,1).stat_summary('geom',{'black_errorbar'},'type','sem','dodge',.75);
% g(1,1).axe_property('LineWidth',1.5,'FontSize',16,'Font','Helvetica','TickDir','out');
% g(1,1).set_order_options('x',{'Female' 'Male'});
% g(1,1).set_names('x','Sex','y','Demand Elasticity','color','Sex');
% f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
% g(1,1).no_legend();
% g.draw;
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','Alpha.pdf'),'ContentType','vector');
% 
% clear g
% g(1,1)=gramm('x',aT.Sex,'y',aT.Elastic,'color',aT.Sex);
% g(1,1).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
% g(1,1).stat_violin('normalization','width','half',0,'fill','transparent','dodge',.75)
% g(1,1).geom_jitter('width',.1,'dodge',.75,'alpha',.5);
% g(1,1).stat_summary('geom',{'black_errorbar'},'type','sem','dodge',.75);
% g(1,1).axe_property('LineWidth',1.5,'FontSize',16,'Font','Helvetica','TickDir','out');
% g(1,1).set_order_options('x',{'Female' 'Male'});
% g(1,1).set_names('x','Sex','y','Demand Elasticity','color','Sex');
% f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
% g(1,1).no_legend();
% g.draw;
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','Elastic.pdf'),'ContentType','vector');
% 
% clear g
% g(1,1)=gramm('x',beT.Dose__g_ml_,'y',beT.Intake__g_kg_,'color',beT.Sex);
% g(1,1).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
% g(1,1).stat_summary('geom',{'area','point'},'type','sem','setylim',1);
% g.set_text_options('font','Helvetica','base_size',16,'legend_scaling',.75,'legend_title_scaling',.75);
% g.axe_property('LineWidth',1.5,'XLim',[0 250],'YLim',[0 800],'tickdir','out');
% g(1,1).set_names('x','Unit Dose (μg)','y','Fentanyl Intake (μg/kg)','color','Sex');
% f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
% g(1,1).no_legend();
% g.draw;
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','Intake.pdf'),'ContentType','vector');
% 
% clear g
% g(1,1)=gramm('x',beT.Dose__g_ml_,'y',responses,'color',beT.Sex);
% g(1,1).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
% g(1,1).stat_summary('geom',{'area','point'},'type','sem','setylim',1);
% g.set_text_options('font','Helvetica','base_size',16,'legend_scaling',.75,'legend_title_scaling',.75);
% g.axe_property('LineWidth',1.5,'XLim',[-5 250],'tickdir','out');
% g(1,1).set_names('x','Dose (μg/mL)','y','Responses','color','Sex');
% f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
% g(1,1).no_legend();
% g.draw;
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','Responses.pdf'),'ContentType','vector');
% 
% clear g
% g(1,1)=gramm('x',beT.unitPrice,'y',beT.Intake__g_kg_,'color',beT.Sex,'subset',beT.Dose__g_ml_~=0);
% g(1,1).set_color_options('hue_range',[50 542.5],'chroma',80,'lightness',60,'n_color',2);
% g(1,1).stat_summary('geom',{'area','point'},'type','sem','setylim',1);
% %g(1,1).stat_smooth('geom',{'area_only'});
% g.set_text_options('font','Helvetica','base_size',16,'legend_scaling',.75,'legend_title_scaling',.75);
% g.axe_property('LineWidth',1.5,'tickdir','out');
% g(1,1).set_names('x','Unit Price (responses/mg)','y','Fentanyl Intake (μg/kg)','color','Sex');
% f=figure('Position',[100 100 350 300],'Color',[1 1 1]);
% g(1,1).no_legend();
% g.draw;
% set(g.facet_axes_handles,'YScale','log','XScale','log')
% set(g.facet_axes_handles,'XTick',[1 10 20 40])
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','Unit Price Intake.pdf'),'ContentType','vector');
% 
% BE_LME = fitlme(beT,'responses ~ Sex*Dose__g_ml_ + (1|ID)');
% BE_F = anova(BE_LME,'DFMethod','satterthwaite');
% statsna=fullfile('Statistics','Oral SA BE Stats.mat');
% save(statsna,'BE_F');
% 
% 
% % Group BE Demand Curve
% myfittype = fittype('log(b)*(exp(1)^(-1*a*x))',...
%     'dependent',{'y'},'independent',{'x'},...
%     'coefficients',{'a','b'})
% 
% x=g.results.stat_summary.x
% [y z]=g.results.stat_summary.y
% x=x-x(1)+exp(1);
% 
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
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','True BE Figure.pdf'),'ContentType','vector');
% save('Statistics\BE_Stats.m','fAlpha','mAlpha','fQ0','mQ0');
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
% exportgraphics(f,fullfile('Combined Oral Fentanyl Output\BE HP Figs','Unit Price Response.pdf'),'ContentType','vector');
% 
% close all;

% %% A-F individual differences
% % *** SS Move
% 
% % A) fentanyl intake, 
% % B) fentanyl seeking (defined as total head entries), 
% % C) cue-association (defined as head entry latency), 
% % D) escalation (defined as slope of total intake), 
% % E) persistence in extinction (defined as total presses during extinction)
% % F) relapse (defined as total pressed during cued reinstatement)
% 
% % SS to-add metrics
% % relapse / intake mean?
% % relapse / mean-last-two-intake-mean?
% % relapse / mean-first-two-intake-mean?
% % mean active lever / mean inactive lever?
% 