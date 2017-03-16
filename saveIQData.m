function saveIQData(TempIQData)

    %Read in the file path defined at the top of the file.  Retrieve the
    %run number, the label for the set of scans being done, and the file
    %number, the label for individual scans
    filePath = evalin('base', 'filePath');
    runNumber = evalin('base', 'runNumber');
    fileNumber = evalin('base', 'fileNumber');
    matName = evalin('base', 'matName');
    dateStr = evalin('base', 'dateStr');
    
    %The file name for this run and iteration
    fileName = strcat(filePath,matName,'_',dateStr,'_IQ_Run-', num2str(runNumber), '_Iteration-',...
           num2str(fileNumber), '.mat.');
       
    if(fileNumber == 0) %If this is the first scan of the run
        %Make the directory if it doesn't exist.
        directoryTest = fileName(1:find(fileName=='/','/','last'));
        if directoryTest ~= filePath
            if (~exist(directoryTest, 'dir'))
                mkdir(directoryTest);
            end
        end
        
        while(exist(fileName, 'file')) %Check that the run # is correct
            runNumber = runNumber + 1;
            fileName = strcat(filePath, 'Run-', num2str(runNumber),...
                '_Iteration-0.mat');
        end
        assignin('base', 'runNumber', runNumber);
    end
    
    
    %Save the IQ Data
    save(fileName, TempIQData)
    
    %Iterate the file number to save the next acquisition when freeze is
    %clicked
    fileNumber = fileNumber + 1;
    assignin('base', 'fileNumber', fileNumber);

    return
end

