function [ perror ] = find_perror( t_ref_if, ts, trefdelay, bsweep )
% find_perror find the phase error in the vco
% [ perror ] = find_perror( f_lo, ts )
% requires sample time ts and f_lo, the time domain samples of the lo output
% returns perror, a time domain vector of the phase error estimate through time
    n = (1:length(t_ref_if));
    t_ideal = exp(1j*2*pi*(bsweep*trefdelay)*ts*n);
    perror = angle(t_ideal) - angle(t_ref_if);
end
