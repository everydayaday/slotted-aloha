function [throughput, meanDelay, trafficOffered, pcktCollisionProb] = csma_ca(sourceNumber, packetReadyProb, maxBackoff, simulationTime, showProgressBar, niceOutput)
    % function [throughput, mean delay, traffic offered, packet collision probability]
    %    = csma_ca(source number,packet ready probability, maximum backoff,simulation time,
    %      show progress bar,nice output)
    %
    % +++ Function input parameters
    %
    % source number (positive integer): the number of sources that generate packets.
    %
    % packet ready probability (real, [0,1]): the probability that a given source has
    %        a packet ready to be transmitted at any given time slot.
    %
    % maximum backoff (positive integer): the maximum backoff value that a backlogged
    %        source must wait before a new transmission attempt.
    %
    % simulation time (positive integer): the duration of the simulation in time slots.
    %
    % show progress bar (optional): if true, a progress bar showing the simulation
    %        advance will be displayed. Default behaviour is showProgressBar = false
    %        for faster simulations.
    %
    % nice output (optional): if true, prints out the function outputs. Default
    %        behaviour is niceOutput = false.
    %
    % +++ Function outputs
    %
    % throughput: normalized throughput of the CSMA/CA random access protocol
    %
    % mean delay: the average delay (in slots) for a packet to be successfully
    %        transmitted (acknowledge) from the moment it is ready at the source
    %
    % traffic offered: normalized traffic offered to the system,including
    %        retransmissions
    %
    % packet collision probability: probability that a packet collides with others
    %        at any given time slot
    
    throughputArray = zeros(1, simulationTime);
    trafficOfferedArray = zeros(1, simulationTime);
    meanDelayArray = zeros(1, simulationTime);
    pcktCollisionProbArray = zeros(1, simulationTime);
    
    sourceStatus = zeros(1, sourceNumber);
    sourceBackoff = zeros(1, sourceNumber);
    pcktTransmissionAttempts = 0;
    ackdPacketDelay = zeros(1, simulationTime);
    ackdPacketCount = 0;
    pcktCollisionCount = 0;
    pcktGenerationTimestamp = zeros(1, sourceNumber);
    currentSlot = 0;
    channelBusy = false;
    
    if exist('showProgressBar','var') && showProgressBar == 1
        showProgressBar = 1;
        progressBar = waitbar(0, 'Generating traffic...', 'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
        setappdata(progressBar, 'canceling', 0);
    else
        showProgressBar = 0;
    end
    
    while currentSlot < simulationTime
        currentSlot = currentSlot + 1;
        
        if showProgressBar == 1
            if getappdata(progressBar, 'canceling')
                delete(progressBar);
                fprintf('\nWarning: terminated by user!\n');
                break
            end
            waitbar(currentSlot / simulationTime, progressBar, sprintf('Packets sent: %u; packets acknowledged: %u.', pcktTransmissionAttempts, ackdPacketCount));
        end
    
        % Check if new packets are ready to be transmitted
        for eachSource1 = 1:length(sourceStatus)
            if sourceStatus(1, eachSource1) == 0 && rand(1) <= packetReadyProb
                sourceStatus(1, eachSource1) = 1;
                sourceBackoff(1, eachSource1) = randi(maxBackoff, 1);
                pcktGenerationTimestamp(1, eachSource1) = currentSlot;
            elseif sourceStatus(1, eachSource1) == 1
                if channelBusy
                    sourceStatus(1, eachSource1) = sourceBackoff(1, eachSource1);
                else
                    sourceBackoff(1, eachSource1) = randi(maxBackoff, 1);
                end
            end
        end
        
        % Determine which sources attempt transmission
        transmitters = find(sourceStatus == 1);
        pcktTransmissionAttempts = pcktTransmissionAttempts + length(transmitters);
        
        % Handle transmissions
        if length(transmitters) == 1
            % Successful transmission
            ackdPacketCount = ackdPacketCount + 1;
            sourceId = transmitters(1);
            ackdPacketDelay(ackdPacketCount) = currentSlot - pcktGenerationTimestamp(sourceId);
            sourceStatus(sourceId) = 0;
            channelBusy = true;
        elseif length(transmitters) > 1
            % Collision occurs
            pcktCollisionCount = pcktCollisionCount + 1;
            for i = transmitters
                sourceStatus(i) = sourceStatus(i) + sourceBackoff(i);
            end
            channelBusy = false;
        else
            channelBusy = false;
        end
        
        % Decrement backoff timers
        sourceStatus(sourceStatus > 0) = sourceStatus(sourceStatus > 0) - 1;
        
        % 주요 변수 기록
        trafficOfferedArray(currentSlot) = pcktTransmissionAttempts / currentSlot;
        throughputArray(currentSlot) = ackdPacketCount / currentSlot;
        pcktCollisionProbArray(currentSlot) = pcktCollisionCount / currentSlot;
        if ackdPacketCount == 0
            meanDelayArray(currentSlot) = simulationTime;
        else
            meanDelayArray(currentSlot) = mean(ackdPacketDelay(1:ackdPacketCount));
        end
    end
    
    if currentSlot == simulationTime && showProgressBar == 1
        delete(progressBar);
    end
    
    trafficOffered = trafficOfferedArray(end);
    throughput = throughputArray(end);
    meanDelay = meanDelayArray(end);
    pcktCollisionProb = pcktCollisionProbArray(end);
    
    if exist('niceOutput', 'var') && niceOutput == 1
        fprintf('\nTraffic offered (G): %.3f,\nThroughput (S): %.3f,\nMean delay (D): %.2f slots,\nCollision probability (P_c): %.3f.\n', trafficOffered, throughput, meanDelay, pcktCollisionProb);
    end
    
    % 그래프 출력
    figure;
    subplot(2,2,1);
    plot(1:simulationTime, trafficOfferedArray);
    title('Traffic Offered');
    xlabel('Time Slot');
    ylabel('Traffic Offered (G)');
    
    subplot(2,2,2);
    plot(1:simulationTime, throughputArray);
    title('Throughput');
    xlabel('Time Slot');
    ylabel('Throughput (S)');
    
    subplot(2,2,3);
    plot(1:simulationTime, meanDelayArray);
    title('Mean Delay');
    xlabel('Time Slot');
    ylabel('Mean Delay (D)');
    
    subplot(2,2,4);
    plot(1:simulationTime, pcktCollisionProbArray);
    title('Packet Collision Probability');
    xlabel('Time Slot');
    ylabel('Collision Probability (P_c)');
    end
    