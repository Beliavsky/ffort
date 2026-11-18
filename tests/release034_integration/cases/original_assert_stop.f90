program main
use original_positions
implicit none
integer,allocatable::selected(:)
selected=positions_char_string('banana','a')
write(*,'(a)')'checked positions'
call assert_le(size(selected),2,'positions','limit','pipeline')
write(*,'(a)')'must not appear'
end program
