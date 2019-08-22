% function [matpress, frametime, time_down, time_in, time_ratio] = SAM_ambiguous_simple_v01(partID)
% This version runs the experiment with the ambiguous version of the
% stimulus with a static trial after 60 sec of motion.
% The transitions are direct and determined by participant's responses
% This version does not include eyetracker comands
% The key presses are verified by regular KbCheck function
%
% Outputs:
% matpress - variable with the key presses, together with time and frame
% frametime - timing of each frame presentation
% time_down - total duration of downard condition
% time_in - total duration of inward condition
% time_ratio - ratio between downward and 1inward duration
% escapekeypress - flag for program aborption or successful run
%

% Close (eventually) PTB screens
Screen('CloseAll');
% % Trick suggested by the PTB authors to avoid synchronization/calibration
% % problems2
% figure(1)
% plot(sin(0:0.1:3.14));
% % Close figure with sin plot (PTB authors trick for synchronization)
% close Figure 1

% Synchronization tests procedure - PTB
% Do you want to skipsync tests (1) or not (0) ?
skipsynctests = 1;
% Size of the text
textsize = 50;

% try
%     load('MM_listratio.mat')
% catch
%     disp('ERROR. Could not open list of conditions for current subject')
% end

% condition to run from list of conditions
condi = 2;

% Screen and viewing distance
screen_sizev = 27; % vertical screen size in cm
viewing_dist = 65; % in cm

% visual angles of stimulus
view_angv = 5; % in degress
viewrad_angv = (view_angv * pi)/180; % convert to radians
dots_angv = 1;
dotsrad_angv = (dots_angv * pi)/180; % convert to radians

% stimulus dimensions in cm
stim_sizecm = atan(viewrad_angv) * viewing_dist;
dots_sizecm = atan(dotsrad_angv) * viewing_dist;

% KbName will switch its internal naming
% scheme from the operating system specific scheme (which was used in
% the old Psychtoolboxes on MacOS-9 and on Windows) to the MacOS-X
% naming scheme, thereby allowing to use one common naming scheme for
% all operating systems
KbName('UnifyKeyNames');

% This variable will become 1 if 'Esc' is pressed
escapekeypress = 0;
% Code to identify "escape" key
escapekeycode = 27;
% Code to identify the key to report "vertical" movement
vertkeycode = 97; %54 % 49 % 97 (1 numbpad)
% Code to identify the key to report "horizontal" movement
horzkeycode = 98; % 55 % 50 % 98 (2 numbpad)
% Code to identify the key to receive scanner trigger
keytriggercode = 53;

%%%
teclas = {};


% --------------------------------------------------------------------
%                  Port and Trigger Settings
% --------------------------------------------------------------------

% Triggers IDs
trigReady=35;
trigBaseline=1;
trigEnd=14;
trigDouble=222;
trigStopDouble=220;
trigInward=21;
trigStopInward=20;
trigDownward=11;
trigStopDownward=10;

% 1 to send state (1 or 2 triggers)
sendStateTrigger = 0;

% 1 to send triggers through port conn
portTrigg = 0;

% choose between 1 - lptwrite (32bits); or 2 - IOport (64bits);
syncbox = 2;

% init var;
PortAddress=[];

if portTrigg
    if syncbox == 1
        addpath('./ParallelPortLibraries/');
        PortAddress = hex2dec('E800'); %-configure paralell port adress
    elseif syncbox == 2
        addpath('./ParallelPortLibraries/');
        ioObj = io64;
        status = io64(ioObj);
        PortAddress = hex2dec('378'); %-configure paralell port adress
        data_out=1;
        io64(ioObj, PortAddress, data_out);
        data_out=0;
        pause(0.01);
        io64(ioObj, PortAddress, data_out);
    end
end

%-------------------%
% Stimuli variables %
%-------------------%
% How should the protocol initiate, after Absolute static
protocol = 'ambiguous';

% Duration of the experiment (sec)
protoTime = 12;

% Duration of the initial baseline (sec)
baselineTime = 1;

% Duration of the initial block before baseline (sec)
readyDuration = 1;


% Determine screen resolution
screens = Screen('Screens');
screenNumber = max(screens);
rect = Screen('Rect', screenNumber);

Pausa = 0; % time to pause inbetween each frame (in case one wants to show
% frames with a delay  bigger than 16.67ms)

