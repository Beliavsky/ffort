program main
implicit none
integer(8)::a(4)
integer::sh(2)
sh=[-1,4]
print *,kind(pack(reshape(a,sh),.true.))
end program
