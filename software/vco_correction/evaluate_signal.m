function [ width ] = evaluate_signal( df, f_lo, bwthreshold, smooth)
    % returns the 3dB width of the signal   
    f_lo_lp_smooth = medfilt1(f_lo,smooth);
    width = df * sum(f_lo_lp_smooth > (bwthreshold * max(f_lo_lp_smooth)));
end

