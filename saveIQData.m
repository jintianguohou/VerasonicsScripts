function saveIQData(path,fileName,IQData)
%This function saves IQ data from a verasonics script
%INPUTS: The destination path, a string representing the date, and the
%frame data
%Note: This function DOES NOT check for a valid file name.  The path should
%be valid.

%Get the final file name
fileName = strcat(path,fileName,'_IQ-Frame.mat.');

%Save the IQ Data
save(fileName, IQData)

return
end
% Commented out; don't think we'll run into problems with the new setup
% unless files are moved out of their destination piecemeal
%     while(exist(fileName, 'file')) %Check that the run # is correct
%         runNumber = runNumber + 1;
%         fileName = strcat(filePath, 'Run-', num2str(runNumber),...
%             '_Iteration-0.mat');
%     end
    
