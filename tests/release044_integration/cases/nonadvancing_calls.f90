program p
implicit none
character(24)::fmt
fmt='(*(i0,1x))'
write(*,'(a)',advance='no')'P:'
call emit(fmt)
write(*,'(a)',advance='yes')'done'
contains
subroutine emit(f)
character(*),intent(in)::f
integer::i,j
write(*,fmt=f,advance='nO')((10*i+j,j=1,2),i=1,2)
end subroutine
end program
