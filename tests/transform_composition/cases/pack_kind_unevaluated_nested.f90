program main
implicit none
integer(8)::a(4)
integer::sh(2)
logical::m(2,2),q(4)
print *,kind(pack(reshape(a,sh),m)),kind(reshape(pack(a,q),sh))
end program
