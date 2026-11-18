program p
implicit none

write(*,'(a)')max('ba','azzz'),max('a ','a!'),max(' ab','a'),max('a','a'//char(0))
end program
