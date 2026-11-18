program main
implicit none
real,pointer::p(:)
print *,minexponent(p),maxexponent(p)
nullify(p)
print *,minexponent(p),maxexponent(p)
end program
