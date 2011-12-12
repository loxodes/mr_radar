function [ x_delayed ] = delay_line( x, delay, ts )
% Prepends zeros to the start of an input signal, then trims to match the input length.
% [x_delayed] = delay_line(x,delay,ts) adds delay seconds of delay to signal x.
% The last delay seconds of the input signal are trimmed to preserve the length of x.
% delay_line returns x_delayed, a delayed version of x.
% This function is used to simulate delay from the reference path and the reflected signal.
    x_delayed = [zeros(1,round(delay/ts)) x];
    x_delayed = x_delayed(1:length(x));
end

