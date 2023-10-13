function [stat, out] = MoveToCartPos(obj,desired_pos,out)

if (size(desired_pos)~=6)
    disp('Check the size of input');
    stat=-1;
    return;
end    
    
limit_x=0.9;
limit_y=0.9;
limit_z=1.1;
current_pos=obj.EndEffectorPose;

if abs(desired_pos(1))>limit_x
    disp('Unable to move');
    stat=-1;
    return;
end    

if abs(desired_pos(2))>limit_y
    disp('Unable to move');
    stat=-1;
end

if (desired_pos(3)>limit_z || desired_pos(3)<0)
    disp('Unable to move');
    stat=-1;
end

if abs(desired_pos(4))>pi
   desired_pos(4)=mod(desired_pos(4)+pi,2*pi)-pi;
end    

if abs(desired_pos(5))>limit_y
   desired_pos(5)=mod(desired_pos(5)+pi,2*pi)-pi;
end

if abs(desired_pos(6))>limit_y
   desired_pos(6)=mod(desired_pos(6)+pi,2*pi)-pi;
end

error_xyz=sqrt((desired_pos(1)-current_pos(1)).^2+(desired_pos(2)-current_pos(2)).^2+(desired_pos(3)-current_pos(3)).^2);
tollerance_xyz=0.01;
timestep=0;
while error_xyz>tollerance_xyz 
    temp_pos=obj.EndEffectorPose;
    
    error_xyz=sqrt((desired_pos(1)-temp_pos(1)).^2+(desired_pos(2)-temp_pos(2)).^2+(desired_pos(3)-temp_pos(3)).^2);
    CartVel=0.2;
    direction=CartVel*[desired_pos(1)-temp_pos(1),desired_pos(2)-temp_pos(2),desired_pos(3)-temp_pos(3)]/error_xyz;
   
    CartVelCmd = [direction(1);direction(2);direction(3);0;0;0];
    sendCartesianVelocityCommand(obj,CartVelCmd);
    
    timestep=timestep+1;
    out = DisplayPos(obj);
    if(timestep>2000)
        break;
    end    
end

stat=0;
end

