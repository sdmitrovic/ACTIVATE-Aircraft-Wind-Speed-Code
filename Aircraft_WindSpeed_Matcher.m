%Author: Sanja Dmitrovic
%Title: ACTIVATE Aircraft Wind Speed Intercomparison: TAMMS and Dropsondes

%To run this code, you need the following functions:
%extractDate1
%extractDate2
%readICT1
%readICT2
%removeInvalidData
%haversine

% Please set directories containing the dropsonde and TAMMS .ict files.
directory1 = strcat('C:\Users\Photon\Desktop\ACTIVATEData\ACTIVATEDropsonde\2021sondes');
directory2 = strcat('C:\Users\Photon\Desktop\ACTIVATEData\TAMMS\2021DataUpdated');

% Pattern to match the files
filePattern1 = fullfile(directory1, 'ACTIVATE-Dropsonde_*.ict');
filePattern2 = fullfile(directory2, 'ACTIVATE-SUMMARY_HU25_*.ict');

% List of files matching the pattern
files1 = dir(filePattern1);
files2 = dir(filePattern2);

%Initialize array to store matched TAMMS-dropsonde points.
finalResults = [];

% Iterate through all files in the second pattern. Throughout the code, I refer to dropsonde data as 1 and TAMMS data as 2.
for k2 = 1:length(files2)
    % Extract date from the current file2
    date2 = extractDate2(files2(k2).name);
    
    % Find all matching files in the first pattern
    matchingFiles1 = {};
    for k1 = 1:length(files1)
        date1 = extractDate1(files1(k1).name);
        if strcmp(date1, date2)
            matchingFiles1{end+1} = files1(k1).name;
        end
    end

    % If no matching files found, continue to the next TAMMS file.
    if isempty(matchingFiles1)
        continue;
    end
    
    % Process each matching file in the first pattern with the current file in the second pattern.
    for k1 = 1:length(matchingFiles1)
        date1 = extractDate1(matchingFiles1{k1});
        dropsondeFileName = matchingFiles1{k1};
        % Read data from the matched pair of files
        data1 = readICT1(fullfile(directory1, matchingFiles1{k1}));
        data2 = readICT2(fullfile(directory2, files2(k2).name));
        
        %This prints which dropsonde file matches with which TAMMS file. This is to ensure that the dates match correctly.
        disp(['Comparing Dropsonde file: ', matchingFiles1{k1}, ' with TAMMS file: ', files2(k2).name]);
        disp(['Date1: ', date1, ', Date2: ', date2]);
        
        % Remove invalid data points
        invalidValue = -9999;
        data1 = removeInvalidData(data1, invalidValue);
        data2 = removeInvalidData(data2, invalidValue);

        % Extract relevant columns (columns: latitude, longitude, altitude, time, wind speed).
        lat1 = data1{8};
        lon1 = data1{9};
        altitude1 = data1{11};
        time1 = data1{1};
        windSpeed1 = data1{6};

        lat2 = data2{2};
        lon2 = data2{3};
        altitude2 = data2{4};
        time2 = data2{1};
        windSpeed2 = data2{13};

        % Initialize array to store filtered points information.
        filteredPoints = [];

        % Iterate through all points in the first file.
        for i = 1:length(lat1)
            % Iterate through all points in the second file
            for j = 1:length(lat2)
                % Calculate the distance between the current points in file 1 and file 2
                distance = haversine(lat1(i), lon1(i), lat2(j), lon2(j));
                
                % Calculate altitude difference and time difference.
                altitudeDiff = abs(altitude1(i) - altitude2(j));
                timeDiff = abs(time1(i) - time2(j));
                
                % Apply the specified thresholds
                if distance <= 30 & altitudeDiff <= 25 & timeDiff <= 900         
                    % Store the valid points
                    filteredPoints = [filteredPoints; i, j, altitude1(i), altitude2(j), distance, time1(i), time2(j), windSpeed1(i), windSpeed2(j), timeDiff, altitudeDiff, string(dropsondeFileName)];
                    %The next four lines remove duplicate matched pairs.
                    [~,uidx] = unique(filteredPoints(:,8),'stable');
                    filteredPoints = filteredPoints(uidx,:);
                    [~,uidx2] = unique(filteredPoints(:,9),'stable');
                    filteredPoints = filteredPoints(uidx2,:);
                end
            end
        end

        %Convert to table if there are filtered points.
        if ~isempty(filteredPoints)
            filteredPointsTable = array2table(filteredPoints, ...
                'VariableNames', {'IndexInFile1', 'IndexInFile2', 'AltitudeFile1', 'AltitudeFile2', ...
                'Distance', 'TimeFile1', 'TimeFile2', 'WindSpeedFile1', ...
                'WindSpeedFile2', 'TimeDifference', 'AltitudeDifference', 'Sonde'});

            % Append the results to the final table
            finalResults = [finalResults; filteredPointsTable];
            
            end
        end
    end

%Convert columns in results table back to numeric other than the dates.
columnsToConvert = {'IndexInFile1', 'IndexInFile2', 'AltitudeFile1', 'AltitudeFile2', ...
                    'Distance', 'TimeFile1', 'TimeFile2', 'WindSpeedFile1', ...
                    'WindSpeedFile2', 'TimeDifference', 'AltitudeDifference'};

for i = 1:length(columnsToConvert)
    colName = columnsToConvert{i};
    finalResults.(colName) = str2double(finalResults.(colName));
end

% Here, we need to get the paired points closest in altitude grouped by each dropsonde.
uniqueNames = unique(finalResults.Sonde);

% Initialize an array to hold the indices of the rows with the minimum altitude difference
minAltitudeDiffIndices = [];

% Iterate through each dropsonde.
for i = 1:length(uniqueNames)
    % Get the current date
    currentName = uniqueNames(i);
    
    % Find the indices of the rows that match the current name.
    nameIndices = find(finalResults.Sonde == currentName);
    
    % Extract the altitude differences for the current name.
    altitudeDifferences = finalResults.AltitudeDifference(nameIndices);
    
    % Find the index of the minimum altitude difference for the current name.
    [~, minIndex] = min(altitudeDifferences);
    
    % Store closest altitude points.
    minAltitudeDiffIndices(i) = nameIndices(minIndex);
end

% Create final table of TAMMS-dropsonde pairs closest in altitude.
finalResults_minimized = finalResults(minAltitudeDiffIndices, :);

