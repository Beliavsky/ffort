program p
implicit none

print *,min(-9,0,5),min(-9223372036854775807_8-1_8,9223372036854775807_8),min(a2=7,a1=3),min([1,2,3],2)
end program
