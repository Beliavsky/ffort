program p
implicit none

print *, 'must not leak', lge('aé','z')
end program
