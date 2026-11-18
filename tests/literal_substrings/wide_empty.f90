program p
implicit none
integer(8)::lo,hi
lo=9223372036854775807_8;hi=-9223372036854775807_8-1_8
if(len('abc'(lo:hi))/=0) error stop 1
print *, 'wide empty' 
end program
