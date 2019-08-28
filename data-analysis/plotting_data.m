%%
mean_ERP= squeeze(mean(data_cond11_run, 1))';
mean_ERP_allchan_even= squeeze(mean(mean_ERP(1:2:40), 1));
mean_ERP_allchan_odd= squeeze(mean(mean_ERP(2:2:40), 1));


colors_ERP_chan=summer(40); 



%%
figure, 
for i=1:40
    
    plot(mean_ERP(i, :), 'color', colors_ERP_chan(i,:))
    
    pause(.5)
    
end


%%

figure, 
plot(mean_ERP_allchan_even, 'r')
hold on
plot(mean_ERP_allchan_odd, 'b')
