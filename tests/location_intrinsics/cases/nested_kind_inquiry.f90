program main
implicit none
real(8)::a(2)
print *,kind(minloc(a,kind=kind(a))),kind(minloc(a,kind=kind(minloc(a,kind=8))))
end program
