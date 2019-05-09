%% INIT
%make paths
name = 'project_NEUROENHANCE';
% name = 'neuroenhance';
proj = fullfile(name, 'China', 'ANALYSIS', 'neuroenhance_bei_pre');
ind = fullfile(filesep, 'media', 'bcowley', 'Maxtor', proj);
oud = fullfile(filesep, 'home', 'bcowley', 'Benslab', proj, 'STAT_REP');
% ind = fullfile(filesep, 'wrk', 'grp', proj);
% oud = fullfile(ind, 'STAT_REP');

% if ~isfolder(oud), mkdir(oud); end
% if ~isfolder(fullfile(oud, 'STAT_HISTS'))
%     mkdir(fullfile(oud, 'STAT_HISTS'))
% end

%specify groups, protocols, and pipe levels
grps = {'Control'  'English'  'Music'};
cnds = {'atten' 'AV' 'multi' 'melody'};
plvls = {{'2A' '2B'}; {'3A' '3B'}; {'epout'}};
plotnsave = false;

% READ SUBJxGROUP INFO
if exist(fullfile(oud, 'subjectXgroup.mat'), 'file') == 2
    load(fullfile(oud, 'subjectXgroup.mat'))
else
    %read list of subjects per group
%     [p, ~, ~] = fileparts(mfilename('fullpath'));
%     sbjXgrp = fullfile(p, '..', 'meta', 'subjectXgroup.csv');
%     if exist(sbjXgrp, 'file') ~= 2
%         error('report_bei_stats:no_meta', '%s is not found', sbjXgrp)
%     end
    sbjXgrp = map_bei_subj_grps;
    save(fullfile(oud, 'subjectXgroup.mat'), 'sbjXgrp')
end


%% CALL FUNCTIONS TO READ & PROCESS STATS LOGS
[treeStats, peek_stat_files] = ctap_get_peek_stats(ind, oud...
                                    , 'post_pipe_part', 'peekpipe/this/');
[treeStats, nups] = ctap_compare_branchstats(treeStats, grps, cnds...
                                                    , plvls(1:2), 1:9, 1:9);


%% CALL FUNCTIONS TO READ & PROCESS REJECTION LOGS
[treeRej, rej_files] = ctap_get_rejections(ind, oud...
                        , 'post_pipe_part', 'this/logs/all_rejections.txt');
treeRej = ctap_parse_rejections(treeRej, grps, cnds, 1:9);
treeRej = ctap_compare_branch_rejs(treeRej, grps, cnds, plvls);


%% JUDGEMENT : THE COMBININING
if exist(fullfile(oud, 'best_pipe.mat'), 'file') == 2
    load(fullfile(oud, 'best_pipe.mat'))
else
    %% BUILD IT
    % SET UP PIPE NAMES
    plvlcombo = allcomb(plvls{:});
    pn = size(plvlcombo);
    lvl_nms = cell(1, pn(1));
    for pidx = 1:pn(1)
        lvl_nms{pidx} = ['p1_p' [plvlcombo{1, :}]];
    end

    bestpipe = struct;
    thr = 20;
    for idx = 1:numel(treeRej(end).pipe)
        if treeRej(end).pipe(idx).subj ~= treeStats(end).pipe(idx).subj
            error('something has gone terribly wrong')
        else
            bestpipe(idx).subj = treeStats(end).pipe(idx).subj;
            bestpipe(idx).group = treeStats(end).pipe(idx).group;
            bestpipe(idx).proto = treeStats(end).pipe(idx).proto;
        end
        rejn = treeRej(end).pipe(idx).bestn;
        stan = treeStats(end).pipe(idx).bestn;
        bestpipe(idx).rejbest = rejn;
        bestpipe(idx).statbst = stan;
        
        [rejrank, rjix] = sort(treeRej(end).pipe(idx).badness);
        [srank, stix] = sort(treeStats(end).pipe(idx).mean_stats, 'descend');
        for p = 1:numel(plvls)
            piperank(p) = find(rjix == p) + find(stix == p);
        end
        bestix = find(piperank == min(piperank));
        if numel(bestix) > 1
            [~, bestix] = min(rejrank(bestix));
        end
        bestpipe(idx).bestpipe = bestix;

        if any(ismember(rejn, stan))
            bestpipe(idx).bestn = rejn(ismember(rejn, stan));
        else
            bestpipe(idx).bestn = stan;
        end
% TODO - THIS IS RESTRICTED TO FIRST TWO LEVELS OF BADNESS: EXTEND!?
        bestpipe(idx).badness1 = treeRej(end).pipe(idx).badness(bestix);
        bestpipe(idx).badness2 =...
                       treeRej(end).pipe(idx).badness(bestpipe(idx).bestn);
        bestpipe(idx).stat1 = treeStats(end).pipe(idx).mean_stats(bestix);
        bestpipe(idx).stat2 =...
                  treeStats(end).pipe(idx).mean_stats(bestpipe(idx).bestn);
    end
    save(fullfile(oud, 'best_pipe.mat'), 'bestpipe')
end


%% GROUP-WISE AND CONDITION-WISE HISTOGRAMS OF PIPE STATS
pidx = nups(end);
for g = grps
    ix = ismember({treeStats(pidx).pipe.group}, g);
    dat = [treeStats(pidx).pipe(ix).bestn];
    figure('Name', g{:}); hist(dat, numel(unique(dat)));
end
for c = cnds
    ix = ismember({treeStats(pidx).pipe.proto}, c);
    dat = [treeStats(pidx).pipe(ix).bestn];
    figure('Name', c{:}); hist(dat, numel(unique(dat)));
end


%% SCRATCH

for pidx = 1:numel(peek_stat_files)
    peek_stat_files(pidx).name = strrep(peek_stat_files(pidx).name...
                            , 'neuroenhance_base', 'neuroenhance_bei_pre');
    peek_stat_files(pidx).folder = strrep(peek_stat_files(pidx).folder...
                            , 'neuroenhance_base', 'neuroenhance_bei_pre');
end