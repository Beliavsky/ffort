program p
implicit none
logical::mask(2,3)
mask(:,1)=[.true.,.false.]
mask(:,2)=.true.
mask(:,3)=.false.
call inspect(mask(:,3:1:-1),2)
contains
subroutine inspect(x,dim)
logical,intent(in)::x(:,:)
integer,intent(in)::dim
print *,all(x,1),any(x,dim),count(x,dim,8),dble(count(x))
end subroutine
end program
