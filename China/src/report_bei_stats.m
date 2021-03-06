function [treeStats, treeRej, bestpipe] = report_bei_stats(anew, plvls)

%% INIT
if nargin < 1, anew = false; end

%specify pipe levels, groups, and protocols
if nargin < 2
    plvls = {{'2A' '2B' '2C'}; {'3A' '3B'}; {'epout'}};
end
grps = {'Control'  'English'  'Music'};
cnds = {'atten' 'AV' 'multi' 'melody'};

%make paths
name = './';
ind = fullfile(name, 'China', 'ANALYSIS', 'neuroenhance_bei_pre');
oud = fullfile(ind, ['STAT_REP_' myToString(unpackCellStr(plvls))]);
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


%% CALL FUNCTIONS TO READ & PROCESS STATS LOGS
[treeStats, ~] = ctap_get_peek_stats(ind, oud, 'anew', anew...
                                    , 'post_pipe_part', 'peekpipe/this/');
[treeStats, new_rows] = ctap_compare_branchstats(treeStats, grps, cnds...
                                                    , plvls(1:2), 1:9, 1:9);
save(fullfile(oud, 'peek_stats.mat'), 'treeStats', 'new_rows')


%% CALL FUNCTIONS TO READ & PROCESS REJECTION LOGS
[treeRej, ~] = ctap_get_rejections(ind, oud, 'anew', anew...
                        , 'post_pipe_part', 'this/logs/all_rejections.txt');
treeRej = ctap_parse_rejections(treeRej, grps, cnds, 1:9);
treeRej = ctap_compare_branch_rejs(treeRej, grps, cnds, plvls);
save(fullfile(oud, 'rej_stats.mat'), 'treeRej')


%% JUDGEMENT : THE COMBININING
ctap_get_bestpipe(treeStats, treeRej, oud, plvls, 'anew', anew)
