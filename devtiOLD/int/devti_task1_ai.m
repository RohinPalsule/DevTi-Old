function data = devti_task1_ai(header)

   
oldEnableFlag = Screen('Preference','SuppressAllWarnings');
Screen('Preference', 'VisualDebugLevel', 1);
Screen('Preference', 'SkipSyncTests', 2); % will not show warning screen

commandwindow;

%% Setup
par = header.parameters;
data = struct('game', 'associative inference, overlapping novel object pairs', 'subNr', header.subNr,...
   'subAge', header.subAge, 'subGender',...
   header.subGender,...
   'isAdult',header.isAdult);
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
outfname = sprintf('%stask1_ai_%03d_%s',header.path.data, header.subNr, header.subInit);
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

repText = 'PAIR GAME';
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

% start time of entire thing.
absStart = GetSecs;

% present run trials
for r = 1:par.ai.study.nStudy
    
    runNr = r;

    data.study.actualOnsets{runNr} = NaN(par.ai.nABCTriads*2,1); 
    
    %% begin study
    repText = sprintf('LEARNING %d',runNr);
    Screen('TextSize',par.window,par.ai.txtSize);
    [normBoundsRect_repText,offsetBoundsRects_repText] = Screen('TextBounds',par.window,repText);
    xcreptext = par.xc - normBoundsRect_repText(3)/2;
  
    Screen(par.window, 'DrawText', repText, xcreptext, par.yc, par.ai.txtColor);
    Screen(par.window, 'Flip');
    
    clear keyCode;
    clear keyIsDown;
    
    WaitSecs(0.5);

    pa.TRIGGERED = 0;
    while ~pa.TRIGGERED
        [keyIsDown, t, keyCode] = KbCheck(-1);
        if strcmp(KbName(keyCode), '5%')
            pa.TRIGGERED = 1;
        end
        
    end
    
    startTime = GetSecs;
    data.study.beginTime{runNr} = fix(clock);
    
    for t = 1:par.ai.study.nTrialsPerStudy
        
        % get trial onset
        ontime = data.studyStim{runNr}(t,1);
                
        % load current trial images
        triadNr = data.studyStim{runNr}(t,2); % number within the run; row number in data.triads
        
        % get the rid stims
        % note there are no stimulus numbers as these are fixed across
        % participants. thus, ID's by triad and position will work.
        if data.studyStim{runNr}(t,6) == 1 % if AB
            imgL = abcStim{triadNr,1}; % present A
            imgR = abcStim{triadNr,2}; % ... and B
        else
            imgL = abcStim{triadNr,3}; % present C
            imgR = abcStim{triadNr,2}; % ... and B
        end
        
        % make texture for current trial presentation
        pic = [imgL buffer imgR]; % B always presented on RIGHT
        stim = Screen(par.window,'MakeTexture',pic);
        
        % draw current trial image to buffer
        Screen(par.window,'DrawTexture',stim);
        
        % calculate presentation onset
        stimtime = startTime + ontime;
        
        % flip presentation of image to screen at correct onset
        on = Screen(par.window,'Flip',stimtime);
        data.study.actualOnsets{runNr}(t) = on - startTime;
        
        % draw fixation to buffer
        fixText = '+';
        Screen('TextSize',par.window,par.ai.txtSize);
        [normBoundsRect_fixText,offsetBoundsRects_fixText] = Screen('TextBounds',par.window,fixText);
        xcfixtext = par.xc - normBoundsRect_fixText(3)/2;
        Screen(par.window,'DrawText', fixText, xcfixtext, par.yc, par.ai.fixColor);
        
        % calculate fixation onset
        fixtime = stimtime + par.ai.study.stimTime;
        
        % flip fixation to screen
        Screen(par.window,'Flip',fixtime);

        % leave fixation on
        tic
        while toc<par.ai.study.fixTime
        end
        
        % trash stimulus
        Screen('Close',stim);
       
    end
    
    clear t
    
    % put important info into data structure
    data.study.duration{runNr} = GetSecs - startTime;
    data.study.endTime{runNr} = fix(clock);
    
    clear startTime;

    %% begin test
    % tests direct associations only
    
    data.test.actualOnsets{runNr} = nan(par.ai.nABCTriads*2,1);
    data.test.resp{runNr} = nan(par.ai.nABCTriads*2,1);
    data.test.stimRT{runNr} = nan(par.ai.nABCTriads*2,1);
    data.test.isCorrect{runNr} = nan(par.ai.nABCTriads*2,1);
    
    formatString = '%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%0.3f\n';
    fid=fopen([outfname sprintf('_test%d.txt',runNr)], 'w'); % open the file
    fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n',...
        'triadNr','stimTypeA','stimTypeB', 'stimTypeC',...
        'foilTriad1','foilTriad2','trialType','locAns','locFoil1','locFoil2','resp','isCorrect','RT'); %Create header
    
    % display some text
    repText = sprintf('REMEMBERING %d',runNr);
    Screen('TextSize',par.window,par.ai.txtSize);
    [normBoundsRect_repText,offsetBoundsRects_repText] = Screen('TextBounds',par.window,repText);
    xcreptext = par.xc - normBoundsRect_repText(3)/2;    
    Screen(par.window, 'DrawText', repText, xcreptext, par.yc, par.ai.txtColor);
    
    Screen(par.window, 'Flip');
    
    clear keyCode;
    clear keyIsDown;
    WaitSecs(1);
    
    pa.TRIGGERED = 0;
    while ~pa.TRIGGERED
        [keyIsDown, t, keyCode] = KbCheck(-1);
        if strcmp(KbName(keyCode), '5%')
            pa.TRIGGERED = 1;
        end
        
    end
    
    startTime = GetSecs;
    data.test.beginTime{runNr} = fix(clock);
    
    for t = 1:par.ai.nABCTriads*2
        
        % load current trial images
        triadNr = data.testStim{runNr}(t,1); % number within the run; row number in data.triads
                
        % B cues A
        % C cues B
        if data.testStim{runNr}(t,7) == 1 % if AB
            imgCue = abcStim{triadNr,2}; % cue = B
            img{data.testStim{runNr}(t,8)} = abcStim{triadNr,1};
            img{data.testStim{runNr}(t,9)} = abcStim{data.testStim{runNr}(t,5),1};
            img{data.testStim{runNr}(t,10)} = abcStim{data.testStim{runNr}(t,6),1};
        else if data.testStim{runNr}(t,7) == 2 % if BC
            imgCue = abcStim{triadNr,3}; % cue = C
            img{data.testStim{runNr}(t,8)} = abcStim{triadNr,2};
            img{data.testStim{runNr}(t,9)} = abcStim{data.testStim{runNr}(t,5),2};
            img{data.testStim{runNr}(t,10)} = abcStim{data.testStim{runNr}(t,6),2}; % ... and B
            end
        end
        
        % make a pic
        pic = [repmat(testBuffer,1,4) imgCue repmat(testBuffer,1,4); repmat(testBufferShort,1,11);  img{1} testBuffer img{2} testBuffer img{3}];
        
        % make texture for current trial presentation
        stim = Screen(par.window,'MakeTexture',pic);
        
        % draw current trial image to buffer
        Screen(par.window,'DrawTexture',stim);
        
        % flip presentation of image to screen 
        on = Screen(par.window,'Flip');
        data.test.actualOnsets{runNr}(t) = on - startTime;
        
