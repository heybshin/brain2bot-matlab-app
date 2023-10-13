classdef brain2bot < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        AboutUsButton                 matlab.ui.control.Button
        TestModeCheckBox              matlab.ui.control.CheckBox
        TestModeLabel                 matlab.ui.control.Label
        TestModeButton                matlab.ui.container.ButtonGroup
        Button                        matlab.ui.control.StateButton
        TestModeIdeal                 matlab.ui.control.RadioButton
        TestModeRealistic             matlab.ui.control.RadioButton
        CorrectLamp                   matlab.ui.control.Lamp
        Panel                         matlab.ui.container.Panel
        ConsoleOutput                 matlab.ui.control.TextArea
        UIAxes                        matlab.ui.control.UIAxes
        InitializingRobotLabel        matlab.ui.control.Label
        GoodbyeLabel                  matlab.ui.control.Label
        MissionCompleteLabel          matlab.ui.control.Label
        QuitButton                    matlab.ui.control.Button
        HomeButton                    matlab.ui.control.Button
        ActionLabel                   matlab.ui.control.Label
        Result                        matlab.ui.control.Label
        Target                        matlab.ui.control.Label
        ResultLabel                   matlab.ui.control.Label
        TargetLabel                   matlab.ui.control.Label
        CorrectLampLabel              matlab.ui.control.Label
        CountdownLabel                matlab.ui.control.Label
        VirtualModeButton             matlab.ui.control.Button
        RealRobotButton               matlab.ui.control.Button
        ReadyLabel                    matlab.ui.control.Label
        RoboticArmControlSystemLabel  matlab.ui.control.Label
        InteractLabel                 matlab.ui.control.Label
        SkipTutorialButton            matlab.ui.control.Button
        StartTutorialButton           matlab.ui.control.Button
        Image                         matlab.ui.control.Image
        ContextMenu                   matlab.ui.container.ContextMenu
        Menu                          matlab.ui.container.Menu
        Menu2                         matlab.ui.container.Menu
    end

    properties (Access = public)
        TutorialButton matlab.ui.control.Button
        SkipButton matlab.ui.control.Button
        ReadyText matlab.ui.control.Label
        VirtualButton matlab.ui.control.Button
        RealButton matlab.ui.control.Button
    end
    
    properties (Access = private)
        % State variables
        MODE string;
        TEST logical = false;
        PERFECT logical = false;
        ERROR logical = false;
        StopTask logical = false;
        StopVideoPlayback logical = false; % flag for whether to stop/interrupt a video playback
        
        % UI Components
        HomeMenuComponents cell = {};
        ModeSelectionComponents cell = {};

        % Task variables
        Robot;  % Robot object
        Pos;   % Positions of objects (as given by AR module)
        PreloadedVideos = struct();
        VirtualModeClips = struct(...
            'Bottle', 'to_bottle.mp4', ...
            'Grasp', 'grasp_bottle.mp4', ...
            'Cup', 'to_cup.mp4', ...
            'Pour', 'pour.mp4', ...
            'Drink', 'drink.mp4', ...
            'BottleFail', 'initial.png', ...
            'GraspFail', 'grasp_bottle_fail.mp4', ...
            'CupFail', 'to_cup_fail.mp4', ...
            'PourFail', 'pour_fail.mp4', ...
            'DrinkFail', 'drink_fail.mp4' ...
            );
        Tasks = {'Bottle', 'Grasp', 'Cup', 'Pour', 'Drink'};  % Target task sequence
        MIs = {'Right', 'Grasp', 'Left', 'Twist', 'Left'};    % Corresponding MI
        Messages = {'Reaching to Bottle...', 'Grasping...', 'Reaching to Cup...', 'Pouring...', 'Retrieving Cup...'};
        ModelClasses = {'Left', 'Right', 'Grasp', 'Twist', 'Idle'};   % Classes used to pretrain classification model
    end
    
    % helper functions
    methods (Access = private)
        function ResetDisplay(app)
            % Get all properties of the app
            propNames = fieldnames(app);

            % List of components to always keep visible
            alwaysVisible = {'UIFigure', 'Image'};
            
            % Loop through each property and set its visibility to 'off' if it's a UI component
            for i = 1:length(propNames)
                propName = propNames{i};
                propValue = app.(propName);
                
                % Check if the current property is in the always visible list
                if ~ismember(propName, alwaysVisible) && ~isempty(propValue) && isprop(propValue, 'Visible')
                    propValue.Visible = 'off';
                end
            end
        end

        function DisplayModeSelection(app)
            % Hide initial components
            app.ResetDisplay();

            % Show the new components
            for component = app.ModeSelectionComponents
                component{1}.Visible = 'on';
            end
        end
        
        function DisplayHomeMenu(app)
            app.ResetDisplay();
            for component = app.HomeMenuComponents
                component{1}.Visible = 'on';
            end
        end
        
        function SetupAxesDisplay(app, contentWidth, contentHeight)
            % Set the fixed height
            fixedHeight = 720;
            
            % Calculate the aspect ratio of the video
            aspectRatio = contentWidth / contentHeight;
            
            % Calculate the width based on the fixed height and aspect ratio
            newWidth = fixedHeight * aspectRatio;
            
            % Adjust dimensions of the Panel
            app.Panel.Position(3) = newWidth-2;
            app.Panel.Position(4) = fixedHeight;

            % Adjust dimensions and position of the UIAxes
            app.UIAxes.Position = [0, 0, newWidth-2, fixedHeight];
            app.UIAxes.XLim = [0, contentWidth];
            app.UIAxes.YLim = [0, contentHeight];
        end


        function PlayVideo(app, fname)
            app.Panel.Visible = 'on';
            app.UIAxes.Visible = 'on';
            app.HomeButton.Visible = "on";
            app.StopVideoPlayback = false;

            cwd = fileparts(mfilename('fullpath'));
            filePath = fullfile(cwd, 'videos', fname);
            vidObj = VideoReader(filePath);
            
            SetupAxesDisplay(app, vidObj.Width, vidObj.Height);

            while hasFrame(vidObj) && ~app.StopVideoPlayback
                vidFrame = readFrame(vidObj);
                image(vidFrame, 'Parent', app.UIAxes); 
                pause(1/vidObj.FrameRate);
                if app.StopVideoPlayback || app.StopTask
                    break;
                end
            end

        end

        function DisplayVisualFeedback(app, fname)
            if app.StopTask
                return;
            end
            cwd = fileparts(mfilename('fullpath'));
            app.Panel.Visible = 'on';
            app.UIAxes.Visible = 'on';
            app.HomeButton.Visible = "on";
            app.StopVideoPlayback = false;

            % Check if the file is an image (.jpg)
            [~,~,ext] = fileparts(fname);
            if ismember(ext, {'.jpg', '.png'})
                img = imread(fullfile(cwd, 'videos/480', fname));
                % Adjust UIAxes dimensions and centering
                SetupAxesDisplay(app, size(img, 2), size(img, 1));
                imshow(img, 'Parent', app.UIAxes);
                pause(2);
                return;
            end
            
            fieldname = strrep(fname, '.mp4', '');
            vidFrames = app.PreloadedVideos.(fieldname).frames;
            framerate = app.PreloadedVideos.(fieldname).framerate;
            SetupAxesDisplay(app, size(vidFrames, 2), size(vidFrames, 1));

            % Play video frame by frame
            for i = 1:size(vidFrames, 4)
                if app.StopVideoPlayback || app.StopTask
                    break;
                end
                imshow(vidFrames(:,:,:,i), 'Parent', app.UIAxes);
                pause(1/framerate);
            end
            app.UIAxes.Visible = 'off';
        end

        function i = DisplayResults(app, i, pred, actual, task, msg)
            % Display the classification result
            app.Result.Text = pred;
            
            % Check the output against the expected MI
            if strcmp(pred, actual)
                % Update lamp
                app.CorrectLamp.Color = 'green';
                app.CorrectLampLabel.Text = 'Correct!';
                app.CorrectLampLabel.FontColor = 'green';
                app.ActionLabel.Text = msg;

                % Display results
                if app.StopTask
                    return;
                else
                    app.Result.Visible = "on";
                    pause(0.5);
                    app.CorrectLamp.Visible = "on";
                    app.CorrectLampLabel.Visible = "on";
                    app.ActionLabel.Visible = "on";
                end
                
                if strcmp(app.MODE, 'Real')
                    pause(1);
                    try
                        if app.StopTask
                            return;
                        else
                            app.Panel.Visible = "on";
                            app.ConsoleOutput.Visible = "on";
                        end
                        pause(0.5);
                        [consoleOutput] = RobotTaskExecution(app.Robot, task, app.Pos, false);
                        app.ConsoleOutput.Value = [app.ConsoleOutput.Value; consoleOutput];
                    catch ME
                        app.HandleError(ME);
                    end
                end
                if strcmp(app.MODE, 'Virtual')
                    % Play the corresponding video
                    video = app.VirtualModeClips.(task);
                    app.DisplayVisualFeedback(video);
                end

                i = i + 1;
                
            else
                % Update lamp
                app.CorrectLamp.Color = 'red';
                app.CorrectLampLabel.Text = 'Incorrect!';
                app.CorrectLampLabel.FontColor = 'red';
                app.ActionLabel.Text = 'Returning to Step 1...';

                % Display results
                if app.StopTask
                    return;
                else
                    app.Result.Visible = "on";
                    pause(0.5);
                    app.CorrectLamp.Visible = "on";
                    app.CorrectLampLabel.Visible = "on";
                    app.ActionLabel.Visible = "on";
                end

                if strcmp(app.MODE, 'Real') 
                    pause(1);
                    try
                        if app.StopTask
                            return;
                        else
                            app.Panel.Visible = "on";
                            app.ConsoleOutput.Visible = "on";
                        end
                        pause(0.5);
                        [consoleOutput] = RobotTaskExecution(app.Robot, task, app.Pos, true);
                        app.ConsoleOutput.Value = [app.ConsoleOutput.Value; consoleOutput];
                    catch ME
                        app.HandleError(ME);
                    end
                end
                if strcmp(app.MODE, 'Virtual')
                    % Play the "fail" video
                    video = app.VirtualModeClips.([task 'Fail']);
                    app.DisplayVisualFeedback(video);
                end

                % Reset to the beginning of the sequence
                i = 1;
            end

            % Turn off results display
            app.CorrectLamp.Visible = "off";
            app.CorrectLampLabel.Visible = "off";
            app.ActionLabel.Visible = "off";
            app.Result.Visible = "off";
            app.Target.Visible = "off";
        end

        function [state, model] = Initialize(app)
            % Mute all buttons and objects
            app.StopTask = false;
            app.StopVideoPlayback = false;

            app.ResetDisplay();
            app.InitializingRobotLabel.Text = "Initializing Robot...";
            app.InitializingRobotLabel.Visible = "on";

            % Main Task init
            state = struct;
            if app.TEST
                model = 1;
            else
                bbci_acquire_bv('close');
                state = bbci_acquire_bv('init', state);
                EEGSignalAcqusition(state, 749);
                model = EEGNetModel(32, 5, 750);
                load('EEGNetParams.mat', 'learnableParams');
                model.Learnables = learnableParams;
            end

            if strcmp(app.MODE, 'Real')
                app.Robot = JacoComm;
                connect(app.Robot);
                RobotInitialization(app.Robot);
                endEffectorOrientation = app.Robot.EndEffectorPose(4:6);
                app.Pos = ObjPosParams(endEffectorOrientation);
            end

            if strcmp(app.MODE, 'Virtual')
                % Preload videos in the background
    %             preload = parfeval(pool, @robot_arm_control.PreloadVideos, 1);
                app.PreloadVideos();
            end

            % Start countdown for user
            app.Countdown(3);
        end

        function HandleError(app, ME)
            % Display the error message in a dialog box
            errorMessage = sprintf('Error occurred: %s\n\nWould you like to return home or exit the program?', ME.message);
            choice = questdlg(errorMessage, 'Error', 'Return Home', 'Exit', 'Return Home');
            app.ERROR = true;
            
            switch choice
                case 'Return Home'
                    app.HomeButtonPushed();
                    app.ERROR = false;
                case 'Exit'
                    app.QuitButtonPushed();
                    app.ERROR = false;
                    return;
            end
        end

        function PreloadVideos(app)
            cwd = fileparts(mfilename('fullpath'));
            videoDir = fullfile(cwd, 'videos/480');
            
            % Get a list of all the video files in the directory
            videoFiles = dir(fullfile(videoDir, '*.mp4'));

            for i = 1:length(videoFiles)
                fname = videoFiles(i).name;
                vidObj = VideoReader(fullfile(videoDir, fname));
        
                vidFrames = zeros(vidObj.Height, vidObj.Width, 3, vidObj.NumFrames, 'uint8');
                idx = 1;
                while hasFrame(vidObj)
                    vidFrames(:,:,:,idx) = readFrame(vidObj);
                    idx = idx + 1;
                end
                fieldname = strrep(fname, '.mp4', '');
                app.PreloadedVideos.(fieldname).frames = vidFrames;
                app.PreloadedVideos.(fieldname).duration = vidObj.Duration;
                app.PreloadedVideos.(fieldname).framerate = vidObj.FrameRate;

                 % Update the label with changing number of dots
