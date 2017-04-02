function IQtoRF_Verasonics(fileName,IQData,ImageParameters)
%AUTHOR: Michael Pinkert
%DATE MODIFIED: 3/16/2017
%DESCRIPTION: Script for single frame calculation of the RF and power
%spectrum.  This MUST be called from within the verasonics script,
%otherwise the evalin functions do not work.
%INPUT: 
%   fileName is the path, minus the file extension, to be saved at.
%   IQData is an US frame of IQ data
%   ImageParameters is an array that contains several different variables
%       (1) = The wavelength in mm
%       (2) = Lateral resolution in wavelengths
%       (3) = Axial resolution in wavelengths
%       (4) = Transducer center frequency in Hz
%       (5) = Sampling frequency in Hz
%       (6) = Transducer Element Spacing in mm
%       (7) = Number of transducer elements
%OUTPUT:

%STEP 1: GET THE NAMES OF THE RFD DATA
IData=real(IQData);
QData=imag(IQData);
Env=abs(IQData);
Bmode=log10(Env+1);


%Read in the variables
Wavelength = ImageParameters(1); %Wavelength of (1.54/15.625 mm/wavelength) = .09856 mm
LatRes = ImageParameters(2);
AxRes = ImageParameters(3);
SampFreq = ImageParameters(4);
CenterFreq = ImageParameters(5);
ElementSpacing = ImageParameters(6);

[NumRows,NumCols]=size(IQData);

%Position Vectors

AxialPosition=[0:NumRows-1]*AxRes + 5*Wavelength; %Starting depth of 5 Wavelengths

%The following assumes a transducer spacing of 100 microns
LateralOrigin = ElementSpacing*127/2; %To get the lateral origin, if 0 is to be the center of the image.
LateralPosition=[0:NumCols-1].*((LatRes*0.1)*(0.1/Wavelength)) - LateralOrigin; % - LateralOrigin;

%Re-modulation;



VirtualSamplingFactor = (CenterFreq/SampFreq)*ImageParameters(3); %This variable adjusts for the actual axial pixel length as defined by the acquisition script

Delta_t=1/SampFreq/VirtualSamplingFactor; %In Seconds

fc=CenterFreq*VirtualSamplingFactor; %In MegaHertz

t=[0:NumRows-1]*Delta_t; 

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
saveas(gcf, strcat(fileName,'_RF'),'png');
saveas(gcf, strcat(fileName,'_RF'),'png');

figure;
set(gca,'FontSize',16);
plot(freq/1E6, 10*log10(PS/max(PS)),'LineWidth',2)
axis([0 31.25 -40 0]);
xlabel('Frequency (MHz)','FontSize',16);
ylabel('Power Spectrum (dB)','FontSize',16);
saveas(gcf, strcat(fileName,'_PS'),'png');
saveas(gcf, strcat(fileName,'_PS'),'png');

save([outputDirectory '\frame_' FileName(1:end-4)],'i0','AxialPosition','LateralPosition', 'SampFreq');

close all;

return [RF, PS];
close all
