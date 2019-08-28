%%
mean_ERP= squeeze(mean(data_cond11_run, 1))';
colors_ERP_chan=summer(40); 

%%
figure, 
for i=1:40
    
    plot(mean_ERP(i, :), 'color', colors_ERP_chan(i,:))
    
    pause(.5)
    
end