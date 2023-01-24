local PlayerData, CurrentActionData, handcuffTimer, dragStatus, blipsCops, currentTask, spawnedVehicles = {}, {}, {}, {}, {}, {}, {}
local HasAlreadyEnteredMarker, isDead, IsHandcuffed, hasAlreadyJoined, playerInService, isInShopMenu = false, false, false, false, false, false
local LastStation, LastPart, LastPartNum, LastEntity, CurrentAction, CurrentActionMsg

local attente = 0

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
     PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)  
	PlayerData.job = job  
	Citizen.Wait(5000) 
end)

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(10)
    end
    while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
    end
    if ESX.IsPlayerLoaded() then

		ESX.PlayerData = ESX.GetPlayerData()

    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

Citizen.CreateThread(function()
	local bcso = AddBlipForCoord(Config.pos.blip.position.x, Config.pos.blip.position.y, Config.pos.blip.position.z)
	SetBlipSprite(bcso, 137)
	SetBlipColour(bcso, 5)
	SetBlipScale(bcso, 0.8)
	SetBlipAsShortRange(bcso, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString("~y~Commissariat ~s~| Bcso")
	EndTextCommandSetBlipName(bcso)
end)

local Items = {}      -- Item que le joueur possède (se remplit lors d'une fouille)
local Armes = {}    -- Armes que le joueur possède (se remplit lors d'une fouille)
local ArgentSale = {}  -- Argent sale que le joueur possède (se remplit lors d'une fouille)
local IsHandcuffed, DragStatus = false, {}
DragStatus.IsDragged          = false

local PlayerData = {}

local function MarquerJoueur()
	local ped = GetPlayerPed(ESX.Game.GetClosestPlayer())
	local pos = GetEntityCoords(ped)
	local target, distance = ESX.Game.GetClosestPlayer()
	if distance <= 4.0 then
	DrawMarker(2, pos.x, pos.y, pos.z+1.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 255, 0, 170, 0, 1, 2, 1, nil, nil, 0)
end
end

-- Reprise du menu fouille du pz_core (modifié)
local function getPlayerInv(player)
Items = {}
Armes = {}
ArgentSale = {}

ESX.TriggerServerCallback('esx_policejob:getOtherPlayerData', function(data)
	for i=1, #data.accounts, 1 do
		if data.accounts[i].name == 'black_money' and data.accounts[i].money > 0 then
			table.insert(ArgentSale, {
				label    = ESX.Math.Round(data.accounts[i].money),
				value    = 'black_money',
				itemType = 'item_account',
				amount   = data.accounts[i].money
			})

			break
		end
	end

	for i=1, #data.weapons, 1 do
		table.insert(Armes, {
			label    = ESX.GetWeaponLabel(data.weapons[i].name),
			value    = data.weapons[i].name,
			right    = data.weapons[i].ammo,
			itemType = 'item_weapon',
			amount   = data.weapons[i].ammo
		})
	end

	for i=1, #data.inventory, 1 do
		if data.inventory[i].count > 0 then
			table.insert(Items, {
				label    = data.inventory[i].label,
				right    = data.inventory[i].count,
				value    = data.inventory[i].name,
				itemType = 'item_standard',
				amount   = data.inventory[i].count
			})
		end
	end
end, GetPlayerServerId(player))
end

function KeyboardInput(TextEntry, ExampleText, MaxStringLenght)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    blockinput = true
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do 
        Wait(0)
    end 
        
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        blockinput = false
        return result
    else
        Wait(500)
        blockinput = false
        return nil
    end
end

RMenu.Add('bcso', 'main', RageUI.CreateMenu("~y~Bcso", "Intéraction"))
RMenu.Add('bcso', 'inter', RageUI.CreateSubMenu(RMenu:Get('bcso', 'main'), "~y~Bcso", "Intéraction"))
RMenu.Add('bcso', 'info', RageUI.CreateSubMenu(RMenu:Get('bcso', 'main'), "~y~Bcso", "Intéraction"))
RMenu.Add('bcso', 'renfort', RageUI.CreateSubMenu(RMenu:Get('bcso', 'main'), "~y~Bcso", "Intéraction"))
RMenu.Add('bcso', 'voiture', RageUI.CreateSubMenu(RMenu:Get('bcso', 'main'), "~y~Bcso", "Intéraction"))
RMenu.Add('bcso', 'chien', RageUI.CreateSubMenu(RMenu:Get('bcso', 'main'), "~y~Bcso", "Intéraction"))
RMenu.Add('bcso', 'cam', RageUI.CreateSubMenu(RMenu:Get('bcso', 'main'), "~y~Bcso", "Intéraction"))
RMenu.Add('bcso', 'fouiller', RageUI.CreateSubMenu(RMenu:Get('bcso', 'main'), "~y~Bcso", "Intéraction"))

Citizen.CreateThread(function()
    while true do
        RageUI.IsVisible(RMenu:Get('bcso', 'main'), true, true, true, function()

				RageUI.ButtonWithStyle("Contact Bcso", nil, {RightLabel = "→"},true, function()
				end, RMenu:Get('bcso', 'info'))
				
				RageUI.ButtonWithStyle("Intéractions sur personne", nil, {RightLabel = "→"},true, function()
				end, RMenu:Get('bcso', 'inter'))

				RageUI.ButtonWithStyle("Intéractions sur véhicules", nil, {RightLabel = "→"},true, function()
				end, RMenu:Get('bcso', 'voiture'))

				RageUI.ButtonWithStyle("Demande de renfort", nil, {RightLabel = "→"},true, function()
				end, RMenu:Get('bcso', 'renfort'))

				RageUI.ButtonWithStyle("Menu Chien", nil, {RightLabel = "→"},true, function()
				end, RMenu:Get('bcso', 'chien'))

				if ESX.PlayerData.job.grade_name == 'sergeant' or ESX.PlayerData.job.grade_name == 'lieutenant' or ESX.PlayerData.job.grade_name == 'boss' then
				RageUI.ButtonWithStyle("Menu Caméra", nil, {RightLabel = "→"},true, function()
				end, RMenu:Get('bcso', 'cam'))
				else
					RageUI.ButtonWithStyle('Menu Caméra', description, {RightBadge = RageUI.BadgeStyle.Lock }, false, function(Hovered, Active, Selected)
						if (Selected) then
							end 
						end)
					end


    end, function()
	end)

		RageUI.IsVisible(RMenu:Get('bcso', 'inter'), true, true, true, function()

			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
			RageUI.ButtonWithStyle("Donner une Amende",nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
				if Selected then
					local target, distance = ESX.Game.GetClosestPlayer()
					playerheading = GetEntityHeading(GetPlayerPed(-1))
					playerlocation = GetEntityForwardVector(PlayerPedId())
					playerCoords = GetEntityCoords(GetPlayerPed(-1))
					local target_id = GetPlayerServerId(target)
					if closestPlayer ~= -1 and closestDistance <= 3.0 then
					RageUI.CloseAll()        
					OpenBillingMenu() 
					else
						RageUI.Popup({message = "~r~Personne autour"})
					end
				end
			end)

			RageUI.ButtonWithStyle('Fouiller la personne', nil, {RightLabel = "→"}, closestPlayer ~= -1 and closestDistance <= 3.0, function(_, a, s)
				if a then
					MarquerJoueur()
					if s then
					getPlayerInv(closestPlayer)
					ExecuteCommand("me fouille l'individu")
				end
			end
			end, RMenu:Get('bcso', 'fouiller')) 

        RageUI.ButtonWithStyle("Menotter/démenotter", nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
            if (Selected) then
				local target, distance = ESX.Game.GetClosestPlayer()
				playerheading = GetEntityHeading(GetPlayerPed(-1))
				playerlocation = GetEntityForwardVector(PlayerPedId())
				playerCoords = GetEntityCoords(GetPlayerPed(-1))
				local target_id = GetPlayerServerId(target)
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
                TriggerServerEvent('e_bcso:handcuff', GetPlayerServerId(closestPlayer))
			else
						RageUI.Popup({message = "~r~Personne autour"})
				end
            end
        end)

            RageUI.ButtonWithStyle("Escorter", nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
                if (Selected) then
					local target, distance = ESX.Game.GetClosestPlayer()
					playerheading = GetEntityHeading(GetPlayerPed(-1))
					playerlocation = GetEntityForwardVector(PlayerPedId())
					playerCoords = GetEntityCoords(GetPlayerPed(-1))
					local target_id = GetPlayerServerId(target)
					if closestPlayer ~= -1 and closestDistance <= 3.0 then
                TriggerServerEvent('e_bcso:drag', GetPlayerServerId(closestPlayer))
			else
						RageUI.Popup({message = "~r~Personne autour"})
				end
            end
        end)

            RageUI.ButtonWithStyle("Mettre dans un véhicule", nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
                if (Selected) then
					local target, distance = ESX.Game.GetClosestPlayer()
					playerheading = GetEntityHeading(GetPlayerPed(-1))
					playerlocation = GetEntityForwardVector(PlayerPedId())
					playerCoords = GetEntityCoords(GetPlayerPed(-1))
					local target_id = GetPlayerServerId(target)
					if closestPlayer ~= -1 and closestDistance <= 3.0 then
                TriggerServerEvent('e_bcso:putInVehicle', GetPlayerServerId(closestPlayer))
			else
						RageUI.Popup({message = "~r~Personne autour"})
				end
                end
            end)

            RageUI.ButtonWithStyle("Sortir du véhicule", nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
                if (Selected) then
					local target, distance = ESX.Game.GetClosestPlayer()
					playerheading = GetEntityHeading(GetPlayerPed(-1))
					playerlocation = GetEntityForwardVector(PlayerPedId())
					playerCoords = GetEntityCoords(GetPlayerPed(-1))
					local target_id = GetPlayerServerId(target)
					if closestPlayer ~= -1 and closestDistance <= 3.0 then
                TriggerServerEvent('e_bcso:OutVehicle', GetPlayerServerId(closestPlayer))
			else
						RageUI.Popup({message = "~r~Personne autour"})
				end
            end
        end)

    end, function()
	end)

	RageUI.IsVisible(RMenu:Get("bcso",'fouiller'),true,true,true,function() -- Le menu de fouille (inspiré du pz_core / Modifié)
		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

		RageUI.Separator("↓ ~g~Argent Sale ~s~↓")
		for k,v  in pairs(ArgentSale) do
			RageUI.ButtonWithStyle("Argent sale :", nil, {RightLabel = "~g~"..v.label.."$"}, true, function(_, _, s)
				if s then
					local combien = KeyboardInput("Combien ?", '' , '', 8)
					if tonumber(combien) > v.amount then
						RageUI.Popup({message = "~r~Quantité invalide"})
					else
						TriggerServerEvent('jejey:confiscatePlayerItem', GetPlayerServerId(closestPlayer), v.itemType, v.value, tonumber(combien))
					end
					RageUI.GoBack()
				end
			end)
		end

		RageUI.Separator("↓ ~g~Objets ~s~↓")
		for k,v  in pairs(Items) do
			RageUI.ButtonWithStyle(v.label, nil, {RightLabel = "~g~x"..v.right}, true, function(_, _, s)
				if s then
					local combien = KeyboardInput("Combien ?", '' , '', 8)
					if tonumber(combien) > v.amount then
						RageUI.Popup({message = "~r~Quantité invalide"})
					else
						TriggerServerEvent('jejey:confiscatePlayerItem', GetPlayerServerId(closestPlayer), v.itemType, v.value, tonumber(combien))
					end
					RageUI.GoBack()
				end
			end)
		end
			RageUI.Separator("↓ ~g~Armes ~s~↓")

			for k,v  in pairs(Armes) do
				RageUI.ButtonWithStyle(v.label, nil, {RightLabel = "avec ~g~"..v.right.. " ~s~balle(s)"}, true, function(_, _, s)
					if s then
						local combien = KeyboardInput("Combien ?", '' , '', 8)
						if tonumber(combien) > v.amount then
							RageUI.Popup({message = "~r~Quantité invalide"})
						else
							TriggerServerEvent('jejey:confiscatePlayerItem', GetPlayerServerId(closestPlayer), v.itemType, v.value, tonumber(combien))
						end
						RageUI.GoBack()
					end
				end)
			end

		end, function() 
		end)

	RageUI.IsVisible(RMenu:Get('bcso', 'info'), true, true, true, function()

		RageUI.ButtonWithStyle("Prise de service",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local info = 'prise'
				TriggerServerEvent('bcso:PriseEtFinservice', info)
			end
		end)

		RageUI.ButtonWithStyle("Fin de service",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local info = 'fin'
				TriggerServerEvent('bcso:PriseEtFinservice', info)
			end
		end)

		RageUI.ButtonWithStyle("Pause de service",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local info = 'pause'
				TriggerServerEvent('bcso:PriseEtFinservice', info)
			end
		end)

		RageUI.ButtonWithStyle("Standby",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local info = 'standby'
				TriggerServerEvent('bcso:PriseEtFinservice', info)
			end
		end)

		RageUI.ButtonWithStyle("Control en cours",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local info = 'control'
				TriggerServerEvent('bcso:PriseEtFinservice', info)
			end
		end)

		RageUI.ButtonWithStyle("Refus d'obtempérer",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local info = 'refus'
				TriggerServerEvent('bcso:PriseEtFinservice', info)
			end
		end)

		RageUI.ButtonWithStyle("Crime en cours",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local info = 'crime'
				TriggerServerEvent('bcso:PriseEtFinservice', info)
			end
		end)

    end, function()
	end)

	RageUI.IsVisible(RMenu:Get('bcso', 'cam'), true, true, true, function()

		RageUI.ButtonWithStyle("Caméra 1", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 25) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 2", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 26) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 3", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 27) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 4", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 1) 
			end
		end)


		RageUI.ButtonWithStyle("Caméra 5", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 2) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 6", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 3) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 7", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 4) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 8", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 5) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 9", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 6) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 10", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 7) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 11", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 8) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 12", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 9) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 13", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 10) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 14", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 11) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 15", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 12) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 16", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 13) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 17", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 14) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 18", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 15) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 19", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 16) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 20", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 17) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 21", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 18) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 22", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 19) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 23", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 20) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 24", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 21) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 25", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 22) 
			end
		end)

		RageUI.ButtonWithStyle("Caméra 26", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
			if Selected then   
				TriggerEvent('cctv:camera', 23) 
			end
		end)

	end, function()
	end)

	RageUI.IsVisible(RMenu:Get('bcso', 'renfort'), true, true, true, function()

		RageUI.ButtonWithStyle("Petite demande",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				local raison = 'petit'
				local elements  = {}
				local playerPed = PlayerPedId()
				local coords  = GetEntityCoords(playerPed)
				local name = GetPlayerName(PlayerId())
			TriggerServerEvent('renfort', coords, raison)
		end
	end)

	RageUI.ButtonWithStyle("Moyenne demande",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
		if Selected then
			local raison = 'importante'
			local elements  = {}
			local playerPed = PlayerPedId()
			local coords  = GetEntityCoords(playerPed)
			local name = GetPlayerName(PlayerId())
		TriggerServerEvent('renfort', coords, raison)
	end
end)

RageUI.ButtonWithStyle("Grosse demande",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
	if Selected then
		local raison = 'omgad'
		local elements  = {}
		local playerPed = PlayerPedId()
		local coords  = GetEntityCoords(playerPed)
		local name = GetPlayerName(PlayerId())
	TriggerServerEvent('renfort', coords, raison)
end
end)

    end, function()
	end)

	RageUI.IsVisible(RMenu:Get('bcso', 'voiture'), true, true, true, function()
		local coords  = GetEntityCoords(PlayerPedId())
		local vehicle = ESX.Game.GetVehicleInDirection()

		RageUI.ButtonWithStyle("Rechercher une plaque",nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
			if Selected then 
				LookupVehicle()
				RageUI.CloseAll()
			end
			end)

			RageUI.ButtonWithStyle("Mettre en fourrière", nil, { RightLabel = "→" }, true, function(Hovered, Active, Selected)
				if Selected then

					TaskStartScenarioInPlace(PlayerPedId(), 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)

					currentTask.busy = true
					currentTask.task = ESX.SetTimeout(10000, function()
						ClearPedTasks(playerPed)
						ESX.Game.DeleteVehicle(vehicle)
						RageUI.Popup({message = "~o~Mise en fourrière effectuée"})
						currentTask.busy = false
						Citizen.Wait(100) -- sleep the entire script to let stuff sink back to reality
					end)

					-- keep track of that vehicle!
					Citizen.CreateThread(function()
						while currentTask.busy do
							Citizen.Wait(1000)

							vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, 0, 71)
							if not DoesEntityExist(vehicle) and currentTask.busy then
								RageUI.Popup({message = "~r~Le véhicule a bougé!"})
								ESX.ClearTimeout(currentTask.task)
								ClearPedTasks(playerPed)
								currentTask.busy = false
								break
							end
						end
					end)
				end
			end)
	
	end, function()
	end)

	RageUI.IsVisible(RMenu:Get('bcso', 'chien'), true, true, true, function()

			RageUI.ButtonWithStyle("Sortir/Rentrer le chien",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
				if Selected then
					if not DoesEntityExist(bcsoDog) then
                        RequestModel(351016938)
                        while not HasModelLoaded(351016938) do Wait(0) end
                        bcsoDog = CreatePed(4, 351016938, GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 1.0, -0.98), 0.0, true, false)
                        SetEntityAsMissionEntity(bcsoDog, true, true)
						RageUI.Popup({message = "~g~Chien spawn"})
                    else
						RageUI.Popup({message = "~r~Chien despawn"})
                        DeleteEntity(bcsoDog)
                    end
				end
			end)

			RageUI.ButtonWithStyle("Assis",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
				if Selected then
					if DoesEntityExist(bcsoDog) then
                        if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(bcsoDog), true) <= 5.0 then
                            if IsEntityPlayingAnim(bcsoDog, "creatures@rottweiler@amb@world_dog_sitting@base", "base", 3) then
                                ClearPedTasks(bcsoDog)
                            else
                                loadDict('rcmnigel1c')
                                TaskPlayAnim(PlayerPedId(), 'rcmnigel1c', 'hailing_whistle_waive_a', 8.0, -8, -1, 120, 0, false, false, false)
                                Wait(2000)
                                loadDict("creatures@rottweiler@amb@world_dog_sitting@base")
                                TaskPlayAnim(bcsoDog, "creatures@rottweiler@amb@world_dog_sitting@base", "base", 8.0, -8, -1, 1, 0, false, false, false)
                            end
                        else
                            ESX.ShowNotification('dog_too_far')
                        end
                    else
                        ESX.ShowNotification('no_dog')
                    end
				end
			end)

		RageUI.ButtonWithStyle("Cherche de drogue",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				if DoesEntityExist(bcsoDog) then
					if not IsPedDeadOrDying(bcsoDog) then
						if GetDistanceBetweenCoords(GetEntityCoords(bcsoDog), GetEntityCoords(PlayerPedId()), true) <= 3.0 then
							local player, distance = ESX.Game.GetClosestPlayer()
							if distance ~= -1 then
								if distance <= 3.0 then
									local playerPed = GetPlayerPed(player)
									if not IsPedInAnyVehicle(playerPed, true) then
										TriggerServerEvent('bcsodog:hasClosestDrugs', GetPlayerServerId(player))
									end
								end
							end
						end
					else
						ESX.ShowNotification('Votre chien est mort')
					end
				else
					ESX.ShowNotification('Vous n\'avez pas de chien')
				end
			end
		end)

		RageUI.ButtonWithStyle("Dire d'attaquer",nil, {RightLabel = nil}, true, function(Hovered, Active, Selected)
			if Selected then
				if DoesEntityExist(bcsoDog) then
					if not IsPedDeadOrDying(bcsoDog) then
						if GetDistanceBetweenCoords(GetEntityCoords(bcsoDog), GetEntityCoords(PlayerPedId()), true) <= 3.0 then
							local player, distance = ESX.Game.GetClosestPlayer()
							if distance ~= -1 then
								if distance <= 3.0 then
									local playerPed = GetPlayerPed(player)
									if not IsPedInCombat(bcsoDog, playerPed) then
										if not IsPedInAnyVehicle(playerPed, true) then
											TaskCombatPed(bcsoDog, playerPed, 0, 16)
										end
									else
										ClearPedTasksImmediately(bcsoDog)
									end
								end
							end
						end
					else
						ESX.ShowNotification('Votre chien est mort')
					end
				else
					ESX.ShowNotification('Vous n\'avez pas de chien')
			end
		end
	end)

    end, function()
	end)

	Citizen.Wait(0)
	end
