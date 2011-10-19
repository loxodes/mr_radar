function [ t, fout ] = vco( f_start, f_stop, t_sweep, type, ts )
    % generates simulated VCO output
    % currently only works for an ideal vco
    if(~strcmp(type,'ideal'))
        warning('vco: sorry, only ideal vcos are currently supported'); %#ok<WNTAG>
    end
    
    df = (f_stop-f_start)/(t_sweep/ts);     % calculate frequency step per sample time
    f = f_start:df:f_stop;                  % calculate instantaneous frequency of chrip
    pa = 2*pi*f*ts;                         % calculate phase change between time steps
    p = mod(cumsum(pa),2*pi);               % calculate phase of cosine at each timestep
    t = 0:ts:t_sweep;                       % create time vector
    fout = cos(p);                          % calculate amplitude of time signal from phase
end

