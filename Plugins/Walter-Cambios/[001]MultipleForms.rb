#Copiar los atributos de Quilava a Cyndaquil
MultipleForms.copy(:QUILAVA, :CYNDAQUIL)

#Actualizacion de las formas de los pokes legendarios
MultipleForms.register(:RESHIRAM, {
    "getFormOnBattle" => proc { |pkmn|
        if pkmn.ability == :TURBOBLAZE && pkmn.form == 0
            next 1
        end
    },
    "getFormOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
        next 0 if pkmn.form >= 1
    }
})

MultipleForms.register(:ZEKROM, {
    "getFormOnBattle" => proc { |pkmn|
        if pkmn.ability == :TERAVOLT && pkmn.form == 0
            next 1
        end
    },
    "getFormOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
        next 0 if pkmn.form >= 1
    }
})

MultipleForms.register(:KYUREM, {
    "getFormOnBattle" => proc { |pkmn|
        if pkmn.form == 1 || pkmn.form == 2
            next pkmn.form + 2
        end
    },
    "getFormOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
        next pkmn.form - 2 if pkmn.form >= 3   # Fused forms stop glowing
    },
    "onSetForm" => proc { |pkmn, form, oldForm|
        case form
        when 0   # Normal
            pkmn.moves.each_with_index do |move, i|
            case move.id
            when :ICEBURN, :FREEZESHOCK
                next if !GameData::Move.exists?(:GLACIATE)
                if pkmn.hasMove?(:GLACIATE)
                    pkmn.moves[i] = nil
                else
                    move.id = :GLACIATE
                end
            when :FUSIONFLARE, :FUSIONBOLT
                next if !GameData::Move.exists?(:SCARYFACE)
                if pkmn.hasMove?(:SCARYFACE)
                    pkmn.moves[i] = nil
                else
                    move.id = :SCARYFACE
                end
            end
            pkmn.moves.compact!
        end
        when 1   # White
            pkmn.moves.each do |move|
            case move.id
            when :GLACIATE
                next if !GameData::Move.exists?(:ICEBURN) || pkmn.hasMove?(:ICEBURN)
                move.id = :ICEBURN
            when :SCARYFACE
                next if !GameData::Move.exists?(:FUSIONFLARE) || pkmn.hasMove?(:FUSIONFLARE)
                move.id = :FUSIONFLARE
            end
        end
        when 2   # Black
            pkmn.moves.each do |move|
            case move.id
            when :GLACIATE
                next if !GameData::Move.exists?(:FREEZESHOCK) || pkmn.hasMove?(:FREEZESHOCK)
                move.id = :FREEZESHOCK
            when :SCARYFACE
                next if !GameData::Move.exists?(:FUSIONBOLT) || pkmn.hasMove?(:FUSIONBOLT)
                move.id = :FUSIONBOLT
            end
        end
    end
  }
})

MultipleForms.register(:ZACIAN, {
    "getFormOnBattle" => proc { |pkmn|
        if pkmn.form == 0 && pkmn.hasItem?(:RUSTEDSWORD)
            next 1
        end
    },
    "changePokemonOnStartingBattle" => proc { |pkmn, battle|
        if GameData::Move.exists?(:BEHEMOTHBLADE) && pkmn.hasItem?(:RUSTEDSWORD)
            pkmn.moves.each { |move| move.id = :BEHEMOTHBLADE if move.id == :IRONHEAD }
        end
    },
    "getFormOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
        next 0 if endBattle
    },
    "changePokemonOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
        if endBattle
            pkmn.moves.each { |move| move.id = :IRONHEAD if move.id == :BEHEMOTHBLADE }
        end
    },
    "getFormOnAttack" => proc { |pkmn, move|
        if pkmn.form == 1 && move == :BEHEMOTHBLADE
            next 2
        end
    }
})

MultipleForms.register(:ZAMAZENTA, {
    "getFormOnBattle" => proc { |pkmn|
        if pkmn.form == 0 && pkmn.hasItem?(:RUSTEDSHIELD)
            next 1
        end
    },
    "changePokemonOnStartingBattle" => proc { |pkmn, battle|
        if GameData::Move.exists?(:BEHEMOTHBASH) && pkmn.hasItem?(:RUSTEDSHIELD)
            pkmn.moves.each { |move| move.id = :BEHEMOTHBASH if move.id == :IRONHEAD }
        end
    },
    "getFormOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
        next 0 if endBattle
    },
    "changePokemonOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
        if endBattle
            pkmn.moves.each { |move| move.id = :IRONHEAD if move.id == :BEHEMOTHBASH }
        end
    },
    "getFormOnAttack" => proc { |pkmn, move|
        if pkmn.form == 1 && move == :BEHEMOTHBASH
            next 2
        end
    }
})

