; parking management system with file storage
; created by 2 team members
;24K-1041 - Syed Mawahid
;24K-1003 - Umais
; features: error handling, input validation, optimized menus, file persistence
INCLUDE Irvine32.inc

.data
.data
; basic system settings
MAX_CAPACITY = 10

; file management
filename BYTE "parking_records.txt",0
fileHandle DWORD ?
linechange byte 0Dh,0Ah,0
tempBuffer BYTE 20 DUP(?)
fileBuffer BYTE 1000 DUP(?)  ; space for reading file contents

; messages for when things go wrong
error_file BYTE " Error: cannot create file! ",0
error_input BYTE " Error: invalid input! please enter a number.",0
error_full BYTE " Error: parking is full!",0
error_empty BYTE " Error: no vehicles of this type parked!",0
error_range BYTE " Error: input out of valid range!",0
error_load BYTE " Error: cannot load previous data. starting fresh.",0

; messages for when things work well
success_vehicle BYTE " Success: vehicle added successfully!",0
success_remove BYTE " Success: vehicle removed successfully!",0
success_clear BYTE " Success: all records cleared!",0
success_save BYTE " Success: records saved to file!",0
success_load BYTE " Success: previous data loaded successfully!",0

; What users see on screen 
menu_title BYTE "Parking Management System",0ah,0ah,0
menu_capacity BYTE "Capacity: 10 vehicles | Current: ",0
menu_divider BYTE "----------------------------------------",0ah,0

menu_items BYTE 0ah,
" 1. Add Rikshaw (Fee: $1)",0ah,
" 2. Add Car (Fee: $2)",0ah,
" 3. Add Bus (Fee: $3)",0ah,
" 4. Show Records & Save",0ah,
" 5. Remove Vehicle",0ah,
" 6. Clear All Records",0ah,
" 7. Clear Screen",0ah,
" 8. Exit Program",0ah,0ah,0

remove_menu BYTE 0ah,
"Remove Vehicle",0ah,0ah,
" 1. Remove Rikshaw",0ah,
" 2. Remove Car",0ah,
" 3. Remove Bus",0ah,
" 4. Back to Main Menu",0ah,0ah,0

; Display text for user interface
str_vehicle BYTE " Vehicle: ",0
str_fee BYTE " Parking Fee: $",0
str_count BYTE " Current Count: ",0
str_press_enter BYTE " Press ENTER to continue... ",0
str_enter_choice BYTE " Enter your choice (1-8): ",0
str_enter_remove BYTE " Enter choice (1-4): ",0
str_exit BYTE " Thank you for using Parking Management System!",0

; Types of vehicles we track
vehicle_rikshaw BYTE "Rikshaw",0
vehicle_car BYTE "Car",0
vehicle_bus BYTE "Bus",0

; FILE FORMAT STRINGS - MUST MATCH ORIGINAL FORMAT FOR COMPATIBILITY
; These exact strings are used for reading/writing files
str_total_amount BYTE " Total Revenue: $",0
str_total_vehicles BYTE " Total Vehicles: ",0
str_rikshaws BYTE " Rikshaws: ",0
str_cars BYTE " Cars: ",0
str_buses BYTE " Buses: ",0
str_records BYTE "****** PARKING RECORDS ******",0ah,0ah,0

; our main data storage
amount DWORD 0
count DWORD 0
rikshawcount DWORD 0
carcount DWORD 0
buscount DWORD 0
record_number DWORD 0

current_count_str BYTE "   ",0
record_header BYTE "Record #",0
.code

; where our program starts running
main PROC
    call LoadFromFile       ; try to load any saved data first
    mov eax, lightGreen + (black * 16)
    call SetTextColor
    call MainMenu
    call ExitProgram
main ENDP

; set all our counters back to zero
InitializeSystem PROC
    mov amount, 0
    mov count, 0
    mov rikshawcount, 0
    mov carcount, 0
    mov buscount, 0
    mov record_number, 0
    ret
InitializeSystem ENDP

; try to load our saved data from last time
LoadFromFile PROC
    pushad
    
    ; try to open the file we saved last time
    mov edx, OFFSET filename
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je file_not_exist
    
    mov fileHandle, eax
    
    ; read everything from the file
    mov edx, OFFSET fileBuffer
    mov ecx, 1000
    call ReadFromFile
    jc read_error
    
    ; start with empty counts
    call InitializeSystem
    
    ; look through the file and find our numbers
    mov esi, OFFSET fileBuffer
    call FindAndParseCounts
    
    mov eax, fileHandle
    call CloseFile
    
    ; let the user know we found their old data
    mov edx, OFFSET success_load
    call WriteString
    call Crlf
    call WaitForEnter
    jmp load_done
    
