local acj = {}

function acj.captureCommandOutput(namespace,workloadName)
    local command = "kubectl get advancedcronjob.apps.kruise.io -n " .. namespace .. " -o yaml"

    if workloadName ~= nil then
        command = command .. " " .. workloadName
    end

    local handle = io.popen(command)
    local output = handle:read("*a")
    local success, exit_reason, exit_code = handle:close()
    
    if not success then
        return nil, exit_reason, exit_code
    end
    
    return output
end

function acj.checkHealthWithTimeout(namespace,workloadName,timeout)
    local lyaml = require("lyaml")

    local function checkStatus()
        local output = acj.captureCommandOutput(namespace,workloadName)
        local obj = lyaml.load(output)
    
        local hs = { status = "Progressing", message = "Waiting for intialization" }
    
        lastScheduleTime = nil
    
        if obj then 
            
            local items = obj.items or { obj }
            
            for _, item in ipairs(items) do
    
                if item.status.lastScheduleTime ~= nil then
                    local year, month, day, hour, min, sec = string.match(item.status.lastScheduleTime, "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z")
                    lastScheduleTime = os.time({year=year, month=month, day=day, hour=hour, min=min, sec=sec})
                end
        
                if lastScheduleTime == nil and item.spec.paused == true then
                    hs.status = "Suspended"
                    hs.message = "AdvancedCronJob is Paused"
                    return hs
                end
        
                if item.status.active ~= nil and #item.status.active > 0 then
                    hs.status = "Progressing"
                    hs.message = "AdvancedCronJobs has active jobs"
                    return hs
                end
        
                if lastScheduleTime == nil then
                    hs.status = "Degraded"
                    hs.message = "AdvancedCronJobs has not run successfully"
                    return hs
                end
        
                if lastScheduleTime ~= nil then
                    hs.status = "Healthy"
                    hs.message = "AdvancedCronJobs has run successfully"
                    return hs
                end
        
            end
        end
    
        return hs
    end

    local initialStatus = checkStatus()

    if initialStatus.status == "Suspended" or initialStatus.status == "Degraded" or initialStatus.status == "Progressing" then
        for _ = 1, timeout do
            os.execute("sleep 1")
            local recheckStatus = checkStatus()
            if recheckStatus.status ~= initialStatus.status then
                return recheckStatus
            end
        end
    end

    return initialStatus
    
end

return acj