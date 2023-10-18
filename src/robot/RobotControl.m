function outputLog = RobotControl(obj, type, pos, interval, lag)
    % Helper function to get command details
    function cmdDetails = getCommandDetails(type, position, lag)
        cmdDetails = sprintf('Task Type: %s\nInput Command: %s\nPause Duration: %s seconds\n------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n', ...
                             type, mat2str(position), num2str(lag));
    end

    % Helper function to get the robot's response after a command
    function response = getRobotResponse(robot)
        response = sprintf('Robot Response:\nEndEffectorPose: %s\nJointPos: %s\nFingerPos: %s\n------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n', ...
                           mat2str(robot.EndEffectorPose), mat2str(robot.JointPos), mat2str(robot.FingerPos));
    end

    cmdOutput = getCommandDetails(type, pos, lag);

    switch (type)
        case 'reach'
            MoveToCartPos(obj, pos);
            pause(lag);
        case 'grasp'
            sendFingerPositionCommand(obj, pos);
            pause(lag);
        case 'twist'
            for i = 1:interval
                sendJointVelocityCommand(obj, pos);
            end
            pause(lag);
    end

    robotResponse = getRobotResponse(obj);

    outputLog = [cmdOutput, robotResponse];
end
