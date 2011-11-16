function [ t, fout, perror ] = vco( f_start, f_stop, t_sweep, type, ts, noise)
% Simulates a VCO generated chrip signal.
% [ t, fout ] = vco( f_start, f_stop, t_sweep, type, ts, noise)
% Generates a t_sweep (seconds) long chrip from f_start (Hz) to f_stop (Hz).
% The sample time ts is needed.
% vco can simulate an ideal vco, a vco with additive white gaussian noise, or with phase noise.
% type determines the type of vco ('ideal', 'awgnoise', 'pnoise', 'triangle')
% noise determines the level of noise. 9
% The mixer is simulated using a phase accumulator, so the phase is continuous across changes in instantaneous frequency. 
% Returns a time vector t and a time domain representation of the signal fout.
% simulates using a model from here:
% http://ieeexplore.ieee.org/xpl/freeabs_all.jsp?arnumber=4542705
% http://www.insidegnss.com/node/2348
    df = (f_stop-f_start)/(t_sweep/ts);     % calculate frequency step per sample time
    f = f_start:df:f_stop;                  % calculate instantaneous frequency of chrip
    pa = 2*pi*f*ts ;                        % calculate phase change between time steps
    
    if(strcmp(type,'pnoise'))
        n = random('norm',0,noise,1,length(f));
        pa = pa + n;
    end
    
    p = mod(cumsum(pa),2*pi);               % calculate phase of cosine at each timestep
    t = 0:ts:t_sweep;                       % create time vector
    perror = zeros(1,length(t));            % phase error is zero
    
    % calculate amplitude of time signal from phase
    if(strcmp(type,'ideal'))
        fout = cos(p);
    elseif strcmp(type, 'awgnoise')
        fout = awgn(cos(p),noise);
    elseif strcmp(type, 'pnoise')
        fout = cos(p);
        perror = mod(cumsum(n),2*pi);
    elseif strcmp(type, 'ramp')
        
    else
         warning('vco: sorry, only ideal and awgnoise vcos are currently supported'); %#ok<WNTAG>
    end
end

