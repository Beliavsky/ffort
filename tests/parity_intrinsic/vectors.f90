program p
implicit none

print *,parity([.false.]),parity([.true.]),parity([.true.,.true.]),parity([.true.,.true.,.true.])
end program