read_error:
    mov edx, OFFSET error_load
    call WriteString
    call Crlf
    call InitializeSystem
    jmp load_done
    
file_not_exist:
    ; if no file exists, just start fresh
    call InitializeSystem
    
load_done:
    popad
    ret
LoadFromFile ENDP

; look through the file text and find our saved numbers
FindAndParseCounts PROC
    pushad
    mov esi, OFFSET fileBuffer
    
parse_loop:
    ; look for the total money we had
    mov edi, OFFSET str_total_amount
    call FindString
    jc next_section1
    call ParseNumberAfterColon
    mov amount, eax
    
next_section1:
    ; look for total vehicles count
    mov edi, OFFSET str_total_vehicles
    call FindString
    jc next_section2
    call ParseNumberAfterColon
    mov count, eax
    
next_section2:
    ; look for rikshaws count
    mov edi, OFFSET str_rikshaws
    call FindString
    jc next_section3
    call ParseNumberAfterColon
    mov rikshawcount, eax
    
next_section3:
    ; look for cars count
    mov edi, OFFSET str_cars
    call FindString
    jc next_section4
    call ParseNumberAfterColon
    mov carcount, eax
    
next_section4:
    ; look for buses count
    mov edi, OFFSET str_buses
    call FindString
    jc parse_done
    call ParseNumberAfterColon
    mov buscount, eax
    
parse_done:
    popad
    ret
FindAndParseCounts ENDP

; look for a specific piece of text in our file
FindString PROC
    push eax
    push ebx
    push ecx
    push edx
    
    mov ecx, 500  ; don't search forever
    
search_outer:
    mov ebx, edi  ; what we're looking for
    mov edx, esi  ; where we're looking
    
compare_loop:
    mov al, [ebx]
    cmp al, 0     ; end of what we're searching for?
    je found
    cmp al, [edx]
    jne not_match
    inc ebx
    inc edx
    jmp compare_loop
    
not_match:
    inc esi
    loop search_outer
    stc           ; didn't find it
    jmp done_find
    
found:
    mov esi, edx  ; move past what we found
    clc           ; found it!
    
done_find:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
FindString ENDP

; read a number from text after a label like "total: 123"
ParseNumberAfterColon PROC
    push ebx
    push edx
    xor eax, eax
    xor ebx, ebx
    
    ; skip any spaces
skip_spaces:
    mov bl, [esi]
    cmp bl, ' '
    jne start_parse
    inc esi
    jmp skip_spaces
    
start_parse:
    ; read the number digit by digit
parse_loop:
    mov bl, [esi]
    cmp bl, '0'
    jb parse_done
    cmp bl, '9'
    ja parse_done
    
    ; turn character into number and add to total
    sub bl, '0'
    imul eax, 10
    add eax, ebx
    inc esi
    jmp parse_loop
    
parse_done:
    pop edx
    pop ebx
    ret
ParseNumberAfterColon ENDP

; show error messages in red and wait for user
ExceptionHandler PROC
    call Crlf
    mov eax, red + (black * 16)
    call SetTextColor
    call WriteString
    call Crlf
    mov eax, lightGreen + (black * 16)
    call SetTextColor
    call WaitForEnter
    ret
ExceptionHandler ENDP

; get user input and make sure it's a valid number
SafeInput PROC
    push edx
    mov edx, OFFSET str_enter_choice
    call WriteString
    call ReadInt
    jno input_valid
    call ClearInputBuffer
    mov edx, OFFSET error_input
    call ExceptionHandler
    mov eax, -1
input_valid:
    pop edx
    ret
SafeInput ENDP

; clear any extra characters the user might have typed
ClearInputBuffer PROC
    push ecx
    mov ecx, 1000
clear_loop:
    call ReadChar
    loop clear_loop
    pop ecx
    ret
ClearInputBuffer ENDP

; wait for the user to press enter before continuing
WaitForEnter PROC
    push edx
    call Crlf
    mov edx, OFFSET str_press_enter
    call WriteString
