program p
implicit none

print *,max(-9,0,5),max(-9223372036854775807_8-1_8,9223372036854775807_8),max(a2=7,a1=3),max([1,2,3],2)
end program