end)

function OpenBillingMenu()

	ESX.UI.Menu.Open(
	  'dialog', GetCurrentResourceName(), 'billing',
	  {
		title = "Amende"
	  },
	  function(data, menu)
	  
		local amount = tonumber(data.value)
		local player, distance = ESX.Game.GetClosestPlayer()
  
		if player ~= -1 and distance <= 3.0 then
  
		  menu.close()
		  if amount == nil then
			  ESX.ShowNotification("~r~Problèmes~s~: Montant invalide")
		  else
			local playerPed        = GetPlayerPed(-1)
			TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TIME_OF_DEATH', 0, true)
			Citizen.Wait(5000)
			  TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(player), 'society_bcso', ('bcso'), amount)
			  Citizen.Wait(100)
			  ESX.ShowNotification("~r~Vous avez bien envoyer la facture")
		  end
  
		else
		  ESX.ShowNotification("~r~Problèmes~s~: Aucun joueur à proximitée")
		end
  
	  end,
	  function(data, menu)
		  menu.close()
	  end
	)
  end

  RegisterNetEvent('bcsodog:hasDrugs')
  AddEventHandler('bcsodog:hasDrugs', function(hadIt)
	  if hadIt then
		  ESX.ShowNotification(Strings['drugs_found'])
		  loadDict('missfra0_chop_find')
		  TaskPlayAnim(policeDog, 'missfra0_chop_find', 'chop_bark_at_ballas', 8.0, -8, -1, 0, 0, false, false, false)
	  else
		  ESX.ShowNotification(Strings['no_drugs'])
	  end
  end)

