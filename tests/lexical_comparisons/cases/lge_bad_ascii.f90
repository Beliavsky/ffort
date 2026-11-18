program p
implicit none

print *, 'must not leak', lge('é','a')
end program
