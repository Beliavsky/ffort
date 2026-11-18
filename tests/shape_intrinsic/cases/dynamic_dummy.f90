program p
implicit none
integer::a(2,3),b(4,1,2)
a=0
b=0
call inspect(a,b)
contains
subroutine inspect(x,y)
integer,intent(in)::x(:,:),y(:,:,:)
print *,shape(x),shape(y),shape(x(:,2:3))
end subroutine
end program
