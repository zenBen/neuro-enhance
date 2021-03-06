function neuroenhance_branch_bei(proj_root, varargin)
%% Branching CTAP script to clean NEURO-ENHANCE Chinese PRE- POST-test data
%
% Syntax:
%   On the Matlab console, execute >> neuroenhance_branch_bei
% 
% Inputs:
%   proj_root   string, path to data: see example_starter.m for examples
% Varargin:
%   grpix       vector, group index to include, default = 1:3
%   parix       vector, paradigm index to include, default = 1:4
%   timept      scalar, time point (pre-or post-test) to attack, default = 1
%   runps       vector, pipes to run, default = all of them
%   pipesrc     cell array, sources for each pipe - to override default you 
%                           must provide as many cells of source vectors as
%                           you have pipes; easiest is to copy+modify default
%                           default = {NaN 1 1 1 1:3 1:3 1:6 1:6 1:10}
% 
%
% Version History:
% 01.09.2018 Created (Benjamin Cowley, UoH)
%
% Copyright(c) 2018:
% Benjamin Cowley (Ben.Cowley@helsinki.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


group_dir = {'control' 'english' 'music'}; %CON ENG MUS
para_dir = {'attention' 'AV' 'multiMMN' 'musmelo'}; %ATTE AV MULT MUSM

% use ctapID to uniquely name the base folder of the output directory tree
ctapID = {'pre' 'post'};

%Dfine pipe array
pipeArr = {@nebr_pipe1,...
           @nebr_pipe2A,...
           @nebr_pipe2B,...
           @nebr_pipe2C,...
           @nebr_pipe3A,...
           @nebr_pipe3B,...
           @nebr_epout,...
           @nebr_segcheck,...
           @nebr_peekpipe};
srcix = {NaN 1 1 1 1:3 1:3 1:6 1:6 1:10};


%% Setup MAIN parameters
p = inputParser;
p.addRequired('proj_root', @ischar)
p.addParameter('grpix', 1:3, @(x) any(x == 1:3))
p.addParameter('parix', 1:4, @(x) any(x == 1:4))
p.addParameter('timept', 1, @(x) x == 1 || x == 2)
p.addParameter('runps', 1:length(pipeArr), @(x) all(ismember(x, 1:length(pipeArr))))
p.addParameter('pipesrc', srcix, @(x) iscell(x) && numel(x) == numel(srcix))

p.parse(proj_root, varargin{:});
Arg = p.Results;


%% Runtime options for CTAP:

%You can parameterize the sources for each pipe
runps = Arg.runps;
pipe_src = [cellfun(@func2str, pipeArr, 'un', 0)', Arg.pipesrc'];

%Set timepoint here: PRE or POST...
ctapID = ctapID{Arg.timept};
timept = Arg.timept;

%Subsetting groups and paradigms
group_dir = group_dir(Arg.grpix);
para_dir = para_dir(Arg.parix);


%% Loop the available data sources
% Use non-nested loop for groups X protocols; allows parfor parallel processing
parfor (ix = 1:numel(group_dir) * numel(para_dir))
    %get sub-index S from global index G by allcomb()
    A = allcomb(1:numel(group_dir), 1:numel(para_dir));
    %First is group index:
    gix = A(ix, 1);
    %Second is protocol index
    pix = A(ix, 2);

    %Create the CONFIGURATION struct
    %First, define important paths; plus step sets and their parameters
    [Cfg, ~] = nebr_cfg(proj_root, group_dir{gix}, para_dir{pix}, ctapID);
    Cfg.pipe_src = pipe_src;

    %Then create measurement config (MC) based on a directory and filetype
    % - name the session/group, and the measurement/condition (pass cells)
    Cfg = get_meas_cfg_MC(Cfg, Cfg.env.paths.branchSource...
                , 'eeg_ext', Cfg.eeg.data_type...
                , 'session', group_dir(gix), 'measurement', para_dir(pix));
    Cfg.MC.export_name_root = sprintf('%d_%s_%s_', timept...
        , upper(group_dir{gix}(1:3)), upper(para_dir{pix}(1:min([4 end]))));

    % Run (and time) the pipe
    tic
        CTAP_pipeline_brancher(Cfg, pipeArr...
                            , 'runPipes', runps, 'dbg', false, 'ovw', true)
    toc

end

end %neuroenhance_branch_bei()