local function LoadAnimDict(dictname)
	if not HasAnimDictLoaded(dictname) then
		RequestAnimDict(dictname) 
		while not HasAnimDictLoaded(dictname) do 
			Citizen.Wait(1)
		end
	end
end

loadDict = function(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) RequestAnimDict(dict) end
end

function OpenVehicleInfosMenu(vehicleData)
	ESX.TriggerServerCallback('e_bcso:getVehicleInfos', function(retrivedInfo)
		local elements = {{label = _U('plate', retrivedInfo.plate)}}

		if retrivedInfo.owner == nil then
			table.insert(elements, {label = _U('owner_unknown')})
		else
			table.insert(elements, {label = _U('owner', retrivedInfo.owner)})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_infos', {
			css      = 'bcso',
			title    = _U('vehicle_info'),
			align    = 'top-left',
			elements = elements
		}, nil, function(data, menu)
			menu.close()
		end)
	end, vehicleData.plate)
end

function LookupVehicle()
	ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'lookup_vehicle', {
		title = _U('search_database_title'),
	}, function(data, menu)
		local length = string.len(data.value)
		if not data.value or length < 2 or length > 8 then
			ESX.ShowNotification(_U('search_database_error_invalid'))
		else
			ESX.TriggerServerCallback('e_bcso:getVehicleInfos', function(retrivedInfo)
				local elements = {{label = _U('plate', retrivedInfo.plate)}}
				menu.close()

				if not retrivedInfo.owner then
					table.insert(elements, {label = _U('owner_unknown')})
				else
					table.insert(elements, {label = _U('owner', retrivedInfo.owner)})
				end

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_infos', {
					title    = _U('vehicle_info'),
					align    = 'top-left',
					elements = elements
				}, nil, function(data2, menu2)
					menu2.close()
				end)
			end, data.value)

		end
	end, function(data, menu)
		menu.close()
	end)
