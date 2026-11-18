program p
implicit none
logical::a(-2:2)
a=[.true.,.false.,.true.,.false.,.true.]
print *,parity(a(2:-2:-2)),parity(a(1:-1:-2))
end program