wait_loop:
    call ReadChar
    cmp al, 0Dh
    jne wait_loop
    pop edx
    ret
WaitForEnter ENDP

; show how many parking spots are used and available
DisplayStatus PROC
    pushad
    mov eax, count
    mov edi, OFFSET current_count_str
    call ConvertToString
    mov edx, OFFSET menu_capacity
    call WriteString
    mov edx, OFFSET current_count_str
    call WriteString
    call Crlf
    mov edx, OFFSET menu_divider
    call WriteString
    popad
    ret
DisplayStatus ENDP

; turn a number into text we can display
ConvertToString PROC
    pushad
    mov ebx, 10
    mov ecx, 0
    
    ; handle zero specially
    test eax, eax
    jnz convert_loop
    mov byte ptr [edi], '0'
    mov byte ptr [edi+1], 0
    jmp done_convert
    
convert_loop:
    xor edx, edx
    div ebx
    add dl, '0'
    push dx
    inc ecx
    test eax, eax
    jnz convert_loop
    
    ; put the digits back in order
    mov esi, edi
pop_loop:
    pop ax
    mov [esi], al
    inc esi
    loop pop_loop
    mov byte ptr [esi], 0
    
done_convert:
    popad
    ret
ConvertToString ENDP

; our main menu that users see first
MainMenu PROC
menu_loop:
    call ClrScr
    mov edx, OFFSET menu_title
    call WriteString
    call DisplayStatus
    mov edx, OFFSET menu_items
    call WriteString
    call SafeInput
    cmp eax, -1
    je menu_loop
    call ProcessMenuChoice
    cmp eax, 1
    je menu_loop
    ret
MainMenu ENDP

; figure out what the user wants to do
ProcessMenuChoice PROC
    cmp eax, 1
    je add_rikshaw
    cmp eax, 2
    je add_car
    cmp eax, 3
    je add_bus
    cmp eax, 4
    je show_records
    cmp eax, 5
    je remove_vehicle
    cmp eax, 6
    je clear_records
    cmp eax, 7
    je clear_screen
    cmp eax, 8
    je exit_program
    
    mov edx, OFFSET error_range
    call ExceptionHandler
    mov eax, 1
    ret

add_rikshaw:
    mov esi, OFFSET vehicle_rikshaw
    mov eax, 1
    jmp menu_processed

add_car:
    mov esi, OFFSET vehicle_car
    mov eax, 2
    jmp menu_processed

add_bus:
    mov esi, OFFSET vehicle_bus
    mov eax, 3

menu_processed:
    call AddVehicleHandler
    mov eax, 1
    ret

show_records:
    call ShowRecords
    mov eax, 1
    ret

remove_vehicle:
    call RemoveVehicleMenu
    mov eax, 1
    ret

clear_records:
    call ClearRecords
    mov eax, 1
    ret

clear_screen:
    call ClrScr
    mov eax, 1
    ret

exit_program:
    mov eax, 0
    ret
ProcessMenuChoice ENDP

; check if we have space for another vehicle
AddVehicle PROC
    mov eax, count
    cmp eax, MAX_CAPACITY
    jl capacity_ok
    mov edx, OFFSET error_full
    call ExceptionHandler
    stc
    ret

capacity_ok:
    inc count
    clc
    ret
AddVehicle ENDP

; handle adding a new vehicle to the parking lot
AddVehicleHandler PROC
    pushad
    call AddVehicle
    jc add_failed
    
    ; figure out what type of vehicle and how much it costs
    mov ebx, 0  ; start with zero fee
    
    ; check which vehicle we're adding
    mov edx, esi
    cmp edx, OFFSET vehicle_rikshaw
    je add_rikshaw_count
    cmp edx, OFFSET vehicle_car
    je add_car_count
    cmp edx, OFFSET vehicle_bus
    je add_bus_count
    jmp add_failed  ; something went wrong

add_rikshaw_count:
    inc rikshawcount
    mov ebx, 1  ; rikshaw costs $1
    add amount, 1
    jmp add_success

add_car_count:
    inc carcount
    mov ebx, 2  ; car costs $2
    add amount, 2
    jmp add_success

add_bus_count:
    inc buscount
    mov ebx, 3  ; bus costs $3
    add amount, 3

