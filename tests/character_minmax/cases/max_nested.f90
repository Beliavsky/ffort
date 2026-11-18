program p
implicit none

write(*,'(a)')max(max('a','bbb'),'cc'),max(adjustl(' a'),repeat('b',3))
end program
