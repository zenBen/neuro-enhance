% Master script for using combine_events.m
% Viertola project
% jenni.saaristo@helsinki.fi
% 10.11.17

% Put the folder containing combine_events.m on your Matlab path!
% Also make sure you have bva-io (in eeglab plugins) on your path.
% And, naturally, eeglab...

% Params
subjects = {'JC137','JC139','JC140','JC141','JC142','JC143','JC144','JC145'...
           ,'JC146','JC147','JC158','JC169','JC170','JC171','JD115','JD118'...
           ,'JD119','JD122','JD124','JD126','JD128','JD129','JD173','JL168'...
           ,'LA130','LA132','LA133','LA134','LA135','LA136','LA148','LA149'...
           ,'LA150','LA151','LA152','LA153','LA154','LA155','LA160','LA161'...
           ,'LA162','LA166','LA167','LB101','LB102','LB104','LB105','LB106'...
           ,'LB107','LB108','LB109','LB111','LB163','LB164','LB165','LB172'};

linux = '~/Benslab';  
proj_root = fullfile(linux, 'PROJECT_NEUROENHANCE', 'Finland', '');
datapath = fullfile(proj_root, 'FIN_PRETEST', 'Data_1', 'A_movement', 'AV');
% 'C:\Users\Tommi\Desktop\Meneill��n olevat\Tikkurila\DATA\eegdata';
logpath = fullfile(proj_root, 'FIN_PRETEST', 'Logfiles_1', 'A_movement', 'AV');
% 'C:\Users\Tommi\Desktop\Meneill��n olevat\Tikkurila\DATA\logs\';
savepath = proj_root;
% 'C:\Users\Tommi\Desktop\Meneill��n olevat\Tikkurila\DATA\newdata\';
paradigm = 'av';
% Choosing files

% Choose files via ui, or code a loop, if you want
%[bvfile, bvpath] = uigetfile('*.vhdr*; *.VHDR*', 'Select Brain Vision data file');
%[logfile, logpath] = uigetfile('*.log*; *.LOG*', 'Select Presentation log file');

% Settings

% switching paradigm requires special attention
% prompt mode asks for some parameters and allows retrying
%   -->  disable if looping
isswitch = false;
prompt = false;

% The function

% Use allclear for catching problematic files if looping
% preslog contains all events from Presentation log
%  --> use for checking if needed, otherwise discard
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
close(gcf)

for s=33%1:size(subjects,2)
    
    bvfile = [subjects{s} '_AVO.vhdr'];
    if exist(fullfile(datapath, bvfile), 'file') ~= 2
        bvfile = [subjects{s} '_AVV.vhdr'];
    end
    logfile = [subjects{s} '-AV.log'];
    eventpath = fullfile(savepath, [subjects{s} '-av-recoded.evt']);
    savename = [subjects{s} '-av-recoded.set'];
    [EEG, allclear, preslog] = combine_events(fullfile(datapath, bvfile)...
                                            , fullfile(logpath, logfile)...
                                            , isswitch...
                                            , prompt);
    %pop_expevents(EEG, eventpath, 'samples');
    if allclear == 1
        writeEVT(EEG.event, EEG.srate, eventpath, paradigm)
        %EEG = pop_saveset( EEG, 'filename',savename,'filepath',savepath);
    else
        eventpath_notOK = fullfile(savepath...
            , [subjects{s} '-av-recoded_missingTriggers.evt']);
        writeEVT(EEG.event, EEG.srate, eventpath_notOK, paradigm)
    end
end

disp('Done.')

% Check

% Check out those awesome events
%pop_eegplot(EEG);