MultipleForms.register(:XERNEAS, {
    "getFormOnBattle" => proc { |pkmn|
        if pkmn.ability == :FAIRYAURA && pkmn.form == 0
            next 1
        end
    },
    "getFormOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
        next 0 if endBattle
    }
})

#Pikachu Cosplay
MultipleForms.register(:PIKACHU, {
    "getForm" => proc { |pkmn|
        next if pkmn.form_simple >= 2
        if $game_map
            map_pos = $game_map.metadata&.town_map_position
            next 1 if map_pos && map_pos[0] == 1   # Tiall region
        end
        next 0
    },
    "onSetForm" => proc { |pkmn, form, oldForm|
        form_moves = [
        :ICICLECRASH,     # Pikachu Belle
        :FLYINGPRESS,     # Pikachu Libre
        :ELECTRICTERRAIN, # Pikachu, Ph.D.
        :DRAININGKISS,    # Pikachu Pop Star
        :METEORMASH       # Pikachu Rock Star
        ]
        # Find a known move that should be forgotten
        old_move_index = -1
        pkmn.moves.each_with_index do |move, i|
        next if !form_moves.include?(move.id)
            old_move_index = i
            break
        end
        # Determine which new move to learn (if any)
        new_move_id = (form > 2) && (form < 8) ? form_moves[form - 3] : nil
        new_move_id = nil if !GameData::Move.exists?(new_move_id)
        if new_move_id.nil? && old_move_index >= 0 && pkmn.numMoves == 1
            new_move_id = :THUNDERSHOCK
            new_move_id = nil if !GameData::Move.exists?(new_move_id)
            raise _INTL("Pikachu está intentando olvidar su último movimiento, pero no tiene más movimientos con el que reemplazarlo.") if new_move_id.nil?
        end
        new_move_id = nil if pkmn.hasMove?(new_move_id)
        # Forget a known move (if relevant) and learn a new move (if relevant)
        if old_move_index >= 0
            old_move_name = pkmn.moves[old_move_index].name
        if new_move_id.nil?
            # Just forget the old move
            pkmn.forget_move_at_index(old_move_index)
            pbMessage(_INTL("{1} olvidó {2}...", pkmn.name, old_move_name))
        else
            # Replace the old move with the new move (keeps the same index)
            pkmn.moves[old_move_index].id = new_move_id
            new_move_name = pkmn.moves[old_move_index].name
            pbMessage(_INTL("{1} olvidó {2}...", pkmn.name, old_move_name) + "\1")
            pbMessage("\\se[]" + _INTL("¡{1} aprendió {2}!", pkmn.name, new_move_name) + "\\se[Pkmn move learnt]")
        end
        elsif !new_move_id.nil?
            # Just learn the new move
            pbLearnMove(pkmn, new_move_id, true)
        end
    }
})

#Correccion Zygarde onleaving
MultipleForms.register(:ZYGARDE, {
    "changePokemonOnMegaEvolve" => proc { |battler, battle|
        if GameData::Move.exists?(:NIHILLIGHT)
            if [4, 5].include?(battler.form)
                battler.eachMoveWithIndex do |m, i|
                    next if m.id != :COREENFORCER
                    pokemon_move = battler.pokemon.moves[i]
                    pokemon_move.id = :NIHILLIGHT
                    battler_move = Battle::Move.from_pokemon_move(battle, pokemon_move)
                    battler.moves[i] = battler_move
                    if battle.choices[battler.index][1] == i
                        battle.choices[battler.index][2] = battler_move 
                        battle.pbDisplay(_INTL("{1}'s {2} transform into {3}!", battler.pbThis,
                                        GameData::Move.get(:COREENFORCER).name, 
                                        GameData::Move.get(:NIHILLIGHT).name
                                        ))
                        break
                    end
                end
            end
        end
    },
    "getMegaMoves" => proc { |pkmn|
        next { :COREENFORCER => :NIHILLIGHT }
    },
    "changePokemonOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
        if GameData::Move.exists?(:COREENFORCER) && endBattle
            pkmn.moves.each { |move| move.id = :COREENFORCER if move.id == :NIHILLIGHT }
        end
    },
    "getFormOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
        next pkmn.form - 2 if pkmn.form >= 2 && (pkmn.fainted? || endBattle)
    }
})

