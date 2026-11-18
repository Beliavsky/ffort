program p
implicit none
integer(8)::a,b
a=-9223372036854775807_8-1_8;b=1_8
print *,sign(a,b)
end program