add_success:
    mov edx, OFFSET success_vehicle
    call WriteString
    call Crlf
    
    mov edx, OFFSET str_vehicle
    call WriteString
    mov edx, esi
    call WriteString
    call Crlf
    
    mov edx, OFFSET str_fee
    call WriteString
    mov eax, ebx  ; show the actual fee
    call WriteDec
    call Crlf
    
    mov edx, OFFSET str_count
    call WriteString
    mov eax, count
    call WriteDec
    call Crlf
    
    call WaitForEnter
    
add_failed:
    popad
    ret
AddVehicleHandler ENDP

; menu for removing vehicles
RemoveVehicleMenu PROC
menu_loop:
    call ClrScr
    mov edx, OFFSET remove_menu
    call WriteString
    
    mov edx, OFFSET str_enter_remove
    call WriteString
    
    call ReadInt
    jno input_ok
    
    call ClearInputBuffer
    mov edx, OFFSET error_input
    call ExceptionHandler
    jmp menu_loop

input_ok:
    cmp eax, 1
    jb invalid_range
    cmp eax, 4
    ja invalid_range
    
    cmp eax, 1
    je remove_rikshaw
    cmp eax, 2
    je remove_car
    cmp eax, 3
    je remove_bus
    cmp eax, 4
    je exit_remove
    
    jmp menu_loop

invalid_range:
    mov edx, OFFSET error_range
    call ExceptionHandler
    jmp menu_loop

remove_rikshaw:
    mov ebx, OFFSET rikshawcount
    mov ecx, 1
    jmp process_remove

remove_car:
    mov ebx, OFFSET carcount
    mov ecx, 2
    jmp process_remove

remove_bus:
    mov ebx, OFFSET buscount
    mov ecx, 3

process_remove:
    call RemoveVehicle
    jmp menu_loop

exit_remove:
    ret
RemoveVehicleMenu ENDP

; remove a vehicle and update our counts
RemoveVehicle PROC
    pushad
    
    mov eax, [ebx]
    test eax, eax
    jz no_vehicle
    
    dec eax
    mov [ebx], eax
    dec count
    
    ; subtract the right amount of money
    cmp ecx, 1
    je sub_rikshaw
    cmp ecx, 2
    je sub_car
    cmp ecx, 3
    je sub_bus

sub_rikshaw:
    sub amount, 1
    jmp remove_success

sub_car:
    sub amount, 2
    jmp remove_success

sub_bus:
    sub amount, 3

remove_success:
    mov edx, OFFSET success_remove
    call WriteString
    call Crlf
    jmp remove_done

no_vehicle:
    mov edx, OFFSET error_empty
    call ExceptionHandler

remove_done:
    call WaitForEnter
    popad
    ret
RemoveVehicle ENDP

; show all our current data and save it to file
ShowRecords PROC
    pushad
    
    call ClrScr
    mov edx, OFFSET str_records
    call WriteString
    
    ; show all the numbers
    mov edx, OFFSET str_total_amount
    call WriteString
    mov eax, amount
    call WriteDec
    call Crlf
    
    mov edx, OFFSET str_total_vehicles
    call WriteString
    mov eax, count
    call WriteDec
    call Crlf
    
    mov edx, OFFSET str_rikshaws
    call WriteString
    mov eax, rikshawcount
    call WriteDec
    call Crlf
    
    mov edx, OFFSET str_cars
    call WriteString
    mov eax, carcount
    call WriteDec
    call Crlf
    
    mov edx, OFFSET str_buses
    call WriteString
    mov eax, buscount
    call WriteDec
    call Crlf
    
    ; save everything to file
    call SaveToFile
    
    call WaitForEnter
    popad
    ret
ShowRecords ENDP

; save our data to a file so we don't lose it
SaveToFile PROC
    pushad
    
    ; create a new file (or overwrite the old one)
    mov edx, OFFSET filename
    call CreateOutputFile
    mov fileHandle, eax
    
    ; make sure the file opened okay
    cmp eax, INVALID_HANDLE_VALUE
    je file_error
    
    ; write the title first
    mov edx, OFFSET str_records
    call StrLength
    mov ecx, eax
    mov eax, fileHandle
    mov edx, OFFSET str_records
    call WriteToFile

    ; write all our numbers
    call WriteSimpleRecord
    
    ; close the file
    mov eax, fileHandle
    call CloseFile
    
    ; let user know it worked
    mov edx, OFFSET success_save
    call WriteString
    call Crlf
    jmp save_done

