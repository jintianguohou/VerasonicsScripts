function [PS, freq]=PowerSpectrumMTF2(ROIdata, E,V, SampFreq)
%IVAN M ROSADO-MENDEZ, 25 FEB 2010
%This function computes the average power spectrum using the Multi-taper method
%with slepian functions. Computes the power spectra of each column of ROIdata (each
%acoustic line), and all the spectra corresponding to each acoustic line.
%INPUT:
%ROIdata: ROI selected from a previous RF data file
%E: Set of Slepian Sequences
%V: Contributions from each of the Slepian Sequences.
%SampFreq:  Sampling Frequency.




%STEP 1: SIZE OF THE ROI
[NoSamp_ROIdata, NoAcLines_ROIdata]=size(ROIdata);
NumDPSS=size(E,2);
nfft=2047;
sRate=SampFreq;
k=NumDPSS;

%STEP 2: COMPUTE THE POWER SPECTRA
PS_AcLine=[];
for i_AcLine = 1:NoAcLines_ROIdata
        tmpdata = detrend(ROIdata(:,i_AcLine));
        meantmpdata=mean(tmpdata);
        meantmpdata=repmat(meantmpdata,size(tmpdata,1),1);
        tmpdata=tmpdata-meantmpdata;
        x=tmpdata;
        x2=x(:,ones(1,NumDPSS));
        Sk = abs(czt(E.*x2,nfft)).^2;
        w = psdfreqvec('npts',nfft,'Fs',sRate);
        N=length(x);
   
        sig2=x'*x/N;              % Power
        S=(Sk(:,1)+Sk(:,2))/2;    % Initial spectrum estimate   
        S1=zeros(nfft,1);  
   
  
        % Set tolerance for acceptance of spectral estimate:
        tol=.0005*sig2/nfft;
        i=0;
        a=sig2*(1-V);
       
        % Do the iteration:
        while sum(abs(S-S1)/nfft)>tol
            i=i+1;
            % calculate weights
            b=(S*ones(1,k))./(S*V'+ones(nfft,1)*a'); 
            % calculate new spectral estimate
            wk=(b.^2).*(ones(nfft,1)*V');
            S1=sum(wk'.*Sk')./ sum(wk,2)';
            S1=S1';
            Stemp=S1; S1=S; S=Stemp;  % swap S and S1
        end

        [PSD,freq] = computepsd(S,w,'onesided',nfft,sRate,'psd'); 
        freq=freq';
        PS_AcLine=[PS_AcLine PSD*SampFreq]; %Storing Power Spectrum (PS=PSD*SampFreq)



end

%STEP 3: GET THE AVERAGE
PS=mean(PS_AcLine,2);
