local rollout = {}

function rollout.captureCommandOutput(namespace,workloadName)
    local command = "kubectl get rollout.rollouts.kruise.io -n " .. namespace .. " -o yaml"

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

function rollout.checkHealthWithTimeout(namespace,workloadName,timeout)
    local lyaml = require("lyaml")

    local function checkStatus()
        local output = rollout.captureCommandOutput(namespace,workloadName)
        local obj = lyaml.load(output)

        hs={ status = "Progressing", message = "Rollout is still progressing" }

        if obj then

            local items = obj.items or { obj }

            for _, item in ipairs(items) do

                if item.metadata.generation == item.status.observedGeneration then

                    if item.status.phase == "Initial" then
                        hs.status = "Degraded"
                        hs.message = item.status.message
        
                    elseif item.status.canaryStatus.currentStepState == "StepUpgrade" and item.status.phase == "Progressing" then
                        hs.status = "Progressing"
                        hs.message = "Rollout is still progressing"
                
                    elseif item.status.canaryStatus.currentStepState == "StepPaused" and item.status.phase == "Progressing" then
                        hs.status = "Suspended"
                        hs.message = "Rollout is Paused need manual intervention"
                
                    elseif item.status.canaryStatus.currentStepState == "Completed" and item.status.phase == "Healthy" then
                        hs.status = "Healthy"
                        hs.message = "Rollout is Completed"
                
                    elseif item.status.canaryStatus.currentStepState == "StepPaused" and (item.status.phase == "Terminating" or item.status.phase == "Disabled") then
                        hs.status = "Degraded"
                        hs.message = "Rollout is Disabled or Terminating"
                    end
                
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

return rollout