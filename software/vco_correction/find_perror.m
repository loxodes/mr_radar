function [ perror ] = find_perror( t_ref_if, ts, trefdelay, bsweep )
% find_perror find the phase error in the vco
% [ perror ] = find_perror( t_ref_if, ts, trefdelay, bsweep )
% requires sample time ts, sweep bandwidth bsweep, 
% and t_ref_if, the time domain samples of at the if output of the mixer
% returns perror, a time domain vector of the phase error estimate

    % calculate phase of downconverted reference signal
    ref_if_phase = -unwrap(angle(t_ref_if));

    % calculate expected phase change across one sample
    ideal_tickphase = trefdelay*bsweep*2*pi*ts;
    
    % calculate instantanous phase error against expected phase change
    iperror = -(diff(ref_if_phase)-ideal_tickphase)*(ts/(trefdelay))/(2*pi);
    iperror(1:floor(10*trefdelay/ts)) = 0;
    
    % calculate cumulative phase error
    perror = -cumsum(cumsum(iperror));
    perror = [perror,perror(end)];    
end
