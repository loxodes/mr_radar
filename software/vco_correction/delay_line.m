function [ x_delayed ] = delay_line( x, delay, ts )
    % delay signal by delay seconds. fill beginning with zeros
    % trims end
    x_delayed = [zeros(1,delay/ts) x];
    x_delayed = x_delayed(1:length(x));
end

