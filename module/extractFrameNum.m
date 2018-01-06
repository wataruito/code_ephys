function extractFrameNum(intFileNameExt,t,aux)

% Read total number of sampling points, d1.
[d1, ~] = size(aux);

% Generating starting time (s) from filename
[pathstr, fileNameNoExt, ~] = fileparts(intFileNameExt);
[~, charLen] = size(fileNameNoExt);
[~, ~, ~, HH, MM, SS] = datevec(fileNameNoExt(charLen - 5 : charLen), 'HHMMSS');
startTime = SS + (MM + HH * 60) * 60;

% Initializing variables
bitNum = 27;
auxCh6 = 1; % pulse trains for timing
auxCh5 = 2; % actual pulse input from master camera

% Start scanning from begining
ind = 1;
pulseEndTs=t(ind);	% Time stamp at the end of a pulse
pulseCount = 0;	% Counting pulses inside a train
frameCount = 1;	% Counting trains (frames)
pulse = 0;		% Bit is high(1) or low(0)

while ind <= d1
    if aux(ind,auxCh6) == 1 % Bit is high
        if pulse==0 % Change from low to high
            pulse=1; % pulse on state
            
            % Examine the detected pulse belongs to the same or previous
            % train
            % Intra-tain pulse
            if t(ind)-pulseEndTs < 0.0002
                % Should be intra train, so that puseCount 1 to 26
                if pulseCount >= bitNum
                    % Error process
                end
            end
            
            % Inter-train pulse
            if t(ind)-pulseEndTs > 0.06
                % Should be inter train
                if pulseCount ~= 0
                    % The last train has less than 27 pulses
                    pulseCount = 0; % reset pulseCount
                end
            end
            
            if pulseCount == 0
                %                timeStamp(frameCount) = t(ind) + startTime;
                timeStamp(frameCount) = t(ind);
                
            end
            
            pulseCount = pulseCount + 1;
            bitCh5(pulseCount) = 0; % initialize bitCh5
            
        elseif pulse == 1 % Continue high
        end
        
        % Check Ch5
        if aux(ind,auxCh5) == 1
            bitCh5(pulseCount) = 1;
        end
        
    elseif aux(ind,auxCh6) == 0 % Bit is low
        if pulse == 1 % Change from high to low. End of one pulse
            pulse = 0;
            pulseEndTs = t(ind);
            if pulseCount == bitNum
                pulseCount = 0;	% reset pulseCount
                % Process Ch5
                frameNum(frameCount) = double(bi2de(fliplr(bitCh5)));
                frameCount = frameCount + 1;
            end
        elseif pulse == 0 % Continue low
        end
    end
    ind = ind + 1;
end

timeFrame = [timeStamp' frameNum'];
file_name = [pathstr filesep fileNameNoExt '_timeFrame'];
save(file_name, 'timeFrame');