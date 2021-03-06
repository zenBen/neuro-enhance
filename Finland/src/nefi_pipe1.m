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
                        @CTAP_load_chanlocs,...
                        @CTAP_load_events };
    stepSet(i).id = [num2str(i) '_load'];

    % Shape the data
    i = i + 1; %stepSet 2
    stepSet(i).funH = { @CTAP_select_evdata,...
                        @CTAP_resample_data,...
                        @CTAP_reref_data,...
                        @CTAP_fir_filter,...
                        @CTAP_fir_filter,...
                        @CTAP_blink2event,...
                        @CTAP_run_ica };
    stepSet(i).id = [num2str(i) '_shape'];

    out.load_events = struct(...
        'method', 'handle',...
        'handle', @neuroenhance_preslog,...
        'src', Cfg.env.paths.logFiles);
    
    out.select_evdata = struct(...
        'covertype', 'total');

    out.load_chanlocs = struct(...
        'overwrite', true,...
        'index_match', false);
    out.load_chanlocs.tidy = {'type' 'ACCEL'};
    %we write type 'EEG' for all channels (must be 1st), then overwrite subsets
    out.load_chanlocs.field = {...
        {{'all'} 'type' 'EEG'}...
        {{'VEOG'} 'type' 'EOG'}...
        {{'RM' 'LM'} 'type' 'REF'}...
        {{'x_dir' 'y_dir' 'z_dir'} 'type' 'ACCEL'}};
    
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
