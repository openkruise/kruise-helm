local CloneSet = {}

function CloneSet.captureCommandOutput(namespace, workloadName)
    local command = "kubectl get cloneset.apps.kruise.io -n " .. namespace .. " -o yaml"

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

function CloneSet.checkHealthWithTimeout(namespace, workloadName, timeout)
    local lyaml = require("lyaml")

    local function checkStatus()
        local output = CloneSet.captureCommandOutput(namespace, workloadName)
        local obj = lyaml.load(output)

        local hs = { status = "Progressing", message = "Waiting for initialization" }

        if obj then
            -- Check if there is an "items" array, and if not, treat the object as a single Cloneset
            local items = obj.items or { obj }

            for _, item in ipairs(items) do
                if item.status then
                    if item.metadata.generation == item.status.observedGeneration then
                        if item.spec.updateStrategy.paused == true or not item.status.updatedAvailableReplicas then
                            hs.status = "Suspended"
                            hs.message = "Cloneset is paused"
                        elseif item.spec.updateStrategy.partition ~= 0 and item.metadata.generation > 1 then
                            if item.status.updatedReplicas > item.status.expectedUpdatedReplicas then
                                hs.status = "Suspended"
                                hs.message = "Cloneset needs manual intervention"
                            elseif item.status.updatedAvailableReplicas == (item.status.replicas - item.spec.updateStrategy.partition) then
                                hs.status = "Suspended"
                                hs.message = "Cloneset needs manual intervention"
                            end
                        elseif item.status.updatedAvailableReplicas == item.status.replicas then
                            hs.status = "Healthy"
                            hs.message = "All Cloneset workloads are ready and updated"
                        elseif item.status.updatedAvailableReplicas ~= item.status.replicas then
                            hs.status = "Degraded"
                            hs.message = "Some replicas are not ready or available"
                        end
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

return CloneSet
