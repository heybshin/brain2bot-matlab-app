function data = EEGSignalAcqusition(state, len)
    data = [];
    pause(3.5);
    [trigger_end_time, ~, ~, ~] = bbci_acquire_bv(state);
    data = [data; trigger_end_time];
    data = data(end-len:end, :);
end