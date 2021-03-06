% Reading Presentation log for Viertola paradigms
% 
% AUTHOR     jenni.saaristo@helsinki.fi
% DATE       7.2.18
% VERSION    1.4
% NOTES      code and type switched, tolerance for additions modified
% Tommi muokkasi 14.3.2018: rivit 354-357 (unhandled indices)

function [eegfile, allclear, pres, eegfname] = combine_events(...
                                    eegfile, logfile, isswitch, prompt, auto)

if nargin < 3, isswitch = false; end
if nargin < 4, prompt = false; end
if nargin < 5, auto = true; end
                                    
% Get files
try
    if ischar(eegfile)
        [eegpath, eegfname, ext] = fileparts(eegfile);
        eegfile = ctapeeg_load_data(eegfile);
    elseif isstruct(eegfile)
        eegfname = eegfile.setname;
        ext = '.set';
    end
    if ischar(logfile)
        [~, logfname, lgx] = fileparts(logfile);
        logfname = [logfname lgx];
        logfile =...
            loadtxt(logfile, 'delim', 9, 'skipline', -2 , 'verbose', 'off');
    elseif iscell(logfile)
        logfname = '(given cell array)';
    end
    disp(['Writing ' logfname ' events onto triggers of ' eegfname '.' ext])
catch ME
    if strcmp('No such file or directory', ME.message)
        warning('Wrong filenames! See headerfile (below) for correct ones.')
        %TODO: make this work for generic data
        hdr = readbvconf(eegpath, eegfile);
        disp(hdr.commoninfos);
        if ~prompt
            warning('Skipping file %s.', [eegfname ext]);
        end
    else
        rethrow(ME);
    end
    allclear = 0;
    pres = [];
    return;
end


% Clean log
pres = clean_log(logfile, prompt);

% If protocol is switching, separate pictures
if isswitch
    [pres, ~] = separate_pictures(pres);
end

% Discrepancies?
disp(['There are ' int2str(length(eegfile.event)-1) ' eeg triggers.'])
disp(['There are ' int2str(length(pres.type)) ' logged events.'])


% Syncing and matching events
tryagain = 1;
while tryagain
    allclear = 1;
    
    % Define the tolerance
    tolr = 11;
    % If in prompt mode
    if prompt
        tolr = input(['How many samples of tolerance for matching?'...
                                        ' (To use default 11, press Enter): ']);
        if isempty(tolr) || ~(isnumeric(tolr))
           tolr = 11;
        end
    end
    
    % Define the event no to be used for syncing (in eeg data):
    syncevt = 2;
    % If auto, try all events for sync and use whichever gives minimum drift:
    if auto
        mincnt = min((length(eegfile.event) - 1), length(pres.type));
        syncrs = syncevt:mincnt;
        drifts = NaN(1, numel(syncrs));
        for s = 1:numel(syncrs)
            [~, drift] = calculate_latencies(...
                        eegfile.event, pres, syncrs(s), eegfname, prompt);
            drifts(s) = mean(abs(drift));
        end
        syncevt = syncrs(find((drifts < tolr), 1));
%         [mindr, ix] = min(drifts);
%         if mindr < tolr
%             syncevt = syncrs(ix);
%         end
    end
    % If in prompt mode just ask the user:
    if prompt
        syncevt = input(['Which eeg trigger no. should be used for syncing?'...
                                        ' (To use default, press Enter): ']);
        if isempty(syncevt) || ~(isnumeric(syncevt))
            syncevt = 2;
        end
    end
        
    % Try to sync
    pres.newlatency = calculate_latencies(...
                        eegfile.event, pres, syncevt, eegfname, prompt);

    % Try to match
    [newevent, bad_log_ind, bad_eeg_ind] = match_events(...
                        eegfile.event, pres, tolr, syncevt, prompt);
    
    % If there was trouble and not in prompt mode, exit immediately
    if isempty(newevent) && ~prompt
        allclear = 0;
        eegfile = [];
        warning('Matching unsuccessful with %s. Quitting.', eegfile)
        return
    end
    
    % See if unresolved events can be safely added
    if ~isempty(newevent)
        add_ok = true;
        if sum(bad_log_ind) > 1
            [add_ok, not_ok_mask] = check_adding(bad_log_ind, pres, tolr);
            allclear = add_ok;
        end
        if sum(bad_eeg_ind) > 1
            warning('Unresolved eeg triggers remain. They will be ignored.');
            allclear = 0;
        end
    end
    
    tryagain = 0;
    % Allow for retry or termination (in prompt mode)
    if isempty(newevent) && prompt
        inp = input('Press Enter to try match again or [x] to give up. ', 's');
        if strcmp(inp, 'x')
            disp('Quitting.');
            allclear = 0;
            eegfile = [];
            return;
        else
            tryagain = 1;
        end
    elseif prompt
        inp = input(['Press Enter to proceed, [a] to try matching again'...
                                                ', or [x] to give up. '], 's');
        if strcmp(inp, 'x')
            disp('Quitting.');
            allclear = 0;
            eegfile = [];
            return;
        elseif isempty(inp)
            tryagain = 0;
        end
    end
