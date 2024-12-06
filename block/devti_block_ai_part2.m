function data = devti_block_ai_part2(header)
   
oldEnableFlag = Screen('Preference','SuppressAllWarnings');
Screen('Preference', 'VisualDebugLevel', 1);
Screen('Preference', 'SkipSyncTests', 2); % will not show warning screen

commandwindow;

%% Setup
par = header.parameters;
data = struct('game', 'associative inference, overlapping novel object pairs', 'subNr', header.subNr,...
   'subAge', header.subAge, 'subGender',...
   header.subGender);
data.studyStim = header.ai.study;
data.testStim = header.ai.test;

% Use internal keyboard -- not to be scanned
intake=PsychHID('Devices');
for n=1:length(intake)
    if strcmp(intake(n).usageName,'Keyboard')
        intKeys=n;
    end
end
dev = intKeys;

%% Preload all stimuli
abcStim = cell(par.ai.nABCTriads, 3);
ltr = {'a','b','c'};
for t=1:par.ai.nABCTriads % for each triad 
    for abc = 1:3
        str = sprintf('%02d%s',t,ltr{abc});
        stimfname = sprintf('%sobject_%s.png',header.ai.path.stim,str);
        [tmp, empty, alpha] = imread(stimfname);
        if ~isempty(alpha)
            tmp(:,:,4) = alpha;
        else
            tmp(:,:,4) = par.ai.backColor(1)*ones(size(colorim,1),size(colorim,2));
        end
        abcStim{t,abc} = imresize(tmp,[300 300]);

    end
end

%Space between objects
buffer = ones(round(size(abcStim{1,1})./[1 2 1]))*par.ai.backColor(1);
testBuffer = ones(round(size(abcStim{1,1})./[1 3 1]))*par.ai.backColor(1);
testBufferShort = ones(round(size(abcStim{1,1})./[3 3 1]))*par.ai.backColor(1);

%% %% Create output text file
outfname = sprintf('%sai_%03d_%s_part2',header.path.data, header.subNr, header.subInit);
if exist([outfname '.mat'],'file') == 2
    error('The data file for this session already exists.  Please check your input parameters.');
end

%% open up the screen
[par.window, par.screenRect] = Screen(0, 'OpenWindow', par.ai.backColor); % change me
Screen('BlendFunction',par.window,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA); % transparent bg objects
par.xc = par.screenRect(3)/2;
par.yc = par.screenRect(4)/2;
par.xcll = par.xc - (size(buffer,2) + size(buffer,1))/2;
par.ycll = par.yc + 150;
par.xcrl = par.xc + (size(buffer,2) + size(buffer,1))/2;
par.ycrl = par.yc + 150;
par.xct = par.xc - par.ai.numSize/3; % center of screen for text
par.yct = par.yc - par.ai.numSize/3; % center of screen for text
Screen(par.window, 'TextSize', par.ai.txtSize);
Screen(par.window, 'TextFont', 'Arial');
HideCursor;

repText = 'FINAL REMEMBERING';
Screen('TextSize',par.window,par.ai.txtSize);
[normBoundsRect_repText,offsetBoundsRects_repText] = Screen('TextBounds',par.window,repText);
xcreptext = par.xc - normBoundsRect_repText(3)/2;

Screen(par.window, 'DrawText', repText, xcreptext, par.yc, par.ai.txtColor);
Screen(par.window, 'Flip');

clear keyCode;
clear keyIsDown;

pa.TRIGGERED = 0;
while ~pa.TRIGGERED
    [keyIsDown, t, keyCode] = KbCheck(-1);
    if strcmp(KbName(keyCode), '5%')
        pa.TRIGGERED = 1;
    end
    
end

%% do AC test
runNr = 9;
data.test.actualOnsets = nan(par.ai.nABCTriads,1);
data.test.resp = nan(par.ai.nABCTriads,1);
data.test.stimRT = nan(par.ai.nABCTriads,1);
data.test.isCorrect = nan(par.ai.nABCTriads,1);

formatString = '%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%0.3f\n';
fid=fopen([outfname '.txt'], 'w'); % open the file
fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n',...
    'triadNr','stimTypeA','stimTypeB', 'stimTypeC',...
    'foilTriad1','foilTriad2','trialType','locAns','locFoil1','locFoil2','resp','isCorrect','RT'); %Create header

startTime = GetSecs;
data.test.beginTime = fix(clock);

for t = 1:par.ai.nABCTriads
    
    % load current trial images
    triadNr = data.testStim{runNr}(t,1); % number within the run; row number in data.triads
    
    % B cues A
    % C cues B
    if data.testStim{runNr}(t,7) == 3 % if AC
        imgCue = abcStim{triadNr,3}; % cue = C
        img{data.testStim{runNr}(t,8)} = abcStim{triadNr,1};
        img{data.testStim{runNr}(t,9)} = abcStim{data.testStim{runNr}(t,5),1};
        img{data.testStim{runNr}(t,10)} = abcStim{data.testStim{runNr}(t,6),1};
    end
    
    % make a pic
    pic = [repmat(testBuffer,1,4) imgCue repmat(testBuffer,1,4); repmat(testBufferShort,1,11);  img{1} testBuffer img{2} testBuffer img{3}];
    
    % make texture for current trial presentation
    stim = Screen(par.window,'MakeTexture',pic);
    
    % draw current trial image to buffer
    Screen(par.window,'DrawTexture',stim);
    
    % flip presentation of image to screen
    on = Screen(par.window,'Flip');
    data.test.actualOnsets(t) = on - startTime;
    
    % get the response
    [resp rt] = getResp(par.ai.leftKey,par.ai.midKey,par.ai.rightKey);
    
    % store the button press RT
    data.test.stimRT(t) = round(1000*rt);
    data.test.resp(t) = resp;
    
    Screen('FillRect',par.window,par.ai.backColor);
    fixText = '+';
    Screen('TextSize',par.window,par.ai.txtSize);
    [normBoundsRect_fixText,offsetBoundsRects_fixText] = Screen('TextBounds',par.window,fixText);
    xcfixtext = par.xc - normBoundsRect_fixText(3)/2;
    Screen(par.window,'DrawText', fixText, xcfixtext, par.yc, par.ai.fixColor);
    Screen( 'Flip',par.window);
    WaitSecs(par.ai.study.fixTime);
    
    % trash stimulus
    Screen('Close',stim);
    
    data.test.isCorrect(t) = data.testStim{runNr}(t,8)==data.test.resp(t);
    
    % save trial info to text file
    fprintf(fid,formatString,...
        data.testStim{runNr}(t,:),data.test.resp(t),data.test.isCorrect(t),data.test.stimRT(t));
    
end

data.test.duration = GetSecs - startTime;
data.test.endTime = fix(clock);

    
%% End experiment

ShowCursor;
Screen('CloseAll');
clear screen;

data.acc = mean(data.test.isCorrect);

data.parameters = par;
save(outfname,'data');

disp('-----------------');
disp('Part 2 completed!');
disp('-----------------');
disp(' ');

