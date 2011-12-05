function [ perror ] = find_perror( t_ref_if, ts, trefdelay, bsweep, real_error, real_ierror)
% find_perror find the phase error in the vco
% [ perror ] = find_perror( f_lo, ts )
% requires sample time ts and f_lo, the time domain samples of the lo output
% returns perror, a time domain vector of the phase error estimate through time
% discard data until reflection
    padlength = length(t_ref_if);
    startup_time = sum(t_ref_if==0);
    offset = 3.2203e-04;

%   t_ref_if = t_ref_if(startup_time+1:end);
    ideal_tickphase = trefdelay*bsweep*2*pi*ts;
    ref_if_phase = -unwrap(angle(t_ref_if));
    
    p_ideal = cumsum(ones(1,length(ref_if_phase)) * ideal_tickphase);
    
    iperror = -((ref_if_phase) - p_ideal)*(ts/(trefdelay*4))-offset;
    
%   iperror(abs(iperror)>.4) = 0;                                       % eliminate artifacts
%    iperror(1:2*startup_time) = 0;
    plot(real_error)
    hold on

    perror = -cumsum(iperror);
    plot(perror,'red');
    perror = [perror,perror(end)*ones(1,padlength-length(perror))];
end
