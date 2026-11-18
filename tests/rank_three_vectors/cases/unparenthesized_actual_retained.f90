program p
implicit none
integer::a(3,3,3),idx(2)
a=1
idx=[3,1]
call inspect(a(:,:,idx))
contains
subroutine inspect(x)
integer,intent(in)::x(:,:,:)
end subroutine
end program
