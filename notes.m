%Random notes

[ps, f] = periodogram(double(RcvData{1}(Receive(1).startSample:Receive(1).endSample,:,1)*1.0),[],[],62.5);