function [ t, fout, perror, n ] = vco( f_start, f_stop, t_sweep, type, ts, noise)
% Simulates a VCO generated chrip signal.
% [ t, fout ] = vco( f_start, f_stop, t_sweep, type, ts, noise)
% Generates a t_sweep (seconds) long chrip from f_start (Hz) to f_stop (Hz).
% The sample time ts is needed.
% vco can simulate an ideal vco, a vco with additive white gaussian noise, or with phase noise.
% type determines the type of vco ('ideal', 'awgnoise', 'pnoise', 'triangle')
% noise determines the level of noise. 9
% The mixer is simulated using a phase accumulator, so the phase is continuous across changes in instantaneous frequency. 
% Returns a time vector t and a time domain representation of the signal fout.

    df = (f_stop-f_start)/(t_sweep/ts);     % calculate frequency step per sample time
    f = f_start:df:f_stop;                  % calculate instantaneous frequency of chrip
    pa = 2*pi*f*ts;                         % calculate phase change between time steps
    
    pc = mod(cumsum(pa),2*pi);               % calculate phase of cosine at each timestep
    t = 0:ts:t_sweep;                       % create time vector
    perror = zeros(1,length(t));            % phase error is zero
    
    % calculate amplitude of time signal from phase
    if(strcmp(type,'ideal'))
        fout = exp(1j*pc);
    elseif strcmp(type, 'awgnoise')
        fout = awgn(exp(1j*pc),noise);
    elseif strcmp(type, 'pnoise')
        n = random('norm',0,noise,1,length(f));
        fout = exp(1j*(pc+2*pi*cumsum(n)));
        perror = cumsum(n);
    elseif strcmp(type, 'ramp')
        % ramp error, hardcoded arguements for testing..
        t_start = .2 * t_sweep;
        t_stop = .6 * t_sweep;
        t_total = t_sweep;
        f_maxdev = 100000;
        theta_maxdev = ((2*pi*f_maxdev) * ts)/(2*pi);

        r_width = (t_stop-t_start)/2;
        r = ones(1,floor(r_width/ts));
        p = [zeros(1,floor(t_start/ts)),conv(r,r),zeros(1,floor((t_total-t_stop)/ts))];
        p = [p, zeros(1,length(t)-length(p))];
        p = (p / max(p))*theta_maxdev; % normalize amplitude
        
        n = (cumsum(p));
        %s = exp(1i*2*pi*(fc*t+e_t));
        %spectrogram(s,256,250,256,1/ts);
        %n = zeros(1,length(p));
        fout = exp(1j*(pc+2*pi*n));
        perror = n;
    else
         warning('vco: sorry, that VCO type is unsupported'); %#ok<WNTAG>
    end
end

