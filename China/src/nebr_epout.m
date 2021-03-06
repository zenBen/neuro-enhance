%% Configure pipe to perform final bad epoch detection and grand avg export
function [Cfg, out] = nebr_epout(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'epout';
    Cfg.srcid= {'pipe1#pipe2A#pipe3A#1_chan_corr_vari'...
                'pipe1#pipe2A#pipe3B#1_chan_corr_maha'...
                'pipe1#pipe2B#pipe3A#1_chan_corr_vari'...
                'pipe1#pipe2B#pipe3B#1_chan_corr_maha'...
                'pipe1#pipe2C#pipe3A#1_chan_corr_vari'...
                'pipe1#pipe2C#pipe3B#1_chan_corr_maha'};
    if isfield(Cfg, 'pipe_src')
        idx = Cfg.pipe_src{ismember(Cfg.pipe_src(:,1), mfilename), 2};
        Cfg.srcid = Cfg.srcid(idx);
    end


    %%%%%%%% Define contingent parameters %%%%%%%%
    time = [[-100 500];%parameterise this in case needs changed later
            [-100 500];
            [-100 500];
            [-50 350]];
    evtype = {{{'DI51'}
              {'DIN1' 'DIN2' 'DIN3' 'DIN4' 'DIN5' 'DIN6' 'DIN7' 'DIN8' 'DIN9' 'DI10' 'DI11' 'DI12' 'DI13' 'DI14' 'DI15' 'DI16' 'DI17' 'DI18' 'DI19' 'DI20' 'DI21' 'DI22' 'DI23' 'DI24' 'DI25' 'DI26' 'DI27' 'DI28' 'DI29' 'DI30' 'DI31' 'DI32' 'DI33' 'DI34'}
              {'D101' 'D102' 'D103' 'D104' 'D105' 'D106' 'D107' 'D108' 'D109' 'D110' 'D111' 'D112' 'D113' 'D114' 'D115' 'D116' 'D117' 'D118' 'D119' 'D120' 'D121' 'D122' 'D123' 'D124' 'D125' 'D126' 'D127' 'D128' 'D129' 'D130' 'D131' 'D132' 'D133' 'D134'}};
            {'DIN5' 'DIN2' 'DIN3' 'DIN8' 'DIN4' 'DIN6' 'DIN7' 'DIN9' 'DIN1'};
            {{'DIN1'}
            {'DI21' 'DI31'}
            {'DI22' 'DI32'}};
            {{'DIN1'}
            {'DIN2'}
            {'DIN3'}
            {'DIN4'}
            {'DIN5'}
            {'DIN6'}
            {'DIN7'}
            {'DIN8' 'DIN9'}
            {'D101' 'DI10'}}};
    newevs = {{'std' 'novel' 'pic'}
        {'dur' 'freq1' 'freq2' 'gap' 'int' 'loc1' 'loc2' 'novel' 'stand'}
        {'std' 'AV_same' 'AV_diff'}
        {'std_key' 'std_rhythm' 'std' 'std_timbre' 'key' 'melody' 'tune' 'timbre' 'rhythm'}};
    match = {'exact' 'exact' 'exact' 'exact'};
    protos = {'AV' 'MULT' 'ATTE' 'MUSM'};
    pix = cellfun(@(x) contains(Cfg.MC.export_name_root, x), protos);
    epoch_evtype = {unpackCellStr(evtype(pix))};


    %%%%%%%% Define pipeline %%%%%%%%
    i = 1; %next stepSet
    stepSet(i).funH = { @CTAP_reref_data,...
                        @CTAP_event_agg,...
                        @CTAP_epoch_data,...
                        @CTAP_detect_bad_epochs,...
                        @CTAP_reject_data };
    stepSet(i).id = [num2str(i) '_epoch'];

    i = i + 1; %next stepSet
    stepSet(i).funH = repmat({@CTAP_export_data}, 1, numel(newevs{pix}));
    stepSet(i).id = [num2str(i) '_export'];
    stepSet(i).save = false;

    out.reref_data = struct(...
        'reference', 'average');
    
    out.epoch_data = struct(...
        'method', 'epoch',...
        'match',  match{pix},...
        'timelim', time(pix, :),...
        'evtype', epoch_evtype);

    out.detect_bad_epochs = struct(...
        'channels', {{'E4' 'E5' 'E6' 'E7' 'E11' 'E12' 'E13' 'E19' 'E20' 'E24'...
        'E29' 'E30' 'E36' 'E104' 'E105' 'E106' 'E111' 'E112' 'E118' 'E124'}},...
        'method', 'eegthresh',...
        'uV_thresh', [-100 100]);
    %TODO: Use EGI-chlocs for selected channels to include

    out.event_agg = struct(...
        'evtype', evtype(pix),...
        'newevs', newevs(pix),...
        'match', match{pix});

%    out.export_data = struct(...
%        'type', 'mul',...
%        'outdir', fullfile('exportRoot', ['MUL_EXPORT_' protos{pix}]),...
%        'lock_event', newevs{pix});

    out.export_data = struct(...
        'type', 'hdf5',...
        'outdir', fullfile('exportRoot', ['HDF5_EXPORT_' protos{pix}]),...
        'lock_event', newevs{pix});

    %%%%%%%% Store to Cfg %%%%%%%%
    if isfield(Cfg, 'pipe_stp')% step sets to run, default: whole thing
        idx = Cfg.pipe_stp{ismember(Cfg.pipe_stp(:,1), mfilename), 2};
        Cfg.pipe.runSets = {stepSet(idx).id};
    else
        Cfg.pipe.runSets = {stepSet(:).id};
    end
    Cfg.pipe.stepSets = stepSet;
end
