%% Configure pipe 1
function [Cfg, out] = nefi_pipe1(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe1';
    Cfg.srcid = {''};

    %%%%%%%% Define pipeline %%%%%%%%
    % Load
    i = 1; %stepSet 1
    stepSet(i).funH = { @CTAP_load_data,...
                        @CTAP_clock_start,...
                        @CTAP_select_evdata,...
                        @CTAP_resample_data,...
                        @CTAP_load_chanlocs,...
                        @CTAP_reref_data,...
                        @CTAP_fir_filter,...
                        @CTAP_fir_filter,...
                        @CTAP_blink2event,...
                        @CTAP_run_ica,...
                        @CTAP_clock_stop };
    stepSet(i).id = [num2str(i) '_load'];

    out.select_evdata = struct(...
        'covertype', 'total');

    out.load_chanlocs = struct(...
        'overwrite', true,...
        'index_match', false);
    %in theory we can write a type for all channels, and then overwrite a subset
    out.load_chanlocs.field = {{{'all'} 'type' 'EEG'}...
        {{'E1' 'E33' 'E14' 'E126'} 'type' 'EOG'}};
    
    out.reref_data = struct(...
        'keepref', 'off');

    out.fir_filter = struct(...
        'locutoff', {0.5 []},...
        'hicutoff', {[] 30},...
        'filtorder', {3380 226});
    
    out.blink2event = struct(...
        'classMethod', 'emgauss_asymmetric');

    out.run_ica = struct(...
        'method', 'fastica',...
        'overwrite', true);
    out.run_ica.channels = {'EEG' 'EOG'};


    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end