%        FOR TESTING
        %             % collect response
%             keepgoing = 1;
%             while keepgoing
%                 [~,secs,keyCode] = KbCheck(-1);
%                 if keyCode(par.ai.leftKey) || keyCode(par.ai.midKey) || keyCode(par.ai.rightKey)
%                     keytxt = KbName(keyCode);
%                     if sum(keyCode)>1
%                         keytxt = keytxt{1};
%                     end
%                     switch keytxt
%                         case par.ai.leftKey
%                             resp = 1;
%                         case par.ai.midKey
%                             resp = 2;
%                         case par.ai.rightKey
%                             resp = 3;
%                     end
%                     
%                     % store the button press RT
%                     data.test.stimRT{runNr}(t) = round(1000*(secs-ontime));
%                     data.test.resp{runNr}(t) = resp;
%                     keepgoing = 0;
%                 end
%             end
%             while KbCheck(-1); end
% 
%         % get the response
         [resp rt] = getResp(par.ai.leftKey,par.ai.midKey,par.ai.rightKey);
% 
%         % store the button press RT
         data.test.stimRT{runNr}(t) = round(1000*rt);
         data.test.resp{runNr}(t) = resp;
                
%WaitSecs(2);

        Screen(par.window,'FillRect',par.ai.backColor);
        fixText = '+';
        Screen('TextSize',par.window,par.ai.txtSize);
        [normBoundsRect_fixText,offsetBoundsRects_fixText] = Screen('TextBounds',par.window,fixText);
        xcfixtext = par.xc - normBoundsRect_fixText(3)/2;
        Screen(par.window,'DrawText', fixText, xcfixtext, par.yc, par.ai.fixColor);
        Screen(par.window,'Flip');
        WaitSecs(par.ai.study.fixTime);
        
        % trash stimulus
        Screen('Close',stim);
        
        data.test.isCorrect{runNr}(t) = data.testStim{runNr}(t,8)==data.test.resp{runNr}(t);
        
        % save trial info to text file
         fprintf(fid,formatString,...
             data.testStim{runNr}(t,:),data.test.resp{runNr}(t),data.test.isCorrect{runNr}(t),data.test.stimRT{runNr}(t));
       
    end
    
    data.test.duration{runNr} = GetSecs - startTime;
    data.test.endTime{runNr} = fix(clock);
    
end
    
%% End experiment

ShowCursor;
Screen('CloseAll');
clear screen;

for r = 1:length(data.test.isCorrect)
    data.acc{r} = mean(data.test.isCorrect{r});
end

data.parameters = par;
data.duration = GetSecs - absStart;
save(outfname,'data');


disp('-----------------');
disp('Task 1 completed!');
disp('-----------------');
disp(' ');

Screen('Preference','SuppressAllWarnings',oldEnableFlag);


end

