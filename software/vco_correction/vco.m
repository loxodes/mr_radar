function [ t, fout, perror, n ] = vco( f_start, f_stop, t_sweep, type, ts, noise)
% Simulates a VCO generated chrip signal.
% [ t, fout ] = vco( f_start, f_stop, t_sweep, type, ts, noise)
% Generates a t_sweep (seconds) long chrip from f_start (Hz) to f_stop (Hz).
% The sample time ts is needed.
% vco can simulate an ideal vco, a vco with additive white gaussian noise, or with phase noise.
% type determines the type of vco ('ideal', 'awgnoise', 'pnoise', 'ramp', 'burguy')
% noise determines the level of noise. 9
% The vco is simulated using a phase accumulator, so the phase is continuous across changes in instantaneous frequency. 
% Returns a time vector t and a time domain representation of the signal fout.

    df = (f_stop-f_start)/(t_sweep/ts);     % calculate frequency step per sample time
    f = f_start:df:f_stop;                  % calculate instantaneous frequency of chrip
    pa = 2*pi*f*ts;                         % calculate phase change between time steps
    
    pc = mod(cumsum(pa),2*pi);              % calculate phase of cosine at each timestep
    t = 0:ts:t_sweep;                       % create time vector
    perror = zeros(1,length(t));            % phase error is zero
    n = perror;
    
    if(strcmp(type,'ideal'))
        % ideal vco
        fout = exp(1j*pc);
        
    elseif strcmp(type, 'awgnoise')
        % additive white gaussian noise model
        fout = awgn(exp(1j*pc),noise);
        
    elseif strcmp(type, 'pnoise')
        % gaussian phase noise model for VCO
        n = random('norm',0,noise,1,length(f));
        fout = exp(1j*(pc+2*pi*cumsum(n)));
        perror = cumsum(n);
        
    elseif strcmp(type, 'ramp')
        % ramp error, hardcoded arguements for testing..
        t_start = .2 * t_sweep;
        t_stop = .6 * t_sweep;
        t_total = t_sweep;
        f_maxdev = 5e6;
        theta_maxdev = ((2*pi*f_maxdev) * ts)/(2*pi);

        r_width = (t_stop-t_start)/2;
        r = ones(1,floor(r_width/ts));
        p = [zeros(1,floor(t_start/ts)),conv(r,r),zeros(1,floor((t_total-t_stop)/ts))];
        p = [p, zeros(1,length(t)-length(p))];
        p = (p / max(p))*theta_maxdev; % normalize amplitude
        
        n = (cumsum(p));
        fout = exp(1j*(pc+2*pi*n));
        perror = n;
        
    elseif strcmp(type, 'burguy')
        % use Alex Bur-Guy's phase noise model and add_phase_noise.m
        % from http://www.mathworks.com/matlabcentral/fileexchange/8844-phase-noise/content/add_phase_noise.m
        % using max phase noise values from CVCO55BE 3245-3500 datasheet
        phase_noise_freq = [ 10e3, 100e3];  % frequency offsets in hertz
        phase_noise_power = [ -93, -117];   % phase noise in dBc/hertz
        s = exp(1j*(pc));
        fout = add_phase_noise(s, 1/ts, phase_noise_freq, phase_noise_power);    
    else
         warning('vco: sorry, that VCO type is unsupported'); %#ok<WNTAG>
    end
end

