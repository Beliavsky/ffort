program p
implicit none
integer::a(3,3,3),idx(2)
a=1
idx=[3,1]
call change((a(:,idx,:)))
contains
subroutine change(x)
integer,intent(out)::x(:,:,:)
x=1
end subroutine
end program
