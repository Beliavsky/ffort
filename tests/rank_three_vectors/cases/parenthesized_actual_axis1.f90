program p
implicit none
integer::a(3,3,3),idx(2)
a=1
idx=[3,1]
call inspect((a(idx,:,:)))
print '(i0)',1
contains
subroutine inspect(x)
integer,intent(in)::x(:,:,:)
if(sum(x)/=18)error stop 1
end subroutine
end program
