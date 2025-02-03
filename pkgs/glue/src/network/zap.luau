local RunService = game:GetService "RunService"

type Server = typeof(require("./server"))
type Client = typeof(require("./client"))

return if RunService:IsServer()
	then require("./server") :: Server & Client
	else require("./client") :: Server & Client