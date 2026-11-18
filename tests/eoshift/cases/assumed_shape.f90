program p
implicit none
integer::a(2,3)
a=reshape([1,2,3,4,5,6],[2,3])
call f(a,[-1,2],[-8,-9])
contains
subroutine f(a,s,b)
integer,intent(in)::a(:,:),s(:),b(:)
write(*,'(*(i0,1x))')eoshift(a,s,b,dim=2)
end subroutine
end program