end

RegisterNetEvent('renfort:setBlip')
AddEventHandler('renfort:setBlip', function(coords, raison)
	if raison == 'petit' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		PlaySoundFrontend(-1, "OOB_Start", "GTAO_FM_Events_Soundset", 1)
		ESX.ShowAdvancedNotification('~y~Contact B.C.S.O', '~y~Demande de renfort', 'Demande de renfort demandé.\nRéponse: ~g~CODE-2\n~w~Importance: ~g~Légère.', 'CHAR_CHAT_CALL', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
		color = 2
	elseif raison == 'importante' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		PlaySoundFrontend(-1, "OOB_Start", "GTAO_FM_Events_Soundset", 1)
		ESX.ShowAdvancedNotification('~y~Contact B.C.S.O', '~y~Demande de renfort', 'Demande de renfort demandé.\nRéponse: ~g~CODE-3\n~w~Importance: ~o~Importante.', 'CHAR_CHAT_CALL', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
		color = 47
	elseif raison == 'omgad' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		PlaySoundFrontend(-1, "OOB_Start", "GTAO_FM_Events_Soundset", 1)
		PlaySoundFrontend(-1, "FocusIn", "HintCamSounds", 1)
		ESX.ShowAdvancedNotification('~y~Contact B.C.S.O', '~y~Demande de renfort', 'Demande de renfort demandé.\nRéponse: ~g~CODE-99\n~w~Importance: ~r~URGENTE !\nDANGER IMPORTANT', 'CHAR_CHAT_CALL', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
		PlaySoundFrontend(-1, "FocusOut", "HintCamSounds", 1)
		color = 1
	end
	local blipId = AddBlipForCoord(coords)
	SetBlipSprite(blipId, 161)
	SetBlipScale(blipId, 1.2)
	SetBlipColour(blipId, color)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString('Demande renfort')
	EndTextCommandSetBlipName(blipId)
	Wait(80 * 1000)
	RemoveBlip(blipId)
end)

RegisterNetEvent('bcso:InfoService')
AddEventHandler('bcso:InfoService', function(service, nom)
	if service == 'prise' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('~y~Contact B.C.S.O', '~y~Prise de service', 'Agent: ~g~'..nom..'\n~w~Code: ~g~10-8\n~w~Information: ~g~Prise de service.', 'CHAR_CHAT_CALL', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'fin' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('~y~Contact B.C.S.O', '~y~Fin de service', 'Agent: ~g~'..nom..'\n~w~Code: ~g~10-10\n~w~Information: ~g~Fin de service.', 'CHAR_CHAT_CALL', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'pause' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('~y~Contact B.C.S.O', '~y~Pause de service', 'Agent: ~g~'..nom..'\n~w~Code: ~g~10-6\n~w~Information: ~g~Pause de service.', 'CHAR_CHAT_CALL', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'standby' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('~y~Contact B.C.S.O', '~y~Mise en standby', 'Agent: ~g~'..nom..'\n~w~Code: ~g~10-12\n~w~Information: ~g~Standby, en attente de dispatch.', 'CHAR_CHAT_CALL', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'control' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('~y~Contact B.C.S.O', '~y~Control routier', 'Agent: ~g~'..nom..'\n~w~Code: ~g~10-48\n~w~Information: ~g~Control routier en cours.', 'CHAR_CHAT_CALL', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'refus' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('~y~Contact B.C.S.O', '~y~Refus d\'obtemperer', 'Agent: ~g~'..nom..'\n~w~Code: ~g~10-30\n~w~Information: ~g~Refus d\'obtemperer / Delit de fuite en cours.', 'CHAR_CHAT_CALL', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'crime' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('~y~Contact B.C.S.O', '~y~Crime en cours', 'Agent: ~g~'..nom..'\n~w~Code: ~g~10-31\n~w~Information: ~g~Crime en cours / poursuite en cours.', 'CHAR_CHAT_CALL', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	end
end)

RegisterNetEvent('e_bcso:handcuff')
AddEventHandler('e_bcso:handcuff', function()
  IsHandcuffed    = not IsHandcuffed;
  local playerPed = GetPlayerPed(-1)
  Citizen.CreateThread(function()
    if IsHandcuffed then
        RequestAnimDict('mp_arresting')
        while not HasAnimDictLoaded('mp_arresting') do
            Citizen.Wait(100)
        end
      TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)
      DisableControlAction(2, 37, true)
      SetEnableHandcuffs(playerPed, true)
      SetPedCanPlayGestureAnims(playerPed, false)
      FreezeEntityPosition(playerPed,  true)
      DisableControlAction(0, 24, true) -- Attack
      DisableControlAction(0, 257, true) -- Attack 2
      DisableControlAction(0, 25, true) -- Aim
      DisableControlAction(0, 263, true) -- Melee Attack 1
      DisableControlAction(0, 37, true) -- Select Weapon
      DisableControlAction(0, 47, true)  -- Disable weapon
      DisplayRadar(false)
    else
      ClearPedSecondaryTask(playerPed)
      SetEnableHandcuffs(playerPed, false)
      SetPedCanPlayGestureAnims(playerPed,  true)
      FreezeEntityPosition(playerPed, false)
	  DisplayRadar(true)
    end
  end)
end)

RegisterNetEvent('e_bcso:drag')
AddEventHandler('e_bcso:drag', function(cop)
  IsDragged = not IsDragged
  CopPed = tonumber(cop)
end)

Citizen.CreateThread(function()
  while true do
    Wait(0)
    if IsHandcuffed then
      if IsDragged then
        local ped = GetPlayerPed(GetPlayerFromServerId(CopPed))
        local myped = GetPlayerPed(-1)
        AttachEntityToEntity(myped, ped, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
      else
        DetachEntity(GetPlayerPed(-1), true, false)
      end
    end
  end
end)

RegisterNetEvent('e_bcso:putInVehicle')
AddEventHandler('e_bcso:putInVehicle', function()
  local playerPed = GetPlayerPed(-1)
  local coords    = GetEntityCoords(playerPed)
  if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
    local vehicle = GetClosestVehicle(coords.x,  coords.y,  coords.z,  5.0,  0,  71)
    if DoesEntityExist(vehicle) then
      local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
      local freeSeat = nil
      for i=maxSeats - 1, 0, -1 do
        if IsVehicleSeatFree(vehicle,  i) then
          freeSeat = i
          break
        end
      end
      if freeSeat ~= nil then
        TaskWarpPedIntoVehicle(playerPed,  vehicle,  freeSeat)
      end
    end
  end
end)

RegisterNetEvent('e_bcso:OutVehicle')
AddEventHandler('e_bcso:OutVehicle', function(t)
  local ped = GetPlayerPed(t)
  ClearPedTasksImmediately(ped)
  plyPos = GetEntityCoords(GetPlayerPed(-1),  true)
  local xnew = plyPos.x+2
  local ynew = plyPos.y+2

  SetEntityCoords(GetPlayerPed(-1), xnew, ynew, plyPos.z)
end)
-- Handcuff
Citizen.CreateThread(function()
  while true do
    Wait(0)
    if IsHandcuffed then
      DisableControlAction(0, 142, true) -- MeleeAttackAlternate
      DisableControlAction(0, 30,  true) -- MoveLeftRight
      DisableControlAction(0, 31,  true) -- MoveUpDown
    end
  end
end)

    Citizen.CreateThread(function()
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Citizen.Wait(100)
        end
    end)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if ESX.PlayerData.job and ESX.PlayerData.job.name == 'bcso' then 
            if IsControlJustReleased(0 ,167) then
                RageUI.Visible(RMenu:Get('bcso', 'main'), not RageUI.Visible(RMenu:Get('bcso', 'main')))
            end
        end
    end
end)

scanId = 0
cityRobbery = false
local myspawns = {}

CCTVCamLocations = {
	[1] =  { ['x'] = 24.18,['y'] = -1347.35,['z'] = 29.5,['h'] = 271.32, ['info'] = ' Store Camera 1', ["recent"] = false },
	[2] =  { ['x'] = -46.56,['y'] = -1757.98,['z'] = 29.43,['h'] = 48.68, ['info'] = ' Store Camera 2', ["recent"] = false },
	[3] =  { ['x'] = -706.02,['y'] = -913.61,['z'] = 19.22,['h'] = 85.61, ['info'] = ' Store Camera 3', ["recent"] = false },
	[4] =  { ['x'] = -1221.97,['y'] = -908.42,['z'] = 12.33,['h'] = 31.1, ['info'] = ' Store Camera 4', ["recent"] = false },
	[5] =  { ['x'] = 1164.99,['y'] = -322.78,['z'] = 69.21,['h'] = 96.91, ['info'] = ' Store Camera 5', ["recent"] = false },
	[6] =  { ['x'] = 372.25,['y'] = 326.43,['z'] = 103.57,['h'] = 252.9, ['info'] = ' Store Camera 6', ["recent"] = false },
	[7] =  { ['x'] = -1819.98,['y'] = 794.57,['z'] = 138.09,['h'] = 126.56, ['info'] = ' Store Camera 7', ["recent"] = false },
	[8] =  { ['x'] = -2966.24,['y'] = 390.94,['z'] = 15.05,['h'] = 84.58, ['info'] = ' Store Camera 8', ["recent"] = false },
	[9] =  { ['x'] = -3038.92,['y'] = 584.21,['z'] = 7.91,['h'] = 19.43, ['info'] = ' Store Camera 9', ["recent"] = false },
	[10] =  { ['x'] = -3242.48,['y'] = 999.79,['z'] = 12.84,['h'] = 351.35, ['info'] = ' Store Camera 10', ["recent"] = false },
	[11] =  { ['x'] = 2557.14,['y'] = 380.64,['z'] = 108.63,['h'] = 353.01, ['info'] = ' Store Camera 11', ["recent"] = false },
	[12] =  { ['x'] = 1166.02,['y'] = 2711.15,['z'] = 38.16,['h'] = 175.0, ['info'] = ' Store Camera 12', ["recent"] = false },
	[13] =  { ['x'] = 549.32,['y'] = 2671.3,['z'] = 42.16,['h'] = 94.96, ['info'] = ' Store Camera 13', ["recent"] = false },
	[14] =  { ['x'] = 1959.96,['y'] = 3739.99,['z'] = 32.35,['h'] = 296.38, ['info'] = ' Store Camera 14', ["recent"] = false },
	[15] =  { ['x'] = 2677.98,['y'] = 3279.28,['z'] = 55.25,['h'] = 327.81, ['info'] = ' Store Camera 15', ["recent"] = false },
	[16] =  { ['x'] = 1392.88,['y'] = 3606.7,['z'] = 34.99,['h'] = 201.69, ['info'] = ' Store Camera 16', ["recent"] = false },
	[17] =  { ['x'] = 1697.8,['y'] = 4922.69,['z'] = 42.07,['h'] = 322.95, ['info'] = ' Store Camera 17', ["recent"] = false },
	[18] =  { ['x'] = 1728.82,['y'] = 6417.38,['z'] = 35.04,['h'] = 233.94, ['info'] = ' Store Camera 18', ["recent"] = false },
	[19] =  { ['x'] = 733.45,['y'] = 127.58,['z'] = 80.69,['h'] = 285.51, ['info'] = ' Cam Power' },
	[20] =  { ['x'] = 1887.25,['y'] = 2605.35,['z'] = 50.40,['h'] = 111.88, ['info'] = ' Cam Jail Front' },
	[21] =  { ['x'] = 1709.37,['y'] = 2569.90,['z'] = 56.18,['h'] = 50.18, ['info'] = ' Cam Jail Prisoner Drop Off' },
	[22] =  { ['x'] = -644.24,['y'] = -241.11,['z'] = 37.97,['h'] = 282.81, ['info'] = ' Cam Jewelry Store' },
	[23] =  { ['x'] = -115.3,['y'] = 6441.41,['z'] = 31.53,['h'] = 341.95, ['info'] = ' Cam Paleto Bank Outside' },
	[24] =  { ['x'] = 240.07,['y'] = 218.97,['z'] = 106.29,['h'] = 276.14, ['info'] = ' Cam Main Bank 1' },
	[25] =  { ['x'] = 92.17,['y'] = -1923.14,['z'] = 29.5,['h'] = 205.95, ['info'] = ' Ballas', ["recent"] = false },
	[26] =  { ['x'] = -176.26,['y'] = -1681.15,['z'] = 47.43,['h'] = 313.29, ['info'] = ' Famillies', ["recent"] = false },
	[27] =  { ['x'] = 285.95,['y'] = -2003.95,['z'] = 35.0,['h'] = 226.0, ['info'] = ' Vagos', ["recent"] = false },	
}

ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
	  TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
	  Citizen.Wait(0)
	  PlayerData = ESX.GetPlayerData()
	end
end)

inCam = false
cctvCam = 0
RegisterNetEvent("cctv:camera")
AddEventHandler("cctv:camera", function(camNumber)
	camNumber = tonumber(camNumber)
	if inCam then
		inCam = false
		PlaySoundFrontend(-1, "HACKING_SUCCESS", false)
		-- TriggerEvent('animation:tablet',false)
		Wait(250)
		ClearPedTasks(GetPlayerPed(-1))
	else
		if camNumber > 0 and camNumber < #CCTVCamLocations+1 then
			PlaySoundFrontend(-1, "HACKING_SUCCESS", false)
			TriggerEvent("cctv:startcamera",camNumber)
		else
			exports['mythic_notify']:SendAlert('error', "This camera appears to be faulty")
		end
	end
end)

RegisterNetEvent("cctv:startcamera")
AddEventHandler("cctv:startcamera", function(camNumber)

	TriggerEvent('animation:tablet',true)
	local camNumber = tonumber(camNumber)
	local x = CCTVCamLocations[camNumber]["x"]
	local y = CCTVCamLocations[camNumber]["y"]
	local z = CCTVCamLocations[camNumber]["z"]
	local h = CCTVCamLocations[camNumber]["h"]

	print("starting cam")
	inCam = true

	SetTimecycleModifier("heliGunCam")
	SetTimecycleModifierStrength(1.0)
	local scaleform = RequestScaleformMovie("TRAFFIC_CAM")
	while not HasScaleformMovieLoaded(scaleform) do
		Citizen.Wait(0)
	end

	local lPed = GetPlayerPed(-1)
	cctvCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
	SetCamCoord(cctvCam,x,y,z+1.2)						
	SetCamRot(cctvCam, -15.0,0.0,h)
	SetCamFov(cctvCam, 110.0)
	RenderScriptCams(true, false, 0, 1, 0)
	PushScaleformMovieFunction(scaleform, "PLAY_CAM_MOVIE")
	SetFocusArea(x, y, z, 0.0, 0.0, 0.0)
	PopScaleformMovieFunctionVoid()

	while inCam do
		SetCamCoord(cctvCam,x,y,z+1.2)						
		-- SetCamRot(cctvCam, -15.0,0.0,h)
		PushScaleformMovieFunction(scaleform, "SET_ALT_FOV_HEADING")
		PushScaleformMovieFunctionParameterFloat(GetEntityCoords(h).z)
		PushScaleformMovieFunctionParameterFloat(1.0)
		PushScaleformMovieFunctionParameterFloat(GetCamRot(cctvCam, 2).z)
		PopScaleformMovieFunctionVoid()
		DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
		Citizen.Wait(1)
	end
	ClearFocus()
	ClearTimecycleModifier()
	RenderScriptCams(false, false, 0, 1, 0)
	SetScaleformMovieAsNoLongerNeeded(scaleform)
	DestroyCam(cctvCam, false)
	SetNightvision(false)
	SetSeethrough(false)	

end)

Citizen.CreateThread(function ()
	while true do
		Citizen.Wait(0)
		if inCam then

			local rota = GetCamRot(cctvCam, 2)

			if IsControlPressed(1, Keys['N4']) then
				SetCamRot(cctvCam, rota.x, 0.0, rota.z + 0.7, 2)
			end

			if IsControlPressed(1, Keys['N6']) then
				SetCamRot(cctvCam, rota.x, 0.0, rota.z - 0.7, 2)
			end

			if IsControlPressed(1, Keys['N8']) then
				SetCamRot(cctvCam, rota.x + 0.7, 0.0, rota.z, 2)
			end

			if IsControlPressed(1, Keys['N5']) then
				SetCamRot(cctvCam, rota.x - 0.7, 0.0, rota.z, 2)
			end
		end
	end
end)

-----------------------------------------------------------------------------------------------


Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local plyCoords3 = GetEntityCoords(GetPlayerPed(-1), false)
		local dist3 = Vdist(plyCoords3.x, plyCoords3.y, plyCoords3.z, Config.pos.coffre.position.x, Config.pos.coffre.position.y, Config.pos.coffre.position.z)
		if dist3 <= 15.0 then
		DrawMarker(20, Config.pos.coffre.position.x, Config.pos.coffre.position.y, Config.pos.coffre.position.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 255, 0, 255, 0, 1, 2, 0, nil, nil, 0)
		end
		if dist3 <= 1.0 then
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'bcso' then  
				ESX.ShowHelpNotification("Appuyez sur [~b~E~w~] pour accéder au coffre")
				if IsControlJustPressed(1,51) then
					coffrenom = "bcso"
					coffrezebieny(coffrenom)
				end   
			end
		end 
	end
end)

coffreharchouma = false


RMenu.Add('coffreenypapi', 'main', RageUI.CreateMenu("Stockage", " "))

RMenu.Add('coffreenypapi', 'coffreprendre', RageUI.CreateSubMenu(RMenu:Get('coffreenypapi', 'main'), "Prendre objet", " "))
RMenu.Add('coffreenypapi', 'coffredepot', RageUI.CreateSubMenu(RMenu:Get('coffreenypapi', 'main'), "Déposer objet", " "))

RMenu.Add('coffreenypapi', 'armeprendre', RageUI.CreateSubMenu(RMenu:Get('coffreenypapi', 'main'), "Prendre objet", " "))
RMenu.Add('coffreenypapi', 'armedepot', RageUI.CreateSubMenu(RMenu:Get('coffreenypapi', 'main'), "Déposer objet", " "))

RMenu:Get('coffreenypapi', 'main').Closed = function()
coffreharchouma = false
end


function coffrezebieny(societezebi)
ESX.TriggerServerCallback('h4ci_coffre:inventairejoueur', function(inventory)
   inventaireducoffreeny = inventory.items
end)

ESX.TriggerServerCallback('h4ci_coffre:prendreitem', function(items)
	itemsducoffrebb = items
end, societezebi)

if not coffreharchouma then
	coffreharchouma = true
	
	RageUI.Visible(RMenu:Get('coffreenypapi', 'main'), true)
while coffreharchouma do

	RageUI.IsVisible(RMenu:Get('coffreenypapi', 'main'), true, true, true, function()

		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'bcso' and ESX.PlayerData.job.grade_name == 'boss' or ESX.PlayerData.job.grade_name == 'lieutenant' then 
		RageUI.ButtonWithStyle("Prendre objet(s)", nil, {RightLabel = "→"},true, function()
		end, RMenu:Get('coffreenypapi', 'coffreprendre'))
	else
		RageUI.ButtonWithStyle('Prendre objet(s)', description, {RightBadge = RageUI.BadgeStyle.Lock }, false, function(Hovered, Active, Selected)
			if (Selected) then
				end 
			end)
		end

		RageUI.ButtonWithStyle("Déposer objet(s)", nil, {RightLabel = "→"},true, function()
		end, RMenu:Get('coffreenypapi', 'coffredepot'))

		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'bcso' and ESX.PlayerData.job.grade_name == 'boss' or ESX.PlayerData.job.grade_name == 'lieutenant' then 
			RageUI.ButtonWithStyle("Prendre Arme(s)",nil, {RightLabel = ""}, true, function(Hovered, Active, Selected)
				if Selected then
					OpenGetWeaponMenu()
					RageUI.CloseAll()
				end
			end)
		else
			RageUI.ButtonWithStyle('Prendre Arme(s)', description, {RightBadge = RageUI.BadgeStyle.Lock }, false, function(Hovered, Active, Selected)
				if (Selected) then
					end 
				end)
			end
			
		--	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' and ESX.PlayerData.job.grade_name == 'boss' or  then 
			RageUI.ButtonWithStyle("Déposer Arme(s)",nil, {RightLabel = ""}, true, function(Hovered, Active, Selected)
				if Selected then
					OpenPutWeaponMenu()
					RageUI.CloseAll()
				end
			end)
		--end

		end, function()
		end)

	RageUI.IsVisible(RMenu:Get('coffreenypapi', 'coffreprendre'), true, true, true, function()

	for i=1, #itemsducoffrebb, 1 do
		RageUI.ButtonWithStyle("x"..itemsducoffrebb[i].count.." "..itemsducoffrebb[i].label, "Pour prendre cet objet.", {RightLabel = "→"},true, function(Hovered, Active, Selected)
		if (Selected) then   
		
		local montant = KeyboardInput('Montant que vous voulez retirer de cet objet', '', 2)
		montant = tonumber(montant)
		if not montant then
			ESX.ShowNotification('quantité invalide')
		else
			TriggerServerEvent('h4ci_coffre:prendreitems', itemsducoffrebb[i].name, montant, societezebi)
			RageUI.CloseAll()
			coffreharchouma = false
		end

			end
		end)
	end

		end, function()
		end)


	RageUI.IsVisible(RMenu:Get('coffreenypapi', 'coffredepot'), true, true, true, function()

	for i=1, #inventaireducoffreeny, 1 do
		if inventaireducoffreeny[i].count > 0 then
		RageUI.ButtonWithStyle("x"..inventaireducoffreeny[i].count.." "..inventaireducoffreeny[i].label, "Pour déposer cet objet.", {RightLabel = "→"},true, function(Hovered, Active, Selected)
		if (Selected) then   
		
		local montant = KeyboardInput('Montant que vous voulez déposer de cet objet', '', 2)
		montant = tonumber(montant)
		if not montant then
			ESX.ShowNotification('quantité invalide')
		else
			TriggerServerEvent('h4ci_coffre:stockitem', inventaireducoffreeny[i].name, montant, societezebi)
			RageUI.CloseAll()
			coffreharchouma = false
		end

			end
			end)
		end
	end

		end, function()
		end)
		Citizen.Wait(0)
	end
else
	coffreharchouma = false
end
end

function OpenGetWeaponMenu()

	ESX.TriggerServerCallback('bcso:getArmoryWeapons', function(weapons)
		local elements = {}

		for i=1, #weapons, 1 do
			if weapons[i].count > 0 then
				table.insert(elements, {
					label = 'x' .. weapons[i].count .. ' ' .. ESX.GetWeaponLabel(weapons[i].name),
					value = weapons[i].name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_get_weapon',
		{
			title    = _U('get_weapon_menu'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)

			menu.close()

			ESX.TriggerServerCallback('bcso:removeArmoryWeapon', function()
			OpenGetWeaponMenu()
			end, data.current.value)

		end, function(data, menu)
			menu.close()
		end)
	end)

end

function OpenPutWeaponMenu()
	local elements   = {}
	local playerPed  = PlayerPedId()
	local weaponList = ESX.GetWeaponList()

	for i=1, #weaponList, 1 do
		local weaponHash = GetHashKey(weaponList[i].name)

		if HasPedGotWeapon(playerPed, weaponHash, false) and weaponList[i].name ~= 'WEAPON_UNARMED' then
			table.insert(elements, {
				label = weaponList[i].label,
				value = weaponList[i].name
			})
		end
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_put_weapon',
	{
		title    = _U('put_weapon_menu'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)

		menu.close()

		ESX.TriggerServerCallback('bcso:addArmoryWeapon', function()
			OpenPutWeaponMenu()
		end, data.current.value, true)

	end, function(data, menu)
		menu.close()
	end)
end

---------------- FONCTIONS ------------------

RMenu.Add('enos', 'boss', RageUI.CreateMenu("Bcso", "Actions Patron"))
Citizen.CreateThread(function()
    while true do

        RageUI.IsVisible(RMenu:Get('enos', 'boss'), true, true, true, function()

				RageUI.ButtonWithStyle("Retirer argent de société",nil, {RightLabel = ""}, true, function(Hovered, Active, Selected)
					if Selected then
						local amount = KeyboardInput("Montant", "", 9)
						amount = tonumber(amount)
					if amount == nil then
						ESX.ShowNotification('Montant invalide')
					else
						TriggerServerEvent('esx_society:withdrawMoney', 'bcso', amount)
						end
					end
				end)
	
				RageUI.ButtonWithStyle("Déposer argent de société",nil, {RightLabel = ""}, true, function(Hovered, Active, Selected)
					if Selected then
						local amount = KeyboardInput("Montant", "", 9)
						amount = tonumber(amount)
							if amount == nil then
								ESX.ShowNotification('Montant invalide')
							else
								TriggerServerEvent('esx_society:depositMoney', 'bcso', amount)
							end
						end
					end) 
	
			   RageUI.ButtonWithStyle("Accéder aux actions de Management",nil, {RightLabel = ""}, true, function(Hovered, Active, Selected)
					if Selected then
						aboss()
						RageUI.CloseAll()
					end
				end)


        end, function()
        end, 1)
                        Citizen.Wait(0)
                                end
                            end)

---------------------------------------------

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

            if ESX.PlayerData.job and ESX.PlayerData.job.name == 'bcso' and ESX.PlayerData.job.grade_name == 'boss' then 

            local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
            local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, Config.pos.boss.position.x, Config.pos.boss.position.y, Config.pos.boss.position.z)
            if dist <= 15.0 then
            DrawMarker(20, Config.pos.boss.position.x, Config.pos.boss.position.y, Config.pos.boss.position.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 255, 0, 255, 0, 1, 2, 0, nil, nil, 0)
            end
            if dist <= 1.0 then
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_TALK~ pour accéder au Actions Patron")
                if IsControlJustPressed(1,51) then
                    RageUI.Visible(RMenu:Get('enos', 'boss'), not RageUI.Visible(RMenu:Get('enos', 'boss')))
                end
            end
        end
    end
end)

function aboss()
    TriggerEvent('esx_society:openBossMenu', 'bcso', function(data, menu)
        menu.close()
    end, {wash = false})
end

------------------------------------

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

            if ESX.PlayerData.job and ESX.PlayerData.job.name == 'bcso' then 
            DrawMarker(20, Config.pos.vestiaire.position.x, Config.pos.vestiaire.position.y, Config.pos.vestiaire.position.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 255, 0, 255, 0, 1, 2, 0, nil, nil, 0)
            local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
            local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, Config.pos.vestiaire.position.x, Config.pos.vestiaire.position.y, Config.pos.vestiaire.position.z)
        
            if dist <= 1.0 then
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_TALK~ pour accéder au vestiaire")
                if IsControlJustPressed(1,51) then
                    OpenVestiaire()
                end
        end
    end
    end
end)


local bcso_vestiaire = false

RMenu.Add('bcso_vestiaire', 'main', RageUI.CreateMenu("~y~Vestiaires", "", 10,80))
RMenu:Get('bcso_vestiaire', 'main'):SetSubtitle("Vestiaires")

RMenu:Get('bcso_vestiaire', 'main').EnableMouse = false
RMenu:Get('bcso_vestiaire', 'main').Closed = function()
	bcso_vestiaire = false
end


function OpenVestiaire()
	if not bcso_vestiaire then
		bcso_vestiaire = true
		RageUI.CloseAll()
		RageUI.Visible(RMenu:Get('bcso_vestiaire', 'main'), true)
	Citizen.CreateThread(function()
		while bcso_vestiaire do
			Citizen.Wait(1)
				local pCo = GetEntityCoords(PlayerPedId())
				RageUI.IsVisible(RMenu:Get('bcso_vestiaire', 'main'), true, true, true, function()

					RageUI.Separator("~o~"..GetPlayerName(PlayerId()).. "~w~ - ~o~" ..ESX.PlayerData.job.grade_label.. "")

						for index,infos in pairs(Bcso.clothes.specials) do
							RageUI.ButtonWithStyle(infos.label,nil, {RightBadge = RageUI.BadgeStyle.Clothes}, ESX.PlayerData.job.grade >= infos.minimum_grade, function(_,_,s)
								if s then
									ApplySkin(infos)
								end
							end)
						end

                        RageUI.Separator("~o~Gestion du Gilet par balle")

						for index,infos in pairs(Bcso.clothes.grades) do
							RageUI.ButtonWithStyle(infos.label,nil, {RightBadge = RageUI.BadgeStyle.Clothes}, ESX.PlayerData.job.grade >= infos.minimum_grade, function(_,_,s)
							if s then
								ApplySkin(infos)
								SetPedArmour(PlayerPedId(), 100)
							end
						end)
					end
				end)
			end
		end)
	end
end

function ApplySkin(infos)
	TriggerEvent('skinchanger:getSkin', function(skin)
		local uniformObject

		if skin.sex == 0 then
			uniformObject = infos.variations.male
		else
			uniformObject = infos.variations..female
		end

		if uniformObject then
			TriggerEvent('skinchanger:loadClothes', skin, uniformObject)
		end

		infos.onEquip()
	end)
end

-----------------------------------------------------------

function SetVehicleMaxMods(vehicle)
    local props = {
      modEngine       = 2,
      modBrakes       = 2,
      modTransmission = 2,
      modSuspension   = 3,
      modTurbo        = true,
    }
    ESX.Game.SetVehicleProperties(vehicle, props)
end

local bcso_garage = false

RMenu.Add('bcso_garage', 'main', RageUI.CreateMenu("~y~Garage", ""))
RMenu:Get('bcso_garage', 'main'):SetSubtitle("Liste des voitures")

RMenu:Get('bcso_garage', 'main').EnableMouse = false
RMenu:Get('bcso_garage', 'main').Closed = function()
	bcso_garage = false
end


function openVeh()
	if not bcso_garage then
		bcso_garage = true
		RageUI.Visible(RMenu:Get('bcso_garage', 'main'), true)
	Citizen.CreateThread(function()
		while bcso_garage do
			Citizen.Wait(1)
					RageUI.IsVisible(RMenu:Get('bcso_garage', 'main'), true, true, true, function()
						local pCo = GetEntityCoords(PlayerPedId())
	
						for index,infos in pairs(Bcso.vehicles.car) do
							if infos.category ~= nil then 
								RageUI.Separator(infos.category)
							else 
								RageUI.ButtonWithStyle(infos.label,nil, {RightBadge = RageUI.BadgeStyle.Car}, ESX.PlayerData.job.grade >= infos.minimum_grade, function(_,_,s)
									if s then
										Citizen.CreateThread(function()
											local model = GetHashKey(infos.model)
											RequestModel(model)
											while not HasModelLoaded(model) do Citizen.Wait(1) end
											local vehicle = CreateVehicle(model, Config.spawn.voiture.position.x, Config.spawn.voiture.position.y, Config.spawn.voiture.position.z, Config.spawn.voiture.position.h, true, false)
											SetModelAsNoLongerNeeded(model)
                                            SetPedIntoVehicle(GetPlayerPed(-1), vehicle, -1)
                                            TriggerServerEvent('ddx_vehiclelock:givekey', 'no', GetVehicleNumberPlateText(vehicle))
                                            SetVehicleMaxMods(vehicle)
											bcso_garage = false
											RageUI.CloseAll()
										end)
	
									end
								end)
							end
						end

						RageUI.ButtonWithStyle("Ranger le véhicule", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
							if (Selected) then   
							local veh,dist4 = ESX.Game.GetClosestVehicle(playerCoords)
							if dist4 < 5 then
								DeleteEntity(veh)
                                TriggerServerEvent('ddx_vehiclelock:deletekeyjobs', 'no')
							end 
						end
					end) 
					end, function()    
					end, 1)
			end
		end)
	end
end

Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
    

    
                local plyCoords3 = GetEntityCoords(GetPlayerPed(-1), false)
                local dist3 = Vdist(plyCoords3.x, plyCoords3.y, plyCoords3.z, Config.pos.garagevoiture.position.x, Config.pos.garagevoiture.position.y, Config.pos.garagevoiture.position.z)
                if dist3 <= 15.0 then
                DrawMarker(20, Config.pos.garagevoiture.position.x, Config.pos.garagevoiture.position.y, Config.pos.garagevoiture.position.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 255, 0, 255, 0, 1, 2, 0, nil, nil, 0)
                end
            if dist3 <= 3.0 then
            if ESX.PlayerData.job and ESX.PlayerData.job.name == 'bcso' or ESX.PlayerData.job2 and ESX.PlayerData.job2.name == 'bcso' then    
                    ESX.ShowHelpNotification("Appuyez sur [~b~E~w~] pour accéder au garage")
                    if IsControlJustPressed(1,51) then           
                        openVeh()
                    end   
                end
               end 
        end
end)


RMenu.Add('garageheli', 'main', RageUI.CreateMenu("Garage", "Garage du LSPD"))

  Citizen.CreateThread(function()
      while true do
          RageUI.IsVisible(RMenu:Get('garageheli', 'main'), true, true, true, function() 
  
              RageUI.ButtonWithStyle("Ranger au garage", nil, {RightLabel = "→→"},true, function(Hovered, Active, Selected)
              if (Selected) then   
              local veh,dist4 = ESX.Game.GetClosestVehicle(playerCoords)
              if dist4 < 4 then
                  DeleteEntity(veh)
                  RageUI.CloseAll()
              end 
          end
      end) 
  
              RageUI.ButtonWithStyle("Hélicoptère", nil, {RightLabel = "→"},true, function(Hovered, Active, Selected)
              if (Selected) then
              Citizen.Wait(1)  
              spawnuniCarre("buzzard")
              RageUI.CloseAll()
              end
          end)
              
                  end, function()
                  end)
  
              Citizen.Wait(0)
          end
      end)
  
  Citizen.CreateThread(function()
          while true do
              Citizen.Wait(0)
      
  
      
                  local plyCoords3 = GetEntityCoords(GetPlayerPed(-1), false)
                  local dist3 = Vdist(plyCoords3.x, plyCoords3.y, plyCoords3.z, Config.pos.garageheli.position.x, Config.pos.garageheli.position.y, Config.pos.garageheli.position.z)
                  if dist3 <= 15.0 then
                    DrawMarker(20, Config.pos.garageheli.position.x, Config.pos.garageheli.position.y, Config.pos.garageheli.position.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 255, 0, 255, 0, 1, 2, 0, nil, nil, 0)
                    end
              if dist3 <= 3.0 then
              if ESX.PlayerData.job and ESX.PlayerData.job.name == 'bcso' or ESX.PlayerData.job2 and ESX.PlayerData.job2.name == 'bcso' then    
                      ESX.ShowHelpNotification("Appuyez sur [~b~E~w~] pour accéder au garage")
                      if IsControlJustPressed(1,51) then           
                          RageUI.Visible(RMenu:Get('garageheli', 'main'), not RageUI.Visible(RMenu:Get('garageheli', 'main')))
                      end   
                  end
                 end 
          end
  end)
  
  function spawnuniCarre(car)
      local car = GetHashKey(car)
      RequestModel(car)
      while not HasModelLoaded(car) do
          RequestModel(car)
          Citizen.Wait(0)
      end
      local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), false))
      local vehicle = CreateVehicle(car, Config.spawn.spawnheli.position.x, Config.spawn.spawnheli.position.y, Config.spawn.spawnheli.position.z, Config.spawn.spawnheli.position.h, true, false)
      SetEntityAsMissionEntity(vehicle, true, true)
      local plaque = "Bcso"..math.random(1,9)
      SetVehicleNumberPlateText(vehicle, plaque) 
      SetPedIntoVehicle(GetPlayerPed(-1),vehicle,-1)
      SetVehicleMaxMods(vehicle)
end

-------armurerie

RMenu.Add('armubcso', 'main', RageUI.CreateMenu("Armurerie", " "))

Citizen.CreateThread(function()
    while true do
        RageUI.IsVisible(RMenu:Get('armubcso', 'main'), true, true, true, function()   

            RageUI.ButtonWithStyle("Equipement de base", nil, { },true, function(Hovered, Active, Selected)
                if (Selected) then   
                    TriggerServerEvent('equipementbase')
                end
            end)


            if ESX.PlayerData.job.grade_name == 'officer' then
                for k,v in pairs(Config.armurerie) do
                RageUI.ButtonWithStyle(v.nom, nil, { },true, function(Hovered, Active, Selected)
                    if (Selected) then   
                        TriggerServerEvent('armurerie', v.arme, v.prix)
                    end
                end)
            end
        end

            if ESX.PlayerData.job.grade_name == 'sergeant' then
                for k,v in pairs(Config.arm) do
                RageUI.ButtonWithStyle(v.nom, nil, { },true, function(Hovered, Active, Selected)
                    if (Selected) then   
                        TriggerServerEvent('armurerie', v.arme, v.prix)
                    end
                end)
            end
        end

                    if ESX.PlayerData.job.grade_name == 'lieutenant' then
                    for k,v in pairs(Config.arm) do
                    RageUI.ButtonWithStyle(v.nom, nil, { },true, function(Hovered, Active, Selected)
                        if (Selected) then   
                            TriggerServerEvent('armurerie', v.arme, v.prix)
                        end
                    end)
                end
            end

            if ESX.PlayerData.job.grade_name == 'boss' then
                for k,v in pairs(Config.armi) do
                RageUI.ButtonWithStyle(v.nom, nil, { },true, function(Hovered, Active, Selected)
                    if (Selected) then   
                        TriggerServerEvent('armurerie', v.arme, v.prix)
                    end
                end)
            end
        end

    



        end, function()
        end)
    Citizen.Wait(0)
    end
end)

Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
                local plyCoords2 = GetEntityCoords(GetPlayerPed(-1), false)
                local dist2 = Vdist(plyCoords2.x, plyCoords2.y, plyCoords2.z, Config.pos.armurerie.position.x, Config.pos.armurerie.position.y, Config.pos.armurerie.position.z)
                if dist2 <= 15.0 then
                    DrawMarker(20, Config.pos.armurerie.position.x, Config.pos.armurerie.position.y, Config.pos.armurerie.position.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 255, 0, 255, 0, 1, 2, 0, nil, nil, 0)
                    end
		    if dist2 <= 1.0 then
		    if ESX.PlayerData.job and ESX.PlayerData.job.name == 'bcso' then 	
                    ESX.ShowHelpNotification("Appuyez sur [~b~E~w~] pour accéder à l'armurerie")
                    if IsControlJustPressed(1,51) then
                        RageUI.Visible(RMenu:Get('armubcso', 'main'), not RageUI.Visible(RMenu:Get('armubcso', 'main')))
                    end   
                end
            end 
        end
end)

