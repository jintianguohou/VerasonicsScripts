function angleCalibration(IQData)
%This function is not actually used, but rather is a better working environment than the SetUp script 
%due to sensitivity to changing or using variables.
   
    if evalin('base','P.saveAcquisition')
        %% File Naming
        %Read in the misc variables struct 
        P = evalin('base','P');

        %Now we want to handle the settings file, to make sure we are saving
        %correctly

        %If the settings have changed since the last time, reset the boolean to
        %false so that new changes will propogate.  Also reset the run number
        %since it's the first run on the new settings
        if P.itNumber == 1
            %Check for previous settings
            while exist(strcat(P.path,P.filePrefix,P.dateStr,...
            '_Run',int2str(P.runNumber),'_It',int2str(P.itNumber),'.mat'),'file')
                P.runNumber = P.runNumber+1;
            end
            
            %Reset the angles and the max RF
            P.maxRF = [];
            P.angles = [];
            
           %TODO: Line to invoke save preSet here.
        end

        %Calculate the file name for any iteration specific file
        fileName = strcat(P.path,P.filePrefix,P.dateStr,...
            '_Run',int2str(P.runNumber),'_It',int2str(P.itNumber));
        
        %File name for the calibration data
        calFileName = strcat(P.path,P.filePrefix,P.dateStr,...
            '_Run',int2str(P.runNumber),'_CalData'); 

        
        %Save the IQ data for the run.
        save(strcat(fileName,'IQ'),IQData); %Save the IQ data     
        
       %% Save the B-mode image
       %STEP 1: Call in variables needed to define axes and position
       Trans = evalin('base','Trans');
       PData = evalin('base','PData');
       
       %STEP2: Create position vectors for each pixel in mm
       wlConversion = Trans.spacingMm/Trans.spacing; %Converting wavelengths to mm
       LateralPosition = (0:(PData.Size(1)-1))*(PData.PDelta(1)*wlConversion) + PData.Origin(1); 
       AxialPosition = (0:(PData.Size(3)-1))*(PData.PDelta(3)*wlConversion) + PData.Origin(3);
       
        figure('Visible','off')
        imagesc(LateralPosition,AxialPosition,log10(abs(IQData)+1));
        colormap(gray);
        axis 'equal';
        axis 'tight';
        xlabel('Width (mm)','FontSize',16);
        ylabel('Depth (mm)','Fontsize',16);
        saveas(gcf, strcat(fileName,'_BMode'),'png'); 
        %saveas(gcf, strcat(fileName,'_BMode')); %Uncomment this line to save the actual figure 
        
        %% Calculate and save the RF
        
        % Calculate parameters for re-modulation
        VirtualSamplingFactor = 0.25/PData.PDelta(3);  %This variable adjusts for the actual axial pixel length as defined by the acquisition script
        deltaT=1/(4*Trans.frequency*E6*VirtualSamplingFactor); %In Seconds
        fc=Trans.frequency*E6*VirtualSamplingFactor; %In Hertz
        t=(0:(PData.Size(3)-1))*deltaT; 

        %Perform re-modulation
        cosmod=cos(2*pi*fc*t);
        cosmod=repmat(cosmod',1,PData.Size(1));
        
        sinmod=sin(2*pi*fc*t);
        sinmod=repmat(sinmod',1,PData.Size(1));
        
        RF=IData.*cosmod - QData.*sinmod;
        
        save(strcat(fileName,'_RF'),'RF','LateralPosition','AxialPosition');

        %% Update the RF max and angle vectors
        %Need to make a second/third function to actually display this info
        maxRF = [P.maxRF, max(max(RF))];
        
       [lMax, lLoc] = max(RF(1,:));
       [rMax, rLoc] = max(RF(P.Size(1),:));
        
        %Calculate the new angle from the leftmost and rightmost columns
        newAngle = arctan(((lLoc-rLoc)*P.Spacing(3))/(P.Size(1)*P.Spacing(1)));
        angles = [P.angles, newAngle];
        
        P.maxRF = maxRF;
        P.angles = angles;
        
        save(calFileName,'maxRF','angles')

        %% End of code
        %Modify the iteration number
        P.itNumber = P.itNumber+1;
        assignin('base','P',P);
    end
return

end

