%% INIT
%specify groups, protocols, and pipe levels
grps = {'Control'  'English'  'Music'};
cnds = {'atten' 'AV' 'multi' 'melody'};
% plvls = {{'2A' '2B' '2C'}; {'3A' '3B'}; {'epout'}};
plvls = {{'2A' '2C'}; {'3A' '3B'}; {'epout'}};

%make paths
oudyn = ['STAT_REP_' myToString(unpackCellStr(plvls))];
proj = fullfile('project_NEUROENHANCE', 'China', 'ANALYSIS', 'neuroenhance_bei_pre');
ind = fullfile('/media', 'bcowley', 'Maxtor', proj);
oud = fullfile('/home', 'bcowley', 'Benslab', proj, oudyn);
if ~isfolder(oud), mkdir(oud); end

% READ SUBJxGROUP INFO
if exist(fullfile(oud, 'subjectXgroup.mat'), 'file') == 2
    sbjXgrp = load(fullfile(oud, 'subjectXgroup.mat'));
    sbjXgrp = sbjXgrp.sbjXgrp;
else
    %read list of subjects per group
    sbjXgrp = map_bei_subj_grps;
    save(fullfile(oud, 'subjectXgroup.mat'), 'sbjXgrp')
end

anew = true;


%% CALL FUNCTIONS TO READ & PROCESS STATS LOGS
[treeStats, peek_stat_files] = ctap_get_peek_stats(ind, oud, 'anew', anew...
                                    , 'post_pipe_part', 'peekpipe/this/');
[treeStats, new_rows] = ctap_compare_branchstats(treeStats, grps, cnds...
                                                    , plvls(1:2), 1:9, 1:9);


%% CALL FUNCTIONS TO READ & PROCESS REJECTION LOGS
[treeRej, rej_files] = ctap_get_rejections(ind, oud, 'anew', anew...
                        , 'post_pipe_part', 'this/logs/all_rejections.txt');
treeRej = ctap_parse_rejections(treeRej, grps, cnds, 1:9);
treeRej = ctap_compare_branch_rejs(treeRej, grps, cnds, plvls);


%% JUDGEMENT : THE COMBININING
[bestpipe, bpTab] = ctap_get_bestpipe(treeStats, treeRej, oud, plvls, 'anew', anew);


%% GROUP-WISE AND CONDITION-WISE HISTOGRAMS OF PIPE STATS
pidx = new_rows(end);
for g = grps
    ix = ismember({treeStats(pidx).pipe.group}, g);
    dat = [treeStats(pidx).pipe(ix).bestn];
    figure('Name', g{:}); histogram(dat, numel(unique(dat)));
end
for c = cnds
    ix = ismember({treeStats(pidx).pipe.proto}, c);
    dat = [treeStats(pidx).pipe(ix).bestn];
    figure('Name', c{:}); histogram(dat, numel(unique(dat)));
end


%% SCRATCH
for pidx = 1:numel(peek_stat_files)
    peek_stat_files(pidx).name = strrep(peek_stat_files(pidx).name...
                            , 'neuroenhance_base', 'neuroenhance_bei_pre');
    peek_stat_files(pidx).folder = strrep(peek_stat_files(pidx).folder...
                            , 'neuroenhance_base', 'neuroenhance_bei_pre');
end