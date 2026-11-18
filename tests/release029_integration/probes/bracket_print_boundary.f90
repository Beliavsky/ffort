! Synthetic release 0.29 composition fixture; not an extracted utility body.
program composition
implicit none
character(:),allocatable::a(:,:,:)
allocate(character(4)::a(2,2,2))
a='abcd'
call update(a(2:1:-1,1:2,2:1:-1))
print '(3a)','[',a(1,1,2),']'
print '(3a)','[',a(2,2,1),']'
contains
subroutine update(x)
character(*),optional,intent(in &
 ! Comment and blank lines do not end the declaration.

 & out)::x(:,:,:)
if(present(x)) then
 print *,shape(x),len(x),shape(x(1,:,:))
 x(:,:,1)='xy'
end if
end subroutine
end program
