function [ t, fout ] = vco( fstart, fstop, tsweep, type, ts )
    % generates simulated VCO output
    % currently only works for an ideal vco
    if(strcmp(type,'ideal'))
        warning('vco: sorry, only ideal vcos are currently supported');
    end
    df = (fstop-fstart)/(tsweep/ts);
    f = fstart:df:fstop;
    pa = 2*pi*f*ts;
    p = mod(cumsum(pa),2*pi);
    t = 0:ts:tsweep;
    fout = cos(p);
end

