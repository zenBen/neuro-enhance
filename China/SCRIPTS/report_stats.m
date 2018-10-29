%% INIT
%make paths
proj = fullfile('PROJECT_NEUROENHANCE', 'China', 'ANALYSIS', 'neuroenhance_bei_pre');
ind = fullfile(filesep, 'media', 'ben', 'Maxtor', proj);
oud = fullfile(filesep, 'home', 'ben', 'Benslab', proj);
if ~isfolder(fullfile(oud, 'STAT_HISTS'))
    mkdir(fullfile(oud, 'STAT_HISTS'))
end
%spec groups and protocol conditions
grps = {'Control'  'English'  'Music'};
cnds = {'atten' 'AV' 'multi' 'melody'};
plotnsave = false;


%% FIND PEEK STAT FILES 
if exist(fullfile(oud, 'peek_stat_files.mat'), 'file') == 2
    load(fullfile(oud, 'peek_stat_files.mat'))
else
    % This takes about 20 mins
    peek_stat_files = subdir(fullfile(ind, 'peek_stats_log.xlsx'));
    save(fullfile(oud, 'peek_stat_files.mat'), 'peek_stat_files')
end


%% READ PEEK STAT FILES 
if exist(fullfile(oud, 'peek_stats.mat'), 'file') == 2
    load(fullfile(oud, 'peek_stats.mat'))
else
    % This takes about 6 hours! because 'readtable()' takes a LONG time.
    %read list of subjects per group
    sbjXgrp = readtable(fullfile(oud, 'subjectXgroup.csv'));
    %create & fill structure of peek stat tables per participant/recording
    tmp = fieldnames(peek_stat_files);
    tmp = cellfun(@(y) strrep(y, 'peekpipe/this/logs/peek_stats_log.xlsx', '')...
        , cellfun(@(x) strrep(x, ind, '')...
        , struct2cell(rmfield(peek_stat_files, tmp(2:end))), 'Un', 0), 'Un', 0);
    treeStats = cell2struct(tmp, 'pipename', 1);
    for pidx = 1:numel(peek_stat_files)
        [isxl, xlsheets] = xlsfinfo(peek_stat_files(pidx).name);
        xlsheets = xlsheets(~startsWith(xlsheets, 'Sheet'));
        for sid1 = 1:numel(xlsheets)
            treeStats(pidx).pipe(sid1).sbjXpro = xlsheets{sid1};
            treeStats(pidx).pipe(sid1).stat =...
                readtable(peek_stat_files(pidx).name...
                , 'ReadRowNames', true...
                , 'Sheet', xlsheets{sid1});
        end
    end
    save(fullfile(oud, 'peek_stats.mat'), 'treeStats', 'sbjXgrp')
end


%% GET COMPARISON DATA
if exist(fullfile(oud, 'peek_stats.mat'), 'file') == 2
    load(fullfile(oud, 'peek_stats.mat'))
else
    %% COMPARING
    lvl = [3 4 6 7];
    lvl_nms = {'p1_p2A3A' 'p1_p2A3B' 'p1_p2B3A' 'p1_p2B3B'};
    MATS = cell(1, 4);
    vnmi = treeStats(1).pipe(1).stat.Properties.VariableNames;
    
    for g = 1:numel(grps)
        tmp = table2array(sbjXgrp(:, grps{g}));
        tmp(isnan(tmp)) = [];
        for c = 1:numel(cnds)
            for s = 1:numel(tmp)
                sid1 = startsWith({treeStats(1).pipe.sbjXpro}, num2str(tmp(s))) &...
                    contains({treeStats(1).pipe.sbjXpro}, cnds{c}, 'Ig', true);
                if ~any(sid1), continue; end
                for ldx = 1:numel(lvl)
                    sbjXpro = {treeStats(lvl(ldx)).pipe.sbjXpro};%basis measurement subj
                    sidx = startsWith(sbjXpro, num2str(tmp(s))) &...
                            contains(sbjXpro, cnds{c}, 'IgnoreCase', true);
                    if ~any(sidx), continue; end
                    [MATS{ldx}, nrow, nvar] = ctap_compare_stat(...
                        treeStats(1).pipe(sid1).stat...
                        , treeStats(lvl(ldx)).pipe(sidx).stat);
                    if plotnsave
                        fh = ctap_stat_hists(MATS{ldx}, 'xlim', [-1 1]);
                        print(fh, '-dpng', fullfile(oud, 'STAT_HISTS'...
                            , sprintf('%s_%s_%s_%s_stats.png', grps{g}...
                            , cnds{c}, num2str(tmp(s)), lvl_nms{ldx})))
                    end
                    treeStats(lvl(ldx) + 5).pipename = lvl_nms{ldx};
                    treeStats(lvl(ldx) + 5).pipe(sidx).sbjXpro = sbjXpro{sidx};
                    treeStats(lvl(ldx) + 5).pipe(sidx).stat = MATS{ldx};
                end
                % make entry holding best pipe info
                treeStats(10).pipename = 'best_pipes';
                treeStats(10).pipe(sidx).sbjXpro = sbjXpro{sidx};
                treeStats(10).pipe(sidx).subj = num2str(tmp(s));
                treeStats(10).pipe(sidx).group = grps{g};
                treeStats(10).pipe(sidx).proto = cnds{c};
                MATS = cellfun(@(x) x{:,:}, MATS, 'Un', 0);
                MAT = reshape(cell2mat(MATS), nrow, nvar, numel(MATS));
                [treeStats(10).pipe(sidx).stat, I] = max(MAT, [], 3);
                [~, sortn] = sort(hist(I(:), numel(unique(I))), 'descend');
                bestn = mode(I, [1 2]);
                treeStats(10).pipe(sidx).best = lvl_nms{bestn};
                treeStats(10).pipe(sidx).bestn = bestn;
                treeStats(10).pipe(sidx).best2wrst = sortn;
            end
        end
    end
    save(fullfile(oud, 'peek_stats.mat'), 'treeStats', 'sbjXgrp')
end


%% SCRATCH
for g = grps
    ix = ismember({treeStats(10).pipe.group}, g);
    dat = [treeStats(10).pipe(ix).bestn];
    figure('Name', g{:}); hist(dat, numel(unique(dat)));
end
for c = cnds
    ix = ismember({treeStats(10).pipe.proto}, c);
    dat = [treeStats(10).pipe(ix).bestn];
    figure('Name', c{:}); hist(dat, numel(unique(dat)));
end