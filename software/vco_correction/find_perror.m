function [ perror ] = find_perror( t_ref_if, ts, trefdelay, bsweep )
% find_perror find the phase error in the vco
% [ perror ] = find_perror( f_lo, ts )
% requires sample time ts and f_lo, the time domain samples of the lo output
% returns perror, a time domain vector of the phase error estimate through time
% discard data until reflection

    padlength = length(t_ref_if);
    
    ideal_tickphase = trefdelay*bsweep*2*pi*ts;
    ref_if_phase = -unwrap(angle(t_ref_if));

    iperror = -(diff(ref_if_phase)-ideal_tickphase)*(ts/(trefdelay))/(2*pi);
    iperror(1:floor(10*trefdelay/ts)) = 0;
    
    perror = -cumsum(cumsum(iperror));
    perror = [perror,perror(end)*ones(1,padlength-length(perror))];    
end
