function step = EEGClassification(net, data, step)
    
    classNames = {'Left', 'Right', 'Grasp', 'Twist', 'Idle'};

    gt = {'Right', 'Grasp', 'Left', 'Twist', 'Left'};
    output = forward(net, dlarray(data, 'SSCB')); 
    [~, predictedIndex] = max(output, [], 'all');
    if strcmp(classNames{predictedIndex}, gt{step})
        step = step + 1;
        disp(['   디코딩 결과: ' classNames{predictedIndex} '. 맞습니다. 다음 단계로 갑니다.']);
    else
        step = 1;
        disp(['   디코딩 결과: ' classNames{predictedIndex} '. 틀렸습니다. 단계 1로 갑니다.']);
    end
    pause(5);
end