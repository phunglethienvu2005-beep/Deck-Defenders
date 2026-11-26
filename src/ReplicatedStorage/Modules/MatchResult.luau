local MatchResult = {}

function MatchResult.eligible(phase, resultId, playerResultId, shownId)
    return (phase == "Victory" or phase == "Defeat")
        and resultId ~= nil and resultId == playerResultId and resultId ~= shownId
end

return MatchResult
