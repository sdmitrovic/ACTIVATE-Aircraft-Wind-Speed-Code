function data = removeInvalidData(data, invalidValue)
    validRows = true(size(data{1}));
    for k = 1:length(data)
        validRows = validRows & (data{k} ~= invalidValue);
    end
    data = cellfun(@(x) x(validRows), data, 'UniformOutput', false);
end