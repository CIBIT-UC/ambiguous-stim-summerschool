
function success=sendTrigger(configs, triggerID)

success = 0;

try
    % Send trigger right before the experiment starts
    if configs.portTrigg
        if configs.syncbox==1
            lptwrite(configs.PortAddress, triggerID);
            WaitSecs(0.004);
            lptwrite(configs.PortAddress, 0);
        elseif syncbox==2
            io64(configs.ioObj, configs.PortAddress, triggerID);
            WaitSecs(0.004);
            io64(configs.ioObj, configs.PortAddress, 0);
        end
        
    else
        fprintf('Trigger: %i \n', triggerID);
    end
    
    success = 1;
    
catch me
    disp(me);
end

end