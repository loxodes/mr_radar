function [ perror ] = find_perror( t_ref_if, ts, trefdelay, bsweep, real_error, real_ierror)
% find_perror find the phase error in the vco
% [ perror ] = find_perror( f_lo, ts )
% requires sample time ts and f_lo, the time domain samples of the lo output
% returns perror, a time domain vector of the phase error estimate through time
% discard data until reflection
    padlength = length(t_ref_if);
    startup_time = sum(t_ref_if==0);
    ideal_tickphase = trefdelay*bsweep*2*pi*ts;
    ref_if_phase = -unwrap(angle(t_ref_if));

    p_ideal = cumsum(ones(1,length(ref_if_phase)) * ideal_tickphase);
    iperror = -(diff(ref_if_phase)-ideal_tickphase)*(ts/(trefdelay))/(2*pi);
    iperror(1:floor(10*trefdelay/ts)) = 0;
    
    plot(real_error)
    hold on;
    perror = -cumsum(cumsum(iperror));
    perror = [perror,perror(end)*ones(1,padlength-length(perror))];
    plot(perror,'red');
    hold off;
    
end
