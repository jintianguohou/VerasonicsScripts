function saveIQData(path,runNumber,itNumber,IQData)

%Get the final file name
    fullPath = strcat(path,matName,'_',dateStr,'_IQ_Run-', num2str(runNumber), '-',...
        num2str(itNumber), '.mat.');

%Check for the directory
    directoryTest = fullPath(1:find(fullPath=='/','/','last'));
    if (~exist(directoryTest, 'dir'))
            mkdir(directoryTest);
    end
    
% Commented out; don't think we'll run into problems with the new setup
% unless files are moved out of their destination piecemeal
%     while(exist(fileName, 'file')) %Check that the run # is correct
%         runNumber = runNumber + 1;
%         fileName = strcat(filePath, 'Run-', num2str(runNumber),...
%             '_Iteration-0.mat');
%     end
    
    %Save the IQ Data
    save(fullPath, IQData)

    return
end

