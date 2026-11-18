program main
implicit none
integer::i
real(8)::a(5),z
z=-0.0_8
a=[z,(0.125_8*i,i=-1,2)]
print *,a
end program