%                 numDots = mod(i, 4) + 1;  % cycle between 1 and 4 dots
                app.InitializingRobotLabel.Text = ['Initializing Robot', repmat('.', 1, 3+i)];
            end
        end

        function Countdown(app, maxCount)
            app.InitializingRobotLabel.Visible = 'off';
            app.CountdownLabel.Position(1) = (app.UIFigure.Position(3) - app.CountdownLabel.Position(3)) / 2;
            app.CountdownLabel.Position(2) = (app.UIFigure.Position(4) - app.CountdownLabel.Position(4)) / 2; % Roughly centered
            app.CountdownLabel.Visible = "on";

            % Countdown from 3 to 1
            for count = maxCount:-1:1
                app.CountdownLabel.Text = num2str(count);
                pause(1);
            end

            app.CountdownLabel.Visible = "off";

        end
        
        function PerformMainTask(app, state, model)
            if app.StopTask
                return;
            else
                app.ResultLabel.Visible = "on";
                app.TargetLabel.Visible = "on";
                app.HomeButton.Visible = "on";
            end
            
            if app.TEST
                % Generate the preds list for testing all possibilities
                if app.PERFECT
                    targets = {1, 2, 3, 4, 5};
                    preds = {1, 2, 3, 4, 5};
                else
                    targets = {1, 1, 2, 1, 2, 3, 1, 2, 3, 4, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5};
                    preds =   {2, 1, 5, 1, 2, 4, 1, 2, 3, 1, 1, 2, 3, 4, 1, 1, 2, 3, 4, 5};
                end
                for i = 1:length(targets)
                    if app.StopTask
                        return;
                    end
                    target = targets{i};
                    app.Target.Text = app.MIs{target};
                    if ~app.StopTask
                        app.Target.Visible = "on";
                    end
                    pred = preds{i};
                    pause(4);
                    taskName = app.Tasks{target};
                    msg = app.Messages{targets{i}};
                    app.DisplayResults(targets{i}, app.MIs{pred}, app.MIs{target}, taskName, msg);
                end
            else
                i = 1;
                while i <= length(app.Tasks) && ~ app.StopTask
                    app.Target.Text = app.MIs{i};
                    app.Target.Visible = "on";
    
                    % Acquire EEG data for 3 seconds
                    data = EEGSignalAcqusition(state, 749);  % includes pause
                    
                    % Process the data with the neural network model
                    output = forward(model, dlarray(data.', 'SSCB'));  % transpose data first
                    [~, pred] = max(output, [], 'all');
                    if app.PERFECT
                        preds = {2,3,1,4,1};
                        pred = preds{i};
                    end
                    i = app.DisplayResults(i, app.ModelClasses{pred}, app.MIs{i}, app.Tasks{i}, app.Messages{i});
                end
            end

            if ~ app.StopTask  
                % End task gracefully
                app.ResetDisplay();
                app.MissionCompleteLabel.Visible = "on";
                pause(3);
                app.DisplayHomeMenu();   
            end

        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.HomeMenuComponents = {
                app.RoboticArmControlSystemLabel, app.StartTutorialButton, ...
                app.SkipTutorialButton, app.QuitButton, app.AboutUsButton, ...
                app.InteractLabel
            };
            
            app.ModeSelectionComponents = {
                app.ReadyLabel, ...
                app.VirtualModeButton, ...
                app.RealRobotButton, ...
                app.HomeButton, ...
                app.TestModeCheckBox, ...
                app.TestModeIdeal, ...
                app.TestModeRealistic, ...
                app.TestModeLabel, ...
                app.TestModeButton
            };
            
            
            % Get screen resolution
            screenSize = get(0, 'ScreenSize');
            w = screenSize(3);
            h = screenSize(4);
%             app.UIFigure.Position = [w*0.1 h*0.1 w*0.8 h*0.8];
            
            % Create a figure that occupies the full screen
            app.UIFigure.Position = [1 1 w h];

        end

        % Button pushed function: StartTutorialButton
        function StartTutorialButtonPushed(app, event)
            app.StopTask = false;
            app.StopVideoPlayback = false;
            app.PlayVideo('tutorial.mp4'); 
            app.DisplayModeSelection();
        end

        % Button pushed function: SkipTutorialButton
        function SkipTutorialButtonPushed(app, event)
            app.StopVideoPlayback = true;
            app.DisplayModeSelection();
        end

        % Button pushed function: VirtualModeButton
        function VirtualModeButtonPushed(app, event)
            app.MODE = 'Virtual';
            try
                [state, model] = app.Initialize();
            catch ME
                app.HandleError(ME);
            end
            app.DisplayVisualFeedback('initial.png'); 
            app.PerformMainTask(state, model);
        end

        % Button pushed function: RealRobotButton
        function RealRobotButtonPushed(app, event)
            app.MODE = 'Real'; 
            try
                [state, model] = app.Initialize();
            catch ME
                app.HandleError(ME);
            end
            app.PerformMainTask(state, model);
        end

        % Button pushed function: HomeButton
        function HomeButtonPushed(app, event)
            if ~app.ERROR
                % confirm with the user
                choice = questdlg('Return to home menu?', ...
                    'Confirmation', ...
                    'Yes', 'No', 'No');
                if ~strcmp(choice, 'Yes')
                    return; % If user chooses 'No', don't proceed
                end
            end

            app.StopTask = true;
            app.StopVideoPlayback = true;

            app.ResetDisplay();
            app.InitializingRobotLabel.Text = 'Please wait......';
            app.InitializingRobotLabel.Visible = "on";

            if strcmp(app.MODE, 'Real')
                RobotInitialization(app.Robot);
            end
            
            if ~app.TEST
                bbci_acquire_bv('close');
            end

            app.DisplayHomeMenu();

        end

        % Button pushed function: QuitButton
        function QuitButtonPushed(app, event)
            if ~app.ERROR
                % confirm with the user
                choice = questdlg('Are you sure you want to exit?', ...
                    'Exit Confirmation', ...
                    'Yes', 'No', 'No');
                if ~strcmp(choice, 'Yes')
                    return; % If user chooses 'No' or 'X', exit
                end

            end

            app.StopTask = true;
            app.StopVideoPlayback = true;

            app.ResetDisplay();
            app.GoodbyeLabel.Visible = "on";
            
            if strcmp(app.MODE, 'Real')
                RobotInitialization(app.Robot);
                disconnect(app.Robot);
            end
            
            if ~app.TEST
                bbci_acquire_bv('close');
            end

            % Shutdown app
            delete(app);
        end

        % Window key press function: UIFigure
        function UIFigureWindowKeyPress(app, event)
            if strcmp(event.Key, 'f')
                app.UIFigure.WindowState = 'fullscreen';
            end
            % Check for Ctrl+C
            if strcmp(event.Key, 'c') && any(strcmp(event.Modifier, 'control'))
                app.QuitButtonPushed();
            end
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            app.QuitButtonPushed();
        end

        % Selection changed function: TestModeButton
        function TestModeButtonSelectionChanged(app, event)
            selectedButton = app.TestModeButton.SelectedObject;
            switch selectedButton.Text
                case 'Realistic simulation'
                    app.PERFECT = false;
                case 'Ideal simulation'
                    app.PERFECT = true;
            end
        end

        % Value changed function: TestModeCheckBox
        function TestModeCheckBoxValueChanged(app, event)
            value = app.TestModeCheckBox.Value;
            if value
                app.TestModeButton.Enable = 'on';
                app.TEST = true;
            else
                app.TestModeButton.Enable = 'off';
                app.TEST = false;
            end
        end

        % Button pushed function: AboutUsButton
        function AboutUsButtonPushed(app, event)
            message = sprintf('Software Name: Robotic Arm Control System\nAuthors: Hye-Bin Shin, Kang Yin, Dan Li, Elissa Yanting Lim, Yeon-Woo Choi, Byoung-Hee Kwon (The order of authors listed has no significance.)\nAffiliation: PRML Lab, Korea University\nDate: October 12, 2023\n\nCopyright © 2023 PRML Lab. All rights reserved.\nLicensed under the MIT License.');
            msgbox(message, 'About Us', 'help');
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1920 1080];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);
            app.UIFigure.WindowKeyPressFcn = createCallbackFcn(app, @UIFigureWindowKeyPress, true);
            app.UIFigure.WindowState = 'fullscreen';

            % Create Image
            app.Image = uiimage(app.UIFigure);
            app.Image.ScaleMethod = 'fill';
            app.Image.Position = [9 1 1920 1080];
            app.Image.ImageSource = 'abstract-luxury-gradient-blue-background-smooth-dark-blue-with-black-vignette-studio-banner.jpg';

            % Create StartTutorialButton
            app.StartTutorialButton = uibutton(app.UIFigure, 'push');
            app.StartTutorialButton.ButtonPushedFcn = createCallbackFcn(app, @StartTutorialButtonPushed, true);
            app.StartTutorialButton.BackgroundColor = [0.502 0.502 0.502];
            app.StartTutorialButton.FontName = 'Arial Black';
            app.StartTutorialButton.FontSize = 40;
            app.StartTutorialButton.FontColor = [1 1 1];
            app.StartTutorialButton.Position = [267 127 453 135];
            app.StartTutorialButton.Text = 'Start Tutorial';

            % Create SkipTutorialButton
            app.SkipTutorialButton = uibutton(app.UIFigure, 'push');
            app.SkipTutorialButton.ButtonPushedFcn = createCallbackFcn(app, @SkipTutorialButtonPushed, true);
            app.SkipTutorialButton.BackgroundColor = [0.502 0.502 0.502];
            app.SkipTutorialButton.FontName = 'Arial Black';
            app.SkipTutorialButton.FontSize = 40;
            app.SkipTutorialButton.FontColor = [1 1 1];
            app.SkipTutorialButton.Position = [1200 127 453 135];
            app.SkipTutorialButton.Text = 'Skip Tutorial';

            % Create InteractLabel
            app.InteractLabel = uilabel(app.UIFigure);
            app.InteractLabel.HorizontalAlignment = 'center';
            app.InteractLabel.FontName = 'Arial';
            app.InteractLabel.FontSize = 45;
            app.InteractLabel.FontAngle = 'italic';
            app.InteractLabel.FontColor = [1 1 1];
            app.InteractLabel.Position = [443 414 1034 110];
            app.InteractLabel.Text = 'Interact with a robot arm using your brain waves!';

            % Create RoboticArmControlSystemLabel
            app.RoboticArmControlSystemLabel = uilabel(app.UIFigure);
            app.RoboticArmControlSystemLabel.HorizontalAlignment = 'center';
            app.RoboticArmControlSystemLabel.FontName = 'Arial Black';
            app.RoboticArmControlSystemLabel.FontSize = 70;
            app.RoboticArmControlSystemLabel.FontColor = [1 1 1];
            app.RoboticArmControlSystemLabel.Position = [318 612 1285 110];
            app.RoboticArmControlSystemLabel.Text = 'Robotic Arm Control System';

            % Create ReadyLabel
            app.ReadyLabel = uilabel(app.UIFigure);
            app.ReadyLabel.HorizontalAlignment = 'center';
            app.ReadyLabel.FontName = 'Arial';
            app.ReadyLabel.FontSize = 60;
            app.ReadyLabel.FontAngle = 'italic';
            app.ReadyLabel.FontColor = [1 1 1];
            app.ReadyLabel.Visible = 'off';
            app.ReadyLabel.Position = [462 46 1034 1019];
            app.ReadyLabel.Text = 'Ready? Now let''s get interactive!';

            % Create RealRobotButton
            app.RealRobotButton = uibutton(app.UIFigure, 'push');
            app.RealRobotButton.ButtonPushedFcn = createCallbackFcn(app, @RealRobotButtonPushed, true);
            app.RealRobotButton.BackgroundColor = [0.502 0.502 0.502];
            app.RealRobotButton.FontName = 'Arial Black';
            app.RealRobotButton.FontSize = 40;
            app.RealRobotButton.FontColor = [1 1 1];
            app.RealRobotButton.Visible = 'off';
            app.RealRobotButton.Tooltip = {'Interact with a physical robot in front of you'};
            app.RealRobotButton.Position = [267 127 453 135];
            app.RealRobotButton.Text = 'Real Robot';

            % Create VirtualModeButton
            app.VirtualModeButton = uibutton(app.UIFigure, 'push');
            app.VirtualModeButton.ButtonPushedFcn = createCallbackFcn(app, @VirtualModeButtonPushed, true);
            app.VirtualModeButton.BackgroundColor = [0.502 0.502 0.502];
            app.VirtualModeButton.FontName = 'Arial Black';
            app.VirtualModeButton.FontSize = 40;
            app.VirtualModeButton.FontColor = [1 1 1];
            app.VirtualModeButton.Visible = 'off';
            app.VirtualModeButton.Tooltip = {'Interact in virtual mode to get an experience'};
            app.VirtualModeButton.Position = [1200 127 453 135];
            app.VirtualModeButton.Text = 'Virtual Mode';

            % Create CountdownLabel
            app.CountdownLabel = uilabel(app.UIFigure);
            app.CountdownLabel.HorizontalAlignment = 'center';
            app.CountdownLabel.FontName = 'Arial Black';
            app.CountdownLabel.FontSize = 300;
            app.CountdownLabel.FontColor = [1 1 1];
            app.CountdownLabel.Enable = 'off';
            app.CountdownLabel.Visible = 'off';
            app.CountdownLabel.Position = [148 90 207 410];
            app.CountdownLabel.Text = '3';

            % Create CorrectLampLabel
            app.CorrectLampLabel = uilabel(app.UIFigure);
            app.CorrectLampLabel.HorizontalAlignment = 'center';
            app.CorrectLampLabel.FontSize = 40;
            app.CorrectLampLabel.FontAngle = 'italic';
            app.CorrectLampLabel.FontColor = [1 1 1];
            app.CorrectLampLabel.Visible = 'off';
            app.CorrectLampLabel.Position = [831 185 295 65];
            app.CorrectLampLabel.Text = 'Correct!';

            % Create TargetLabel
            app.TargetLabel = uilabel(app.UIFigure);
            app.TargetLabel.HorizontalAlignment = 'center';
            app.TargetLabel.VerticalAlignment = 'top';
            app.TargetLabel.FontName = 'Arial Black';
            app.TargetLabel.FontSize = 60;
            app.TargetLabel.FontColor = [1 1 1];
            app.TargetLabel.Visible = 'off';
            app.TargetLabel.Position = [463 58 285 204];
            app.TargetLabel.Text = 'Target';

            % Create ResultLabel
            app.ResultLabel = uilabel(app.UIFigure);
            app.ResultLabel.HorizontalAlignment = 'center';
            app.ResultLabel.VerticalAlignment = 'top';
            app.ResultLabel.FontName = 'Arial Black';
            app.ResultLabel.FontSize = 60;
            app.ResultLabel.FontColor = [1 1 1];
            app.ResultLabel.Visible = 'off';
            app.ResultLabel.Position = [1183 58 285 204];
            app.ResultLabel.Text = 'Result';

            % Create Target
            app.Target = uilabel(app.UIFigure);
            app.Target.HorizontalAlignment = 'center';
            app.Target.VerticalAlignment = 'top';
            app.Target.FontName = 'Arial';
            app.Target.FontSize = 50;
            app.Target.FontColor = [1 1 1];
            app.Target.Visible = 'off';
            app.Target.Position = [514 71 180 65];
            app.Target.Text = '"Target"';

            % Create Result
            app.Result = uilabel(app.UIFigure);
            app.Result.HorizontalAlignment = 'center';
            app.Result.VerticalAlignment = 'top';
            app.Result.FontSize = 50;
            app.Result.FontColor = [1 1 1];
            app.Result.Visible = 'off';
            app.Result.Position = [1233 71 183 65];
            app.Result.Text = '"Result"';

            % Create ActionLabel
            app.ActionLabel = uilabel(app.UIFigure);
            app.ActionLabel.HorizontalAlignment = 'center';
            app.ActionLabel.VerticalAlignment = 'top';
            app.ActionLabel.FontName = 'Arial';
            app.ActionLabel.FontSize = 35;
            app.ActionLabel.FontAngle = 'italic';
            app.ActionLabel.FontColor = [1 1 1];
            app.ActionLabel.Visible = 'off';
            app.ActionLabel.Position = [790 38 396 65];
            app.ActionLabel.Text = 'Action';

            % Create HomeButton
            app.HomeButton = uibutton(app.UIFigure, 'push');
            app.HomeButton.ButtonPushedFcn = createCallbackFcn(app, @HomeButtonPushed, true);
            app.HomeButton.BackgroundColor = [0.8 0.8 0.8];
            app.HomeButton.FontName = 'Segoe UI';
            app.HomeButton.FontSize = 28;
            app.HomeButton.FontWeight = 'bold';
            app.HomeButton.Visible = 'off';
            app.HomeButton.Position = [1765 19 146 62];
            app.HomeButton.Text = 'Home';

            % Create QuitButton
            app.QuitButton = uibutton(app.UIFigure, 'push');
            app.QuitButton.ButtonPushedFcn = createCallbackFcn(app, @QuitButtonPushed, true);
            app.QuitButton.BackgroundColor = [0.8 0.8 0.8];
            app.QuitButton.FontName = 'Segoe UI';
            app.QuitButton.FontSize = 28;
            app.QuitButton.FontWeight = 'bold';
            app.QuitButton.Position = [1764 20 146 61];
            app.QuitButton.Text = 'Quit';

            % Create MissionCompleteLabel
            app.MissionCompleteLabel = uilabel(app.UIFigure);
            app.MissionCompleteLabel.HorizontalAlignment = 'center';
            app.MissionCompleteLabel.FontName = 'Arial';
            app.MissionCompleteLabel.FontSize = 60;
            app.MissionCompleteLabel.FontAngle = 'italic';
            app.MissionCompleteLabel.FontColor = [1 1 1];
            app.MissionCompleteLabel.Visible = 'off';
            app.MissionCompleteLabel.Position = [462 46 1034 1019];
            app.MissionCompleteLabel.Text = 'Mission Complete!';

            % Create GoodbyeLabel
            app.GoodbyeLabel = uilabel(app.UIFigure);
            app.GoodbyeLabel.HorizontalAlignment = 'center';
            app.GoodbyeLabel.FontName = 'Arial';
            app.GoodbyeLabel.FontSize = 50;
            app.GoodbyeLabel.FontAngle = 'italic';
            app.GoodbyeLabel.FontColor = [1 1 1];
            app.GoodbyeLabel.Visible = 'off';
            app.GoodbyeLabel.Position = [292 46 1336 1019];
            app.GoodbyeLabel.Text = 'Thank you for using the app. Goodbye!';

            % Create InitializingRobotLabel
            app.InitializingRobotLabel = uilabel(app.UIFigure);
            app.InitializingRobotLabel.FontName = 'Arial';
            app.InitializingRobotLabel.FontSize = 75;
            app.InitializingRobotLabel.FontAngle = 'italic';
            app.InitializingRobotLabel.FontColor = [1 1 1];
            app.InitializingRobotLabel.Visible = 'off';
            app.InitializingRobotLabel.Position = [663 46 1034 1019];
            app.InitializingRobotLabel.Text = 'Initializing Robot...';

            % Create Panel
            app.Panel = uipanel(app.UIFigure);
            app.Panel.BorderType = 'none';
            app.Panel.TitlePosition = 'centertop';
            app.Panel.Visible = 'off';
            app.Panel.BackgroundColor = [0.0196 0.0706 0.1294];
            app.Panel.Position = [321 279 1280 720];

            % Create UIAxes
            app.UIAxes = uiaxes(app.Panel);
            app.UIAxes.Toolbar.Visible = 'off';
            app.UIAxes.TickLength = [0 0];
            app.UIAxes.GridLineStyle = 'none';
            app.UIAxes.XColor = [1 1 1];
            app.UIAxes.XTick = [];
            app.UIAxes.YColor = [1 1 1];
            app.UIAxes.YTick = [];
            app.UIAxes.ZColor = [1 1 1];
            app.UIAxes.ZTick = [];
            app.UIAxes.BoxStyle = 'full';
            app.UIAxes.TickDir = 'none';
            app.UIAxes.GridColor = [1 1 1];
            app.UIAxes.MinorGridColor = [1 1 1];
            app.UIAxes.Visible = 'off';
            app.UIAxes.HandleVisibility = 'callback';
            app.UIAxes.Position = [1 1 1280 720];

            % Create ConsoleOutput
            app.ConsoleOutput = uitextarea(app.Panel);
            app.ConsoleOutput.FontName = 'Arial';
            app.ConsoleOutput.FontSize = 19;
            app.ConsoleOutput.BackgroundColor = [0.9412 0.9412 0.9412];
            app.ConsoleOutput.Visible = 'off';
            app.ConsoleOutput.Position = [1 1 1280 720];
            app.ConsoleOutput.Value = {'START'; '------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'};

            % Create CorrectLamp
            app.CorrectLamp = uilamp(app.UIFigure);
            app.CorrectLamp.Visible = 'off';
            app.CorrectLamp.Position = [942 109 74 74];

            % Create TestModeButton
            app.TestModeButton = uibuttongroup(app.UIFigure);
            app.TestModeButton.AutoResizeChildren = 'off';
            app.TestModeButton.SelectionChangedFcn = createCallbackFcn(app, @TestModeButtonSelectionChanged, true);
            app.TestModeButton.ForegroundColor = [1 1 1];
            app.TestModeButton.TitlePosition = 'centertop';
            app.TestModeButton.Visible = 'off';
            app.TestModeButton.BackgroundColor = [0.0392 0.1373 0.2392];
            app.TestModeButton.FontName = 'Arial';
            app.TestModeButton.FontSize = 20;
            app.TestModeButton.Position = [800 89 330 151];

            % Create TestModeRealistic
            app.TestModeRealistic = uiradiobutton(app.TestModeButton);
            app.TestModeRealistic.Visible = 'off';
            app.TestModeRealistic.Text = 'Realistic simulation';
            app.TestModeRealistic.FontName = 'Arial';
            app.TestModeRealistic.FontSize = 24;
            app.TestModeRealistic.FontColor = [1 1 1];
            app.TestModeRealistic.Position = [31 75 229 28];
            app.TestModeRealistic.Value = true;

            % Create TestModeIdeal
            app.TestModeIdeal = uiradiobutton(app.TestModeButton);
            app.TestModeIdeal.Visible = 'off';
            app.TestModeIdeal.Text = 'Ideal simulation';
            app.TestModeIdeal.FontName = 'Arial';
            app.TestModeIdeal.FontSize = 24;
            app.TestModeIdeal.FontColor = [1 1 1];
            app.TestModeIdeal.Position = [31 38 190 28];

            % Create Button
            app.Button = uibutton(app.TestModeButton, 'state');
            app.Button.Text = 'Button';
            app.Button.Position = [54 93 100 22];

            % Create TestModeLabel
            app.TestModeLabel = uilabel(app.UIFigure);
            app.TestModeLabel.FontSize = 30;
            app.TestModeLabel.FontColor = [1 1 1];
            app.TestModeLabel.Visible = 'off';
            app.TestModeLabel.Position = [773 254 383 36];
            app.TestModeLabel.Text = '...or try out first in test mode';

            % Create TestModeCheckBox
            app.TestModeCheckBox = uicheckbox(app.UIFigure);
            app.TestModeCheckBox.ValueChangedFcn = createCallbackFcn(app, @TestModeCheckBoxValueChanged, true);
            app.TestModeCheckBox.Visible = 'off';
            app.TestModeCheckBox.Text = ' TEST (No EEG device)';
            app.TestModeCheckBox.FontName = 'Arial';
            app.TestModeCheckBox.FontSize = 26;
            app.TestModeCheckBox.FontColor = [1 1 1];
            app.TestModeCheckBox.Position = [818 203 301 31];

            % Create AboutUsButton
            app.AboutUsButton = uibutton(app.UIFigure, 'push');
            app.AboutUsButton.ButtonPushedFcn = createCallbackFcn(app, @AboutUsButtonPushed, true);
            app.AboutUsButton.BackgroundColor = [0.8 0.8 0.8];
            app.AboutUsButton.FontName = 'Segoe UI';
            app.AboutUsButton.FontSize = 26;
            app.AboutUsButton.FontWeight = 'bold';
            app.AboutUsButton.Position = [1764 92 147 63];
            app.AboutUsButton.Text = 'About Us';

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);

            % Create Menu
            app.Menu = uimenu(app.ContextMenu);
            app.Menu.Text = 'Menu';

            % Create Menu2
            app.Menu2 = uimenu(app.ContextMenu);
            app.Menu2.Text = 'Menu2';
            
            % Assign app.ContextMenu
            app.VirtualModeButton.ContextMenu = app.ContextMenu;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = brain2bot

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end