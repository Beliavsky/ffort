program p
implicit none

write(*,'(a)')min(min('a','bbb'),'cc'),min(adjustl(' a'),repeat('b',3))
end program
