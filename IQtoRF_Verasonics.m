function IQtoRF_Verasonics(path, filePrefix,)
%AUTHOR: Michael Pinkert
%DATE MODIFIED: 3/16/2017
%DESCRIPTION: Script for calibrating the angle of the US transducer so that
%it is perpendicular to the optical plane.  Please reference associated
%protocol for instructions on use.
%INPUT: 
%OUTPUT:

%STEP 1: GET THE NAMES OF THE RFD DATA
directory='C:\Users\Michael\Desktop\Temp Data\HallReference_Ivan'
outputDirectory ='C:\Users\Michael\Desktop\Temp Data\HallReference_Ivan\Test10'

%currentdir='G:\Functions\HighFrequencyPhantoms_03022016'
%addpath('G:\Functions');
Files=dir([directory,'\Run*.mat']);
NumFiles=length(Files)
for i=1:NumFiles
    Name(i)=cellstr(Files(i).name);
end


%STEP 2: READ THE RFD FILES AND DISPLAY THEM

for j=1:NumFiles
    
    %A structre UserInput with various fields will be built below. This
    %structure is required by the function URIload to read the rfd data
    FileName=char(Name(j));
    
    
        load([directory '\' FileName]);
        IQData=TempIQData;
        IData=real(IQData);
        QData=imag(IQData);
        Env=abs(IQData);
        Bmode=log10(Env+1);

        [NumRows,NumCols]=size(IQData);
        
        %Position Vectors
        Wavelength = (1.54/15.625); %Wavelength of (1.54/15.625 mm/wavelength) = .09856 mm
        AxialConvFactor=(1/5)*Wavelength; %(1/5 wavelengths per pixel)

        AxialPosition=[0:NumRows-1]*AxialConvFactor + 5*Wavelength; %Starting depth of 5 Wavelengths
        
        %The following assumes a transducer spacing of 100 microns
        LateralOrigin = 0.1*(.1/Wavelength)*127/2; %To get the lateral origin, if 0 is to be the center of the image.
        LateralPosition=[0:NumCols-1].*((0.2*0.1)*(0.1/Wavelength)) - LateralOrigin; % - LateralOrigin;

       
        %Re-modulation;
        
        SampFreq=62.5E6; %In Hz
        
        VirtualSamplingFactor = 1.25; %This variable adjusts for the actual axial pixel length as defined by the acquisition script
        
        Delta_t=1/SampFreq/VirtualSamplingFactor; %In Seconds 

        fc=15.625E6*VirtualSamplingFactor; %In MegaHertz

        t=[0:NumRows-1]*Delta_t; %The .8 is to correct for the 1/5 wavelength pixel separation as compared to the 1/4 wavelength sampling frequency
        
        %AxialPosition=t*1540*1000;

        cosmod=cos(2*pi*fc*t);
        cosmod=repmat(cosmod',1,NumCols);

        sinmod=sin(2*pi*fc*t);
        sinmod=repmat(sinmod',1,NumCols);

        i0=IData.*cosmod - QData.*sinmod;

        [E,V]=dpss(200,1);

        [PS,freq]=PowerSpectrumMTF2(i0(301:500,:),E,V,SampFreq);

        figure;
        set(gca,'FontSize',16);
        imagesc(LateralPosition,AxialPosition,Bmode);
        caxis([5 8]);
        colormap(gray);
        axis 'equal';
        axis 'tight';
        xlabel('Width (mm)','FontSize',16);
        ylabel('Depth (mm)','Fontsize',16);
        saveas(gcf, [outputDirectory '\Bmode_' FileName(1:end-4)],'png');
        saveas(gcf, [outputDirectory '\Bmode_' FileName(1:end-4)]);
        
        figure;
        set(gca,'FontSize',16);
        plot(freq/1E6, 10*log10(PS/max(PS)),'LineWidth',2)
        axis([0 31.25 -40 0]);
        xlabel('Frequency (MHz)','FontSize',16);
        ylabel('Power Spectrum (dB)','FontSize',16);  
        saveas(gcf, [outputDirectory '\SamplePowerSpectrum_' FileName(1:end-4)],'png');
        saveas(gcf, [outputDirectory '\SamplePowerSpectrum_' FileName(1:end-4)],'png');
        
        save([outputDirectory '\frame_' FileName(1:end-4)],'i0','AxialPosition','LateralPosition', 'SampFreq');
        
        close all;
end


close all
