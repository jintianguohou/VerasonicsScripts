function AngleCodeTest( IQData )
%% File Naming and IQ data
%Read in the misc variables struct
P = evalin('base','P');
%
%         %Now we want to handle the settings file, to make sure we are saving
%         %correctly
%
%         %If the settings have changed since the last time, reset the boolean to
%         %false so that new changes will propogate.  Also reset the run number
%         %since it's the first run on the new settings
%         if P.itNumber == 1
%             %Check for previous settings
%             while exist(strcat(P.path,P.filePrefix,P.dateStr,...
%             '_Run-',int2str(P.runNumber),'_It-',int2str(P.itNumber),'_IQ.mat'),'file')
%                 P.runNumber = P.runNumber+1;
%             end
%
%             %Reset the angles and the max RF
%             P.maxRF = [];
%             P.angles = [];
%
%            %TODO: Line to invoke save preSet here.
%         end
%
%         %Calculate the file name for any iteration specific file
%         fileName = strcat(P.path,P.filePrefix,P.dateStr,...
%             '_Run-',int2str(P.runNumber),'_It-',int2str(P.itNumber));



%Save the IQ data for the run.
%save(strcat(fileName,'_IQ'),'IQData'); %Save the IQ data

%% Save the B-mode image
%STEP 1: Call in variables needed to define axes and position
Trans = evalin('base','Trans');
PData = evalin('base','PData');

%STEP2: Create position vectors for each pixel in mm
LateralPosition = (0:(PData.Size(2)-1))*(PData.PDelta(1)*P.wls2mm) + PData.Origin(1)*P.wls2mm;
AxialPosition = (0:(PData.Size(1)-1))*(PData.PDelta(3)*P.wls2mm) + PData.Origin(3)*P.wls2mm;

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
deltaT=1/(4*Trans.frequency*1E6*VirtualSamplingFactor); %In Seconds
fc=Trans.frequency*1E6*VirtualSamplingFactor; %In Hertz
t=(0:(PData.Size(1)-1))*deltaT;

