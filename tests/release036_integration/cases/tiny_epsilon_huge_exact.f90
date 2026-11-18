program main
implicit none
real(8)::x
integer(8)::i
write(*,'("binary:",6(1x,i0))') &
merge(1,0,epsilon(x)==2d0**(-52)),merge(1,0,tiny(x)==2d0**(-1022)), &
merge(1,0,huge(x)==(2d0-2d0**(-52))*2d0**1023),radix(x),radix(i),kind(huge(i))
print *,epsilon(x),tiny(x),huge(x),huge(i)
end program
