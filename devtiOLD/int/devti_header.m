% devti_header.m
%
% this script generates the header file 'header' in the  workspace
% the 'header' variable is used when calling each experiment in DevTI
%
% this experiment consists of various tests of reasoning as well as
% measures of intelligence and behavior (day 1). participants then return on a second
% day to do high-res DTI and high-res rest scans.
%
% the DevTI header will have information about every task, except creativity.
% note that because this study is aimed toward looking at individual
% differences, all participants see EXACTLY the same stimulus order for all tasks.
%
% The plan is to run the following:
%   
    % devti_header.m
    % (1) devti_ai.m
        % - associative inference task
    % (2) devti_igt.m
        % - iowa gambling task
        % - VMPFC function
    % (3) STATISTICAL LEARNING TASK -- different script
        % note: must reload header after finishing
    % (4) devti_rpm.m 
        % - Crone et al. 2009 stimuli
    % (5) devti_ri.m
        % - relational integration task, after Wendelken & Bunge (2009)
        % - non-mnemonic test of integration across premises
    % (6) creativity (adults only)
        % - run separately on REDCap
        % - RAT task
%
% must be called from DevTI experiment's folder to work.
% 
% if experiments are not run together, can be run separately. 
% may need to reload data/SUBNUM_header.mat
%
% MLS version 1, May 2013
% 
% dependencies:
%   PsychToolbox

clear;
par = struct;

path = '/Users/Experimenter/Library/Application Support/MathWorks/MATLAB Add-Ons/Toolboxes/Psychtoolbox-3/PsychBasic'
rmpath(path)
addpath(path,'-begin')
%% set-up
header = struct('exp', 'DevTI','version','MLS v.1 | August 2013','parameters',struct);
header.path.exp = pwd;

disp('This script generates a header file for all day 1 DevTI tasks.');
disp('--------------------------------------------------------------');

header.timeRun = fix(clock);

% get information about the participant.
check = 0;
bigcheck = 0;

while bigcheck == 0
    
    while check == 0
        
        % removed DOB, but here's the code to do it (if ever needed)
        %header.dob = datevec(input('Participant date of birth (MM/DD/YYYY): ','s'));
        %today = fix(datenum(now));
        %dob = datenum(header.dob);
        %age = datevec(today-dob);
        %header.age = [age(1) age(2) age(3)]; % age rounded to years
        
        header.subNr = input('Participant number:  ');
        header.subAge = input('Participant age (years): ');
        header.subGender = input('Is this participant male (1) or female (2)?  ');
        header.subInit = input('Participant initials:  ', 's');
        
        disp(' ');
        disp('******* Review the information below *******')
        disp(sprintf('Number: %03d',header.subNr))
        disp(sprintf('Age: %d',header.subAge))
        if header.subGender == 1
            disp('Gender: male')
        else
            disp('Gender: female')
        end
        disp(sprintf('Initials: %s',header.subInit))
        disp(' ')
        
        yn = input('Is this correct? ','s');
        
        if(isequal(upper(yn(1)), 'Y'))
            disp('--------------------------------------------------------------');
            disp('Great! Generating header...')
            check = 1;
        else
            disp(' ');
            disp('Please re-enter participant information: ');
        end
        
    end
    
    clear yn;
    
    % adults do some tasks the kids won't do
    % decide whether they are a kid or an adult, then how many tasks they get
    if header.subAge >= 18
        header.isAdult = 1;
        header.expOrder = {'ai','igt','stat','rpm','ri','rat'};
    else
        header.isAdult = 0;
        header.expOrder = {'ai','igt','stat','rpm','ri',};
    end
    
    header.nTasks = length(header.expOrder);
    header.path.data = [header.path.exp sprintf('/data_%03d/',header.subNr)];
    header.path.pdata = [header.path.data 'practice/'];
    
    % check to see if it's an existing directory
    if isdir(header.path.data)
        disp(' ');
        yn = input('WARNING: This subject number has been used before. Are you sure you want to continue? ','s');
        if(isequal(upper(yn(1)), 'Y'))
            disp('--------------------------------------------------------------');
            disp('Continuing with existing participant information.')
            bigcheck = 1;
        else
            disp(' ');
            disp('Terminating session.');
        end
    end
    
    % make a new directory
    if ~isdir(header.path.data)
        mkdir(header.path.data);
        bigcheck = 1;
    end
    
    
end

if ~isdir(header.path.pdata)
    mkdir(header.path.pdata)
end

headerFname = sprintf('%sheader_%03d_%s.mat',header.path.data,header.subNr,header.subInit);

%%%%%%%%%%%%%%%%%%%%%%%%%
% ASSOCIATIVE INFERENCE %
%%%%%%%%%%%%%%%%%%%%%%%%%

par.ai.nTriadType = 1; % number of triad types
par.ai.nTriadsPerType = 15;
par.ai.nABCTriads = (par.ai.nTriadsPerType * par.ai.nTriadType);
par.ai.nPairsPerType = (par.ai.nTriadsPerType * 2);
par.ai.nPairsTotal = (par.ai.nPairsPerType * par.ai.nTriadType);

par.ai.study.stimTime = 3.5;
par.ai.study.fixTime = 0.5;
par.ai.study.nRepsPerPairPerStudy = 1;
par.ai.study.nStudy = 4;
par.ai.study.nRepsPerPair = par.ai.study.nStudy * par.ai.study.nRepsPerPairPerStudy;
par.ai.study.studyTimePerTrial = par.ai.study.stimTime + par.ai.study.fixTime;
par.ai.study.nTrialsPerStudy = par.ai.nPairsTotal * (par.ai.study.nRepsPerPair/par.ai.study.nStudy);
par.ai.study.totalTime = (par.ai.study.studyTimePerTrial * par.ai.study.nTrialsPerStudy * par.ai.study.nStudy);

par.ai.test.nTests = 4; % number of interleaved DIRECT tests (there will be an additional AC test @ end)
par.ai.test.nTrialsPerTest = par.ai.nABCTriads * 3;

par.ai.rightKey = 'k';
par.ai.midKey = 'g';
par.ai.leftKey = 's';

% practice parameters (nonoverlapping pairs)
% doing 2 practice reps for time
par.ai.practice.nPairsPerType = 4;
par.ai.practice.nPairs = par.ai.practice.nPairsPerType*par.ai.nTriadType;
par.ai.practice.nStudyReps = 2;
par.ai.practice.nTests = 2;

% size and color parameters
par.ai.fixColor = 255;
par.ai.backColor = [175 175 175];
par.ai.txtColor = 255;
par.ai.txtSize = 50;
par.ai.numSize = 100;

% selected order 10
% also includes practice
orderFnameAI = [header.path.exp '/order_ai.mat'];
header.ai = load(orderFnameAI);

header.ai.path.stim = [header.path.exp '/stim1_ai/'];
header.ai.path.pstim = [header.ai.path.stim 'practice/'];

% clear stuffs

header.parameters=par;

% save out header file
save(headerFname,'header')

clear par orderFnameAI headerFname check bigcheck;

