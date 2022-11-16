% Test Plots

index = 70;
plot(-prh.p(Start_Cue_Idx(index):End_Cue_Idx(index)))
hold on
plot(prh.head(Start_Cue_Idx(index):End_Cue_Idx(index)))
hold off
xline(Ascent_Cue(index)*prh.fs,'r')
xline(Descent_Cue(index)*prh.fs,'b')


%% plot(-prh.p)
xline(Ascent_idx,'r')
xline(Descent_idx,'b')
