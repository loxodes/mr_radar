function [ width ] = evaluate_signal( df, f_lo, bwthreshold, smooth)
    % returns relative 3dB width of the signal (with a bit of filtering to smooth out the answer)
    f_lo_lp_smooth = medfilt1(f_lo,smooth);
    width = df * sum(f_lo_lp_smooth > (bwthreshold * max(f_lo_lp_smooth)));
end

