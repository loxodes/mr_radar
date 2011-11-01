function [ y ] = combiner( x1, x2 )
% models an ideal power divider and combines x1 and x2
% function [ y ] = combiner( x1, x2 )
% combiner is used to model the power splitter combining the 
% received signal from the radar with the delayed signal.
    y = (x1 + x2)/sqrt(2);
end
