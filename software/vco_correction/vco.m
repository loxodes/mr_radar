function [ t, fout ] = vco( f_start, f_stop, t_sweep, type, ts, noise)
    % generates simulated VCO output
    % currently only works for an ideal or awgn vco
    
    df = (f_stop-f_start)/(t_sweep/ts);     % calculate frequency step per sample time
    f = f_start:df:f_stop;                  % calculate instantaneous frequency of chrip
    pa = 2*pi*f*ts;                         % calculate phase change between time steps
    p = mod(cumsum(pa),2*pi);               % calculate phase of cosine at each timestep
    t = 0:ts:t_sweep;                       % create time vector
    
    % calculate amplitude of time signal from phase
    if(strcmp(type,'ideal'))
        fout = cos(p);
    elseif strcmp(type, 'awgnoise')
        fout = awgn(cos(p),noise);
    else
         warning('vco: sorry, only ideal and awgnoise vcos are currently supported'); %#ok<WNTAG>
    end
end

