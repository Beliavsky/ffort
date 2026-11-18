program bits_driver
implicit none
integer(4)::a(0,2,3),s
print *,size(iand(a,s)),kind(iand(a,s))
end program
