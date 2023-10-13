function [net, output] = EEGNetModel(in_chans, n_classes, varargin)
    % EEGNetv4 creation function for MATLAB

    % Default parameters
    p = inputParser;
    addRequired(p, 'in_chans');
    addRequired(p, 'n_classes');
    addRequired(p, 'input_window_samples');
    addParameter(p, 'pool_mode', 'mean');
    addParameter(p, 'F1', 8);
    addParameter(p, 'D', 2);
    addParameter(p, 'F2', 16);
    addParameter(p, 'kernel_length', 64);
    addParameter(p, 'third_kernel_size', [8, 4]);
    addParameter(p, 'drop_prob', 0.25);
    parse(p, in_chans, n_classes, varargin{:});

    % Extract parameters from parsed input
    params = p.Results;

    % EEGNetv4 Layers

    % First set of layers
    layers = [
        imageInputLayer([params.in_chans, params.input_window_samples, 1], 'Normalization', 'none')
        convolution2dLayer([1, params.kernel_length], params.F1, 'Stride', [1, 1], 'Padding',[0, floor(params.kernel_length / 2)])
        batchNormalizationLayer()
        convolution2dLayer([params.in_chans, 1], params.F1*params.D, 'Stride', [1, 1], 'Padding', [0, 0])
        batchNormalizationLayer()
        reluLayer()
        averagePooling2dLayer([1, 4], 'Stride', [1, 4])
        dropoutLayer(params.drop_prob)
    ];

    % Second set of layers (Depthwise Separable Convolution)
    layers = [
        layers
        convolution2dLayer([1, 16], params.F1*params.D, 'Stride', [1, 1], 'Padding', [0, 8])
        convolution2dLayer([1, 1], params.F2, 'Stride', [1, 1], 'Padding', [0, 0])
        batchNormalizationLayer()
        reluLayer()
        averagePooling2dLayer([1, 8], 'Stride', [1, 8])
        dropoutLayer(params.drop_prob)
    ];

    % Third set of layers
    layers = [
        layers
        convolution2dLayer([1, 23], params.n_classes)
        softmaxLayer()
        % Add any other required layers or operations
    ];

    % Convert layers to layerGraph
    lgraph = layerGraph(layers);
    
    % Convert layerGraph to dlnetwork
    net = dlnetwork(lgraph);
    output = sprintf('createEEGNet Output:\n%s\n', 'Hello!');
end

