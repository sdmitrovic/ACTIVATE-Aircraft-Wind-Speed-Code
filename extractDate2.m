function dateStr = extractDate2(filename)
    % Assuming the date is located at positions 26 to 33 in the filename
    dateStr = extractBetween(filename, 23, 30);
end