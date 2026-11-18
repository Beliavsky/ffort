program main
implicit none
character(:),allocatable::s
s='A '//new_line('x')//'B '
if(digits(1)/=31.or.digits(1.0)/=24.or.digits(1.0d0)/=53) error stop 1
if(rrspacing(1.0)/=8388608.0.or.rrspacing(1.0d0)/=4503599627370496.0d0) error stop 2
write(*,'(a,:,"SHOULD NOT APPEAR")') s
write(*,'(a,1x,:,a)') '[x ]','[y  ]'
end program
