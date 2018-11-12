function [EEG] = neuroenhance_preslog(EEG, eventfile)

% Params



%% Settings
paradigm = {'av' 'Multi_novel' 'Switching_task'};
% switching paradigm requires special attention
para = cell2mat(cellfun(@(x) contains(eventfile, x, 'Ig', true), paradigm, 'Un', 0));
isswitch = para(3);

% prompt mode asks for some parameters and allows retrying
%   -->  disable if looping
% prompt = false;


%% Combine events in EEG
[EEG, allclear, preslog, eegfname] = combine_events(EEG, eventfile, isswitch);

[savepath, eegfn, ~] = fileparts(eegfname);
eventpath = fullfile(savepath, [eegfn '-' paradigm{para} '-recoded.evt']);
savename = [eegfn '-' paradigm{para} '-recoded.set'];

if allclear == 1
    writeEVT(EEG.event, EEG.srate, eventpath, paradigm)
    EEG = pop_saveset(EEG, 'filename', savename, 'filepath', savepath);
else
    eventpath_notOK = fullfile(savepath...
        , [eegfn '-' paradigm{para} '-recoded_missingTriggers.evt']);
    writeEVT(EEG.event, EEG.srate, eventpath_notOK, paradigm{para})
end
% end

end