% thickness of fixation cross
crossthick = 4;

%%
% ----------------------------------------------------------- %
%              Determine stimulus (dots) properties           %
% ----------------------------------------------------------- %

% number of dots to display
dots.numb = 2;

% size of dots (radius in px) Default if it is not set latter
dots.size = 40;
% contrast of dots relative to white (1)
dots.contrast = 1;

% Distance between dots in y in deg
distance = 6;

% ratio length/height
stim_ratio = 0.9;

% check if for this subject there are conditions pre-specified to be tested
if exist('listratio')
    if condi <= length(listratio)
        stim_ratio = listratio(condi);
    else
    end
else
end

% ----------------------------------------------------------- %
%              Determine protocol properties           %
% ----------------------------------------------------------- %

% rate of motion direction change
freqmot = 2;   % in Hz (change/sec)

% 1 for static frame between different motion; 0 for no static frame
framestop = 1;
% number of frame to appear static
nstopframe = 4;

try
    % Maximum priority for code to execute
    Priority(2);
    
    %------------------------------------------------------------%
    %                                                            %
    % Control monitor and perform synchronization tests (if set) %
    %                                                            %
    %------------------------------------------------------------%
    
    % Perform PTB synchrony tests
    if skipsynctests==1
        Screen('Preference','Verbosity',0);
        Screen('Preference','SkipSyncTests',1);
        Screen('Preference','VisualDebugLevel',0);
    end
    
    % Start Display
    screens = Screen('Screens');
    screenNumber = max(screens);
    [windowID rect] = Screen('OpenWindow', screenNumber, 0, []);
    Screen('BlendFunction', windowID, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    % determine screen framerate
    frate = Screen('FrameRate', windowID);
    
    % Monitor resolution
    res_x = rect(3);
    res_y = rect(4);
    xcenter = res_x/2;
    ycenter = res_y/2;
    
    % Set pixel density (px/cm)
    px_dens = res_y/screen_sizev;
    
    % Set stimulus size in pixels
    stim_sizepx = stim_sizecm * px_dens;
    
    stimsy = sqrt(((stim_sizepx)^2)/stim_ratio);
    stimsx = stim_ratio * stimsy;
    
    stim_sizev = stimsy;
    stim_sizeh = stimsx;
    %     stim_sizeh = stim_sizepx * stim_ratio;
    %     stim_sizev = stim_sizepx * 1;
    
    % Set dots size (radius) in pixels
    dots_sizepx = dots_sizecm * px_dens;
    dots.size = dots_sizepx;
    
    %%
    %     HideCursor
    
    % ----------------------------------------------------------------------
    %                        Set dots positions
    % ----------------------------------------------------------------------
    
    % valid dots position
    dots.posx = [xcenter-stim_sizeh/2 xcenter+stim_sizeh/2];
    dots.posy = [ycenter-stim_sizev/2 ycenter+stim_sizev/2];
    
    % set position of each dot (diametrally opposed)
    dotstate = [1 2; 2 1];
    currstate = 1;
    
    dots.center(1,1) = dots.posx(dotstate(currstate,1));
    dots.center(2,1) = dots.posy(dotstate(currstate,2));
    dots.center(1,2) = dots.posx(dotstate(currstate,2));
    dots.center(2,2) = dots.posy(dotstate(currstate,1));
    
    % set color/contrast of dots
    dots.color = [(255*dots.contrast) (255*dots.contrast) (255*dots.contrast)];
    
    % -----------------------------------------------------------------------
    %                      Set fixation cross
    % -----------------------------------------------------------------------
    
    % set fixation cross points
    FixCross = [xcenter-(sqrt(crossthick)),ycenter-(2*sqrt(crossthick)),xcenter+(sqrt(crossthick)),ycenter+(2*sqrt(crossthick));...
        xcenter-(2*sqrt(crossthick)),ycenter-(sqrt(crossthick)),xcenter+(2*sqrt(crossthick)),ycenter+(sqrt(crossthick))]; % Draw Central Cross
    
    %---------------------------------------------------------------------
    % Create matrix to save key presses and frame-times
    %---------------------------------------------------------------------
    
    % set matrix to get all timepoints of button presses
    matpress = {};
    % set matrix to get all dots positions
    matdots = {};
    
    frametime = [];
    
    doublepress = 0; % refers to "double" button
    button1 = 0; % refers to "inward" button
    button2 = 0; % refers to "downward" button
    button3 = 0; % refers to all other buttons
    time_down = 0;
    time_in = 0;
    time_ratio = 0;
    
    
    %%
    % -------------------------------------------------------------- %
    %                      Set Stimulus times                        %
    % -------------------------------------------------------------- %
    % get the total number of frames the stimulus will have
    totalFr = protoTime * frate;
    % get number of frames to elapse between changes
    numFr_change = ceil(1/freqmot * frate);
    % get all frames where change is to occur
    changeFr = numFr_change:numFr_change:totalFr;
    
    % Set initial frame counter
    currentFr = 1;
    
    % get number of frames to be stopped
    for istop = 1:nstopframe
        if framestop
            if istop == 1
                stopFr = changeFr +istop-1;
            else
                stopFr = [stopFr changeFr+istop-1];
            end
        else
            stopFr = changeFr * 0;
        end
    end
    
    %-------------------------------------------------%
    % Position of textures, fixation cross and frames %
    %-------------------------------------------------%
    
    % Start recording for frame times
    currentFr = 1;
    numbpress = 0;
    
    % Determine letter size and show 'Ready' screen
    Screen('TextSize', windowID , textsize);
    Screen('DrawText', windowID, 'Ready...', res_x/2.5, res_y/2.2, [200 200 200]);
    
    % Update screen
    frametime(currentFr) = Screen('Flip',windowID);
    
    % Wait for the subject to be ready
    KbWait;
    
    % Send trigger.
    success=sendTrigger(portTrigg, PortAddress, trigReady); % trigger 35 - start?
    
    WaitSecs(readyDuration);
    
    
    
    % Screen('FillRect', windowID, [255 255 255], [xcenter-largura, (ycenter-altura/2), xcenter+largura, (ycenter+altura/2)]);
    Screen('FillRect', windowID, [255 0 0], FixCross');
    frametime(currentFr) = Screen('Flip',windowID);
    
    
    [FlipInterval, FlipSamples, FlipStd ] = Screen('GetFlipInterval', windowID, [], [], []);
    
    % ---------------------------------------------------------------------
    %                           Start experiment
    % ---------------------------------------------------------------------
    
    % Set initial time at the start of the stimulation
    startTime = GetSecs;
    % Set initial time of a condition
    initTime = startTime;
    % Get current time
    currentTime = initTime - GetSecs;
    % Set time for experiment to be complete
    endTime = currentTime + protoTime + baselineTime;
    
    % no changes have occured yet
    nchange = 0;
    
    % signal the start of the experiment
    nchange = nchange + 1;
    matdots{nchange, 1} = 36;
    matdots{nchange,2} = currentFr;
    matdots{nchange,3} = 1;
    
    matpress{numbpress+1, 2} = 0;
    matpress{numbpress+1, 1} = 'start';
    matpress{numbpress+1, 3} = currentFr;
    matpress{numbpress+1, 4} = protocol;
    matpress{numbpress+1, 5} = dots.size;
    matpress{numbpress+1, 6} = stim_ratio;
    numbpress = numbpress + 1;
    
    % ---------------------------------------------------------------------
    %                           Display baseline fixation cross (fNIRS)
    % ---------------------------------------------------------------------
    
    % Send trigger.
    success=sendTrigger(portTrigg, PortAddress, trigBaseline); % trigger 35 - start?
    
    WaitSecs(baselineTime);
    
    % Run while the current time is less than the experiment total time
    while currentTime < endTime
        
        % --------------------------------------------------------------- %
        %                       update dots position
        % --------------------------------------------------------------- %
        
        % if it is time to change position
        if ismember(currentFr, changeFr)
            
            % change between the two states
            if currstate == 1
                currstate = 2;
            elseif currstate == 2
                currstate = 1;
            end
            
            dots.center(1,1) = dots.posx(dotstate(currstate,1));
            %             dots.center(2,1) = dots.posy(dotstate(currstate,2));
            dots.center(1,2) = dots.posx(dotstate(currstate,2));
            %             dots.center(2,2) = dots.posy(dotstate(currstate,1));
            
            if sendStateTrigger
                % Send trigger.
                success=sendTrigger(portTrigg, PortAddress, currstate); % send trigger with the new position
            end
            
            nchange = nchange + 1;
            matdots{nchange, 1} = currstate;
            matdots{nchange,2} = currentFr;
            matdots{nchange,3} = 1;
            
        end
        
        %--------------------------------------------------------------%
        %                        Show dots                             %
        %--------------------------------------------------------------%
        
        if ~ismember(currentFr, stopFr)
            Screen('DrawDots', windowID, dots.center, dots.size, dots.color, [], 1);
        else
            nchange = nchange + 1;
            matdots{nchange, 1} = currstate;
            matdots{nchange,2} = currentFr;
            matdots{nchange,3} = 0;
        end
        
        % Show fixation cross
        Screen('FillRect', windowID, [255 0 0], FixCross');
        
        % Get current time
        currentTime = GetSecs - startTime;
        
        % get current frame
        currentFr = currentFr + 1;
        
        % get frame time
        frametime(currentFr) = Screen('Flip',windowID);
        
        
        %%
        %----------------------------------------------------------------%
        %      Verify key presses, which timestamp and frame             %
        %                          (exit if 'esc')                       %
        %----------------------------------------------------------------%
        
        %-------------------%
        % keyboard pressing %
        %-------------------%
        [keyIsDown, secs, keyCode] = KbCheck;
        
        teclas{currentFr,1} = keyCode;
        % A key/button was pressed
        if keyIsDown == 1
            clc
            % Check the name (string) of the key that was pressed
            keystring = KbName(keyCode);
            
            if iscell(keystring)
                % To Escape
                if keyCode(escapekeycode)
                    
                    % Close PTB screen and connections
                    Screen('CloseAll');
                    ShowCursor;
                    Priority(0);
                    
                    % ------------------------------------------------ %
                    
                    % Send trigger.
                    success=sendTrigger(portTrigg, PortAddress, trigEnd);
                    
                    % ------------------------------------------------ %
                    
                    % Save variables anyway
                    experiment.matpress = matpress;
                    experiment.frametime = frametime;
                    experiment.time_down = time_down;
                    experiment.time_in = time_in;
                    experiment.time_ratio = time_ratio;
                    experiment.matdots = matdots;
                    
                    % Time and date of experiment (run)
                    fullDateOfExperiment = datestr(now,'HHMM_ddmmmmyyyy');
                    experiment.full_date =  fullDateOfExperiment;
                    
                    % Save experiment
                    try
                        [filename, pathname] = uiputfile(['matpress_' datestr(now, 'ddmm') '_' datestr(now, 'HHMM') '.mat'], pwd);
                        save([pathname filename], 'matpress', 'frametime', 'experiment');
                        
                        % Launch window with warning of early end of program
                        warndlg('The task was terminated with ''Esc'' before the end!','Warning','modal')
                    catch me
                        partID =  'SA';
                        expname = [partID, '_A_'];
                        
                        % Add information of program 'ERROR' in the filename
                        experimentName = [expname, 'ERRORoutput_', experiment.full_date];
                        save(experimentName,'experiment');
                    end
                    
                    return % abort program
                    
                end
                
                % The participant immediately pressed two buttons
                % simultaneously
                if button1 == 0 && button2 == 0
                    %
                    matpress{numbpress+1, 2} = (secs - startTime);
                    matpress{numbpress+1, 1} = 'double';
                    matpress{numbpress+1, 3} = currentFr;
                    matpress{numbpress+1, 4} = protocol;
                    matpress{numbpress+1, 5} = dots.size;
                    matpress{numbpress+1, 6} = stim_ratio;
                    numbpress = numbpress+1;
                    doublepress = 1;
                    button1 = 1;
                    button2 = 1;
                    
                    % ------------------------------------------------ %
                    % Send trigger for double
                    
                    % Send trigger.
                    success=sendTrigger(portTrigg, PortAddress, trigDouble);
                    
                    % ------------------------------------------------ %
                    
                elseif keyCode(horzkeycode) && button1 == 1 && button2 == 0
                    % There are two buttons pressed and one of them is "inward"
                    % button press - this is a "double" press during
                    % "downward", which we assume is a new "inward" report but
                    % the press in the new "inward" button occurs before the
                    % old "downward" button is released
                    %                     lptwrite(PortAddress, 21);
                    matpress{numbpress+1, 2} = (secs - startTime);
                    matpress{numbpress+1, 1} = 'inward';
                    matpress{numbpress+1, 3} = currentFr;
                    matpress{numbpress+1, 4} = protocol;
                    matpress{numbpress+1, 5} = dots.size;
                    matpress{numbpress+1, 6} = stim_ratio;
                    numbpress = numbpress+1;
                    doublepress = 1;
                    button2 = 1;
                    % ------------------------------------------------ %
                    % Send trigger for trigInward
                    
                    % Send trigger.
                    success=sendTrigger(portTrigg, PortAddress, trigInward);
                    
                    % ------------------------------------------------ %
                    
                elseif keyCode(vertkeycode) && button1 == 0 && button2 == 1
                    % There are two buttons pressed and one of them is "downward"
                    % button press - this is a "double" press during
                    % "inward", which we assume is a new "downward" report but
                    % the press in the new "downward" button occurs before the
                    % old "inward" button is released
                    %                     lptwrite(PortAddress, 11);
                    matpress{numbpress+1, 2} = (secs - startTime);
                    matpress{numbpress+1, 1} = 'down';
                    matpress{numbpress+1, 3} = currentFr;
                    matpress{numbpress+1, 4} = protocol;
                    matpress{numbpress+1, 5} = dots.size;
                    matpress{numbpress+1, 6} = stim_ratio;
                    numbpress = numbpress+1;
                    doublepress = 1;
                    button1 = 1;
                    % ------------------------------------------------ %
                    % Send trigger for down
                    
                    % Send trigger.
                    success=sendTrigger(portTrigg, PortAddress, trigDownward);
                    
                    % ------------------------------------------------ %
                elseif button1 == 1 && button2 == 1
                    % There are two buttons pressed, "downward" and "inward",
                    % either the participant forgot to release a key or he
                    % is confused (and for some reason pressing both keys)
                    % this starts a counter 'doublepress' that will be used
                    % to check if it is a reasonable "double" or not. If
                    % doublepress goes for too long it will tell you by
                    % "stopdouble" that a key has finally been released
                    doublepress = doublepress + 1;
                end
                
                %--------------------------------------%
                % There is only one key/button pressed %
                %--------------------------------------%
            else
                % To Escape
                if keyCode(escapekeycode)
                    
                    % Close PTB screen and connections
                    Screen('CloseAll');
                    ShowCursor;
                    Priority(0);
                    
                    % ------------------------------------------------ %
                    
                    % Send trigger.
                    success=sendTrigger(portTrigg, PortAddress, trigEnd);
                    
                    % ------------------------------------------------ %
                    
                    %                     lptwrite(PortAddress, 14);
                    WaitSecs(0.04)
                    %                     lptwrite(PortAddress, 0);
                    % Compute the ration of downward/inward duration
                    time_ratio = time_down/time_in;
                    
                    % Show mouse cursor
                    ShowCursor;
                    
                    matpress{end+1, 1} = 'finished';
                    matpress{end, 2} = (secs - startTime);
                    matpress{end, 3} = currentFr;
                    matpress{end, 4} = protocol;
                    matpress{end, 5} = dots.size;
                    matpress{end, 6} = stim_ratio;
                    
                    % Save variables anyway
                    experiment.matpress = matpress;
                    experiment.frametime = frametime;
                    experiment.time_down = time_down;
                    experiment.time_in = time_in;
                    experiment.time_ratio = time_ratio;
                    experiment.matdots = matdots;
                    
                    % Time and date of experiment (run)
                    fullDateOfExperiment = datestr(now,'HHMM_ddmmmmyyyy');
                    experiment.full_date =  fullDateOfExperiment;
                    
                    % Save experiment
                    try
                        [filename, pathname] = uiputfile(['matpress_' datestr(now, 'ddmm') '_' datestr(now, 'HHMM') '.mat'], pwd);
                        save([pathname filename], 'matpress', 'frametime', 'experiment');
                        
                        % Launch window with warning of early end of program
                        warndlg('The task was terminated with ''Esc'' before the end!','Warning','modal')
                        
                    catch me
                        partID =  'SA';
                        expname = [partID, '_A_'];
                        
                        % Add information of program 'ERROR' in the filename
                        experimentName = [expname, 'ERRORoutput_', experiment.full_date];
                        save(experimentName,'experiment');
                    end
                    return % abort program
                elseif keyCode(vertkeycode) && button1 == 0
                    % The participant just pressed 'down'
                    %                     lptwrite(PortAddress, 11);
                    matpress{numbpress+1, 2} = (secs - startTime);
                    matpress{numbpress+1, 1} = 'down';
                    matpress{numbpress+1, 3} = currentFr;
                    matpress{numbpress+1, 4} = protocol;
                    matpress{numbpress+1, 5} = dots.size;
                    matpress{numbpress+1, 6} = stim_ratio;
                    numbpress = numbpress+1;
                    button1 = 1;
                    time_down = time_down + FlipInterval;
                    % ------------------------------------------------ %
                    
                    % Send trigger for Downward.
                    success=sendTrigger(portTrigg, PortAddress, trigDownward);
                    
                    % ------------------------------------------------ %
                    
                    %                     lptwrite(PortAddress, 0);
                elseif keyCode(horzkeycode) && button2 == 0
                    % The participant just pressed 'inward'
                    %                     lptwrite(PortAddress, 21);
                    matpress{numbpress+1, 2} = (secs - startTime);
                    matpress{numbpress+1, 1} = 'inward';
                    matpress{numbpress+1, 3} = currentFr;
                    matpress{numbpress+1, 4} = protocol;
                    matpress{numbpress+1, 5} = dots.size;
                    matpress{numbpress+1, 6} = stim_ratio;
                    numbpress = numbpress+1;
                    button2 = 1;
                    time_in = time_in + FlipInterval;
                    % ------------------------------------------------ %
                    
                    % Send trigger for Inward.
                    success=sendTrigger(portTrigg, PortAddress, trigInward);
                    
                    % ------------------------------------------------ %
                    %                     lptwrite(PortAddress, 0);
                elseif keyCode(horzkeycode) && button1 == 1 && button2 == 1  && doublepress < 40
                    % The participant released 'down' while pressing
                    % 'inward' for less than 40 continuous frames. Should
                    % be considered a normal switch
                    %                     lptwrite(PortAddress, 10);
                    matpress{numbpress+1, 2} = (secs - startTime);
                    matpress{numbpress+1, 1} = 'stopd';
                    matpress{numbpress+1, 3} = currentFr;
                    matpress{numbpress+1, 4} = protocol;
                    matpress{numbpress+1, 5} = dots.size;
                    matpress{numbpress+1, 6} = stim_ratio;
                    numbpress = numbpress+1;
                    button1 = 0;
                    button2 = 1;
                    doublepress = 0;
                    time_down = time_down + FlipInterval;
                    % ------------------------------------------------ %
                    
                    % Send trigger for stopDownward.
                    success=sendTrigger(portTrigg, PortAddress, trigStopDownward);
                    
                    % ------------------------------------------------ %
                    %                     lptwrite(PortAddress, 0);
                elseif keyCode(vertkeycode) && button1 == 1 && button2 == 1  && doublepress < 40
                    % The participant released 'inward' while pressing
                    % 'down' for less than 40 continuous frames. Should
                    % be considered a normal switch
                    %                     lptwrite(PortAddress, 20);
                    matpress{numbpress+1, 2} = (secs - startTime);
                    matpress{numbpress+1, 1} = 'stopi';
                    matpress{numbpress+1, 3} = currentFr;
                    matpress{numbpress+1, 4} = protocol;
                    matpress{numbpress+1, 5} = dots.size;
                    matpress{numbpress+1, 6} = stim_ratio;
                    numbpress = numbpress+1;
                    button1 = 1;
                    button2 = 0;
                    doublepress = 0;
                    time_in = time_in + FlipInterval;
                    % ------------------------------------------------ %
                    
                    % Send trigger for stopInward.
                    success=sendTrigger(portTrigg, PortAddress, trigStopInward);
                    
                    % ------------------------------------------------ %
                    %                     lptwrite(PortAddress, 0);
                elseif keyCode(horzkeycode) && button1 == 1 && button2 == 1  && doublepress > 40
                    % The participant released 'down' while pressing
                    % 'inward' for more than 40 continuous frames. It is
                    % considered a switch condition but indicates the
                    % moment of release as 'stopdouble'
                    %                     lptwrite(PortAddress, 220);
                    matpress{numbpress+1, 2} = (secs - startTime);
                    matpress{numbpress+1, 1} = 'stopdouble';
                    matpress{numbpress+1, 3} = currentFr;
                    matpress{numbpress+1, 4} = protocol;
                    matpress{numbpress+1, 5} = dots.size;
                    matpress{numbpress+1, 6} = stim_ratio;
                    numbpress = numbpress+1;
                    button1 = 0;
                    button2 = 1;
                    doublepress = 0;
                    % ------------------------------------------------ %
                    
                    % Send trigger for StopDouble.
                    success=sendTrigger(portTrigg, PortAddress, trigStopDouble);
                    
                    % ------------------------------------------------ %
                    %                     lptwrite(PortAddress, 0);
                elseif keyCode(vertkeycode) && button1 == 1 && button2 == 1  && doublepress > 40
                    % The participant released 'inward' while pressing
                    % 'down' for more than 40 continuous frames. It is
                    % considered a switch condition but indicates the
                    % moment of release as 'stopdouble'
                    %                     lptwrite(PortAddress, 220);
                    matpress{numbpress+1, 2} = (secs - startTime);
                    matpress{numbpress+1, 1} = 'stopdouble';
                    matpress{numbpress+1, 3} = currentFr;
                    matpress{numbpress+1, 4} = protocol;
                    matpress{numbpress+1, 5} = dots.size;
                    matpress{numbpress+1, 6} = stim_ratio;
                    numbpress = numbpress+1;
                    button1 = 1;
                    button2 = 0;
                    doublepress = 0;
                    % ------------------------------------------------ %
                    
                    % Send trigger for StopDouble.
                    success=sendTrigger(portTrigg, PortAddress, trigStopDouble);
                    
                    % ------------------------------------------------ %
                    %                     lptwrite(PortAddress, 0);
                elseif button1 == 1
                    % increase the duration of "time_down" by 1 flip
                    % interval (around 16.67ms)while key 'down' is being
                    % pressed
                    time_down = time_down + FlipInterval;
                elseif button2 == 1
                    % increase the duration of "time_in" by 1 flip
                    % interval (around 16.67ms) while key 'inward' is being
                    % pressed
                    time_in = time_in + FlipInterval;
                end
            end
            
        elseif keyIsDown == 0 && button1 == 1 && doublepress < 40
            % The subject has just released key 'down' and hasnt pressed
            % two keys for more than 40 frames. Should be considered a
            % regular perceptual switch
            %             lptwrite(PortAddress, 10);
            matpress{numbpress+1, 2} = (secs - startTime);
            matpress{numbpress+1, 1} = 'stopd';
            matpress{numbpress+1, 3} = currentFr;
            matpress{numbpress+1, 4} = protocol;
            matpress{numbpress+1, 5} = dots.size;
            matpress{numbpress+1, 6} = stim_ratio;
            numbpress = numbpress+1;
            button1 = 0;
            button2 = 0;
            % ------------------------------------------------ %
            
            
            % Send trigger for trigStopDownward.
            success=sendTrigger(portTrigg, PortAddress, trigStopDownward);
            
            % ------------------------------------------------ %
            %             lptwrite(PortAddress, 0);
        elseif keyIsDown == 0 && button2 == 1 && doublepress < 40
            % The subject has just released key 'in' and hasnt pressed
            % two keys for more than 40 frames. Should be considered a
            % regular perceptual switch
            %             lptwrite(PortAddress, 20);
            matpress{numbpress+1, 2} = (secs - startTime);
            matpress{numbpress+1, 1} = 'stopi';
            matpress{numbpress+1, 3} = currentFr;
            matpress{numbpress+1, 4} = protocol;
            matpress{numbpress+1, 5} = dots.size;
            matpress{numbpress+1, 6} = stim_ratio;
            numbpress = numbpress+1;
            button1 = 0;
            button2 = 0;
            % ------------------------------------------------ %
            
            % Send trigger for trigStopInward.
            success=sendTrigger(portTrigg, PortAddress, trigStopInward);
            
            % ------------------------------------------------ %
            %             lptwrite(PortAddress, 0);
        elseif keyIsDown == 0 && doublepress > 40
            % The subject has just released all or any key after pressing
            % two keys for longer than 40 frames. Should be considered the
            % end of a 'double' press
            %             lptwrite(PortAddress, 220);
            matpress{numbpress+1, 2} = (secs - startTime);
            matpress{numbpress+1, 1} = 'stopdouble';
            matpress{numbpress+1, 3} = currentFr;
            matpress{numbpress+1, 4} = protocol;
            matpress{numbpress+1, 5} = dots.size;
            matpress{numbpress+1, 6} = stim_ratio;
            numbpress = numbpress+1;
            button1 = 0;
            button2 = 0;
            doublepress = 0;
            % ------------------------------------------------ %
            
            % Send trigger for StopDouble.
            success=sendTrigger(portTrigg, PortAddress, trigStopDouble);
            
            % ------------------------------------------------ %
            %             lptwrite(PortAddress, 0);
        else
            % If no key is pressed, return "button" values to 0, to allow
            % for further pressed
            button1 = 0; % for downkeycode
            button2 = 0; % for inkeycode
            button3 = 0; % for other keys related to stimulus editing
            continue
        end
        % end while cycle
    end
    
    % ---------------------------------------------------------------------
    %              Display final fixation cross (fNIRS)
    % ---------------------------------------------------------------------
    
    Screen('FillRect', windowID, [255 0 0], FixCross');
    frametime(currentFr) = Screen('Flip',windowID);
    % Send trigger.
    success=sendTrigger(portTrigg, PortAddress, trigBaseline); % trigger 35 - start?
    
    WaitSecs(baselineTime);
    
    % ---------------------------------------------------------------------
    %              Stim finished
    % ---------------------------------------------------------------------
    
    % Send trigger for end.
    success=sendTrigger(portTrigg, PortAddress, trigEnd);

    %     Screen('FillRect', windowID, [255 255 255], [xcenter-largura, (ycenter-altura/2), xcenter+largura, (ycenter+altura/2)]);
    Screen('FillRect', windowID, [255 0 0], FixCross');
    frametime(currentFr) = Screen('Flip',windowID);
    WaitSecs(2);
    
    % Close stimulus window
    Screen('Close',windowID);
    %     lptwrite(PortAddress, 14);
    %     WaitSecs(0.04)
    %     lptwrite(PortAddress, 0);
    % Compute the ration of downward/inward duration
    time_ratio = time_down/time_in;
    
    % Show mouse cursor
    ShowCursor;
    
    matpress{end+1, 1} = 'finished';
    matpress{end, 2} = (secs - startTime);
    matpress{end, 3} = currentFr;
    matpress{end, 4} = protocol;
    matpress{end, 5} = dots.size;
    matpress{end, 6} = stim_ratio;
    
    % Save variables anyway
    experiment.matpress = matpress;
    experiment.frametime = frametime;
    experiment.time_down = time_down;
    experiment.time_in = time_in;
    experiment.time_ratio = time_ratio;
    experiment.matdots = matdots;
    
    % Time and date of experiment (run)
    fullDateOfExperiment = datestr(now,'HHMM_ddmmmmyyyy');
    experiment.full_date =  fullDateOfExperiment;
    
    % Save experiment
    try
        [filename, pathname] = uiputfile(['matpress_' datestr(now, 'ddmm') '_' datestr(now, 'HHMM') '.mat'], pwd);
        save([pathname filename], 'matpress', 'frametime', 'experiment');
    catch me
        partID =  'SA';
        expname = [partID, '_A_'];
        
        % Add information of program 'ERROR' in the filename
        experimentName = [expname, 'ERRORoutput_', experiment.full_date];
        save(experimentName,'experiment');
    end
catch me
    
    % ------------------------------------------------ %
    %               Send trigger for end
    success=sendTrigger(portTrigg, PortAddress, trigEnd);
    % ------------------------------------------------ %
    
    [filename, pathname] = uiputfile(['matpress_' datestr(now, 'ddmm') '_' datestr(now, 'HHMM') '.mat'], pwd);
    save([pathname filename], 'matpress', 'frametime');
    
    % Save variables anyway
    experiment.matpress = matpress;
    experiment.frametime = frametime;
    experiment.time_down = time_down;
    experiment.time_in = time_in;
    experiment.time_ratio = time_ratio;
    experiment.matdots = matdots;
    
    % Time and date of experiment (run)
    fullDateOfExperiment = datestr(now,'HHMM_ddmmmmyyyy');
    experiment.full_date =  fullDateOfExperiment;
    
    partID =  'SA';
    expname = [partID, '_A_'];
    
    % Add information of program 'ERROR' in the filename
    experimentName = [expname, 'ERRORoutput_', experiment.full_date];
    
    % Save experiment
    save(experimentName,'experiment');
    
    % Close PTB Screen and connections
    Screen('CloseAll');
    
    ShowCursor;
    Priority(0);
    rethrow(me);
    
end
