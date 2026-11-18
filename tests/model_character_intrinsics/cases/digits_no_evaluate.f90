program p
implicit none
integer::z
real(8)::r
z=0
r=0
print *,digits(1/z),digits(1d0/r),kind(digits(1d0/r))
end program
