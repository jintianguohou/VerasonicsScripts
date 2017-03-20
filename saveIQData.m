function saveIQData(fileName, IQData)
%This function saves IQ data from a verasonics script
%INPUTS: The destination path, a string representing the date, and the
%frame data
%Note: This function DOES NOT check for a valid file name.  The path should
%be valid.

%Get the final file name
fileName = strcat(fileName,'_IQ-Frame');

%Save the IQ Data
save(fileName, 'IQData')

return
end

