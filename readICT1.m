function data = readICT1(filename)
    fid = fopen(filename, 'rt');
    data = textscan(fid, '%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f', 'HeaderLines', 126, 'Delimiter', ',');
    fclose(fid);
end