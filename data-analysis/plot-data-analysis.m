
%% Load data
load ('EventAnalysis_FNIRS.mat')


%% average - timecourse data
m_tc_event_11=squeeze(mean(data_cond11_run,1)); % mean timecourse event 11
m_tc_event_21=squeeze(mean(data_cond21_run,1)); % mean timecourse event 21

%% plot timecourse

% hbo
figure, 

plot(squeeze(mean(m_tc_event_11(:,1:2:end),2)), 'b'); 
hold on
plot(squeeze(mean(m_tc_event_21(:,1:2:end),2)), 'r'); 
title('hbo')

% hbr
figure, 

plot(squeeze(mean(m_tc_event_11(:,2:2:end),2)), 'b'); 
hold on
plot(squeeze(mean(m_tc_event_21(:,2:2:end),2)), 'r'); 
title('hbr')

%%