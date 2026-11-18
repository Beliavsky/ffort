program p
implicit none

print *, 'must not leak', llt('aé','z')
end program
