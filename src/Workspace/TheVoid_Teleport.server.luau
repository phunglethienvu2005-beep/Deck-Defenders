local placeId = 11125800394

script.Parent.Touched:Connect(function(opart)
	local player = game.Players:GetPlayerFromCharacter(opart.Parent)

	if player then
		game["Teleport Service"]:Teleport(placeId, player)
	end
end)
