% Test Plots

index = 1658;
plot(-p(Start_Cue_Idx(index):End_Cue_Idx(index)))
xline(Ascent_Cue(index)*fs,'r')
xline(Descent_Cue(index)*fs,'b')