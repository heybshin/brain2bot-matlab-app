function RobotInitialization(robot)

    % Initialize fingers to default ('open')
    calibrateFingers(robot);
    sendFingerPositionCommand(robot,[0;0;0]);
    pause(5);

    % Initialize position to default ('home')
    setPositionControlMode(robot);
%     setVelocityControlMode(robot);
    goToHomePosition(robot);
    pause(5);

    disp(robot.EndEffectorPose);

end

