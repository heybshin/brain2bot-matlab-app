function coordinates = ObjPosCartesian(endEffectorOrientation)
    % Manually set object coordinates from AR module

    % Finger Positions
    coordinates.FINGER_OPEN = 0 * ones(3,1);
    coordinates.FINGER_CLOSE = 4000 * ones(3,1);

    % Twist directions
    coordinates.TWIST_LEFT = [0;0;0;0;0;0;0.5];
    coordinates.TWIST_RIGHT = [0;0;0;0;0;0;-0.5];
    
    % Locations
    coordinates.HOME = [0.21; -0.26; 0.50; endEffectorOrientation];
    coordinates.PICKUP_BOTTLE = [0.37; -0.31; 0.07; endEffectorOrientation];
    coordinates.POUR2CUP = [0.75; -0.43; 0.24; endEffectorOrientation];
    coordinates.PUTDOWN_BOTTLE = [0.56; -0.51; 0.09; endEffectorOrientation];
    coordinates.STEPBACK = [0.45; -0.30; 0.09; endEffectorOrientation];
    coordinates.PICKUP_CUP = [0.72; -0.31; 0.09; endEffectorOrientation];
    coordinates.TO_USER = [0.50; -0.05; 0.25; endEffectorOrientation];
end