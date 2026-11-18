program p
implicit none
character(8)::s
write(s,'(*(g0))')'a',1,.true.
write(*,'(a)')s
end program
