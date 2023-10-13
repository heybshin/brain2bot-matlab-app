function [out] = RobotTaskExecution(robot, task, coords, fail)
    out = '';  % initialize the output string

    switch task
        case 'Bottle'
            if ~fail
                out = [out, RobotControl(robot, 'reach', coords.PICKUP_BOTTLE, 0, 3)];
            end

        case 'Grasp'
            if fail
                out = [out, RobotControl(robot, 'reach', coords.HOME, 0, 3)];
            else
                out = [out, RobotControl(robot, 'grasp', coords.FINGER_CLOSE, 0, 2)];
            end

        case 'Cup'
            if fail
                out = [out, RobotControl(robot, 'grasp', coords.FINGER_OPEN, 0, 2)];
                out = [out, RobotControl(robot, 'reach', coords.HOME, 0, 3)];
            else
                out = [out, RobotControl(robot, 'reach', coords.POUR2CUP, 0, 3)];
            end

        case 'Pour'
            if fail
                out = [out, RobotControl(robot, 'reach', coords.PUTDOWN_BOTTLE, 0, 3)];
                out = [out, RobotControl(robot, 'grasp', coords.FINGER_OPEN, 0, 2)];
                out = [out, RobotControl(robot, 'reach', coords.HOME, 0, 3)];
            else
                out = [out, RobotControl(robot, 'twist', coords.TWIST_LEFT, 360, 5)];
                out = [out, RobotControl(robot, 'twist', coords.TWIST_RIGHT, 360, 5)];
                out = [out, RobotControl(robot, 'reach', coords.PUTDOWN_BOTTLE, 0, 3)];
                out = [out, RobotControl(robot, 'grasp', coords.FINGER_OPEN, 0, 2)];
                out = [out, RobotControl(robot, 'reach', coords.STEPBACK, 0, 3)];
            end

        case 'Drink'
            if fail
                out = [out, RobotControl(robot, 'reach', coords.HOME, 0, 3)];
            else
                out = [out, RobotControl(robot, 'reach', coords.PICKUP_CUP, 0, 3)];
                out = [out, RobotControl(robot, 'grasp', coords.FINGER_CLOSE, 0, 2)];
                out = [out, RobotControl(robot, 'reach', coords.TO_USER, 0, 1)];
            end
    end
end
