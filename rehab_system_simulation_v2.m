%% Wrist-Rotation + Grip Rehab System -- Behavioural Simulation (v2)
% -------------------------------------------------------------------------
% This script SIMULATES THE SYSTEM LOGIC AND SIGNALS only.
% It does NOT perform any electrical stimulation. FES here is modelled as a
% decision ("would the controller trigger stimulation, and at what
% assistive force?") so the behaviour can be validated in software before
% any hardware is built.
%
% Task modelled: GRIP first, THEN ROTATE  (e.g. opening a bottle)
%
% CHANGES IN THIS VERSION (v2)
%   1. Voluntary movement is back to a CURVED (exponential-approach) ramp
%      toward each patient's personal ceiling -- matches the smooth,
%      asymptotic-looking traces in the reference plot, instead of the
%      straight-line ramps used previously.
%   2. FES assistance now has an escalating FORCE profile:
%         - When the controller decides a patient needs help, FES starts
%           at fesForceStart (1 N).
%         - If the target still hasn't been reached, the force is
%           increased by fesForceStep (1 N) every fesForceIncInterval
%           seconds (0.5 s), up to a safety ceiling fesForceMax (10 N).
%         - i.e. force literally climbs 1 N -> 2 N -> 3 N -> ... until the
%           patient achieves the task (or the max safe force is hit).
%   3. The system now records, per patient, how long FES had to stay on
%      (from first trigger to task success) for BOTH the grip channel and
%      the rotation channel, and reports it in the console AND as a text
%      annotation on the plots.
%   4. A 4th subplot row was added showing the FES force (N) actually
%      delivered over time, so you can see the escalation happen.
%
% LED scheme:
%   1 = Blue          -> prompt / start the attempt
%   2 = Red           -> attempting, target not yet reached
%   3 = Green (solid) -> success, VOLUNTARY (no FES used)
%   4 = Green (blink) -> success, achieved WITH FES assistance
% -------------------------------------------------------------------------

clear; clc; close all;

%% ---------------- Parameters (edit these) ----------------
dt            = 0.05;     % time step (s)
T             = 11.0;     % total simulation time (s)
gripPhaseEnd  = 4.0;      % grip attempt window ends (s)
rotPhaseEnd   = 9.0;      % rotation attempt window ends (s)

gripThreshold = 0.50;     % normalised FSR grip needed to "hold" object (0..1)
targetAngle   = 60.0;     % supination target (deg)

checkGripAt   = 2.0;      % when controller checks voluntary grip (s)
checkRotAt    = 6.5;      % when controller checks voluntary rotation (s)

% Voluntary movement is a CURVED (exponential) approach toward the
% patient's own ceiling (p.grip / p.angle). Larger alpha = faster/ more
% abrupt curve, smaller alpha = slower, lazier curve.
voluntaryGripAlpha = 0.12;   % 0..1, fraction of remaining distance closed per step
voluntaryRotAlpha  = 0.10;   % 0..1, fraction of remaining distance closed per step

% ---- Escalating FES force profile ----
fesForceStart      = 1;    % N, force the very first time FES kicks in
fesForceStep        = 1;    % N, how much the force climbs each increment
fesForceIncInterval = 0.5;  % s, how often the force is allowed to step up
fesForceMax          = 10;   % N, safety ceiling on assistive force

% How much each Newton of FES force contributes to movement per second.
% (Simple linear scaling for simulation purposes only.)
fesGripPerN = 0.15;   % grip units / s, per N of stimulation force
fesRotPerN  = 6.0;    % deg / s, per N of stimulation force

%% ---------------- Patient examples (spanning the full spectrum) ----------------
% .grip  = max grip the patient can produce voluntarily (0..1)
% .angle = max rotation the patient can reach voluntarily (deg)
patientA = struct('name','Full voluntary (no FES needed)',   'grip',0.90,'angle',75);
patientB = struct('name','Partial movement (voluntary)',     'grip',0.70,'angle',65);
patientC = struct('name','Borderline (light FES assist)',    'grip',0.48,'angle',48);
patientD = struct('name','Little movement (FES-assisted)',   'grip',0.30,'angle',32);
patientE = struct('name','No voluntary movement (full FES)', 'grip',0.00,'angle',0);

P = {patientA, patientB, patientC, patientD, patientE};
nP = numel(P);
R = cell(1,nP);
for k = 1:nP
    R{k} = simulateRep(P{k}, dt, T, gripPhaseEnd, rotPhaseEnd, ...
        gripThreshold, targetAngle, checkGripAt, checkRotAt, ...
        voluntaryGripAlpha, voluntaryRotAlpha, ...
        fesForceStart, fesForceStep, fesForceIncInterval, fesForceMax, ...
        fesGripPerN, fesRotPerN);
end

%% ---------------- Plot (grid size follows number of patients) ----------------
figure('Name','Rehab System Simulation v2','Color','w','Position',[60 60 1600 900]);
for k = 1:nP
    r = R{k};

    % Grip signal
    subplot(4,nP,k);
    plot(r.t, r.grip, 'LineWidth', 1.8); hold on;
    yline(gripThreshold, '--', 'grip target');
    shadeFES(r.t, r.fesGrip);
    title(r.name, 'FontSize', 9);
    if k == 1, ylabel('Grip (0..1)'); end
    ylim([0 1.1]); grid on;

    % Rotation signal
    subplot(4,nP,k+nP);
    plot(r.t, r.angle, 'LineWidth', 1.8); hold on;
    yline(targetAngle, '--', 'angle target');
    shadeFES(r.t, r.fesRot);
    if k == 1, ylabel('Rotation (deg)'); end
    ylim([0 targetAngle*1.25]); grid on;

    % FES force delivered
    subplot(4,nP,k+2*nP);
    stairs(r.t, r.fesGripForce, 'LineWidth', 1.6); hold on;
    stairs(r.t, r.fesRotForce, 'LineWidth', 1.6);
    if k == 1
        ylabel('FES force (N)');
        legend('grip ch1','rot ch2','Location','northwest','FontSize',7);
    end
    ylim([0 fesForceMax+1]); grid on;
    txt = sprintf('grip FES: %.1fs @ %dN\nrot FES: %.1fs @ %dN', ...
        r.fesGripDuration, r.fesGripFinalForce, r.fesRotDuration, r.fesRotFinalForce);
    text(0.3, fesForceMax*0.75, txt, 'FontSize', 7, 'Color', [0.3 0.3 0.3]);

    % LED state
    subplot(4,nP,k+3*nP);
    stairs(r.t, r.ledCode, 'LineWidth', 1.8);
    if k == 1, ylabel('LED'); end
    xlabel('Time (s)'); ylim([0.5 4.5]);
    yticks(1:4); yticklabels({'Blue','Red','Grn solid','Grn blink'}); grid on;
end
sgtitle('Grip-then-Rotate logic with escalating-force FES (curved voluntary ramps, shaded = FES active)');

%% ---------------- Console summary ----------------
for k = 1:nP
    r = R{k};
    fprintf('\n--- %s ---\n', r.name);
    fprintf('  Final grip : %.2f  (target %.2f)\n', r.grip(end),  gripThreshold);
    fprintf('  Final angle: %.1f  (target %.1f)\n', r.angle(end), targetAngle);

    if any(r.fesGrip)
        fprintf('  FES grip used    : YES  (%.2f s active, force reached %d N)\n', ...
            r.fesGripDuration, r.fesGripFinalForce);
    else
        fprintf('  FES grip used    : NO  (achieved voluntarily)\n');
    end

    if any(r.fesRot)
        fprintf('  FES rotation used: YES  (%.2f s active, force reached %d N)\n', ...
            r.fesRotDuration, r.fesRotFinalForce);
    else
        fprintf('  FES rotation used: NO  (achieved voluntarily)\n');
    end

    if any(r.fesGrip) || any(r.fesRot)
        fprintf('  RESULT: success WITH FES   -> LED = BLINKING GREEN\n');
    else
        fprintf('  RESULT: success VOLUNTARY  -> LED = SOLID GREEN\n');
    end

    if r.gripForceMaxedOut || r.rotForceMaxedOut
        fprintf('  WARNING: FES force hit the %dN safety ceiling before task success.\n', fesForceMax);
    end
end

%% ================= Local functions =================
function r = simulateRep(p, dt, T, gripPhaseEnd, rotPhaseEnd, ...
        gripThreshold, targetAngle, checkGripAt, checkRotAt, ...
        voluntaryGripAlpha, voluntaryRotAlpha, ...
        fesForceStart, fesForceStep, fesForceIncInterval, fesForceMax, ...
        fesGripPerN, fesRotPerN)

    t  = 0:dt:T;
    n  = numel(t);
    grip        = zeros(1,n);
    angle       = zeros(1,n);
    fesGrip     = false(1,n);
    fesRot      = false(1,n);
    fesGripForce = zeros(1,n);
    fesRotForce  = zeros(1,n);
    ledCode     = ones(1,n);     % default blue

    gripDone = false; rotDone = false;
    fesGripOn = false; fesRotOn = false;

    % force-escalation trackers
    gripForceVal = 0; rotForceVal = 0;
    lastGripForceIncTime = -Inf; lastRotForceIncTime = -Inf;

    % timing trackers (NaN until FES actually triggers)
    fesGripOnTime = NaN; fesGripAchieveTime = NaN;
    fesRotOnTime  = NaN; fesRotAchieveTime  = NaN;

    for i = 2:n
        ti = t(i);

        if ti <= gripPhaseEnd
            % ---- GRIP PHASE: patient tries to close the hand ----
            % Curved (exponential) voluntary approach toward the patient's ceiling.
            grip(i) = grip(i-1) + (p.grip - grip(i-1)) * voluntaryGripAlpha;

            % controller checks voluntary grip; trigger FES ch1 if short
            if ti >= checkGripAt && grip(i) < gripThreshold && ~gripDone && ~fesGripOn
                fesGripOn = true;
                gripForceVal = fesForceStart;          % force starts at 1 N
                fesGripOnTime = ti;
                lastGripForceIncTime = ti;
            end

            if fesGripOn && ~gripDone
                % escalate force 1N -> 2N -> 3N ... every fesForceIncInterval
                % seconds, until the patient succeeds or the ceiling is hit
                if (ti - lastGripForceIncTime) >= fesForceIncInterval && gripForceVal < fesForceMax
                    gripForceVal = min(gripForceVal + fesForceStep, fesForceMax);
                    lastGripForceIncTime = ti;
                end
                grip(i) = grip(i) + fesGripPerN * gripForceVal * dt;  % FES assists
                fesGrip(i) = true;
                fesGripForce(i) = gripForceVal;
            end

            if grip(i) >= gripThreshold
                grip(i)  = gripThreshold;                        % hold the object
                gripDone = true;
                if fesGripOn, fesGripAchieveTime = ti; end
                fesGripOn = false;
            end
            angle(i) = 0;                                        % no rotation yet

        elseif gripDone && ti <= rotPhaseEnd
            % ---- ROTATION PHASE: patient tries to turn the forearm ----
            grip(i)  = gripThreshold;                            % keep holding
            % Curved (exponential) voluntary approach toward the patient's ceiling.
            angle(i) = angle(i-1) + (p.angle - angle(i-1)) * voluntaryRotAlpha;

            if ti >= checkRotAt && angle(i) < targetAngle && ~rotDone && ~fesRotOn
                fesRotOn = true;
                rotForceVal = fesForceStart;
                fesRotOnTime = ti;
                lastRotForceIncTime = ti;
            end

            if fesRotOn && ~rotDone
                if (ti - lastRotForceIncTime) >= fesForceIncInterval && rotForceVal < fesForceMax
                    rotForceVal = min(rotForceVal + fesForceStep, fesForceMax);
                    lastRotForceIncTime = ti;
                end
                angle(i) = angle(i) + fesRotPerN * rotForceVal * dt;  % FES assists
                fesRot(i) = true;
                fesRotForce(i) = rotForceVal;
            end

            if angle(i) >= targetAngle
                angle(i) = targetAngle;
                rotDone  = true;
                if fesRotOn, fesRotAchieveTime = ti; end
                fesRotOn = false;
            end

        else
            % ---- hold last values ----
            grip(i)  = grip(i-1);
            angle(i) = angle(i-1);
        end

        % ---- LED state machine ----
        if ti < 0.4
            ledCode(i) = 1;                                      % blue prompt
        elseif gripDone && rotDone
            if any(fesGrip) || any(fesRot)
                ledCode(i) = 4;                                  % green blink (FES)
            else
                ledCode(i) = 3;                                  % green solid
            end
        else
            ledCode(i) = 2;                                      % red attempting
        end
    end

    % ---- summarise FES timing / force for this patient ----
    if ~isnan(fesGripOnTime) && ~isnan(fesGripAchieveTime)
        fesGripDuration = fesGripAchieveTime - fesGripOnTime;
    else
        fesGripDuration = 0;
    end
    if ~isnan(fesRotOnTime) && ~isnan(fesRotAchieveTime)
        fesRotDuration = fesRotAchieveTime - fesRotOnTime;
    else
        fesRotDuration = 0;
    end

    r = struct('name',p.name,'t',t,'grip',grip,'angle',angle, ...
               'fesGrip',fesGrip,'fesRot',fesRot, ...
               'fesGripForce',fesGripForce,'fesRotForce',fesRotForce, ...
               'fesGripDuration',fesGripDuration,'fesRotDuration',fesRotDuration, ...
               'fesGripFinalForce', max(fesGripForce), ...
               'fesRotFinalForce', max(fesRotForce), ...
               'gripForceMaxedOut', any(fesGripForce >= fesForceMax) && grip(end) < gripThreshold, ...
               'rotForceMaxedOut', any(fesRotForce >= fesForceMax) && angle(end) < targetAngle, ...
               'ledCode',ledCode);
end

function shadeFES(t, mask)
    % Shade the time windows where FES is active (light amber).
    if ~any(mask), return; end
    yl = ylim; inseg = false; x0 = t(1);
    for i = 1:numel(mask)
        if mask(i) && ~inseg
            x0 = t(i); inseg = true;
        elseif ~mask(i) && inseg
            patch([x0 t(i) t(i) x0], [yl(1) yl(1) yl(2) yl(2)], ...
                  [1 0.85 0.4], 'FaceAlpha',0.25, 'EdgeColor','none');
            inseg = false;
        end
    end
    if inseg
        patch([x0 t(end) t(end) x0], [yl(1) yl(1) yl(2) yl(2)], ...
              [1 0.85 0.4], 'FaceAlpha',0.25, 'EdgeColor','none');
    end
end
