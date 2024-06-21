function data = readICT2(filename)
    fid = fopen(filename, 'rt');
    data = textscan(fid, '%f %f %f %f %f %f %f %f %f %f %f %f %f %f', 'HeaderLines', 59, 'Delimiter', ',');
    fclose(fid);
end