%Perform re-modulation
cosmod=cos(2*pi*fc*t);
cosmod=repmat(cosmod',1,PData.Size(2));

sinmod=sin(2*pi*fc*t);
sinmod=repmat(sinmod',1,PData.Size(2));

RF=real(IQData).*cosmod - imag(IQData).*sinmod;

%save(strcat(fileName,'_RF'),'RF','LateralPosition','AxialPosition');

%% Calculate the power spectrum
%         halfAxWindow = int16(0.5*P.axialWindow/PData.PDelta(3)); %Axial window in pixels.
%         focusIdx = int16(P.txFocus/PData.PDelta(3)); % location of the tx focus in the array
%
%         %Make sure the window is possible
%         if (focusIdx-halfAxWindow) < 1 %Check that the window stops at the lower bound
%             halfAxWindow = focusIdx - 1;
%         end
%
%         if (focusIdx + halfAxWindow) > PData.Size(1) %Check that the window stops at the upper bound
%             halfAxWindow = PData.Size(1)-focusIdx;
%         end
%
%         [E, V] = dpss(2*halfAxWindow+1,1);
%         [powerSpectrum, C.frequencies] = PowerSpectrumMTF2(...
%             RF((focusIdx-halfAxWindow):(focusIdx+halfAxWindow),:), E,V,4*Trans.frequency);
%         P.powerSpectra = [P.powerSpectra powerSpectrum];
%
%         %% Update the RF max and angle vectors
%
%         maxRF = max(max(abs(RF)));
%
%        [lMax, angLoc.left] = max(abs(RF(5,:)));
%        [rMax, angLoc.right] = max(abs(RF(PData.Size(2)-4,:)));
%
    %% Calculate the new angle and maxRF
%newAngle = atand(((angLoc.right-angLoc.left)*PData.PDelta(3))/(PData.Size(2)*PData.PDelta(1)));
newAngle = 0;


%
%         P.maxRF = [P.maxRF maxRF];
P.angles = [P.angles newAngle];
%         P.loc = [P.angLoc angLoc];
%
%         %File name for the calibration data
%         calFileName = strcat(P.path,P.filePrefix,P.dateStr,...
%             '_Run-',int2str(P.runNumber),'_CalData');
            
        %% Save calibration file
%         %Set up a calibration file
%         C.maxRF = P.maxRF;
%         C.angles = P.angles;
%         C.powerSpectra = P.powerSpectra;
%         C.loc = P.loc;
%         save(calFileName,'C')
%
%% Display the RF and angles in figures
%We need persistents so that they stay open
persistent rfGraph;
persistent angleGraph;
%persistent psGraph;

%X vector for the graphs based on the number of iterations
x = 1:P.itNumber;

%Plot the maximum RF over iteration
if P.itNumber == 1
    %Get a new handle for the figure, makes a figure per run
    while ishandle(P.psHandle) && strcmp(get(P.psHandle,'type'),'figure')
        P.psHandle = P.psHandle+1;
    end
    
    %             %Power spectrum graph
    %             figure(P.psHandle)
    %             set(figure(P.psHandle),'Name',strcat('Run-',num2str(P.runNumber)...
    %                 ,'_It-',num2str(P.itNumber))...
    %                 ,'NumberTitle','off')
    %             psGraph = axes('XLim',[0,max(C.frequencies)],...
    %                 'YLim', [-40 0],...
    %                 'NextPlot','replaceChildren');
    %             plot(psGraph,C.frequencies,10*log10(powerSpectrum/max(powerSpectrum)))
    %             xlabel('Frequency (MHz)')
    %             ylabel('Transducer Response (dB)')
    %             title('Power Spectrum')
    %             drawnow
    
    %RF graph
    P.rfHandle = P.psHandle + 1;
    figure(P.rfHandle)
    set(figure(P.rfHandle),'Name',strcat('Run-',num2str(P.runNumber)),'NumberTitle','off')
    rfGraph = axes('XLim',[LateralPosition(1),LateralPosition(size(LateralPosition))],...
        'YLim', [AxialPosition(1),AxialPosition(size(AxialPosition))],...
        'NextPlot','replaceChildren');
    imagesc(rfGraph,RF)
    title('RF Reconstruction')
    xlabel('mm')
    ylabel('mm')
    drawnow
    
    %Optical flat angle graph
    P.angleHandle = P.rfHandle+1;
    while ishandle(P.angleHandle) && strcmp(get(P.angleHandle,'type'),'figure')
        P.angleHandle = P.angleHandle+1;
    end
    figure(P.angleHandle)
    set(figure(P.angleHandle),'Name',strcat('Run-',num2str(P.runNumber)),'NumberTitle','off')
    angleGraph = axes('XLim',[0,(P.itNumber+1)],...
        'YLim', [-45, 45],...
        'NextPlot','replaceChildren');
    plot(angleGraph,x,P.angles,'-o')
    title('Optical Flat Angle')
    xlabel('Iteration')
    ylabel('Angle')
    
    drawnow
else
    %Update the power spectrum figure
    figure(P.psHandle)
    plot(psGraph, C.frequencies, 10*log10(powerSpectrum/max(powerSpectrum)))
    drawnow
    
    %Update the RF line plot
    figure(P.rfHandle)
    set(rfGraph,'XLim',[0 P.itNumber+1],'YLim',[(min(P.maxRF)*0.9) (max(P.maxRF)*1.1)]);
    plot(rfGraph,x,C.maxRF,'-o')
    drawnow
    
    %Update the Angle line plot
    figure(P.angleHandle)
    set(angleGraph,'XLim',[0 P.itNumber+1]);
    plot(angleGraph,x,C.angles,'-o')
    drawnow
end

% %Save the power spectrum
% saveas(figure(P.psHandle),strcat(fileName,'_PS'),'png')
% 
% %Save the figures, overwriting by iteration
% rfName = strcat(P.path,P.filePrefix,P.dateStr,...
%     '_Run-',int2str(P.runNumber),'_rfGraph');
% 
% angleName = strcat(P.path,P.filePrefix,P.dateStr,...
%     '_Run-',int2str(P.runNumber),'_angleGraph');
% 
% saveas(figure(P.rfHandle),rfName,'png')
% saveas(figure(P.angleHandle),angleName,'png')

%% End of code
%Modify the iteration number
P.itNumber = P.itNumber+1;
assignin('base','P',P);
end


