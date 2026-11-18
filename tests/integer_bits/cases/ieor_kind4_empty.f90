program bits_driver
implicit none
integer(4)::a(0,2,3),s
print *,size(ieor(a,s)),kind(ieor(a,s))
end program