end

% Replace old events with new
if prompt
    disp('Replacing old event table...')
end
eegfile.event = newevent;
if prompt
    disp('Done.')
end
% NOTE: urevents are not modified!! Should they be?
% If yes, the whole match_events function needs overhaul!

% Add unresolved log events to eeg
if sum(bad_log_ind) > 1 && ~add_ok && prompt
    inp = input(['Some events cannot be added. Press [a] if you want to add'...
                        ' what can be added, otherwise press Enter. '], 's');
    if strcmp(inp, 'a')
        bad_log_ind = bad_log_ind & ~not_ok_mask;
        add_ok = 1;
    end
elseif sum(bad_log_ind) > 1 && ~add_ok && ~prompt
    % There really should be a log written about these troublemakers!!
    disp('Note: Unadded events remain. Check indices is strongly recommended!');
    disp(find(bad_log_ind & not_ok_mask))   ;
end

if sum(bad_log_ind) > 1 && add_ok
    eegfile = add_unresolved(eegfile, bad_log_ind, syncevt, tolr, pres, prompt);
end
% NOTE: Pictures in switching are not added!! Should they be?
% Function above is defined with varargin to enable adding this later

disp(['Finished! Allclear is ', int2str(allclear)]);

end % combine_events()


%% clean_log()
function pres = clean_log(fields, prompt)

    if prompt
        disp('Cleaning Presentation log...')
    end

    data = fields(2:end, :);
    fields = fields(1, :);

    % Find columns
    i_type = ismember(fields, 'Event Type');
    i_code = ismember(fields, 'Code');
    i_latency = ismember(fields, 'Time');
    i_dur = ismember(fields, 'Duration');

    % Copy and clean
    lat = data(:, i_latency);

    indend = find(cell2mat(cellfun(...
                    @(x) ~isnumeric(x) | isempty(x), lat, 'Un', 0)), 1) - 1;
    if isempty(indend)
        indend = length(lat);
    end

    latency = cell2mat(lat(1:indend));
    type = data(1:indend, i_type);
    code = data(1:indend, i_code);
    duration = data(1:indend, i_dur);

    % replace empty duration cells with zeros
    duration(cell2mat(cellfun(@isempty, duration, 'Un', 0))) = {0};
    duration = cell2mat(duration);

    if prompt
        disp('Done.')
    end

    % Create table
    pres = table;
    pres.latency = latency;
    pres.duration = duration;
    pres.type = type;
    pres.code = code;

end % clean_log()


%% separate_pictures()
function [pres, pres_pics] = separate_pictures(pres)

    % How many pictures
    pic_ind = false(1,length(pres.type));
    for i  = 1:length(pres.type)
        if strcmp(pres.type{i}, 'Picture')
            pic_ind(i) = 1;
        end
    end

    pres_pics = pres(pic_ind,:);
    pres = pres(~pic_ind,:);

end % separate_pictures()


%% calculate_latencies()
function [newlatency, drifts] = calculate_latencies(...
                                        event, pres, syncevent, eegname, prompt)

    if prompt
        disp('Calculating latencies and drifts...')
    end

    offest = event(syncevent).latency - pres.latency(1) * 0.05;
    
    newlatency = int64((pres.latency .* 0.05) + offest);

    % See whether there are drifts
    drifts = zeros(1, length(newlatency));
    for i = 1:min(length(event) - syncevent, length(newlatency))
        drifts(i) = event(syncevent - 1 + i).latency - newlatency(i);
    end

    if prompt
        disp('Done.')
    end

    % Show plot (only in prompt mode)
    if prompt
        figure;
        plot(drifts);
        title(['Drifts between eeg triggers and log events, ', eegname]);
        xlabel('log event no.');
        ylabel('drift (samples)');
        disp('Note: Drifts are expected if amounts of triggers don''t match.')
    end

end % calculate_latencies()


