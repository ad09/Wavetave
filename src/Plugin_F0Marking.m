function F0Marking(Spectrum)
	global FFTSize;
	global SampleRate;
	F0 = fix(50 * FFTSize / SampleRate + 1);
	UBound = fix(1500 / SampleRate * FFTSize);
	MaxDiff = 0;
	Spectrum = max(Spectrum, - 20);
	for i = 5 : UBound
		if(Spectrum(i) - Spectrum(i - 1) && Spectrum(i) > Spectrum(i + 1)
		&& Spectrum(i) - Spectrum(i - 2) > 5
		&& Spectrum(i) - Spectrum(i + 2) > 5)
			LeftMax = max(Spectrum(1 : F0));
			if(Spectrum(i) - LeftMax > MaxDiff)
				MaxDiff = Spectrum(i) - LeftMax;
				F0 = i;
			end
		end
	end
	text(F0, Spectrum(F0), cstrcat("x ", mat2str(fix(F0 * SampleRate / FFTSize)), "Hz"));
end