file_error:
    mov edx, OFFSET error_file
    call WriteString
    call Crlf

save_done:
    popad
    ret
SaveToFile ENDP

; write all our data to the file in a nice format
WriteSimpleRecord PROC
    pushad
    
    ; write total money collected
    mov edx, OFFSET str_total_amount
    call StrLength
    mov ecx, eax
    mov eax, fileHandle
    mov edx, OFFSET str_total_amount
    call WriteToFile
    
    mov eax, amount
    mov edi, OFFSET tempBuffer
    call ConvertToString
    
    mov edx, OFFSET tempBuffer
    call StrLength
    mov ecx, eax
    mov eax, fileHandle
    mov edx, OFFSET tempBuffer
    call WriteToFile
    
    mov edx, OFFSET linechange
    mov ecx, 2
    mov eax, fileHandle
    call WriteToFile
    
    ; write total vehicles
    mov edx, OFFSET str_total_vehicles
    call StrLength
    mov ecx, eax
    mov eax, fileHandle
    mov edx, OFFSET str_total_vehicles
    call WriteToFile
    
    mov eax, count
    mov edi, OFFSET tempBuffer
    call ConvertToString
    
    mov edx, OFFSET tempBuffer
    call StrLength
    mov ecx, eax
    mov eax, fileHandle
    mov edx, OFFSET tempBuffer
    call WriteToFile
    
    mov edx, OFFSET linechange
    mov ecx, 2
    mov eax, fileHandle
    call WriteToFile

    ; write rikshaws count
    mov edx, OFFSET str_rikshaws
    call StrLength
    mov ecx, eax
    mov eax, fileHandle
    mov edx, OFFSET str_rikshaws
    call WriteToFile

    mov eax, rikshawcount
    mov edi, OFFSET tempBuffer
    call ConvertToString

    mov edx, OFFSET tempBuffer
    call StrLength
    mov ecx, eax
    mov eax, fileHandle
    mov edx, OFFSET tempBuffer
    call WriteToFile

    mov edx, OFFSET linechange
    mov ecx, 2
    mov eax, fileHandle
    call WriteToFile

    ; write cars count
    mov edx, OFFSET str_cars
    call StrLength
    mov ecx, eax
    mov eax, fileHandle
    mov edx, OFFSET str_cars
    call WriteToFile

    mov eax, carcount
    mov edi, OFFSET tempBuffer
    call ConvertToString

    mov edx, OFFSET tempBuffer
    call StrLength
    mov ecx, eax
    mov eax, fileHandle
    mov edx, OFFSET tempBuffer
    call WriteToFile

    mov edx, OFFSET linechange
    mov ecx, 2
    mov eax, fileHandle
    call WriteToFile

    ; write buses count
    mov edx, OFFSET str_buses
    call StrLength
    mov ecx, eax
    mov eax, fileHandle
    mov edx, OFFSET str_buses
    call WriteToFile

    mov eax, buscount
    mov edi, OFFSET tempBuffer
    call ConvertToString

    mov edx, OFFSET tempBuffer
    call StrLength
    mov ecx, eax
    mov eax, fileHandle
    mov edx, OFFSET tempBuffer
    call WriteToFile

    mov edx, OFFSET linechange
    mov ecx, 2
    mov eax, fileHandle
    call WriteToFile
    
    popad
    ret
WriteSimpleRecord ENDP

; reset everything back to zero
ClearRecords PROC
    pushad
    
    call ClrScr
    mov edx, OFFSET str_records
    call WriteString
    
    mov edx, OFFSET str_total_vehicles
    call WriteString
    mov eax, count
    call WriteDec
    call Crlf
    
    mov edx, OFFSET str_total_amount
    call WriteString
    mov eax, amount
    call WriteDec
    call Crlf
    
    call Crlf
    mov edx, OFFSET success_clear
    call WriteString
    call Crlf
    
    call InitializeSystem
    
    ; also clear the file
    mov edx, OFFSET filename
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je clear_file_error
    mov fileHandle, eax
    mov eax, fileHandle
    call CloseFile
    
clear_file_error:
    call WaitForEnter
    popad
    ret
ClearRecords ENDP

; say goodbye and end the program
ExitProgram PROC
    call ClrScr
    mov edx, OFFSET str_exit
    call WriteString
    call Crlf
    call Crlf
    exit
ExitProgram ENDP

END main