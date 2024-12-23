#!/bin/bash

declare -a board
turn=1
player=1
save_file="kolkoikrzyzyk_save.txt"
game_over=false
play_with_computer=true

# Funkcja inicjalizująca planszę
initialize_board() {
    for i in {0..8}; do
        board[$i]=$i
    done
}

# Funkcja wyświetlająca planszę
print_board() {
    echo ""
    echo " ${board[0]} | ${board[1]} | ${board[2]} "
    echo "---+---+---"
    echo " ${board[3]} | ${board[4]} | ${board[5]} "
    echo "---+---+---"
    echo " ${board[6]} | ${board[7]} | ${board[8]} "
    echo ""
}

# Funkcja sprawdzająca zwycięzcę
check_winner() {
    local win_combinations=(
        "0 1 2" "3 4 5" "6 7 8" 
        "0 3 6" "1 4 7" "2 5 8" 
        "0 4 8" "2 4 6"
    )

    for combo in "${win_combinations[@]}"; do
        set -- $combo
        if [[ "${board[$1]}" == "${board[$2]}" && "${board[$2]}" == "${board[$3]}" ]]; then
            echo "${board[$1]}"
            return
        fi
    done

    if [[ ! " ${board[@]} " =~ [0-8] ]]; then
        echo "draw"
    fi
}

# Funkcja zapisująca grę do pliku
save_game() {
    echo "${board[@]}" > "$save_file"
    echo "$player" >> "$save_file"
    echo "$turn" >> "$save_file"
    echo "$play_with_computer" >> "$save_file"
    echo "Gra została zapisana."
}

# Funkcja wczytująca grę z pliku
load_game() {
    if [[ -f "$save_file" ]]; then
        read -a board < "$save_file"
        read player < <(tail -n 3 "$save_file" | head -n 1)
        read turn < <(tail -n 2 "$save_file" | head -n 1)
        read play_with_computer < <(tail -n 1 "$save_file")
        echo "Gra została wczytana."
        game_over=false
    else
        echo "Brak zapisanej gry."
        initialize_board
    fi
}

# Funkcja obsługująca ruch gracza
player_move() {
    local move
    while true; do
        read -p "Gracz $player, wybierz pole (0-8) lub wpisz 'q', aby zapisać i zakończyć grę: " move
        if [[ "$move" == "q" ]]; then
            save_game
            echo "Gra została zapisana. Zakończono grę."
            exit 0
        elif [[ "$move" =~ ^[0-8]$ ]] && [[ "${board[$move]}" == "$move" ]]; then
            board[$move]=$1
            break
        else
            echo "Nieprawidłowy ruch, spróbuj ponownie."
        fi
    done
}

# Funkcja obsługująca ruch komputera
computer_move() {
    echo "Komputer wykonuje ruch..."
    # Priorytet 1: Wygrana w jednym ruchu
    for i in {0..8}; do
        if [[ "${board[$i]}" == "$i" ]]; then
            board[$i]=O
            if [[ "$(check_winner)" == "O" ]]; then
                return
            else
                board[$i]=$i
            fi
        fi
    done

    # Priorytet 2: Zablokowanie wygranej gracza
    for i in {0..8}; do
        if [[ "${board[$i]}" == "$i" ]]; then
            board[$i]=X
            if [[ "$(check_winner)" == "X" ]]; then
                board[$i]=O
                return
            else
                board[$i]=$i
            fi
        fi
    done

    # Priorytet 3: Zajęcie środka, jeśli wolny
    if [[ "${board[4]}" == "4" ]]; then
        board[4]=O
        return
    fi

    # Priorytet 4: Zajęcie narożnika, jeśli wolny
    for corner in 0 2 6 8; do
        if [[ "${board[$corner]}" == "$corner" ]]; then
            board[$corner]=O
            return
        fi
    done

    # Priorytet 5: Zajęcie dowolnego wolnego pola
    for i in {0..8}; do
        if [[ "${board[$i]}" == "$i" ]]; then
            board[$i]=O
            return
        fi
    done
}

# Główna pętla gry
main_game_loop() {
    game_over=false
    while ! $game_over; do
        print_board
        local winner=$(check_winner)
        if [[ -n "$winner" ]]; then
            if [[ "$winner" == "draw" ]]; then
                echo "Remis!"
            else
                echo "Zwycięża: $winner!"
            fi
            game_over=true
            break
        fi

        if [[ "$player" == 1 ]]; then
            player_move X
        else
            if $play_with_computer; then
                computer_move
            else
                player_move O
            fi
        fi

        winner=$(check_winner)
        if [[ -n "$winner" ]]; then
            print_board
            if [[ "$winner" == "draw" ]]; then
                echo "Remis!"
            else
                echo "Zwycięża: $winner!"
            fi
            game_over=true
            break
        fi

        player=$((3-player))
        ((turn++))
    done
}

# Menu gry
menu() {
    while true; do
        echo "1. Nowa gra"
        echo "2. Wczytaj grę"
        echo "3. Zakończ"
        read -p "Wybierz opcję: " choice

        case $choice in
            1)
                read -p "Czy chcesz grać z komputerem? (y/n): " computer_choice
                if [[ "$computer_choice" == "y" ]]; then
                    play_with_computer=true
                else
                    play_with_computer=false
                fi
                initialize_board
                main_game_loop
                ;;
            2)
                load_game
                if ! $game_over; then
                    main_game_loop
                fi
                ;;
            3)
                echo "Do widzenia!"
                break
                ;;
            *)
                echo "Nieprawidłowy wybór."
                ;;
        esac

        if $game_over; then
            echo "Gra zakończona. Powrót do menu."
            game_over=false
        fi
    done
}

menu
