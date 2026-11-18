program bits_driver
implicit none
integer(4)::a(0,2,3),s
print *,size(ior(a,s)),kind(ior(a,s))
end program
