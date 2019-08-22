
function success = sendTrigger(portTrigg, PortAddress, triggerID)

success = 0;

try
    % Send trigger right before the experiment starts
    if portTrigg
        if syncbox==1
            lptwrite(PortAddress, triggerID);
            WaitSecs(0.004);
            lptwrite(PortAddress, 0);
        elseif syncbox==2
            io64(ioObj, PortAddress, triggerID);
            WaitSecs(0.004);
            io64(ioObj, PortAddress, 0);
        end
        
    else
        fprintf('Trigger: %i \n', triggerID);
    end
    
    success = 1;
    
catch me
    disp(me);
end

end