%% match_events
function [newevent, bad_log_ind, bad_eeg_ind] = match_events(...
                                event, pres, tolerance, syncevent, prompt)
    newevent = event;

    if prompt
        disp('Matching coincident events...')
    end

    lkg_j = syncevent-1;
    bad_log_ind = false(length(pres.newlatency), 1);
    for i = 1:length(pres.newlatency)
        % if no more event triggers in eeg, stop
        if lkg_j > length(newevent)
            disp(['Stopping at log index ', num2str(i)]);
            break;
        end
        for j = lkg_j+1:length(newevent)
            % a match (inside tolerance limits) and copy
            if abs(newevent(j).latency - pres.newlatency(i)) < tolerance
                % fun stuff bc of editeventvals function!
                if isnumeric(pres.code{i})
                    newevent(j).type = int2str(pres.code{i});
                else
                    newevent(j).type = pres.code{i};
                end
                newevent(j).code = pres.type{i};
                newevent(j).duration = pres.duration(i);
                % a new last known good index
                lkg_j = j;
                break;
            end
            % way past useful tolerance -> give up
            if newevent(j).latency - pres.newlatency(i) > 50
                bad_log_ind(i) = 1;
                if sum(bad_log_ind) < 10
                    disp(['Giving up on log index ', num2str(i)]);
                elseif sum(bad_log_ind) == 10
                    disp('...etc');
                elseif sum(bad_log_ind) > 40
                    disp('More than 40 unresolved log events: giving up.');
                    newevent=[]; bad_log_ind=[]; bad_eeg_ind=[];
                    return;
                end
                break;
            end
        end
    end

    if prompt
        disp('Done.')
    end

    % Unresolved eeg triggers
    bad_eeg_ind = zeros(numel(syncevent:length(newevent)), 1);
    for i = syncevent:length(newevent)
        if newevent(i).duration == 1
            bad_eeg_ind(i) = 1;
        end
    end


    disp(['There are ' int2str(sum(bad_eeg_ind)-1) ' unresolved eeg triggers.'])
    disp(['There are ' int2str(sum(bad_log_ind)-1) ' unresolved log events.'])

end % match_events()


%% check_adding()
function [add_ok, not_ok_mask] = check_adding(bad_log_vec, pres, tolerance)

    bad_log_ind = find(bad_log_vec);
    % Calculate minimum distance to neighbours
    min_dists = bad_log_ind;
    for i = 2:length(bad_log_ind)
        j = bad_log_ind(i);
        if j < size(pres.newlatency,1) && j > 1
            lats = pres.newlatency(j-1:j+1);
            min_dists(i) = floor(min([lats(2) - lats(1) lats(3) - lats(2)]));
        end
    end
    add_ok = max(min_dists) < tolerance;

    % Info and note the bad indices
    not_ok_mask = bad_log_vec & 0;
    if add_ok
        disp('All unresolved log events can be added to the data.')
    else
        not_ok_mask(bad_log_ind(min_dists >= tolerance)) = 1;
        warning('%d log events cannot be added to the data.', sum(not_ok_mask))
        disp(pres(bad_log_vec & not_ok_mask, :))
    end

end


%% add_unresolved()
function EEG = add_unresolved(EEG, bad_log_ind, syncevent, tolr, pres, prompt)

    bad_log_ind(find(bad_log_ind, 1)) = 0;
    badpres = pres(bad_log_ind, :);

    if prompt
        disp('Adding unresolved events...');
    end

    %TODO (??): FIX THIS TO INCLUDE MULTIPLE ADDITIONS !!
    % Add events with eeg-derived latencies
    lkg_j = syncevent-1;
    for i = 1:height(badpres)
        % if no more event triggers in eeg, stop
        if lkg_j > length(EEG.event)
            break
        end
        for j = lkg_j+1:length(EEG.event)
            % a match --> add event
            if abs(EEG.event(j).latency - badpres.newlatency(i)) < tolr
                eegtime = EEG.event(j).latency;
%                 row = badpres(i,:);
                % more fun stuff bc of editeventvals!
                code = badpres.code{i};
                if isnumeric(code)
                    code = int2str(code);
                end
                type = badpres.type{i};
                if isnumeric(type)
                    type = int2str(type);
                end
                dur = badpres.duration(i) / EEG.srate;
                % index latency duration channel bvtime bvmknum type code
                EEG = pop_editeventvals(EEG, 'add', {...
                    j+1 eegtime/EEG.srate dur 0 [] 0 type code});
                if prompt
                    disp(['Event was added at latency ' int2str(eegtime) '.']);
                end
                % a new last known good index
                lkg_j = j-1;
                break
            end
            % way past useful tolerance -> give up
            if EEG.event(j).latency - badpres.newlatency(i) > 50
                disp('Trouble! This should not happen - event not added!');
                break
            end
        end
    end

    if prompt
        disp('Done.')
    end

end
