function [ t_ref_if, t_if ] = split_ref( t_rx_ref, trefdelay, ts, bwsweep )
    % splits apart the reference delay reflected signal
    N = 5;
    f_refmax = 1000*trefdelay*bwsweep*ts;
    [b,a] = butter(N,f_refmax);
    t_ref_if = filter(b,a,t_rx_ref); 
    [b,a] = butter(N,f_refmax,'high');
    t_if = filter(b,a,t_rx_ref);
end