#Correcciones Formas OnCreation
MultipleForms.register(:TOXEL, {
    "getFormOnCreation" => proc { |pkmn|
        next 1 if [:LONELY, :BOLD, :RELAXED, :TIMID, :SERIOUS, :MODEST, :MILD,
                    :QUIET, :BASHFUL, :CALM, :GENTLE, :CAREFUL].include?(pkmn.nature_id)
        next 0
    },
    "getForm" => proc { |pkmn|
        next 1 if [:LONELY, :BOLD, :RELAXED, :TIMID, :SERIOUS, :MODEST, :MILD,
                    :QUIET, :BASHFUL, :CALM, :GENTLE, :CAREFUL].include?(pkmn.nature_id)
        next 0
    }
})

MultipleForms.copy(:TOXEL, :TOXTRICITY)

MultipleForms.register(:SCATTERBUG, {
    "getFormOnCreation" => proc { |pkmn|
        next $player.secret_ID % 18
    },
    "getForm" => proc { |pkmn|
        next $player.secret_ID % 18
    }
})

MultipleForms.copy(:SCATTERBUG, :SPEWPA, :VIVILLON)

MultipleForms.register(:TANDEMAUS, {
    "getFormOnCreation" => proc { |pkmn|
        next (pkmn.personalID % 100 == 0) ? 1 : 0
    },
    "getForm" => proc { |pkmn|
        next (pkmn.personalID % 100 == 0) ? 1 : 0
    }
})

MultipleForms.copy(:TANDEMAUS, :MAUSHOLD)

MultipleForms.register(:DUNSPARCE, {
    "getFormOnCreation" => proc { |pkmn|
        next (pkmn.personalID % 100 == 0) ? 1 : 0
    },
    "getForm" => proc { |pkmn|
        next (pkmn.personalID % 100 == 0) ? 1 : 0
    }
})

MultipleForms.copy(:DUNSPARCE, :DUDUNSPARCE)

#Correccion de Fecha y hora de cambio de forma
MultipleForms.register(:FURFROU, {
    "getForm" => proc { |pkmn|
        if !pkmn.time_form_set ||
            pbGetTimeNow.to_i > pkmn.time_form_set.to_i + (60 * 60 * 24 * 5)   # 5 days
            next 0
        end
    },
    "onSetForm" => proc { |pkmn, form, oldForm|
        pkmn.time_form_set = pbGetTimeNow.to_i
    }
})

MultipleForms.register(:HOOPA, {
    "getForm" => proc { |pkmn|
        if Settings::MECHANICS_GENERATION < 9 && (!pkmn.time_form_set ||
            pbGetTimeNow.to_i > pkmn.time_form_set.to_i + (60 * 60 * 24 * 3))   # 3 days
            next 0
        end
    },
    "onSetForm" => proc { |pkmn, form, oldForm|
        pkmn.time_form_set = pbGetTimeNow.to_i if Settings::MECHANICS_GENERATION < 9
        # Move Change
        form_moves = [
        :HYPERSPACEHOLE,    # Confined form
        :HYPERSPACEFURY,    # Unbound form
        ]
        # Find a known move that should be forgotten
        old_move_index = -1
        pkmn.moves.each_with_index do |move, i|
            next if !form_moves.include?(move.id)
            old_move_index = i
            break
        end
        # Determine which new move to learn (if any)
        new_move_id = form_moves[form]
        new_move_id = nil if !GameData::Move.exists?(new_move_id)
        new_move_id = nil if pkmn.hasMove?(new_move_id)
        # Forget a known move (if relevant) and learn a new move (if relevant)
        if old_move_index >= 0
            old_move_name = pkmn.moves[old_move_index].name
            if new_move_id.nil?
                # Just forget the old move
                pkmn.forget_move_at_index(old_move_index)
            else
                # Replace the old move with the new move (keeps the same index)
                pkmn.moves[old_move_index].id = new_move_id
                new_move_name = pkmn.moves[old_move_index].name
                pbMessage("\\se[]" + _INTL("{1} learned {2}!", pkmn.name, new_move_name) + "\\se[Pkmn move learnt]")
            end
        end
    }
})

MultipleForms.register(:SOLGALEO, {
    "getFormOnAttack" => proc { |pkmn, move|
        if pkmn.form == 0 && (move == :SUNSTEELSTRIKE || move == :SEARINGSUNRAZESMASH)
            next 1
        end
    }
})

MultipleForms.register(:LUNALA, {
    "getFormOnAttack" => proc { |pkmn, move|
        if pkmn.form == 0 && (move == :MOONGEISTBEAM || move == :MENACINGMOONRAZEMAELSTROM)
            next 1
        end
    }
})

MultipleForms.register(:MARSHADOW, {
    "getFormOnAttack" => proc { |pkmn, move|
        if pkmn.form == 0 && move == :SOULSTEALING7STARSTRIKE
            next 1
        end
    }
})